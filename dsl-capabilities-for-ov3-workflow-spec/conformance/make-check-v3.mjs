// Revises conformance/check_capability_feature_conformance.body.sql in place by anchored edits (each anchor exactly once):
//   - document mode: {"featureText" or "featureDigest", "document"} checks a feature against a compiled document, as the
//     compiler does for a source that pins its feature, before anything is declared;
//   - provider bindings in both directions: PROVIDER_TAG_UNBOUND and PROVIDER_BINDING_UNTAGGED, from the operations a
//     scenario declares with providerCapabilityId (the declared execution authority, or the document);
//   - DSL_FEATURE_STALE: the installed capability document pins another feature digest than the bound one;
//   - @result OUTPUT and @emit, so the compiler and the author path call the check without a result set.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
const here = path.dirname(fileURLToPath(import.meta.url));
const file = path.join(here, "check_capability_feature_conformance.body.sql");
let t = fs.readFileSync(file, "utf8").replace(/\r\n/g, "\n");
if (t.includes("PROVIDER_TAG_UNBOUND")) throw new Error("already revised");
const edit = (anchor, replacement) => {
  const n = t.split(anchor).length - 1;
  if (n !== 1) throw new Error(`anchor found ${n} times: ${anchor.slice(0, 120)}`);
  t = t.replace(anchor, () => replacement);
};

edit(String.raw`-- Body of analysis.check_capability_feature_conformance (parameters @input nvarchar(max), @estate_model_pk bigint).`,
  String.raw`-- Body of analysis.check_capability_feature_conformance (parameters @input nvarchar(max), @estate_model_pk bigint,
-- @result nvarchar(max) OUTPUT, @emit bit): the result is returned in @result, and also selected as value when @emit is 1.`);
edit(String.raw`--   {"featureText" | "featureDigest", "capabilityId"?} that text; with capabilityId, compared with its declaration`,
  String.raw`--   {"featureText" | "featureDigest", "capabilityId"?} that text; with capabilityId, compared with its declaration
--   {"featureText" | "featureDigest", "document"}    that text against a compiled document, before anything is declared`);

edit(String.raw`DECLARE @acc nvarchar(max) = JSON_QUERY(@input, N'$.acceptance');`,
  String.raw`DECLARE @acc nvarchar(max) = JSON_QUERY(@input, N'$.acceptance');
DECLARE @docin nvarchar(max) = JSON_QUERY(@input, N'$.document');`);
edit(String.raw`  WHEN @ftext IS NOT NULL OR @fdig IS NOT NULL THEN N'text' ELSE N'bound' END;`,
  String.raw`  WHEN @docin IS NOT NULL THEN N'document' WHEN @ftext IS NOT NULL OR @fdig IS NOT NULL THEN N'text' ELSE N'bound' END;`);

// The capability under check in document mode is the document's.
edit(String.raw`IF @mode = N'baseline'
  INSERT #cap(capability_pk, capability_id, cvpk)`,
  String.raw`IF @mode = N'document'
  INSERT #cap(capability_id, lookup) VALUES(ISNULL(@capId, JSON_VALUE(@docin, N'$.capabilityId')), 'DOCUMENT');
ELSE IF @mode = N'baseline'
  INSERT #cap(capability_pk, capability_id, cvpk)`);

// The declared side, from the document.
edit(String.raw`CREATE TABLE #dstep(fid int NOT NULL, scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL, ord int NOT NULL, stype varchar(20) NULL,
  text nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);`,
  String.raw`IF @mode = N'document'
  INSERT #dsc(fid, scenario_pk, scenario_id, svpk, is_root, input_id, input_contract, event_id, event_authority, outcome_id, outcome_contract, terminal, eavpk, envelope)
  SELECT k.fid, 0, s.scenarioId, 0, CASE WHEN s.root = N'true' THEN 1 ELSE 0 END, s.inputId, s.inputContract, s.eventId, s.eventAuthority,
    s.outcomeId, s.outcomeContract, CASE WHEN s.terminal = N'true' THEN 1 ELSE 0 END, NULL, s.scen
  FROM #cap k CROSS APPLY OPENJSON(@docin, N'$.scenarios') WITH (scenarioId nvarchar(400) N'$.scenarioId', root nvarchar(10) N'$.root',
    terminal nvarchar(10) N'$.terminal', inputId nvarchar(400) N'$.inputId', inputContract nvarchar(400) N'$.inputContract',
    eventId nvarchar(400) N'$.eventId', eventAuthority nvarchar(400) N'$.eventAuthority', outcomeId nvarchar(400) N'$.outcomeId',
    outcomeContract nvarchar(400) N'$.outcomeContract', scen nvarchar(max) N'$' AS JSON) s
  WHERE k.lookup = 'DOCUMENT' AND s.scenarioId IS NOT NULL AND EXISTS (SELECT 1 FROM #feat f WHERE f.fid = k.fid);
CREATE TABLE #dstep(fid int NOT NULL, scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL, ord int NOT NULL, stype varchar(20) NULL,
  text nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);`);
edit(String.raw`CROSS APPLY OPENJSON(CASE WHEN ISJSON(j.value) = 1 THEN j.value END) WITH (text nvarchar(max) N'$.text') x;`,
  String.raw`CROSS APPLY OPENJSON(CASE WHEN ISJSON(j.value) = 1 THEN j.value END) WITH (text nvarchar(max) N'$.text') x
WHERE @mode <> N'document';
-- A document's scenario states its steps as given, when and then.
INSERT #dstep(fid, scenario_id, ord, stype, text)
SELECT d.fid, d.scenario_id, v.ord, v.stype, v.txt FROM #dsc d
CROSS APPLY (VALUES (0, 'Context', JSON_VALUE(d.envelope, N'$.given')), (1, 'Action', JSON_VALUE(d.envelope, N'$.when')),
  (2, 'Outcome', JSON_VALUE(d.envelope, N'$.then'))) v(ord, stype, txt)
WHERE @mode = N'document' AND v.txt IS NOT NULL;`);
edit(String.raw`INSERT #dvar SELECT d.fid, d.scenario_id, ov.variant_id FROM #dsc d JOIN model.outcome_variant ov ON ov.scenario_version_pk = d.svpk WHERE ov.variant_id IS NOT NULL;`,
  String.raw`INSERT #dvar SELECT d.fid, d.scenario_id, ov.variant_id FROM #dsc d JOIN model.outcome_variant ov ON ov.scenario_version_pk = d.svpk WHERE ov.variant_id IS NOT NULL;
-- A document's variants are those it declares; without them, they are derived as model.declare_capability_document derives
-- them: the status enum of the outcome contract, or the one return of a terminal scenario (its status const, else RETURNED).
INSERT #dvar SELECT d.fid, d.scenario_id, x.variantId FROM #dsc d
CROSS APPLY OPENJSON(d.envelope, N'$.variants') WITH (variantId nvarchar(400) N'$.variantId') x WHERE @mode = N'document' AND x.variantId IS NOT NULL;
INSERT #dvar SELECT d.fid, d.scenario_id, CONVERT(nvarchar(400), e.value) FROM #dsc d
CROSS APPLY (SELECT TOP (1) JSON_QUERY(c.value, N'$.schema') AS sch FROM OPENJSON(@docin, N'$.contracts') c
  WHERE JSON_VALUE(c.value, N'$.id') = d.outcome_contract) sc
CROSS APPLY OPENJSON(sc.sch, N'$.properties.status.enum') e
WHERE @mode = N'document' AND NOT EXISTS (SELECT 1 FROM #dvar v WHERE v.fid = d.fid AND v.scenario_id = d.scenario_id);
INSERT #dvar SELECT d.fid, d.scenario_id, COALESCE(JSON_VALUE(sc.sch, N'$.properties.status.const'), N'RETURNED') FROM #dsc d
OUTER APPLY (SELECT TOP (1) JSON_QUERY(c.value, N'$.schema') AS sch FROM OPENJSON(@docin, N'$.contracts') c
  WHERE JSON_VALUE(c.value, N'$.id') = d.outcome_contract) sc
WHERE @mode = N'document' AND d.terminal = 1 AND NOT EXISTS (SELECT 1 FROM #dvar v WHERE v.fid = d.fid AND v.scenario_id = d.scenario_id);`);
edit(String.raw`INSERT #dop SELECT d.fid, d.scenario_id, o.operation_id FROM #dsc d JOIN model.execution_operation o ON o.execution_authority_version_pk = d.eavpk WHERE o.operation_id IS NOT NULL;`,
  String.raw`INSERT #dop SELECT d.fid, d.scenario_id, o.operation_id FROM #dsc d JOIN model.execution_operation o ON o.execution_authority_version_pk = d.eavpk WHERE o.operation_id IS NOT NULL;
INSERT #dop SELECT d.fid, d.scenario_id, x.operationId FROM #dsc d
CROSS APPLY OPENJSON(d.envelope, N'$.operations') WITH (operationId nvarchar(400) N'$.operationId') x WHERE @mode = N'document' AND x.operationId IS NOT NULL;
-- The provider capability each operation names by identity: in the declared execution authority's operations, or the document's.
CREATE TABLE #dprov(fid int NOT NULL, scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
  operation_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL, provider_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL);
INSERT #dprov SELECT d.fid, d.scenario_id, x.operationId, x.providerCapabilityId FROM #dsc d
CROSS APPLY OPENJSON(d.envelope, N'$.operations') WITH (operationId nvarchar(400) N'$.operationId', providerCapabilityId nvarchar(400) N'$.providerCapabilityId') x
WHERE @mode = N'document' AND x.providerCapabilityId IS NOT NULL;
INSERT #dprov SELECT d.fid, d.scenario_id, x.operationId, x.providerCapabilityId
FROM #dsc d JOIN model.execution_authority_version av ON av.execution_authority_version_pk = d.eavpk
JOIN model.semantic_object_definition sd ON sd.semantic_object_definition_pk = av.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk = sd.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS env) a
CROSS APPLY OPENJSON(CASE WHEN ISJSON(a.env) = 1 THEN a.env END, N'$.semantics.authority.operations')
  WITH (operationId nvarchar(400) N'$.operationId', providerCapabilityId nvarchar(400) N'$.providerCapabilityId') x
WHERE @mode <> N'document' AND x.providerCapabilityId IS NOT NULL;`);

// The comparisons that need the declared side read #dsc; a document has one too.
edit(String.raw`-- Provider tags resolve exactly to a selected capability.`,
  String.raw`-- Provider tags equal the provider capabilities the scenario's operations name, in both directions. A tag that does not
-- resolve is PROVIDER_UNKNOWN only.
INSERT #fd(fid, code, scenario_id, line, fval)
SELECT c.fid, 'PROVIDER_TAG_UNBOUND', s.tval, MIN(c.line), p.tval
FROM #case c JOIN #pt s ON s.pk = c.pk AND s.tkey = N'scenario' JOIN #pt p ON p.pk = c.pk AND p.tkey = N'provider'
WHERE EXISTS (SELECT 1 FROM #dsc d WHERE d.fid = c.fid AND d.scenario_id = s.tval)
  AND NOT EXISTS (SELECT 1 FROM #dprov v WHERE v.fid = c.fid AND v.scenario_id = s.tval AND v.provider_id = p.tval)
  AND EXISTS (SELECT 1 FROM model.estate_capability ec JOIN model.capability cp ON cp.capability_pk = ec.capability_pk
    JOIN model.identity_namespace ns ON ns.namespace_pk = cp.namespace_pk AND ns.namespace_id = N'sidefx:capabilities'
    WHERE ec.estate_model_pk = @e AND cp.capability_id COLLATE Latin1_General_100_BIN2 = p.tval)
GROUP BY c.fid, s.tval, p.tval;
INSERT #fd(fid, code, scenario_id, fval, dval)
SELECT v.fid, 'PROVIDER_BINDING_UNTAGGED', v.scenario_id, v.operation_id, v.provider_id FROM #dprov v
WHERE EXISTS (SELECT 1 FROM #case c JOIN #pt s ON s.pk = c.pk AND s.tkey = N'scenario' AND s.tval = v.scenario_id WHERE c.fid = v.fid)
  AND NOT EXISTS (SELECT 1 FROM #case c JOIN #pt s ON s.pk = c.pk AND s.tkey = N'scenario' AND s.tval = v.scenario_id
    JOIN #pt p ON p.pk = c.pk AND p.tkey = N'provider' AND p.tval = v.provider_id WHERE c.fid = v.fid);

-- The installed capability document pins the feature it was compiled against; a pin other than the bound feature is drift.
INSERT #fd(fid, code, fval, dval)
SELECT f.fid, 'DSL_FEATURE_STALE', f.content_digest, x.pinned
FROM #feat f JOIN #cap k ON k.fid = f.fid
CROSS APPLY (SELECT TOP (1) JSON_VALUE(d.definition_json, N'$.semantics.document_digest') AS dig FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk = @e AND d.object_kind = 'CAPABILITY_DOCUMENT' AND d.namespace_id = N'sidefx:capability-documents'
    AND d.declared_id = k.capability_id) doc
JOIN source.content_object co ON co.content_digest = TRY_CONVERT(binary(32), doc.dig, 2)
CROSS APPLY (SELECT JSON_VALUE(CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), N'$.feature.digest') AS pinned) x
WHERE @mode <> N'baseline' AND f.source = 'binding' AND x.pinned IS NOT NULL AND x.pinned COLLATE Latin1_General_100_BIN2 <> f.content_digest COLLATE Latin1_General_100_BIN2;

-- Provider tags resolve exactly to a selected capability.`);

// A document is a declaration: CONFORMANT or DRIFT.
edit(String.raw`    WHEN EXISTS (SELECT 1 FROM #fd f WHERE f.fid = k.fid) THEN CASE WHEN k.cvpk IS NULL THEN 'MALFORMED' ELSE 'DRIFT' END
    ELSE CASE WHEN k.cvpk IS NULL THEN 'WELL_FORMED' ELSE 'CONFORMANT' END END`,
  String.raw`    WHEN EXISTS (SELECT 1 FROM #fd f WHERE f.fid = k.fid) THEN CASE WHEN k.cvpk IS NULL AND k.lookup <> 'DOCUMENT' THEN 'MALFORMED' ELSE 'DRIFT' END
    ELSE CASE WHEN k.cvpk IS NULL AND k.lookup <> 'DOCUMENT' THEN 'WELL_FORMED' ELSE 'CONFORMANT' END END`);

// The result is returned, and selected only when asked.
edit(String.raw`SELECT @res AS value;
END`,
  String.raw`SET @result = @res;
IF @emit = 1 SELECT @res AS value;
END`);

fs.writeFileSync(file, t);
console.log("revised", file, t.length, "chars");
