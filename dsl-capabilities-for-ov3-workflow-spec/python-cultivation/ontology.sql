-- Public declaration summaries only. Select the active capability version and the latest selected
-- non-capability definition in the same model. No credentials or provider configurations are exported.
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
WITH selected AS (
    SELECT ns.namespace_id ns,o.declared_id id,o.object_kind kind,d.definition_digest,d.canonical_content_pk,
      ROW_NUMBER() OVER(PARTITION BY o.semantic_object_pk ORDER BY d.semantic_object_definition_pk DESC) AS revision
    FROM model.estate_definition ed JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ed.semantic_object_definition_pk
    JOIN model.semantic_object o ON o.semantic_object_pk=d.semantic_object_pk JOIN model.identity_namespace ns ON ns.namespace_pk=o.namespace_pk
    LEFT JOIN model.estate_capability ec ON ec.semantic_object_definition_pk=d.semantic_object_definition_pk AND ec.estate_model_pk=@estate
    WHERE ed.estate_model_pk=@estate AND (o.object_kind<>'CAPABILITY' OR ec.capability_pk IS NOT NULL) AND ns.namespace_id IN
      ('sidefx:capabilities','sidefx:platform-capabilities','sidefx:dependencies','sidefx:providers','sidefx:mechanics')
)
SELECT (SELECT @estate AS estateModel,CONVERT(varchar(32),SYSUTCDATETIME(),126)+'Z' AS capturedAt,
    JSON_QUERY((SELECT s.ns,s.id,s.kind,'sha256:'+LOWER(CONVERT(varchar(64),s.definition_digest,2)) AS digest,
        LEFT(COALESCE(JSON_VALUE(doc.body,'$.semantics.authority.userStory.intent'),JSON_VALUE(doc.body,'$.semantics.mechanic.meaning'),
            JSON_VALUE(doc.body,'$.semantics.meaning'),JSON_VALUE(doc.body,'$.semantics.name'),s.id),400) AS intent,
        LEFT(COALESCE(JSON_VALUE(doc.body,'$.semantics.authority.userStory.outcome'),JSON_VALUE(doc.body,'$.semantics.mechanic.output')),300) AS outcome,
        COALESCE(JSON_VALUE(doc.body,'$.semantics.mechanic.inputContractId'),JSON_VALUE(doc.body,'$.semantics.authority.scenarios[0].inputContract')) AS inputContract,
        COALESCE(JSON_VALUE(doc.body,'$.semantics.mechanic.outputContractId'),JSON_VALUE(doc.body,'$.semantics.authority.scenarios[0].outcomeContract')) AS outputContract,
        JSON_VALUE(doc.body,'$.semantics.effectClassification') AS effect
      FROM selected s JOIN source.content_object co ON co.content_object_pk=s.canonical_content_pk
      CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) body) doc
      WHERE revision=1 ORDER BY s.ns,s.id FOR JSON PATH)) entries FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;
