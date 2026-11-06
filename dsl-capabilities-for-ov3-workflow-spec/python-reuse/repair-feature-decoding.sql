-- The governed engineering writer owns the transaction and rolls its preflight back.
IF @@TRANCOUNT=0 THROW 51000,'FEATURE_DECODER_TRANSACTION_REQUIRED',1;
DECLARE @source nvarchar(max)=OBJECT_DEFINITION(OBJECT_ID(N'model.apply_capability_from_dsl',N'P'));
DECLARE @base binary(32)=0x9fcefd0854d8ed1fa32f9b68df741a9542f33a745aaf5995d192e64a5b3ff593;
IF @source IS NULL OR HASHBYTES('SHA2_256',CONVERT(varchar(max),@source COLLATE Latin1_General_100_BIN2_UTF8))<>@base
    THROW 51000,'FEATURE_DECODER_BASE_CHANGED',1;
DECLARE @eol nchar(2)=NCHAR(13)+NCHAR(10);
DECLARE @from nvarchar(max)=N'DECLARE @feature_text nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)'
    +@eol+N'      FROM source.content_object co WHERE co.content_digest=TRY_CONVERT(binary(32),SUBSTRING(@feature_digest,8,64),2));';
DECLARE @to nvarchar(max)=N'DECLARE @feature_bytes TABLE (payload varchar(max) COLLATE Latin1_General_100_BIN2_UTF8);'
    +@eol+N'    INSERT @feature_bytes SELECT co.content_bytes FROM source.content_object co WHERE co.content_digest=TRY_CONVERT(binary(32),SUBSTRING(@feature_digest,8,64),2);'
    +@eol+N'    DECLARE @feature_text nvarchar(max)=(SELECT CONVERT(nvarchar(max),payload) FROM @feature_bytes);';
IF CHARINDEX(@from,@source)=0 OR CHARINDEX(@from,@source,CHARINDEX(@from,@source)+1)>0 OR LEFT(@source,6)<>N'CREATE'
    THROW 51000,'FEATURE_DECODER_SOURCE_MISMATCH',1;
DECLARE @candidate nvarchar(max)=STUFF(REPLACE(@source COLLATE Latin1_General_100_BIN2,@from,@to),1,6,N'ALTER');
EXEC sys.sp_executesql @candidate;
DECLARE @after nvarchar(max)=OBJECT_DEFINITION(OBJECT_ID(N'model.apply_capability_from_dsl',N'P'));
IF @after IS NULL OR CONVERT(varbinary(max),SUBSTRING(@after,CHARINDEX(N'PROCEDURE ',@after),DATALENGTH(@after)))<>
    CONVERT(varbinary(max),SUBSTRING(@candidate,CHARINDEX(N'PROCEDURE ',@candidate),DATALENGTH(@candidate)))
    THROW 51000,'FEATURE_DECODER_READBACK_MISMATCH',1;
SELECT 'feature_decoder' AS result_set,'VERIFIED' AS outcome,LOWER(CONVERT(varchar(64),@base,2)) AS base_digest,
    LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@after COLLATE Latin1_General_100_BIN2_UTF8)),2)) AS installed_digest;
