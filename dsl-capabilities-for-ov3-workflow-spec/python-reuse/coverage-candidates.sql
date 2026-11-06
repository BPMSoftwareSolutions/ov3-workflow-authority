-- Preserve candidates for rare, explicit terms in a multi-operation objective.
-- The existing catalog has already been limited to public, selectable MCP tools.
DECLARE @coverage nvarchar(max);
IF JSON_QUERY(@input,'$.visibleCapabilities') IS NULL AND JSON_QUERY(@input,'$.payload.visibleCapabilities') IS NULL
BEGIN
 ;WITH hits AS (
    SELECT w.w,k.id,COUNT(*) OVER(PARTITION BY w.w) AS frequency
    FROM @words w JOIN @catalog k ON CHARINDEX(N' '+w.w+N' ',N' '+TRANSLATE(k.haystack,N'.,;:()[]/?!',N'           ')+N' ')>0
    WHERE LEN(w.w)>=4 AND w.w COLLATE Latin1_General_100_BIN2 NOT LIKE N'%[^a-z0-9-]%'
 ), chosen AS (
    SELECT TOP(8) id,MAX(IIF(w LIKE '%[0-9]%',1,0)) AS technical,MIN(frequency) rarity,COUNT(*) matches
    FROM hits WHERE frequency<=5 GROUP BY id ORDER BY technical DESC,rarity,matches DESC,id
 )
 SELECT @coverage=N'['+STRING_AGG(CONVERT(nvarchar(max),N'"'+STRING_ESCAPE(id,'json')+N'"'),N',')
    WITHIN GROUP(ORDER BY technical DESC,rarity,matches DESC,id)+N']' FROM chosen;
END;
SET @context=JSON_MODIFY(@context,N'$.routingCoverageCandidates',JSON_QUERY(ISNULL(@coverage,N'[]')));
