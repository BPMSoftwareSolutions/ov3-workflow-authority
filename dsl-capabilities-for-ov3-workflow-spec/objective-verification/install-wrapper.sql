-- Applied only by apply-engineering-change, which owns the transaction and its preflight rollback.
IF @@TRANCOUNT=0 THROW 51000,'OBJECTIVE_CLOSURE_TRANSACTION_REQUIRED',1;
DECLARE @base binary(32)=0xa310f57f6c85e5fc0a6b23fe4481d691ed971f46d32757a3defd006ad66b414b;
DECLARE @candidate binary(32)=0xe2f5a46b92cce00549315fccdc261df0ec5e54e586b360d2e8f34947742af2f6;
DECLARE @stored TABLE(bytes varchar(max) COLLATE Latin1_General_100_BIN2_UTF8);
INSERT @stored SELECT TOP(1) c.content_bytes FROM source.content_object c JOIN model.content_artifact a ON a.content_digest=c.content_digest
WHERE a.artifact_kind='engineering-revision' AND c.content_digest=@candidate AND HASHBYTES('SHA2_256',c.content_bytes)=@candidate;
DECLARE @new nvarchar(max)=(SELECT CONVERT(nvarchar(max),bytes) FROM @stored);
IF @new IS NULL THROW 51000,'OBJECTIVE_CLOSURE_CANDIDATE_NOT_RETAINED',1;
DECLARE @old nvarchar(max)=OBJECT_DEFINITION(OBJECT_ID(N'analysis.objective_agent_step',N'P'));
DECLARE @before binary(32)=HASHBYTES('SHA2_256',CONVERT(varchar(max),@old COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @marker nvarchar(60)=N'PROCEDURE analysis.objective_agent_step';
DECLARE @wantedBody varbinary(max)=CONVERT(varbinary(max),SUBSTRING(@new,CHARINDEX(@marker,@new),LEN(@new)+1));
IF @old IS NULL OR CHARINDEX(@marker,@new)=0 THROW 51000,'OBJECTIVE_CLOSURE_MODULE_MISSING',1;
IF CONVERT(varbinary(max),SUBSTRING(@old,CHARINDEX(@marker,@old),LEN(@old)+1))<>@wantedBody
BEGIN
    IF @before<>@base THROW 51000,'OBJECTIVE_CLOSURE_BASE_CHANGED',1;
    EXEC sys.sp_executesql @new;
END;
DECLARE @after nvarchar(max)=OBJECT_DEFINITION(OBJECT_ID(N'analysis.objective_agent_step',N'P'));
IF @after IS NULL OR CONVERT(varbinary(max),SUBSTRING(@after,CHARINDEX(@marker,@after),LEN(@after)+1))<>@wantedBody
    THROW 51000,'OBJECTIVE_CLOSURE_READBACK_MISMATCH',1;
SELECT 'objective_closure_install' AS result_set,LOWER(CONVERT(varchar(64),@before,2)) AS before_digest,
    LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@after COLLATE Latin1_General_100_BIN2_UTF8)),2)) AS after_digest;
