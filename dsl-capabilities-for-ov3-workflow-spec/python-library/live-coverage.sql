-- This entry point takes its population directly from a fresh complete read of both official indexes.
DECLARE @job uniqueidentifier=NULL, @scope nvarchar(250)=NULL, @hash nvarchar(100)=JSON_VALUE(@input,'$.moduleIndexHash'),
        @total int=TRY_CONVERT(int,JSON_VALUE(@input,'$.indexedCount')), @since datetime2=DATEADD(hour,-24,SYSUTCDATETIME());
DECLARE @turns TABLE (id uniqueidentifier, seq bigint, result nvarchar(max), cap nvarchar(100));
DECLARE @inventory TABLE (name nvarchar(250) COLLATE Latin1_General_100_BIN2 PRIMARY KEY, url nvarchar(900), section nvarchar(250), removed bit, summary nvarchar(1500));
INSERT @inventory SELECT name,url,section,removed,summary FROM OPENJSON(@input,'$.modules') WITH
    (name nvarchar(250) '$.module',url nvarchar(900) '$.documentationUrl',section nvarchar(250),removed bit,summary nvarchar(1500));
IF ISNULL(JSON_VALUE(@input,'$.status'),'')<>'LISTED' OR @hash IS NULL OR ISNULL(@total,0)=0 OR @total<>(SELECT COUNT(*) FROM @inventory)
    THROW 51000,'PYTHON_REPORT_SOURCE_INVENTORY_INCOMPLETE',1;
DECLARE @entries TABLE(name nvarchar(250) COLLATE Latin1_General_100_BIN2 PRIMARY KEY, proposal nvarchar(max));
