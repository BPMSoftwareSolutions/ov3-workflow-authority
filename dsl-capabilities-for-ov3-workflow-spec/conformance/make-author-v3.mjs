// Writes source/model.apply_capability_from_dsl.v3.sql from the installed revision (source/model.apply_capability_from_dsl.new.sql)
// by anchored edits (each anchor exactly once):
//   - a source that pins its feature does not re-point the feature bound before; at the end of the change, once the
//     topology and the label have selected the capability's final version, the retained feature bytes become the canonical
//     feature of that version, and the change commits only when analysis.check_capability_feature_conformance finds the
//     binding CONFORMANT;
//   - a source that pins no feature has its bound feature re-pointed once more at the end, so the binding follows the
//     version the change finally selected (today it can stay on the version before the topology's).
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
let t = fs.readFileSync(path.join(root, "source", "model.apply_capability_from_dsl.new.sql"), "utf8").replace(/\r\n/g, "\n");
const edit = (anchor, replacement) => {
  const n = t.split(anchor).length - 1;
  if (n !== 1) throw new Error(`anchor found ${n} times: ${anchor.slice(0, 120)}`);
  t = t.replace(anchor, () => replacement);
};
edit(String.raw`  EXEC model.declare_capability_document @document=@doc;
  EXEC model.repoint_capability_feature @capability_id=@cap;`,
  String.raw`  EXEC model.declare_capability_document @document=@doc;
  -- A source that pins its feature is bound to that feature at the end of this change, not to the one bound before.
  DECLARE @feature_digest nvarchar(80)=JSON_VALUE(@doc,N'$.feature.digest');
  IF @feature_digest IS NULL
    EXEC model.repoint_capability_feature @capability_id=@cap;`);
edit(String.raw`  SELECT N'capability_from_dsl_applied' AS result_set,@cap AS capability_id,N'INSTALLED' AS disposition,`,
  String.raw`  -- The feature binding follows the version this change finally selected: the topology and the label above can select a
  -- later capability version than the document's declaration did.
  IF @feature_digest IS NULL
    EXEC model.repoint_capability_feature @capability_id=@cap;
  ELSE
  BEGIN
    -- Feature first: the source pins the feature whose retained bytes it was compiled against. Those exact bytes become the
    -- canonical feature of the selected version, and the change commits only when the no-drift check finds the binding
    -- CONFORMANT; any other answer rolls the whole declaration back.
    DECLARE @feature_text nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
      FROM source.content_object co WHERE co.content_digest=TRY_CONVERT(binary(32),SUBSTRING(@feature_digest,8,64),2));
    IF @feature_text IS NULL THROW 51000,N'CAPABILITY_FROM_DSL_FEATURE_NOT_RETAINED',1;
    EXEC model.declare_capability_feature @capability_id=@cap,@feature_text=@feature_text;
    DECLARE @feature_version bigint=(SELECT TOP (1) fv.feature_version_pk FROM model.feature_version fv
      JOIN model.capability c ON c.capability_pk=fv.capability_pk
      JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
      JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=fv.semantic_object_definition_pk
      JOIN source.content_object env ON env.content_object_pk=d.canonical_content_pk
      WHERE c.capability_id=@cap COLLATE Latin1_General_100_BIN2
        AND JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),env.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),N'$.semantics.content_digest')=SUBSTRING(@feature_digest,8,64)
      ORDER BY fv.feature_version_pk DESC);
    IF @feature_version IS NULL THROW 51000,N'CAPABILITY_FROM_DSL_FEATURE_NOT_DECLARED',1;
    EXEC model.repoint_capability_feature @capability_id=@cap,@feature_version_pk=@feature_version;
    DECLARE @conformance nvarchar(max)=NULL,@conformance_request nvarchar(max)=(SELECT @cap AS capabilityId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    EXEC analysis.check_capability_feature_conformance @input=@conformance_request,@estate_model_pk=@estate,@result=@conformance OUTPUT,@emit=0;
    SELECT N'capability_feature_conformance' AS result_set,JSON_VALUE(@conformance,N'$.status') AS status,
      JSON_VALUE(@conformance,N'$.summary.signature') AS signature,@feature_digest AS feature_digest,@feature_version AS feature_version_pk;
    IF ISNULL(JSON_VALUE(@conformance,N'$.status'),N'')<>N'CONFORMANT'
    BEGIN
      DECLARE @drift nvarchar(2048)=N'CAPABILITY_FROM_DSL_FEATURE_DRIFT: '+ISNULL(JSON_VALUE(@conformance,N'$.summary.signature'),N'(the check returned nothing)');
      THROW 51000,@drift,1;
    END
  END
  SELECT N'capability_from_dsl_applied' AS result_set,@cap AS capability_id,N'INSTALLED' AS disposition,`);
const out = path.join(root, "source", "model.apply_capability_from_dsl.v3.sql");
fs.writeFileSync(out, t);
console.log("wrote", out, t.length, "chars");
