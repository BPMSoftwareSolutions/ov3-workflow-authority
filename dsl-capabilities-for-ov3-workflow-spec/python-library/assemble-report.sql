DECLARE @covered int=(SELECT COUNT(*) FROM @entries),@current int=(SELECT COUNT(*) FROM @inventory WHERE removed=0),@lf nchar(1)=NCHAR(10);
DECLARE @sourceRecord nvarchar(max)=CASE WHEN JSON_VALUE(@input,'$.moduleIndexHash')=@hash THEN @input ELSE
    (SELECT TOP (1) result FROM @turns WHERE id=@job AND cap='read-python-library-sources' AND JSON_VALUE(result,'$.moduleIndexHash')=@hash ORDER BY seq DESC) END;
DECLARE @title nvarchar(300)=JSON_VALUE(@sourceRecord,'$.sourceTitle');
DECLARE @vStart int=CHARINDEX('Python ',@title,2)+7,@vEnd int=CHARINDEX(' documentation',@title);
DECLARE @version nvarchar(32)=SUBSTRING(@title,@vStart,CASE WHEN @vEnd>@vStart THEN @vEnd-@vStart ELSE 0 END);
IF @version IS NULL OR @version NOT LIKE '[0-9]%.[0-9]%' OR @version LIKE '%[^0-9.]%' THROW 51000,'PYTHON_DOCUMENTATION_VERSION_UNRESOLVED',1;
DECLARE @meta nvarchar(max)=(SELECT CASE WHEN @current=@covered THEN 'COMPLETE' ELSE 'PARTIAL' END AS status,
    CONVERT(varchar(36),@job) AS conversationId,COALESCE(@scope,'all') AS scope,@hash AS moduleIndexHash,@total AS indexedCount,
    JSON_QUERY((SELECT JSON_VALUE(@sourceRecord,'$.moduleIndexUrl') AS uri,@version AS version,@hash AS responseBodyHash FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS sourceIdentity,
    @current AS currentInScope,@covered AS proposals,@current-@covered AS missingCount,(SELECT COUNT(*) FROM @inventory WHERE removed=1) AS removedInScope,
    JSON_QUERY((SELECT TOP (10) m.name AS module,m.url AS documentationUrl FROM @inventory m
        LEFT JOIN @entries p ON m.name=p.name WHERE m.removed=0 AND p.name IS NULL ORDER BY m.name FOR JSON PATH)) AS nextMissingModules
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @paragraph nchar(2)=@lf+@lf;
DECLARE @sections nvarchar(max)=(SELECT STRING_AGG(CONVERT(nvarchar(max),CONCAT('## ',m.name,@lf,@lf,m.section,@lf,@lf,'[Python documentation](',m.url,')',@lf,@lf,
    CASE WHEN m.removed=1 THEN CONCAT('Removed. ',m.summary)
         WHEN p.proposal IS NULL THEN 'Awaiting a source-grounded binding proposal.'
         ELSE CONCAT(JSON_VALUE(p.proposal,'$.operation'),@lf,@lf,'**APIs**',@lf,fields.apis,@lf,@lf,
          '**Input contract**',@lf,'```json',@lf,JSON_QUERY(p.proposal,'$.inputContract'),@lf,'```',@lf,@lf,
          '**Output contract**',@lf,'```json',@lf,JSON_QUERY(p.proposal,'$.outputContract'),@lf,'```',@lf,@lf,
          '**Effects** ',JSON_VALUE(p.proposal,'$.effects'),@lf,@lf,'**Constraints** ',JSON_VALUE(p.proposal,'$.constraints'),@lf,@lf,
          '**Failure modes**',@lf,fields.failures,@lf,@lf,'**Ranked use cases**',@lf,fields.uses,@lf,@lf,'Source digest `',JSON_VALUE(p.proposal,'$.source.responseBodyHash'),'`') END)) COLLATE DATABASE_DEFAULT,@paragraph)
    WITHIN GROUP (ORDER BY m.name) FROM @inventory m LEFT JOIN @entries p ON m.name=p.name
    OUTER APPLY (SELECT
      (SELECT STRING_AGG(CONVERT(nvarchar(max),'- '+value),@lf) WITHIN GROUP (ORDER BY CONVERT(int,[key])) FROM OPENJSON(p.proposal,'$.apis')) AS apis,
      (SELECT STRING_AGG(CONVERT(nvarchar(max),'- '+value),@lf) WITHIN GROUP (ORDER BY CONVERT(int,[key])) FROM OPENJSON(p.proposal,'$.failureModes')) AS failures,
      (SELECT STRING_AGG(CONVERT(nvarchar(max),CONCAT(CONVERT(int,[key])+1,'. ',value)),@lf) WITHIN GROUP (ORDER BY CONVERT(int,[key])) FROM OPENJSON(p.proposal,'$.useCases')) AS uses) fields);
DECLARE @markdown nvarchar(max)=CONCAT('<!--',@meta,'-->',@lf,'# Python standard library provider proposals',@lf,@lf,
    'Python ',@version,' documentation. ',@covered,' of ',@current,' current modules in scope have a source-grounded proposal. ',@lf,@lf,
    'The bindings and rankings are estate design proposals. Removed modules are identified separately. ',@lf,@lf,
    '[Python library reference](https://docs.python.org/3/library/index.html) | [Module index](https://docs.python.org/3/py-modindex.html)',@lf,@lf,@sections,@lf);
SELECT (SELECT 'content-artifact-change.v1' AS contractId, 'python-library-report:'+COALESCE(LOWER(CONVERT(varchar(36),@job)),@hash) AS artifactKind,@markdown AS [text],
    'read-harness-authoring-state' AS verificationCapabilityId,JSON_QUERY(N'{"resolvedDisposition":"terminated"}') AS route,
    JSON_QUERY(N'{"input":{"changeKind":"content-artifact-change","includeDefinitions":true},"expected":{"disposition":"terminated"}}') AS preflight FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;
