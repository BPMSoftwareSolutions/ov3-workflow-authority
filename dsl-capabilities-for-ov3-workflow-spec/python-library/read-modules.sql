DECLARE @html nvarchar(max) = (SELECT value FROM OPENJSON(@input) WHERE [key] = 'responseBodyText');
DECLARE @start int = CHARINDEX('<table class="indextable modindextable">', @html);
DECLARE @stop int = CHARINDEX('</table>', @html, @start);
DECLARE @tree xml = TRY_CONVERT(xml, SUBSTRING(@html, @start, CASE WHEN @stop > @start THEN @stop - @start + 8 ELSE 0 END));
DECLARE @rows TABLE (name nvarchar(250), href nvarchar(700), summary nvarchar(1500), removed bit);
INSERT @rows
SELECT r.value('(td[2]//code/text())[1]', 'nvarchar(250)'),
       NULLIF(r.value('string((td[2]/a/@href)[1])', 'nvarchar(700)'), ''),
       TRIM(REPLACE(REPLACE(r.value('string((td[3]/em)[1])', 'nvarchar(1500)'), CHAR(13), ' '), CHAR(10), ' ')),
       CONVERT(bit, CASE WHEN r.value('string((td[3]/em)[1])', 'nvarchar(1500)') LIKE 'Removed in %' THEN 1 ELSE 0 END)
FROM @tree.nodes('/table/tr[td[2]//code]') AS indexed(r);
DECLARE @sections TABLE (section nvarchar(200), href nvarchar(500));
INSERT @sections SELECT section, href FROM OPENJSON(@input, '$.sections') WITH (section nvarchar(200), href nvarchar(500));
DECLARE @parents TABLE (name nvarchar(250), section nvarchar(200), href nvarchar(500));
INSERT @parents SELECT r.name,s.section,s.href FROM @sections s JOIN @rows r
    ON 'library/'+s.href=LEFT(r.href,CHARINDEX('#',r.href+'#')-1) OR (r.href IS NULL AND s.href=r.name+'.html');
DECLARE @offset int = COALESCE(TRY_CONVERT(int,TRY_CONVERT(float,JSON_VALUE(@input,'$.offset'))),0),
        @limit int = COALESCE(TRY_CONVERT(int,TRY_CONVERT(float,JSON_VALUE(@input,'$.limit'))),10),
        @name nvarchar(250) = JSON_VALUE(@input,'$.module'),
        @hash nvarchar(100) = JSON_VALUE(@input,'$.responseBodyHash'),
        @expected nvarchar(100) = JSON_VALUE(@input,'$.expectedIndexHash'),
        @base nvarchar(80) = N'https://docs.python.org/3/',
        @total int = (SELECT COUNT(*) FROM @rows);
DECLARE @matches int = (SELECT COUNT(*) FROM @rows WHERE @name IS NULL OR name COLLATE Latin1_General_100_BIN2 = @name);
DECLARE @titleStart int = CHARINDEX('<title>',@html) + 7, @titleEnd int = CHARINDEX('</title>',@html);
DECLARE @status nvarchar(30) = CASE
    WHEN ISNULL(JSON_VALUE(@input,'$.status'),'') <> 'EXCHANGED' OR ISNULL(JSON_VALUE(@input,'$.libraryHttpStatus'),'') <> '200' THEN 'FETCH_FAILED'
    WHEN @tree IS NULL OR @total=0 OR NOT EXISTS (SELECT 1 FROM @sections) OR EXISTS (SELECT name FROM @rows GROUP BY name HAVING COUNT(*)>1) THEN 'SOURCE_CHANGED'
    WHEN @expected IS NOT NULL AND @expected <> @hash THEN 'SOURCE_CHANGED'
    WHEN @matches=0 THEN 'NOT_FOUND' ELSE 'LISTED' END;
DECLARE @modules nvarchar(max) = N'[]';
IF @status='LISTED' AND @offset>=0 AND @limit BETWEEN 1 AND 400
    SET @modules = (SELECT m.name AS module, m.summary, m.removed,
        COALESCE(s.section, CASE WHEN m.removed=1 THEN 'Removed Modules' ELSE 'Additional indexed modules' END) AS section,
        @base + COALESCE(m.href, 'library/'+s.href, 'py-modindex.html') AS documentationUrl
      FROM @rows m
      OUTER APPLY (SELECT TOP (1) p.section,p.href FROM @parents p
          WHERE p.name=m.name OR LEFT(m.name,LEN(p.name)+1)=p.name+'.'
          ORDER BY LEN(p.name) DESC, p.href) s
      WHERE @name IS NULL OR m.name COLLATE Latin1_General_100_BIN2=@name ORDER BY m.name COLLATE Latin1_General_100_BIN2
      OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY FOR JSON PATH);
SELECT (SELECT 'python-library-sources.v1' AS contractId, @status AS status,
       @base+'library/index.html' AS libraryIndexUrl, @base+'py-modindex.html' AS moduleIndexUrl,
       JSON_VALUE(@input,'$.libraryIndexHash') AS libraryIndexHash, @hash AS moduleIndexHash,
       CASE WHEN @titleEnd>@titleStart THEN SUBSTRING(@html,@titleStart,@titleEnd-@titleStart) END AS sourceTitle,
       @total AS indexedCount, (SELECT COUNT(*) FROM @rows WHERE removed=1) AS removedCount,
       @matches AS matchingCount, @offset AS [offset],
       CASE WHEN @status='LISTED' AND @matches-@offset>@limit THEN @offset+@limit END AS nextOffset,
       JSON_QUERY(ISNULL(@modules,'[]')) AS modules
       FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS value;
