-- The HTTP exchange carries the caller's paging and selection fields in its result.
DECLARE @html nvarchar(max) = (SELECT value FROM OPENJSON(@input) WHERE [key] = 'responseBodyText');
DECLARE @start int = CHARINDEX('<div class="toctree-wrapper compound">', @html);
DECLARE @stop int = CHARINDEX('</div>', @html, @start);
DECLARE @tree xml = TRY_CONVERT(xml, SUBSTRING(@html, @start, CASE WHEN @stop > @start THEN @stop - @start + 6 ELSE 0 END));
DECLARE @sections nvarchar(max) = (
    SELECT groupNode.value('(a/text())[1]', 'nvarchar(200)') AS section,
           entry.value('(@href)[1]', 'nvarchar(500)') AS href
    FROM @tree.nodes('/div/ul/li') AS groups(groupNode)
    CROSS APPLY groupNode.nodes('ul/li/a') AS entries(entry)
    FOR JSON PATH
);
SELECT (SELECT JSON_VALUE(@input, '$.responseBodyHash') AS libraryIndexHash,
               JSON_VALUE(@input, '$.httpStatus') AS libraryHttpStatus,
               JSON_QUERY(@sections) AS sections,
               JSON_VALUE(@input, '$.offset') AS [offset],
               JSON_VALUE(@input, '$.limit') AS [limit],
               JSON_VALUE(@input, '$.module') AS module,
               JSON_VALUE(@input, '$.expectedIndexHash') AS expectedIndexHash
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS value;
