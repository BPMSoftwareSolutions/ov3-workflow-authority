-- Body of analysis.check_capability_feature_conformance (parameters @input nvarchar(max), @estate_model_pk bigint).
-- Read-only: it reads model.* and source.* and writes only its own temporary tables.
-- Canonical reference: features/check-capability-feature-conformance.feature.
--
-- Request (check-capability-feature-conformance-request.v1), one of:
--   {"capabilityId"}                                   the canonical feature bound to the selected version, exactly
--   {"featureText" | "featureDigest", "capabilityId"?} that text; with capabilityId, compared with its declaration
--   {"acceptance", "evidenceText", "featureText"?, "capabilityId"?}   a case or flight accepted from pinned evidence
--   {"baseline": {"after", "size"}}                    a page of every selected capability, bound mode
-- Result: capability-feature-conformance.v1.
BEGIN
SET NOCOUNT ON;
SET ARITHABORT ON;
DECLARE @e bigint = ISNULL(@estate_model_pk, (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1));
DECLARE @capId nvarchar(400) = JSON_VALUE(@input, N'$.capabilityId');
DECLARE @ftext nvarchar(max), @etext nvarchar(max);
SELECT @ftext = featureText, @etext = evidenceText
FROM OPENJSON(@input) WITH (featureText nvarchar(max) N'$.featureText', evidenceText nvarchar(max) N'$.evidenceText');
DECLARE @fdig nvarchar(100) = JSON_VALUE(@input, N'$.featureDigest');
DECLARE @acc nvarchar(max) = JSON_QUERY(@input, N'$.acceptance');
DECLARE @base nvarchar(max) = JSON_QUERY(@input, N'$.baseline');
DECLARE @explain bit = CASE WHEN JSON_VALUE(@input, N'$.explain') = N'true' THEN 1 ELSE 0 END;
DECLARE @mode nvarchar(20) = CASE WHEN @base IS NOT NULL THEN N'baseline' WHEN @acc IS NOT NULL THEN N'acceptance'
  WHEN @ftext IS NOT NULL OR @fdig IS NOT NULL THEN N'text' ELSE N'bound' END;
DECLARE @after nvarchar(400) = ISNULL(JSON_VALUE(@base, N'$.after'), N'');
DECLARE @size int = ISNULL(TRY_CONVERT(int, JSON_VALUE(@base, N'$.size')), 100);
DECLARE @res nvarchar(max);

-- 1. Capabilities under check: exact identity in sidefx:capabilities of the selected estate, no fallback.
CREATE TABLE #cap(fid int IDENTITY(1,1) PRIMARY KEY, capability_pk bigint NULL, capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL,
  cvpk bigint NULL, lookup varchar(20) NOT NULL DEFAULT 'FOUND');
IF @mode = N'baseline'
  INSERT #cap(capability_pk, capability_id, cvpk)
  SELECT TOP (@size) c.capability_pk, c.capability_id, ec.capability_version_pk
  FROM model.estate_capability ec JOIN model.capability c ON c.capability_pk = ec.capability_pk
  JOIN model.identity_namespace ns ON ns.namespace_pk = c.namespace_pk AND ns.namespace_id = N'sidefx:capabilities'
  WHERE ec.estate_model_pk = @e AND c.capability_id COLLATE Latin1_General_100_BIN2 > @after COLLATE Latin1_General_100_BIN2
  ORDER BY c.capability_id COLLATE Latin1_General_100_BIN2;
ELSE IF @capId IS NOT NULL
BEGIN
  INSERT #cap(capability_pk, capability_id, cvpk)
  SELECT c.capability_pk, c.capability_id, ec.capability_version_pk
  FROM model.estate_capability ec JOIN model.capability c ON c.capability_pk = ec.capability_pk
  JOIN model.identity_namespace ns ON ns.namespace_pk = c.namespace_pk AND ns.namespace_id = N'sidefx:capabilities'
  WHERE ec.estate_model_pk = @e AND c.capability_id COLLATE Latin1_General_100_BIN2 = @capId COLLATE Latin1_General_100_BIN2;
  IF @@ROWCOUNT = 0 INSERT #cap(capability_id, lookup) VALUES(@capId, 'NOT_FOUND');
END
ELSE INSERT #cap(capability_id, lookup) VALUES(NULL, 'TEXT');

-- 2. Feature bytes: the request's text, the bytes retained under a digest, or the exact CANONICAL binding of the
--    selected capability version. The bytes must hash to the digest they are kept under.
CREATE TABLE #feat(fid int PRIMARY KEY, fvpk bigint NULL, content_digest varchar(80) NULL, bytes_ok bit NULL,
  source varchar(20) NOT NULL, text nvarchar(max) NULL, feature_n int NULL);
IF @ftext IS NOT NULL
  INSERT #feat(fid, content_digest, bytes_ok, source, text)
  SELECT fid, 'sha256:' + LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), @ftext COLLATE Latin1_General_100_BIN2_UTF8))), 2)),
    1, 'text', @ftext FROM #cap WHERE lookup <> 'NOT_FOUND';
ELSE IF @fdig IS NOT NULL
  INSERT #feat(fid, content_digest, bytes_ok, source, text)
  SELECT k.fid, @fdig, CASE WHEN HASHBYTES('SHA2_256', co.content_bytes) = co.content_digest THEN 1 ELSE 0 END, 'retained',
    CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
  FROM #cap k LEFT JOIN source.content_object co ON co.content_digest = TRY_CONVERT(binary(32), SUBSTRING(@fdig, 8, 64), 2)
  WHERE k.lookup <> 'NOT_FOUND';
ELSE
BEGIN
  ;WITH b AS (
    SELECT k.fid, f.feature_version_pk, COUNT(*) OVER (PARTITION BY k.fid) AS cnt
    FROM #cap k JOIN model.estate_capability_feature f ON f.estate_model_pk = @e AND f.capability_pk = k.capability_pk
      AND f.capability_version_pk = k.cvpk AND f.binding_role = N'CANONICAL'
    WHERE k.lookup = 'FOUND')
  UPDATE k SET lookup = CASE WHEN bb.fid IS NULL THEN 'NOT_BOUND' WHEN bb.cnt > 1 THEN 'AMBIGUOUS' ELSE 'FOUND' END
  FROM #cap k LEFT JOIN (SELECT DISTINCT fid, cnt FROM b) bb ON bb.fid = k.fid WHERE k.lookup = 'FOUND';
  INSERT #feat(fid, fvpk, content_digest, bytes_ok, source, text)
  SELECT k.fid, f.feature_version_pk, 'sha256:' + x.hex,
    CASE WHEN co.content_object_pk IS NULL THEN NULL WHEN HASHBYTES('SHA2_256', co.content_bytes) = TRY_CONVERT(binary(32), x.hex, 2) THEN 1 ELSE 0 END,
    'binding', CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
  FROM #cap k
  JOIN model.estate_capability_feature f ON f.estate_model_pk = @e AND f.capability_pk = k.capability_pk
    AND f.capability_version_pk = k.cvpk AND f.binding_role = N'CANONICAL'
  JOIN model.feature_version fv ON fv.feature_version_pk = f.feature_version_pk
  JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = fv.semantic_object_definition_pk
  JOIN source.content_object env ON env.content_object_pk = d.canonical_content_pk
  CROSS APPLY (SELECT LOWER(REPLACE(JSON_VALUE(CONVERT(nvarchar(max), CONVERT(varchar(max), env.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),
    N'$.semantics.content_digest'), N'sha256:', N'')) AS hex) x
  LEFT JOIN source.content_object co ON co.content_digest = TRY_CONVERT(binary(32), x.hex, 2)
  WHERE k.lookup = 'FOUND';
END

-- 3. Gherkin, parsed here scope by scope. A tag set belongs to the next Feature, Rule, Scenario or Examples line
--    only; pickles inherit Feature, Rule, Scenario and Examples tags, as @cucumber/gherkin compiles them.
CREATE TABLE #ln(fid int NOT NULL, n int NOT NULL, raw nvarchar(max) NULL, t nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
  ind int NULL, kind varchar(8) NULL, el_n int NULL, PRIMARY KEY(fid, n));
INSERT #ln(fid, n, raw)
SELECT f.fid, CONVERT(int, s.ordinal), REPLACE(s.value, NCHAR(13), N'')
FROM #feat f CROSS APPLY STRING_SPLIT(f.text, NCHAR(10), 1) s WHERE f.text IS NOT NULL;
UPDATE #ln SET t = TRIM(NCHAR(9) + NCHAR(32) FROM raw),
  ind = LEN(raw + N'x') - LEN(LTRIM(raw, NCHAR(9) + NCHAR(32)) + N'x');

CREATE TABLE #fd(fid int NOT NULL, code varchar(60) NOT NULL, scenario_id nvarchar(400) NULL, case_id nvarchar(400) NULL,
  line int NULL, fval nvarchar(max) NULL, dval nvarchar(max) NULL);

-- Docstrings: a delimiter closes only the kind that opened it; the other kind inside is content.
CREATE TABLE #dl(fid int NOT NULL, n int NOT NULL, mark nchar(3) NOT NULL, media nvarchar(200) NULL, ind int NULL,
  role char(1) NULL, open_n int NULL, PRIMARY KEY(fid, n));
INSERT #dl(fid, n, mark, media, ind)
SELECT fid, n, LEFT(t, 3), NULLIF(TRIM(SUBSTRING(t, 4, 200)), N''), ind FROM #ln WHERE LEFT(t, 3) IN (N'"""', N'```');
DECLARE @lf int = -1, @lnn int = -1, @of int = NULL, @on int = NULL, @om nchar(3) = NULL, @cf int, @cn int, @cm nchar(3);
WHILE 1 = 1
BEGIN
  SELECT TOP (1) @cf = fid, @cn = n, @cm = mark FROM #dl WHERE fid > @lf OR (fid = @lf AND n > @lnn) ORDER BY fid, n;
  IF @@ROWCOUNT = 0 BREAK;
  IF @of IS NOT NULL AND @of <> @cf SELECT @of = NULL, @on = NULL, @om = NULL;
  IF @of IS NULL
  BEGIN
    UPDATE #dl SET role = 'O' WHERE fid = @cf AND n = @cn;
    SELECT @of = @cf, @on = @cn, @om = @cm;
  END
  ELSE IF @cm = @om
  BEGIN
    UPDATE #dl SET role = 'C', open_n = @on WHERE fid = @cf AND n = @cn;
    SELECT @of = NULL, @on = NULL, @om = NULL;
  END
  ELSE UPDATE #dl SET role = 'X' WHERE fid = @cf AND n = @cn;
  SELECT @lf = @cf, @lnn = @cn;
END
CREATE TABLE #dsp(fid int NOT NULL, open_n int NOT NULL, close_n int NOT NULL, media nvarchar(200) COLLATE Latin1_General_100_BIN2 NULL, ind int NULL, step_n int NULL,
  content nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL, PRIMARY KEY(fid, open_n));
INSERT #dsp(fid, open_n, close_n, media, ind)
SELECT o.fid, o.n, c.n, o.media, o.ind FROM #dl o JOIN #dl c ON c.fid = o.fid AND c.role = 'C' AND c.open_n = o.n WHERE o.role = 'O';
INSERT #fd(fid, code, line, fval)
SELECT o.fid, 'GHERKIN_PARSE_ERROR', o.n, N'UNCLOSED_DOCSTRING' FROM #dl o
WHERE o.role = 'O' AND NOT EXISTS (SELECT 1 FROM #dsp d WHERE d.fid = o.fid AND d.open_n = o.n);
UPDATE l SET kind = 'doc' FROM #ln l JOIN #dsp d ON d.fid = l.fid AND l.n > d.open_n AND l.n < d.close_n;
UPDATE l SET kind = 'doc' FROM #ln l
WHERE l.kind IS NULL AND EXISTS (SELECT 1 FROM #dl o WHERE o.fid = l.fid AND o.role = 'O' AND o.n < l.n
  AND NOT EXISTS (SELECT 1 FROM #dsp d WHERE d.fid = o.fid AND d.open_n = o.n));
UPDATE l SET kind = 'delim' FROM #ln l JOIN #dl d ON d.fid = l.fid AND d.n = l.n AND d.role IN ('O', 'C') WHERE l.kind IS NULL;
UPDATE #ln SET kind = CASE
    WHEN t = N'' THEN 'blank'
    WHEN LEFT(t, 1) = N'#' THEN 'comment'
    WHEN LEFT(t, 1) = N'@' THEN 'tags'
    WHEN LEFT(t, 8) = N'Feature:' THEN 'F'
    WHEN LEFT(t, 5) = N'Rule:' THEN 'R'
    WHEN LEFT(t, 11) = N'Background:' THEN 'B'
    WHEN LEFT(t, 17) = N'Scenario Outline:' OR LEFT(t, 18) = N'Scenario Template:' THEN 'O'
    WHEN LEFT(t, 9) = N'Scenario:' OR LEFT(t, 8) = N'Example:' THEN 'S'
    WHEN LEFT(t, 9) = N'Examples:' OR LEFT(t, 10) = N'Scenarios:' THEN 'E'
    WHEN LEFT(t, 6) = N'Given ' OR LEFT(t, 5) = N'When ' OR LEFT(t, 5) = N'Then ' OR LEFT(t, 4) = N'And '
      OR LEFT(t, 4) = N'But ' OR LEFT(t, 2) = N'* ' THEN 'step'
    WHEN LEFT(t, 1) = N'|' THEN 'row'
    ELSE 'text' END
WHERE kind IS NULL;
UPDATE l SET el_n = x.el_n FROM #ln l JOIN (
  SELECT fid, n, MAX(CASE WHEN kind IN ('F', 'R', 'B', 'S', 'O', 'E') THEN n END) OVER (PARTITION BY fid ORDER BY n ROWS UNBOUNDED PRECEDING) AS el_n
  FROM #ln) x ON x.fid = l.fid AND x.n = l.n;
UPDATE f SET feature_n = (SELECT MIN(n) FROM #ln l WHERE l.fid = f.fid AND l.kind = 'F') FROM #feat f;
INSERT #fd(fid, code, fval) SELECT fid, 'GHERKIN_PARSE_ERROR', N'NO_FEATURE' FROM #feat WHERE text IS NOT NULL AND feature_n IS NULL;

CREATE TABLE #el(fid int NOT NULL, n int NOT NULL, kind char(1) NOT NULL, name nvarchar(max) NULL, rule_n int NULL, scen_n int NULL,
  PRIMARY KEY(fid, n));
INSERT #el(fid, n, kind, name)
SELECT fid, n, kind, TRIM(SUBSTRING(t, CHARINDEX(N':', t) + 1, 4000)) FROM #ln WHERE kind IN ('F', 'R', 'B', 'S', 'O', 'E');
UPDATE e SET rule_n = (SELECT MAX(r.n) FROM #el r WHERE r.fid = e.fid AND r.kind = 'R' AND r.n < e.n) FROM #el e WHERE e.kind <> 'F';
UPDATE e SET scen_n = (SELECT MAX(s.n) FROM #el s WHERE s.fid = e.fid AND s.kind IN ('S', 'O') AND s.n < e.n) FROM #el e WHERE e.kind = 'E';
INSERT #fd(fid, code, line, fval)
SELECT fid, 'GHERKIN_PARSE_ERROR', n, N'EXAMPLES_WITHOUT_SCENARIO' FROM #el
WHERE kind = 'E' AND (scen_n IS NULL OR scen_n < ISNULL(rule_n, 0));

-- Tags: owned by the next line that is not a tag, a comment or blank, which must be a taggable keyword.
CREATE TABLE #tag(fid int NOT NULL, owner_n int NOT NULL, line_n int NOT NULL, tag nvarchar(800) COLLATE Latin1_General_100_BIN2 NOT NULL,
  tkey nvarchar(100) COLLATE Latin1_General_100_BIN2 NULL, tval nvarchar(800) COLLATE Latin1_General_100_BIN2 NULL);
;WITH o AS (
  SELECT fid, n, kind, t, MIN(CASE WHEN kind NOT IN ('blank', 'comment', 'tags') THEN n END)
    OVER (PARTITION BY fid ORDER BY n ROWS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING) AS next_n
  FROM #ln)
INSERT #tag(fid, owner_n, line_n, tag)
SELECT o.fid, o.next_n, o.n, LEFT(s.value, 800)
FROM o JOIN #ln nx ON nx.fid = o.fid AND nx.n = o.next_n AND nx.kind IN ('F', 'R', 'S', 'O', 'E')
CROSS APPLY STRING_SPLIT(REPLACE(CASE WHEN CHARINDEX(N' #', o.t) > 0 THEN LEFT(o.t, CHARINDEX(N' #', o.t) - 1) ELSE o.t END, NCHAR(9), N' '), N' ', 1) s
WHERE o.kind = 'tags' AND LEFT(s.value, 1) = N'@';
;WITH o AS (
  SELECT fid, n, kind, MIN(CASE WHEN kind NOT IN ('blank', 'comment', 'tags') THEN n END)
    OVER (PARTITION BY fid ORDER BY n ROWS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING) AS next_n
  FROM #ln)
INSERT #fd(fid, code, line, fval)
SELECT o.fid, 'GHERKIN_PARSE_ERROR', o.n, N'TAGS_WITHOUT_ELEMENT'
FROM o LEFT JOIN #ln nx ON nx.fid = o.fid AND nx.n = o.next_n
WHERE o.kind = 'tags' AND (nx.kind IS NULL OR nx.kind NOT IN ('F', 'R', 'S', 'O', 'E'));
UPDATE #tag SET
  tkey = CASE WHEN CHARINDEX(N':', tag) > 0 THEN SUBSTRING(tag, 2, CHARINDEX(N':', tag) - 2) ELSE SUBSTRING(tag, 2, 800) END,
  tval = CASE WHEN CHARINDEX(N':', tag) > 0 THEN SUBSTRING(tag, CHARINDEX(N':', tag) + 1, 800) END;

-- Steps, their types (And and But take the type of the step before them), docstrings and table rows.
CREATE TABLE #st(fid int NOT NULL, n int NOT NULL, owner_n int NULL, kw varchar(5) NOT NULL, stype varchar(8) NULL, text nvarchar(max) NULL,
  PRIMARY KEY(fid, n));
INSERT #st(fid, n, owner_n, kw, text)
SELECT fid, n, el_n, k.kw, TRIM(SUBSTRING(t, LEN(k.kw) + 2, 1000000))
FROM #ln CROSS APPLY (SELECT CASE WHEN LEFT(t, 6) = N'Given ' THEN 'Given' WHEN LEFT(t, 5) = N'When ' THEN 'When'
  WHEN LEFT(t, 5) = N'Then ' THEN 'Then' WHEN LEFT(t, 4) = N'And ' THEN 'And' WHEN LEFT(t, 4) = N'But ' THEN 'But' ELSE '*' END AS kw) k
WHERE kind = 'step';
INSERT #fd(fid, code, line, fval)
SELECT s.fid, 'GHERKIN_PARSE_ERROR', s.n, N'STEP_OUTSIDE_SCENARIO' FROM #st s LEFT JOIN #el e ON e.fid = s.fid AND e.n = s.owner_n
WHERE e.kind IS NULL OR e.kind NOT IN ('S', 'O', 'B');
UPDATE #st SET stype = CASE kw WHEN 'Given' THEN 'Context' WHEN 'When' THEN 'Action' WHEN 'Then' THEN 'Outcome' END;
UPDATE s SET stype = ISNULL((SELECT TOP (1) p.stype FROM #st p WHERE p.fid = s.fid AND p.owner_n = s.owner_n AND p.n < s.n
  AND p.kw IN ('Given', 'When', 'Then') ORDER BY p.n DESC), 'Unknown') FROM #st s WHERE s.kw IN ('And', 'But', '*');
UPDATE d SET step_n = p.n FROM #dsp d CROSS APPLY (SELECT TOP (1) l.n, l.kind FROM #ln l WHERE l.fid = d.fid AND l.n < d.open_n
  AND l.kind NOT IN ('blank', 'comment') ORDER BY l.n DESC) p WHERE p.kind = 'step';
INSERT #fd(fid, code, line, fval) SELECT fid, 'GHERKIN_PARSE_ERROR', open_n, N'DOCSTRING_WITHOUT_STEP' FROM #dsp WHERE step_n IS NULL;
UPDATE d SET content = ISNULL(x.content, N'')
FROM #dsp d OUTER APPLY (
  SELECT STRING_AGG(CONVERT(nvarchar(max), y.line), NCHAR(10)) WITHIN GROUP (ORDER BY y.n) AS content
  FROM (SELECT l.n, CASE WHEN l.ind >= d.ind THEN SUBSTRING(l.raw, d.ind + 1, 2147483647) ELSE LTRIM(l.raw, NCHAR(9) + NCHAR(32)) END AS line
        FROM #ln l WHERE l.fid = d.fid AND l.n > d.open_n AND l.n < d.close_n) y) x;

CREATE TABLE #cell(fid int NOT NULL, owner_n int NOT NULL, owner_kind char(1) NOT NULL, line_n int NOT NULL, row_i int NOT NULL, col_i int NOT NULL,
  val nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);
;WITH r AS (
  SELECT fid, n, t, kind, MAX(CASE WHEN kind NOT IN ('row', 'blank', 'comment') THEN n END)
    OVER (PARTITION BY fid ORDER BY n ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS owner_n
  FROM #ln),
rr AS (
  SELECT r.fid, r.n, r.t, r.owner_n, CASE WHEN ow.kind = 'step' THEN 'S' WHEN ow.kind = 'E' THEN 'E' END AS owner_kind,
    ROW_NUMBER() OVER (PARTITION BY r.fid, r.owner_n ORDER BY r.n) - 1 AS row_i
  FROM r LEFT JOIN #ln ow ON ow.fid = r.fid AND ow.n = r.owner_n WHERE r.kind = 'row')
INSERT #cell(fid, owner_n, owner_kind, line_n, row_i, col_i, val)
SELECT rr.fid, rr.owner_n, rr.owner_kind, rr.n, rr.row_i, CONVERT(int, s.ordinal) - 2, TRIM(NCHAR(9) + NCHAR(32) FROM s.value)
FROM rr CROSS APPLY STRING_SPLIT(rr.t, N'|', 1) s
WHERE rr.owner_kind IS NOT NULL AND s.ordinal > 1
  AND s.ordinal < (SELECT MAX(CONVERT(int, s2.ordinal)) FROM STRING_SPLIT(rr.t, N'|', 1) s2);
;WITH r AS (
  SELECT fid, n, kind, MAX(CASE WHEN kind NOT IN ('row', 'blank', 'comment') THEN n END)
    OVER (PARTITION BY fid ORDER BY n ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS owner_n
  FROM #ln)
INSERT #fd(fid, code, line, fval)
SELECT r.fid, 'GHERKIN_PARSE_ERROR', r.n, N'ROW_WITHOUT_OWNER' FROM r LEFT JOIN #ln ow ON ow.fid = r.fid AND ow.n = r.owner_n
WHERE r.kind = 'row' AND (ow.kind IS NULL OR ow.kind NOT IN ('step', 'E'));
INSERT #fd(fid, code, line, fval)
SELECT fid, 'GHERKIN_PARSE_ERROR', MIN(line_n), N'INCONSISTENT_CELL_COUNT' FROM (
  SELECT fid, owner_n, line_n, COUNT(*) AS cells, MAX(COUNT(*)) OVER (PARTITION BY fid, owner_n) AS mx
  FROM #cell GROUP BY fid, owner_n, line_n) x WHERE cells <> mx GROUP BY fid, owner_n;

-- Pickles: a Scenario without Examples is one pickle; each Examples body row is one pickle.
CREATE TABLE #pk(pk int IDENTITY(1,1) PRIMARY KEY, fid int NOT NULL, scen_n int NOT NULL, ex_n int NULL, row_i int NULL, line int NOT NULL);
-- Numbered in document order, as @cucumber/gherkin numbers them.
INSERT #pk(fid, scen_n, ex_n, row_i, line)
SELECT fid, scen_n, ex_n, row_i, line FROM (
  SELECT e.fid, e.n AS scen_n, NULL AS ex_n, NULL AS row_i, e.n AS line FROM #el e
  WHERE e.kind = 'S' AND NOT EXISTS (SELECT 1 FROM #el x WHERE x.fid = e.fid AND x.kind = 'E' AND x.scen_n = e.n)
  UNION ALL
  SELECT x.fid, x.scen_n, x.n, r.row_i, r.line_n
  FROM #el x JOIN (SELECT DISTINCT fid, owner_n, row_i, line_n FROM #cell WHERE owner_kind = 'E' AND row_i > 0) r ON r.fid = x.fid AND r.owner_n = x.n
  WHERE x.kind = 'E' AND x.scen_n IS NOT NULL) p
ORDER BY fid, line;

CREATE TABLE #pt(pk int NOT NULL, tag nvarchar(800) COLLATE Latin1_General_100_BIN2 NOT NULL, tkey nvarchar(100) COLLATE Latin1_General_100_BIN2 NULL,
  tval nvarchar(800) COLLATE Latin1_General_100_BIN2 NULL, line_n int NULL);
INSERT #pt(pk, tag, tkey, tval, line_n)
SELECT p.pk, t.tag, t.tkey, t.tval, MIN(t.line_n)
FROM #pk p JOIN #el s ON s.fid = p.fid AND s.n = p.scen_n JOIN #feat f ON f.fid = p.fid
JOIN #tag t ON t.fid = p.fid AND (t.owner_n = s.n OR t.owner_n = s.rule_n OR t.owner_n = p.ex_n OR t.owner_n = f.feature_n)
GROUP BY p.pk, t.tag, t.tkey, t.tval;

CREATE TABLE #pv(pk int NOT NULL, col_i int NOT NULL, name nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL, val nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
  PRIMARY KEY(pk, col_i));
INSERT #pv(pk, col_i, name, val)
SELECT p.pk, h.col_i, h.val, v.val FROM #pk p
JOIN #cell h ON h.fid = p.fid AND h.owner_n = p.ex_n AND h.row_i = 0
JOIN #cell v ON v.fid = p.fid AND v.owner_n = p.ex_n AND v.row_i = p.row_i AND v.col_i = h.col_i
WHERE p.ex_n IS NOT NULL;

CREATE TABLE #ps(pk int NOT NULL, ord int NOT NULL, src_n int NOT NULL, stype varchar(8) NULL, kw varchar(5) NULL, text nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
  media nvarchar(200) COLLATE Latin1_General_100_BIN2 NULL, doc nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL, PRIMARY KEY(pk, ord));
INSERT #ps(pk, ord, src_n, stype, kw, text, media, doc)
SELECT p.pk, ROW_NUMBER() OVER (PARTITION BY p.pk ORDER BY o.grp, st.n), st.n, st.stype, st.kw, st.text, d.media, d.content
FROM #pk p JOIN #el s ON s.fid = p.fid AND s.n = p.scen_n
CROSS APPLY (
  SELECT 0 AS grp, b.n AS owner FROM #el b WHERE b.fid = p.fid AND b.kind = 'B' AND b.rule_n IS NULL
  UNION ALL SELECT 1, b.n FROM #el b WHERE b.fid = p.fid AND b.kind = 'B' AND s.rule_n IS NOT NULL AND b.rule_n = s.rule_n
  UNION ALL SELECT 2, s.n) o
JOIN #st st ON st.fid = p.fid AND st.owner_n = o.owner
LEFT JOIN #dsp d ON d.fid = st.fid AND d.step_n = st.n;

CREATE TABLE #pc(pk int NOT NULL, ord int NOT NULL, row_i int NOT NULL, col_i int NOT NULL, val nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);
INSERT #pc(pk, ord, row_i, col_i, val)
SELECT ps.pk, ps.ord, c.row_i, c.col_i, c.val FROM #ps ps JOIN #pk p ON p.pk = ps.pk
JOIN #cell c ON c.fid = p.fid AND c.owner_n = ps.src_n AND c.owner_kind = 'S';

DECLARE @col int = 0, @maxcol int = ISNULL((SELECT MAX(col_i) FROM #pv), -1);
WHILE @col <= @maxcol
BEGIN
  UPDATE ps SET text = REPLACE(ps.text, N'<' + v.name + N'>', ISNULL(v.val, N'')),
    doc = REPLACE(ps.doc, N'<' + v.name + N'>', ISNULL(v.val, N''))
  FROM #ps ps JOIN #pv v ON v.pk = ps.pk AND v.col_i = @col AND ISNULL(v.name, N'') <> N'';
  UPDATE pc SET val = REPLACE(pc.val, N'<' + v.name + N'>', ISNULL(v.val, N''))
  FROM #pc pc JOIN #pv v ON v.pk = pc.pk AND v.col_i = @col AND ISNULL(v.name, N'') <> N'';
  SET @col += 1;
END

-- Cases: identity, request and assertions of each pickle.
CREATE TABLE #case(pk int PRIMARY KEY, fid int NOT NULL, line int NOT NULL, case_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL,
  case_ids int NOT NULL, scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL, scenario_ids int NOT NULL,
  request nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL, rows_n int NOT NULL DEFAULT 0);
INSERT #case(pk, fid, line, case_id, case_ids, scenario_id, scenario_ids, request)
SELECT p.pk, p.fid, p.line,
  COALESCE((SELECT MIN(tval) FROM #pt WHERE pk = p.pk AND tkey = N'case'), (SELECT val FROM #pv WHERE pk = p.pk AND name = N'case')),
  (SELECT COUNT(DISTINCT tval) FROM #pt WHERE pk = p.pk AND tkey = N'case') + CASE WHEN EXISTS (SELECT 1 FROM #pv WHERE pk = p.pk AND name = N'case') THEN 1 ELSE 0 END,
  (SELECT MIN(tval) FROM #pt WHERE pk = p.pk AND tkey = N'scenario'),
  (SELECT COUNT(DISTINCT tval) FROM #pt WHERE pk = p.pk AND tkey = N'scenario'),
  COALESCE((SELECT TOP (1) doc FROM #ps WHERE pk = p.pk AND media = N'json' ORDER BY ord), (SELECT val FROM #pv WHERE pk = p.pk AND name = N'request'))
FROM #pk p;
CREATE TABLE #pa(pk int NOT NULL, ord int NOT NULL, row_i int NOT NULL, operation nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL,
  path nvarchar(1000) COLLATE Latin1_General_100_BIN2 NULL, equals nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);
INSERT #pa(pk, ord, row_i, operation, path, equals)
SELECT b.pk, b.ord, b.row_i, MAX(CASE WHEN b.col_i = 0 THEN b.val END), MAX(CASE WHEN b.col_i = 1 THEN b.val END), MAX(CASE WHEN b.col_i = 2 THEN b.val END)
FROM #pc b
WHERE b.row_i > 0 AND EXISTS (SELECT 1 FROM #pc h WHERE h.pk = b.pk AND h.ord = b.ord AND h.row_i = 0 GROUP BY h.pk
  HAVING COUNT(*) = 3 AND MAX(CASE WHEN h.col_i = 0 THEN h.val END) = N'operation'
    AND MAX(CASE WHEN h.col_i = 1 THEN h.val END) = N'path' AND MAX(CASE WHEN h.col_i = 2 THEN h.val END) = N'equals')
GROUP BY b.pk, b.ord, b.row_i;
UPDATE c SET rows_n = (SELECT COUNT(*) FROM #pa a WHERE a.pk = c.pk) FROM #case c;

-- 4. The declared circuit of each capability under check.
CREATE TABLE #dsc(fid int NOT NULL, scenario_pk bigint NOT NULL, scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL, svpk bigint NOT NULL,
  is_root bit NOT NULL, input_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL, input_contract nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL,
  event_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL, event_authority nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL,
  outcome_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL, outcome_contract nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL,
  terminal bit NULL, eavpk bigint NULL, envelope nvarchar(max) NULL);
INSERT #dsc(fid, scenario_pk, scenario_id, svpk, is_root, input_id, input_contract, event_id, event_authority, outcome_id, outcome_contract, terminal, eavpk, envelope)
SELECT k.fid, s.scenario_pk, s.scenario_id, cs.scenario_version_pk,
  CASE WHEN EXISTS (SELECT 1 FROM model.capability_root_scenario r WHERE r.capability_version_pk = k.cvpk AND r.scenario_pk = cs.scenario_pk) THEN 1 ELSE 0 END,
  (SELECT TOP (1) si.input_id FROM model.scenario_input si WHERE si.scenario_version_pk = cs.scenario_version_pk),
  (SELECT TOP (1) ct.contract_id FROM model.scenario_input si JOIN model.contract_version cv ON cv.contract_version_pk = si.input_contract_version_pk
     JOIN model.contract ct ON ct.contract_pk = cv.contract_pk WHERE si.scenario_version_pk = cs.scenario_version_pk),
  (SELECT TOP (1) se.event_id FROM model.scenario_event se WHERE se.scenario_version_pk = cs.scenario_version_pk),
  (SELECT TOP (1) a.execution_authority_id FROM model.scenario_event se JOIN model.execution_authority_version av ON av.execution_authority_version_pk = se.execution_authority_version_pk
     JOIN model.execution_authority a ON a.execution_authority_pk = av.execution_authority_pk WHERE se.scenario_version_pk = cs.scenario_version_pk),
  (SELECT TOP (1) so.outcome_id FROM model.scenario_outcome so WHERE so.scenario_version_pk = cs.scenario_version_pk),
  (SELECT TOP (1) ct.contract_id FROM model.scenario_outcome_contract oc JOIN model.contract_version cv ON cv.contract_version_pk = oc.contract_version_pk
     JOIN model.contract ct ON ct.contract_pk = cv.contract_pk WHERE oc.scenario_version_pk = cs.scenario_version_pk),
  (SELECT TOP (1) CONVERT(bit, so.terminal) FROM model.scenario_outcome so WHERE so.scenario_version_pk = cs.scenario_version_pk),
  (SELECT TOP (1) se.execution_authority_version_pk FROM model.scenario_event se WHERE se.scenario_version_pk = cs.scenario_version_pk),
  (SELECT CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
     FROM model.scenario_version v JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = v.semantic_object_definition_pk
     JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk WHERE v.scenario_version_pk = cs.scenario_version_pk)
FROM #cap k JOIN model.capability_scenario cs ON cs.capability_version_pk = k.cvpk JOIN model.scenario s ON s.scenario_pk = cs.scenario_pk
WHERE k.lookup <> 'NOT_FOUND' AND k.cvpk IS NOT NULL AND EXISTS (SELECT 1 FROM #feat f WHERE f.fid = k.fid);
CREATE TABLE #dstep(fid int NOT NULL, scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL, ord int NOT NULL, stype varchar(20) NULL,
  text nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);
INSERT #dstep(fid, scenario_id, ord, stype, text)
SELECT d.fid, d.scenario_id, CONVERT(int, j.[key]), JSON_VALUE(j.value, N'$.keywordType'), x.text
FROM #dsc d CROSS APPLY OPENJSON(CASE WHEN ISJSON(d.envelope) = 1 THEN d.envelope END, N'$.semantics.scenario.steps') j
CROSS APPLY OPENJSON(CASE WHEN ISJSON(j.value) = 1 THEN j.value END) WITH (text nvarchar(max) N'$.text') x;
CREATE TABLE #dvar(fid int NOT NULL, scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL, variant nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL);
INSERT #dvar SELECT d.fid, d.scenario_id, ov.variant_id FROM #dsc d JOIN model.outcome_variant ov ON ov.scenario_version_pk = d.svpk WHERE ov.variant_id IS NOT NULL;
CREATE TABLE #dop(fid int NOT NULL, scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL, operation_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL);
INSERT #dop SELECT d.fid, d.scenario_id, o.operation_id FROM #dsc d JOIN model.execution_operation o ON o.execution_authority_version_pk = d.eavpk WHERE o.operation_id IS NOT NULL;

-- 5. Findings. Feature identity and entry.
DECLARE @hasDecl TABLE(fid int PRIMARY KEY);
INSERT @hasDecl SELECT DISTINCT fid FROM #dsc;
INSERT #fd(fid, code, line, fval, dval)
SELECT f.fid, 'FEATURE_CAPABILITY_MISMATCH', f.feature_n,
  (SELECT STRING_AGG(CONVERT(nvarchar(max), t.tval), N',') FROM #tag t WHERE t.fid = f.fid AND t.owner_n = f.feature_n AND t.tkey = N'capability'), k.capability_id
FROM #feat f JOIN #cap k ON k.fid = f.fid
WHERE f.feature_n IS NOT NULL AND (
  (SELECT COUNT(*) FROM #tag t WHERE t.fid = f.fid AND t.owner_n = f.feature_n AND t.tkey = N'capability') <> 1
  OR (k.capability_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #tag t WHERE t.fid = f.fid AND t.owner_n = f.feature_n AND t.tkey = N'capability' AND t.tval = k.capability_id)));
INSERT #fd(fid, code, line, fval, dval)
SELECT f.fid, 'ROOT_SCENARIO_MISMATCH', f.feature_n,
  (SELECT STRING_AGG(CONVERT(nvarchar(max), t.tval), N',') FROM #tag t WHERE t.fid = f.fid AND t.owner_n = f.feature_n AND t.tkey = N'root-scenario'),
  (SELECT STRING_AGG(CONVERT(nvarchar(max), d.scenario_id), N',') FROM #dsc d WHERE d.fid = f.fid AND d.is_root = 1)
FROM #feat f JOIN @hasDecl h ON h.fid = f.fid
WHERE ISNULL((SELECT STRING_AGG(CONVERT(nvarchar(max), t.tval), N',') WITHIN GROUP (ORDER BY t.tval) FROM #tag t WHERE t.fid = f.fid AND t.owner_n = f.feature_n AND t.tkey = N'root-scenario'), N'')
   <> ISNULL((SELECT STRING_AGG(CONVERT(nvarchar(max), d.scenario_id), N',') WITHIN GROUP (ORDER BY d.scenario_id) FROM #dsc d WHERE d.fid = f.fid AND d.is_root = 1), N'');

-- Scenario identities in both directions.
INSERT #fd(fid, code, case_id, line) SELECT fid, 'SCENARIO_TAG_MISSING', case_id, line FROM #case WHERE scenario_ids = 0;
INSERT #fd(fid, code, case_id, line, fval)
SELECT c.fid, 'SCENARIO_TAG_AMBIGUOUS', c.case_id, c.line,
  (SELECT STRING_AGG(CONVERT(nvarchar(max), tval), N',') WITHIN GROUP (ORDER BY tval) FROM #pt WHERE pk = c.pk AND tkey = N'scenario')
FROM #case c WHERE c.scenario_ids > 1;
INSERT #fd(fid, code, scenario_id, line, fval)
SELECT c.fid, 'FEATURE_SCENARIO_UNDECLARED', t.tval, MIN(c.line), t.tval
FROM #case c JOIN @hasDecl h ON h.fid = c.fid JOIN #pt t ON t.pk = c.pk AND t.tkey = N'scenario'
WHERE NOT EXISTS (SELECT 1 FROM #dsc d WHERE d.fid = c.fid AND d.scenario_id = t.tval)
GROUP BY c.fid, t.tval;
INSERT #fd(fid, code, scenario_id, dval)
SELECT d.fid, 'SCENARIO_NOT_IN_FEATURE', d.scenario_id, d.scenario_id FROM #dsc d JOIN #feat f ON f.fid = d.fid
WHERE f.text IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #case c JOIN #pt t ON t.pk = c.pk AND t.tkey = N'scenario' AND t.tval = d.scenario_id WHERE c.fid = d.fid);

-- Identity tags of each tagged scenario against its declaration; a missing tag is a mismatch with no feature value.
;WITH tagged AS (
  SELECT DISTINCT c.fid, c.pk, c.line, t.tval AS scenario_id FROM #case c JOIN #pt t ON t.pk = c.pk AND t.tkey = N'scenario'),
kinds AS (
  SELECT d.fid, d.scenario_id, v.tkey, v.code, v.declared
  FROM #dsc d CROSS APPLY (VALUES
    (N'input', 'INPUT_IDENTITY_MISMATCH', d.input_id), (N'input-contract', 'INPUT_CONTRACT_MISMATCH', d.input_contract),
    (N'event', 'EVENT_IDENTITY_MISMATCH', d.event_id), (N'event-authority', 'EVENT_AUTHORITY_MISMATCH', d.event_authority),
    (N'outcome', 'OUTCOME_IDENTITY_MISMATCH', d.outcome_id), (N'outcome-contract', 'OUTCOME_CONTRACT_MISMATCH', d.outcome_contract)) v(tkey, code, declared)),
per AS (
  SELECT g.fid, g.scenario_id, k.code, g.line, k.declared,
    (SELECT STRING_AGG(CONVERT(nvarchar(max), t.tval), N',') WITHIN GROUP (ORDER BY t.tval) FROM #pt t WHERE t.pk = g.pk AND t.tkey = k.tkey) AS fval
  FROM tagged g JOIN kinds k ON k.fid = g.fid AND k.scenario_id = g.scenario_id)
INSERT #fd(fid, code, scenario_id, line, fval, dval)
SELECT fid, code, scenario_id, MIN(line), fval, declared FROM per
WHERE ISNULL(fval, N'') COLLATE Latin1_General_100_BIN2 <> ISNULL(declared, N'') COLLATE Latin1_General_100_BIN2
GROUP BY fid, code, scenario_id, fval, declared;
;WITH tagged AS (
  SELECT DISTINCT c.fid, c.pk, c.line, t.tval AS scenario_id FROM #case c JOIN #pt t ON t.pk = c.pk AND t.tkey = N'scenario'),
flags AS (
  SELECT g.fid, g.scenario_id, g.line, CASE WHEN EXISTS (SELECT 1 FROM #pt t WHERE t.pk = g.pk AND t.tkey = N'outcome-terminal') THEN 1 ELSE 0 END AS tagged_terminal
  FROM tagged g)
INSERT #fd(fid, code, scenario_id, line, fval, dval)
SELECT x.fid, 'OUTCOME_TERMINAL_MISMATCH', x.scenario_id, MIN(x.line), CASE WHEN x.tagged_terminal = 1 THEN N'terminal' ELSE N'not terminal' END,
  CASE WHEN d.terminal = 1 THEN N'terminal' ELSE N'not terminal' END
FROM flags x JOIN #dsc d ON d.fid = x.fid AND d.scenario_id = x.scenario_id
WHERE x.tagged_terminal <> ISNULL(CONVERT(int, d.terminal), 0)
GROUP BY x.fid, x.scenario_id, x.tagged_terminal, d.terminal;

-- Declared Gherkin steps must be steps of a case that tags the scenario.
INSERT #fd(fid, code, scenario_id, dval)
SELECT ds.fid, 'SCENARIO_STEP_NOT_IN_FEATURE', ds.scenario_id, ds.text
FROM #dstep ds
WHERE EXISTS (SELECT 1 FROM #case c JOIN #pt t ON t.pk = c.pk AND t.tkey = N'scenario' AND t.tval = ds.scenario_id WHERE c.fid = ds.fid)
  AND NOT EXISTS (SELECT 1 FROM #case c JOIN #pt t ON t.pk = c.pk AND t.tkey = N'scenario' AND t.tval = ds.scenario_id
    JOIN #ps s ON s.pk = c.pk AND s.text = ds.text AND (ds.stype NOT IN ('Context', 'Action', 'Outcome') OR ds.stype IS NULL OR s.stype = ds.stype)
    WHERE c.fid = ds.fid);

-- A tagged scenario whose declaration carries no Gherkin steps cannot be compared, so it does not pass.
INSERT #fd(fid, code, scenario_id)
SELECT d.fid, 'SCENARIO_STEPS_UNDECLARED', d.scenario_id FROM #dsc d
WHERE EXISTS (SELECT 1 FROM #case c JOIN #pt t ON t.pk = c.pk AND t.tkey = N'scenario' AND t.tval = d.scenario_id WHERE c.fid = d.fid)
  AND NOT EXISTS (SELECT 1 FROM #dstep s WHERE s.fid = d.fid AND s.scenario_id = d.scenario_id);

-- The feature version's scenario pins are the tagged scenarios at their selected versions.
INSERT #fd(fid, code, scenario_id, fval, dval)
SELECT f.fid, CASE WHEN d.svpk IS NULL THEN 'FEATURE_PIN_UNDECLARED' ELSE 'FEATURE_PIN_STALE' END, s.scenario_id,
  CONVERT(nvarchar(40), fs.scenario_version_pk), CONVERT(nvarchar(40), d.svpk)
FROM #feat f JOIN model.feature_scenario fs ON fs.feature_version_pk = f.fvpk JOIN model.scenario s ON s.scenario_pk = fs.scenario_pk
LEFT JOIN #dsc d ON d.fid = f.fid AND d.scenario_pk = fs.scenario_pk
WHERE f.fvpk IS NOT NULL AND (d.svpk IS NULL OR d.svpk <> fs.scenario_version_pk);
INSERT #fd(fid, code, scenario_id)
SELECT d.fid, 'FEATURE_PIN_MISSING', d.scenario_id FROM #dsc d JOIN #feat f ON f.fid = d.fid
WHERE f.fvpk IS NOT NULL AND EXISTS (SELECT 1 FROM #case c JOIN #pt t ON t.pk = c.pk AND t.tkey = N'scenario' AND t.tval = d.scenario_id WHERE c.fid = d.fid)
  AND NOT EXISTS (SELECT 1 FROM model.feature_scenario fs WHERE fs.feature_version_pk = f.fvpk AND fs.scenario_pk = d.scenario_pk);
INSERT #fd(fid, code, scenario_id)
SELECT f.fid, 'FEATURE_PIN_UNTAGGED', s.scenario_id
FROM #feat f JOIN model.feature_scenario fs ON fs.feature_version_pk = f.fvpk JOIN model.scenario s ON s.scenario_pk = fs.scenario_pk
WHERE f.fvpk IS NOT NULL AND NOT EXISTS (SELECT 1 FROM #case c JOIN #pt t ON t.pk = c.pk AND t.tkey = N'scenario'
  AND t.tval = s.scenario_id COLLATE Latin1_General_100_BIN2 WHERE c.fid = f.fid);

-- Provider tags resolve exactly to a selected capability.
INSERT #fd(fid, code, case_id, line, fval)
SELECT c.fid, 'PROVIDER_UNKNOWN', MIN(c.case_id), MIN(c.line), t.tval
FROM #case c JOIN #pt t ON t.pk = c.pk AND t.tkey = N'provider'
WHERE NOT EXISTS (SELECT 1 FROM model.estate_capability ec JOIN model.capability cp ON cp.capability_pk = ec.capability_pk
  JOIN model.identity_namespace ns ON ns.namespace_pk = cp.namespace_pk AND ns.namespace_id = N'sidefx:capabilities'
  WHERE ec.estate_model_pk = @e AND cp.capability_id COLLATE Latin1_General_100_BIN2 = t.tval)
GROUP BY c.fid, t.tval;

-- Acceptance cases: one identity each, a JSON request, and assertions that include the returned status.
INSERT #fd(fid, code, line) SELECT fid, 'CASE_IDENTITY_MISSING', line FROM #case WHERE case_ids = 0;
INSERT #fd(fid, code, case_id, line, fval)
SELECT c.fid, 'CASE_IDENTITY_AMBIGUOUS', c.case_id, c.line,
  (SELECT STRING_AGG(CONVERT(nvarchar(max), tval), N',') WITHIN GROUP (ORDER BY tval) FROM #pt WHERE pk = c.pk AND tkey = N'case')
FROM #case c WHERE c.case_ids > 1;
INSERT #fd(fid, code, case_id, line)
SELECT fid, 'CASE_IDENTITY_DUPLICATE', case_id, MIN(line) FROM #case WHERE case_id IS NOT NULL GROUP BY fid, case_id HAVING COUNT(*) > 1;
INSERT #fd(fid, code, case_id, line) SELECT fid, 'CASE_REQUEST_MISSING', case_id, line FROM #case WHERE request IS NULL;
INSERT #fd(fid, code, case_id, line) SELECT fid, 'CASE_REQUEST_INVALID', case_id, line FROM #case WHERE request IS NOT NULL AND ISJSON(request) = 0;
INSERT #fd(fid, code, case_id, line) SELECT fid, 'CASE_ASSERTION_MISSING', case_id, line FROM #case WHERE rows_n = 0;
INSERT #fd(fid, code, case_id, line)
SELECT c.fid, 'CASE_STATUS_UNASSERTED', c.case_id, c.line FROM #case c
WHERE c.rows_n > 0 AND NOT EXISTS (SELECT 1 FROM #pa a WHERE a.pk = c.pk AND a.path = N'$.status');
INSERT #fd(fid, code, scenario_id, case_id, line, fval)
SELECT c.fid, 'ASSERTION_OPERATION_UNDECLARED', c.scenario_id, c.case_id, c.line, a.operation
FROM #case c JOIN #pa a ON a.pk = c.pk JOIN #dsc d ON d.fid = c.fid AND d.scenario_id = c.scenario_id
WHERE c.scenario_ids = 1 AND NOT EXISTS (SELECT 1 FROM #dop o WHERE o.fid = c.fid AND o.scenario_id = c.scenario_id AND o.operation_id = a.operation)
GROUP BY c.fid, c.scenario_id, c.case_id, c.line, a.operation;
INSERT #fd(fid, code, scenario_id, case_id, line, fval, dval)
SELECT c.fid, 'OUTCOME_UNDECLARED', c.scenario_id, c.case_id, c.line, a.equals,
  (SELECT STRING_AGG(CONVERT(nvarchar(max), v.variant), N',') WITHIN GROUP (ORDER BY v.variant) FROM #dvar v WHERE v.fid = c.fid AND v.scenario_id = c.scenario_id)
FROM #case c JOIN #pa a ON a.pk = c.pk AND a.path = N'$.status'
WHERE c.scenario_ids = 1 AND EXISTS (SELECT 1 FROM #dvar v WHERE v.fid = c.fid AND v.scenario_id = c.scenario_id)
  AND NOT EXISTS (SELECT 1 FROM #dvar v WHERE v.fid = c.fid AND v.scenario_id = c.scenario_id AND v.variant = a.equals);

-- Lookup outcomes that end the check early.
INSERT #fd(fid, code) SELECT fid, 'FEATURE_BINDING_AMBIGUOUS' FROM #cap WHERE lookup = 'AMBIGUOUS';
INSERT #fd(fid, code, fval) SELECT fid, 'FEATURE_SOURCE_NOT_FOUND', content_digest FROM #feat WHERE text IS NULL;
INSERT #fd(fid, code, fval) SELECT fid, 'FEATURE_SOURCE_DIGEST_MISMATCH', content_digest FROM #feat WHERE text IS NOT NULL AND bytes_ok = 0;

-- 6. Acceptance: a case or a flight is proven only by its own call, in the pinned evidence.
CREATE TABLE #af(code varchar(60) NOT NULL, step_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL, case_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL, fval nvarchar(max) NULL, dval nvarchar(max) NULL);
CREATE TABLE #cand(rnk int NOT NULL, code varchar(60) NOT NULL, step_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL,
  case_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL, fval nvarchar(max) NULL, dval nvarchar(max) NULL);
DECLARE @acceptance nvarchar(max) = NULL;
IF @mode = N'acceptance'
BEGIN
  DECLARE @kind nvarchar(20) = JSON_VALUE(@acc, N'$.kind'), @accCase nvarchar(400) = JSON_VALUE(@acc, N'$.caseId'),
    @accRun nvarchar(100) = JSON_VALUE(@acc, N'$.runId'), @accDigest nvarchar(100) = JSON_VALUE(@acc, N'$.evidenceDigest'),
    @evDigest nvarchar(100) = CASE WHEN @etext IS NULL THEN NULL ELSE 'sha256:' + LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256',
      CONVERT(varbinary(max), CONVERT(varchar(max), @etext COLLATE Latin1_General_100_BIN2_UTF8))), 2)) END;
  IF @evDigest IS NULL OR @accDigest IS NULL OR @evDigest COLLATE Latin1_General_100_BIN2 <> @accDigest COLLATE Latin1_General_100_BIN2
    INSERT #af(code, fval, dval) VALUES('EVIDENCE_DIGEST_MISMATCH', @evDigest, @accDigest);
  ELSE IF ISJSON(@etext) = 0 INSERT #af(code) VALUES('EVIDENCE_CONTRACT_INVALID');
  ELSE
  BEGIN
    DECLARE @evRun nvarchar(100) = JSON_VALUE(@etext, N'$.runId');
    IF @accRun IS NULL OR @evRun IS NULL OR @accRun COLLATE Latin1_General_100_BIN2 <> @evRun COLLATE Latin1_General_100_BIN2
      INSERT #af(code, fval, dval) VALUES('RUN_MISMATCH', @evRun, @accRun);
    IF ISNULL(JSON_VALUE(@etext, N'$.read.partial'), N'true') <> N'false' OR ISNULL(JSON_QUERY(@etext, N'$.read.gaps'), N'[x]') <> N'[]'
      INSERT #af(code, fval) VALUES('EVIDENCE_GAP', JSON_QUERY(@etext, N'$.read.gaps'));
    IF @kind = N'flight'
    BEGIN
      IF ISNULL(JSON_VALUE(@etext, N'$.contractId'), N'') <> N'flight-run-evidence.v1' INSERT #af(code) VALUES('EVIDENCE_CONTRACT_INVALID');
      IF ISNULL(JSON_VALUE(@etext, N'$.flight.agentId'), N'') COLLATE Latin1_General_100_BIN2 <> ISNULL(JSON_VALUE(@acc, N'$.plan.agentId'), N'-') COLLATE Latin1_General_100_BIN2
        OR ISNULL(JSON_VALUE(@etext, N'$.flight.planRevision'), N'') <> ISNULL(JSON_VALUE(@acc, N'$.plan.planRevision'), N'-')
        OR ISNULL(JSON_VALUE(@etext, N'$.flight.planDigest'), N'') COLLATE Latin1_General_100_BIN2 <> ISNULL(JSON_VALUE(@acc, N'$.plan.planDigest'), N'-') COLLATE Latin1_General_100_BIN2
        INSERT #af(code, fval, dval) VALUES('PLAN_MISMATCH',
          CONCAT(JSON_VALUE(@etext, N'$.flight.agentId'), N' r', JSON_VALUE(@etext, N'$.flight.planRevision'), N' ', JSON_VALUE(@etext, N'$.flight.planDigest')),
          CONCAT(JSON_VALUE(@acc, N'$.plan.agentId'), N' r', JSON_VALUE(@acc, N'$.plan.planRevision'), N' ', JSON_VALUE(@acc, N'$.plan.planDigest')));
      CREATE TABLE #ev(cursor_n int NOT NULL, kind nvarchar(80) NOT NULL, event_id nvarchar(400) NULL, root nvarchar(2000) COLLATE Latin1_General_100_BIN2 NULL,
        capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL, invoking_cell nvarchar(400) NULL, graph_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL,
        graph_digest nvarchar(100) COLLATE Latin1_General_100_BIN2 NULL, variant nvarchar(200) COLLATE Latin1_General_100_BIN2 NULL);
      INSERT #ev SELECT cursor_n, kind, event_id, root, capability_id, invoking_cell, graph_id, graph_digest, variant
      FROM OPENJSON(@etext, N'$.events') WITH (cursor_n int N'$.cursor', kind nvarchar(80) N'$.kind', event_id nvarchar(400) N'$.eventId',
        root nvarchar(2000) N'$.rootExecutionId', capability_id nvarchar(400) N'$.capabilityId', invoking_cell nvarchar(400) N'$.invokingCellId',
        graph_id nvarchar(400) N'$.graphId', graph_digest nvarchar(100) N'$.canonicalGraphDigest', variant nvarchar(200) N'$.outcomeVariant');
      IF EXISTS (SELECT 1 FROM #ev WHERE event_id IS NULL OR CHARINDEX(N':' + ISNULL(@evRun, N'?') + N':', event_id) = 0)
        INSERT #af(code, fval) VALUES('EVIDENCE_RUN_MISMATCH', (SELECT TOP (1) event_id FROM #ev WHERE event_id IS NULL OR CHARINDEX(N':' + ISNULL(@evRun, N'?') + N':', event_id) = 0));
      -- The k-th dispatch is the k-th attempt; the join holds only while both counts agree.
      CREATE TABLE #dsp2(k int NOT NULL PRIMARY KEY, cursor_n int NOT NULL, next_cursor int NULL, root nvarchar(2000) COLLATE Latin1_General_100_BIN2 NULL,
        capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL);
      INSERT #dsp2(k, cursor_n, next_cursor, root, capability_id)
      SELECT ROW_NUMBER() OVER (ORDER BY cursor_n) - 1, cursor_n, LEAD(cursor_n) OVER (ORDER BY cursor_n), root, capability_id
      FROM #ev WHERE kind = N'nested-capability-invocation.v1' AND invoking_cell = N'cell:mechanic:fly-flight-step.dispatch';
      CREATE TABLE #att(k int NOT NULL PRIMARY KEY, step_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL, attempt int NULL, status nvarchar(40) COLLATE Latin1_General_100_BIN2 NULL,
        actual nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);
      INSERT #att(k, step_id, attempt, status, actual)
      SELECT ROW_NUMBER() OVER (ORDER BY s.ordinal, a.attempt) - 1, s.step_id, a.attempt, a.status, a.actual
      FROM OPENJSON(@etext, N'$.steps') WITH (step_id nvarchar(400) N'$.stepId', ordinal int N'$.ordinal', attempts nvarchar(max) N'$.attempts' AS JSON) s
      CROSS APPLY OPENJSON(s.attempts) WITH (attempt int N'$.attempt', status nvarchar(40) N'$.status', actual nvarchar(max) N'$.actual') a;
      DECLARE @gap bit = CASE WHEN (SELECT COUNT(*) FROM #dsp2) <> (SELECT COUNT(*) FROM #att) THEN 1 ELSE 0 END;
      CREATE TABLE #req(step_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL, tag nvarchar(800) COLLATE Latin1_General_100_BIN2 NULL,
        provider nvarchar(800) COLLATE Latin1_General_100_BIN2 NULL, accepted_digest nvarchar(100) COLLATE Latin1_General_100_BIN2 NULL,
        returned nvarchar(200) COLLATE Latin1_General_100_BIN2 NULL, epath nvarchar(1000) COLLATE Latin1_General_100_BIN2 NULL,
        eequals nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL, plan_cap nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL,
        plan_path nvarchar(1000) COLLATE Latin1_General_100_BIN2 NULL, plan_equals nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
        k int NULL, attempt int NULL, status nvarchar(40) COLLATE Latin1_General_100_BIN2 NULL, actual nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
        d_cursor int NULL, d_next int NULL, d_root nvarchar(2000) COLLATE Latin1_General_100_BIN2 NULL, d_cap nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL,
        g_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL, g_digest nvarchar(100) COLLATE Latin1_General_100_BIN2 NULL, o_variant nvarchar(200) COLLATE Latin1_General_100_BIN2 NULL,
        o_found bit NULL, g_found bit NULL);
      INSERT #req(step_id, tag, accepted_digest, returned, epath, eequals)
      SELECT step_id, tag, accepted_digest, returned, epath, eequals
      FROM OPENJSON(@acc, N'$.steps') WITH (step_id nvarchar(400) N'$.stepId', tag nvarchar(800) N'$.providerTag', accepted_digest nvarchar(100) N'$.acceptedGraphDigest',
        returned nvarchar(200) N'$.returnedOutcome', epath nvarchar(1000) N'$.expect.path', eequals nvarchar(max) N'$.expect.equals');
      UPDATE #req SET provider = CASE WHEN LEFT(tag, 10) = N'@provider:' THEN SUBSTRING(tag, 11, 800) END;
      UPDATE r SET plan_cap = p.capability_id, plan_path = p.epath, plan_equals = p.eequals FROM #req r
      JOIN OPENJSON(@etext, N'$.planSteps') WITH (step_id nvarchar(400) N'$.stepId', capability_id nvarchar(400) N'$.capabilityId',
        epath nvarchar(1000) N'$.expect.path', eequals nvarchar(max) N'$.expect.equals') p ON p.step_id COLLATE Latin1_General_100_BIN2 = r.step_id;
      UPDATE r SET k = a.k, attempt = a.attempt, status = a.status, actual = a.actual FROM #req r JOIN #att a ON a.step_id = r.step_id AND a.attempt = 1;
      UPDATE r SET d_cursor = d.cursor_n, d_next = d.next_cursor, d_root = d.root, d_cap = d.capability_id FROM #req r JOIN #dsp2 d ON d.k = r.k WHERE @gap = 0;
      UPDATE r SET g_found = CASE WHEN g.cursor_n IS NULL THEN 0 ELSE 1 END, g_id = g.graph_id, g_digest = g.graph_digest
      FROM #req r OUTER APPLY (SELECT TOP (1) e.cursor_n, e.graph_id, e.graph_digest FROM #ev e WHERE e.kind = N'execution-graph-captured.v1'
        AND e.root = r.d_root AND e.cursor_n > r.d_cursor AND (r.d_next IS NULL OR e.cursor_n < r.d_next) ORDER BY e.cursor_n) g
      WHERE r.d_cursor IS NOT NULL;
      UPDATE r SET o_found = CASE WHEN o.cursor_n IS NULL THEN 0 ELSE 1 END, o_variant = o.variant
      FROM #req r OUTER APPLY (SELECT TOP (1) e.cursor_n, e.variant FROM #ev e WHERE e.kind = N'execution-outcome-returned.v1'
        AND e.root = r.d_root AND e.cursor_n > r.d_cursor AND (r.d_next IS NULL OR e.cursor_n < r.d_next) ORDER BY e.cursor_n) o
      WHERE r.d_cursor IS NOT NULL;
      IF @gap = 1 INSERT #af(code, fval, dval) VALUES('EVIDENCE_ATTRIBUTION_GAP',
        CONCAT((SELECT COUNT(*) FROM #dsp2), N' dispatches'), CONCAT((SELECT COUNT(*) FROM #att), N' attempts'));
      -- Layers in order: tag, provider identity, step binding, attempt, call, graph, outcome, step result.
      INSERT #cand(rnk, code, step_id, fval, dval)
      SELECT x.rnk, x.code, r.step_id, x.fval, x.dval FROM #req r CROSS APPLY (
        SELECT 1 AS rnk, 'PROVIDER_TAG_MISSING' AS code, r.tag AS fval, N'@provider:<capability-id>' AS dval WHERE r.provider IS NULL
        UNION ALL SELECT 2, 'PROVIDER_UNKNOWN', r.provider, NULL WHERE r.provider IS NOT NULL AND NOT EXISTS (
          SELECT 1 FROM model.estate_capability ec JOIN model.capability cp ON cp.capability_pk = ec.capability_pk
          JOIN model.identity_namespace ns ON ns.namespace_pk = cp.namespace_pk AND ns.namespace_id = N'sidefx:capabilities'
          WHERE ec.estate_model_pk = @e AND cp.capability_id COLLATE Latin1_General_100_BIN2 = r.provider)
        UNION ALL SELECT 3, 'PROVIDER_TAG_NOT_STEP_BINDING', r.provider, r.plan_cap WHERE r.provider IS NOT NULL AND ISNULL(r.plan_cap, N'') <> r.provider
        UNION ALL SELECT 4, 'STEP_EXPECTATION_MISMATCH', CONCAT(r.epath, N' = ', r.eequals), CONCAT(r.plan_path, N' = ', r.plan_equals)
          WHERE ISNULL(r.epath, N'') <> ISNULL(r.plan_path, N'?') OR ISNULL(r.eequals, N'') <> ISNULL(r.plan_equals, N'?')
        UNION ALL SELECT 5, 'STEP_NOT_ATTEMPTED', NULL, NULL WHERE r.k IS NULL
        UNION ALL SELECT 6, CASE WHEN EXISTS (SELECT 1 FROM #dsp2 d WHERE d.capability_id = r.provider) THEN 'CALL_IN_ANOTHER_STEP' ELSE 'PROVIDER_SUBSTITUTED' END,
          r.d_cap, r.provider WHERE r.d_cursor IS NOT NULL AND r.provider IS NOT NULL AND ISNULL(r.d_cap, N'') <> r.provider
        UNION ALL SELECT 7, 'GRAPH_NOT_CAPTURED', NULL, r.accepted_digest WHERE r.d_cursor IS NOT NULL AND r.g_found = 0
        UNION ALL SELECT 7, 'PROVIDER_SUBSTITUTED', r.g_id, N'graph:' + r.provider WHERE r.g_found = 1 AND r.provider IS NOT NULL AND ISNULL(r.d_cap, N'') = r.provider
          AND ISNULL(r.g_id, N'') <> N'graph:' + r.provider
        UNION ALL SELECT 7, 'GRAPH_DIGEST_MISMATCH', r.g_digest, r.accepted_digest WHERE r.g_found = 1 AND ISNULL(r.g_digest, N'') <> ISNULL(r.accepted_digest, N'?')
        UNION ALL SELECT 8, 'OUTCOME_NOT_RETURNED', NULL, r.returned WHERE r.d_cursor IS NOT NULL AND r.o_found = 0
        UNION ALL SELECT 8, 'OUTCOME_MISMATCH', r.o_variant, r.returned WHERE r.o_found = 1 AND ISNULL(r.o_variant, N'') <> ISNULL(r.returned, N'?')
        UNION ALL SELECT 9, 'STEP_RESULT_MISMATCH', CONCAT(r.status, N' ', r.actual), CONCAT(N'PASSED ', r.eequals)
          WHERE r.k IS NOT NULL AND (ISNULL(r.status, N'') <> N'PASSED' OR ISNULL(r.actual, N'') <> ISNULL(r.eequals, N'?'))) x;
      INSERT #af(code, step_id, fval, dval)
      SELECT c.code, c.step_id, c.fval, c.dval FROM #cand c WHERE c.rnk = (SELECT MIN(c2.rnk) FROM #cand c2 WHERE c2.step_id = c.step_id);
      SET @acceptance = (SELECT N'flight' AS kind, @accCase AS caseId, @evRun AS runId, @accDigest AS evidenceDigest,
        CONVERT(bit, CASE WHEN @evDigest = @accDigest THEN 1 ELSE 0 END) AS evidenceVerified,
        (SELECT COUNT(*) FROM #dsp2) AS dispatches, (SELECT COUNT(*) FROM #att) AS attempts,
        (SELECT r.step_id AS stepId, r.tag AS providerTag, r.attempt, r.d_cursor AS dispatchCursor, r.d_cap AS invokedCapability,
           r.g_digest AS graphDigest, r.o_variant AS returnedOutcome, r.actual,
           CASE WHEN EXISTS (SELECT 1 FROM #af f WHERE f.step_id = r.step_id) OR EXISTS (SELECT 1 FROM #af f WHERE f.step_id IS NULL) THEN N'FAILED' ELSE N'PROVEN' END AS verdict,
           (SELECT STRING_AGG(CONVERT(nvarchar(max), f.code), N',') WITHIN GROUP (ORDER BY f.code) FROM #af f WHERE f.step_id = r.step_id) AS codes
         FROM #req r ORDER BY r.k FOR JSON PATH) AS steps
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
    END
    ELSE IF @kind = N'call'
    BEGIN
      IF ISNULL(JSON_VALUE(@etext, N'$.contractId'), N'') <> N'provider-call-evidence.v1' INSERT #af(code) VALUES('EVIDENCE_CONTRACT_INVALID');
      DECLARE @tag nvarchar(800) = JSON_VALUE(@acc, N'$.providerTag'), @op nvarchar(400) = JSON_VALUE(@acc, N'$.operation');
      DECLARE @prov nvarchar(800) = CASE WHEN LEFT(@tag, 10) = N'@provider:' THEN SUBSTRING(@tag, 11, 800) END;
      DECLARE @cpk int = (SELECT TOP (1) pk FROM #case WHERE case_id = @accCase COLLATE Latin1_General_100_BIN2 ORDER BY pk);
      IF @cpk IS NULL INSERT #cand(rnk, code, case_id) VALUES(1, 'CASE_NOT_FOUND', @accCase);
      ELSE
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM #pa WHERE pk = @cpk) INSERT #cand(rnk, code, case_id) VALUES(5, 'CASE_ASSERTION_MISSING', @accCase);
        ELSE IF NOT EXISTS (SELECT 1 FROM #pa WHERE pk = @cpk AND path = N'$.status') INSERT #cand(rnk, code, case_id) VALUES(5, 'CASE_STATUS_UNASSERTED', @accCase);
        IF NOT EXISTS (SELECT 1 FROM #pt WHERE pk = @cpk AND tkey = N'provider' AND tval = @prov COLLATE Latin1_General_100_BIN2)
          INSERT #cand(rnk, code, case_id, fval, dval) VALUES(4, 'PROVIDER_TAG_NOT_IN_CASE', @accCase, @tag,
            (SELECT STRING_AGG(CONVERT(nvarchar(max), tag), N',') FROM #pt WHERE pk = @cpk AND tkey = N'provider'));
        IF EXISTS (SELECT 1 FROM #pa WHERE pk = @cpk AND operation <> ISNULL(@op, N'') COLLATE Latin1_General_100_BIN2)
          INSERT #cand(rnk, code, case_id, fval, dval) VALUES(5, 'ASSERTION_OPERATION_NOT_PROVEN', @accCase,
            (SELECT TOP (1) operation FROM #pa WHERE pk = @cpk AND operation <> ISNULL(@op, N'') COLLATE Latin1_General_100_BIN2), @op);
      END
      IF @prov IS NULL INSERT #cand(rnk, code, fval) VALUES(2, 'PROVIDER_TAG_MISSING', @tag);
      ELSE IF NOT EXISTS (SELECT 1 FROM model.estate_capability ec JOIN model.capability cp ON cp.capability_pk = ec.capability_pk
          JOIN model.identity_namespace ns ON ns.namespace_pk = cp.namespace_pk AND ns.namespace_id = N'sidefx:capabilities'
          WHERE ec.estate_model_pk = @e AND cp.capability_id COLLATE Latin1_General_100_BIN2 = @prov COLLATE Latin1_General_100_BIN2)
        INSERT #cand(rnk, code, fval) VALUES(3, 'PROVIDER_UNKNOWN', @prov);
      IF ISNULL(JSON_VALUE(@etext, N'$.call.capabilityId'), N'') COLLATE Latin1_General_100_BIN2 <> ISNULL(@prov, N'?') COLLATE Latin1_General_100_BIN2
        OR ISNULL(JSON_VALUE(@etext, N'$.call.graph.graphId'), N'') COLLATE Latin1_General_100_BIN2 <> N'graph:' + ISNULL(@prov, N'?') COLLATE Latin1_General_100_BIN2
        INSERT #cand(rnk, code, fval, dval) VALUES(6, 'PROVIDER_SUBSTITUTED', JSON_VALUE(@etext, N'$.call.capabilityId'), @prov);
      IF ISNULL(JSON_VALUE(@etext, N'$.call.graph.rootExecutionId'), N'') COLLATE Latin1_General_100_BIN2 <> ISNULL(JSON_VALUE(@etext, N'$.call.rootExecutionId'), N'?') COLLATE Latin1_General_100_BIN2
        OR ISNULL(JSON_VALUE(@etext, N'$.call.outcome.rootExecutionId'), N'') COLLATE Latin1_General_100_BIN2 <> ISNULL(JSON_VALUE(@etext, N'$.call.rootExecutionId'), N'?') COLLATE Latin1_General_100_BIN2
        INSERT #cand(rnk, code) VALUES(6, 'CALL_NOT_ATTRIBUTED');
      IF ISNULL(JSON_VALUE(@etext, N'$.call.graph.canonicalGraphDigest'), N'') COLLATE Latin1_General_100_BIN2 <> ISNULL(JSON_VALUE(@acc, N'$.acceptedGraphDigest'), N'?') COLLATE Latin1_General_100_BIN2
        INSERT #cand(rnk, code, fval, dval) VALUES(7, 'GRAPH_DIGEST_MISMATCH', JSON_VALUE(@etext, N'$.call.graph.canonicalGraphDigest'), JSON_VALUE(@acc, N'$.acceptedGraphDigest'));
      IF JSON_VALUE(@etext, N'$.call.outcome.outcomeVariant') IS NULL INSERT #cand(rnk, code) VALUES(8, 'OUTCOME_NOT_RETURNED');
      ELSE IF JSON_VALUE(@etext, N'$.call.outcome.outcomeVariant') COLLATE Latin1_General_100_BIN2 <> ISNULL(JSON_VALUE(@acc, N'$.returnedOutcome'), N'?') COLLATE Latin1_General_100_BIN2
        INSERT #cand(rnk, code, fval, dval) VALUES(8, 'OUTCOME_MISMATCH', JSON_VALUE(@etext, N'$.call.outcome.outcomeVariant'), JSON_VALUE(@acc, N'$.returnedOutcome'));
      IF ISNULL(JSON_VALUE(@etext, N'$.call.request.attestedDigest'), N'') COLLATE Latin1_General_100_BIN2 <> ISNULL(JSON_VALUE(@etext, N'$.requestCanonicalSha256'), N'?') COLLATE Latin1_General_100_BIN2
        INSERT #cand(rnk, code, fval, dval) VALUES(9, 'EVIDENCE_REQUEST_UNATTESTED', JSON_VALUE(@etext, N'$.requestCanonicalSha256'), JSON_VALUE(@etext, N'$.call.request.attestedDigest'));
      -- The run's request must be this case's request, member for member.
      DECLARE @want nvarchar(max) = (SELECT request FROM #case WHERE pk = @cpk);
      DECLARE @got nvarchar(max) = JSON_QUERY(@etext, N'$.request' + SUBSTRING(ISNULL(JSON_VALUE(@acc, N'$.requestPath'), N'$'), 2, 1000));
      DECLARE @cw nvarchar(max), @cg nvarchar(max);
      SELECT @cw = STRING_AGG(CONVERT(nvarchar(max), j.[key] + N'=' + CONVERT(nvarchar(4), j.[type]) + N':' + ISNULL(n.flat, j.value)), N'|') WITHIN GROUP (ORDER BY j.[key] COLLATE Latin1_General_100_BIN2)
      FROM OPENJSON(CASE WHEN ISJSON(@want) = 1 THEN @want END) j
      OUTER APPLY (SELECT STRING_AGG(CONVERT(nvarchar(max), j2.[key] + N'=' + CONVERT(nvarchar(4), j2.[type]) + N':' + j2.value), N',') WITHIN GROUP (ORDER BY j2.[key] COLLATE Latin1_General_100_BIN2) AS flat
        FROM OPENJSON(CASE WHEN j.[type] IN (4, 5) THEN j.value END) j2) n;
      SELECT @cg = STRING_AGG(CONVERT(nvarchar(max), j.[key] + N'=' + CONVERT(nvarchar(4), j.[type]) + N':' + ISNULL(n.flat, j.value)), N'|') WITHIN GROUP (ORDER BY j.[key] COLLATE Latin1_General_100_BIN2)
      FROM OPENJSON(CASE WHEN ISJSON(@got) = 1 THEN @got END) j
      OUTER APPLY (SELECT STRING_AGG(CONVERT(nvarchar(max), j2.[key] + N'=' + CONVERT(nvarchar(4), j2.[type]) + N':' + j2.value), N',') WITHIN GROUP (ORDER BY j2.[key] COLLATE Latin1_General_100_BIN2) AS flat
        FROM OPENJSON(CASE WHEN j.[type] IN (4, 5) THEN j.value END) j2) n;
      IF @cw IS NULL OR @cg IS NULL OR @cw COLLATE Latin1_General_100_BIN2 <> @cg COLLATE Latin1_General_100_BIN2
        INSERT #cand(rnk, code, case_id, fval, dval) VALUES(9, 'EVIDENCE_REQUEST_MISMATCH', @accCase, @got, @want);
      -- Each assertion of the case reads the operation's own returned value.
      DECLARE @val nvarchar(max) = JSON_QUERY(@etext, N'$.result' + SUBSTRING(ISNULL(JSON_VALUE(@acc, N'$.valuePath'), N'$'), 2, 1000));
      CREATE TABLE #av(row_i int NOT NULL, operation nvarchar(400) NULL, path nvarchar(1000) NULL, equals nvarchar(max) NULL, actual nvarchar(max) NULL, ok bit NULL, err nvarchar(400) NULL);
      INSERT #av(row_i, operation, path, equals) SELECT row_i, operation, path, equals FROM #pa WHERE pk = @cpk;
      DECLARE @ar int = -1, @ap nvarchar(1000), @aa nvarchar(max);
      WHILE 1 = 1
      BEGIN
        SELECT TOP (1) @ar = row_i, @ap = path FROM #av WHERE row_i > @ar ORDER BY row_i;
        IF @@ROWCOUNT = 0 BREAK;
        BEGIN TRY
          SET @aa = COALESCE(JSON_VALUE(@val, @ap), JSON_QUERY(@val, @ap));
          UPDATE #av SET actual = @aa, ok = CASE WHEN @aa COLLATE Latin1_General_100_BIN2 = equals COLLATE Latin1_General_100_BIN2
            OR (@aa IS NULL AND equals = N'(absent)') THEN 1 ELSE 0 END WHERE row_i = @ar;
        END TRY
        BEGIN CATCH
          UPDATE #av SET ok = 0, err = LEFT(ERROR_MESSAGE(), 400) WHERE row_i = @ar;
        END CATCH
      END
      INSERT #cand(rnk, code, case_id, fval, dval)
      SELECT 10, CASE WHEN err IS NULL THEN 'ASSERTION_FAILED' ELSE 'ASSERTION_PATH_INVALID' END, @accCase, CONCAT(path, N' = ', ISNULL(actual, N'(absent)')), CONCAT(path, N' = ', equals)
      FROM #av WHERE ISNULL(ok, 0) = 0;
      INSERT #af(code, case_id, fval, dval) SELECT code, case_id, fval, dval FROM #cand WHERE rnk = (SELECT MIN(rnk) FROM #cand);
      SET @acceptance = (SELECT N'call' AS kind, @accCase AS caseId, @evRun AS runId, @accDigest AS evidenceDigest,
        CONVERT(bit, CASE WHEN @evDigest = @accDigest THEN 1 ELSE 0 END) AS evidenceVerified,
        JSON_VALUE(@etext, N'$.call.capabilityId') AS invokedCapability, JSON_VALUE(@etext, N'$.call.graph.canonicalGraphDigest') AS graphDigest,
        JSON_VALUE(@etext, N'$.call.outcome.outcomeVariant') AS returnedOutcome,
        CONVERT(bit, CASE WHEN @cw = @cg THEN 1 ELSE 0 END) AS requestMatches,
        (SELECT operation, path, equals, actual, CONVERT(bit, ISNULL(ok, 0)) AS ok FROM #av ORDER BY row_i FOR JSON PATH) AS assertions
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
    END
    ELSE INSERT #af(code, fval) VALUES('ACCEPTANCE_KIND_UNKNOWN', @kind);
  END
END

-- 7. Result.
DECLARE @r TABLE(fid int PRIMARY KEY, status varchar(20), signature nvarchar(max));
INSERT @r(fid, status)
SELECT k.fid, CASE
    WHEN k.lookup = 'NOT_FOUND' THEN 'NOT_FOUND'
    WHEN k.lookup IN ('NOT_BOUND', 'AMBIGUOUS') THEN 'NOT_BOUND'
    WHEN EXISTS (SELECT 1 FROM #fd f WHERE f.fid = k.fid) THEN CASE WHEN k.cvpk IS NULL THEN 'MALFORMED' ELSE 'DRIFT' END
    ELSE CASE WHEN k.cvpk IS NULL THEN 'WELL_FORMED' ELSE 'CONFORMANT' END END
FROM #cap k;
UPDATE r SET signature = N'status=' + r.status + ISNULL((SELECT STRING_AGG(CONVERT(nvarchar(max), N';' + x.code + N'=' + CONVERT(nvarchar(10), x.cnt)), N'')
  WITHIN GROUP (ORDER BY x.code) FROM (SELECT code, COUNT(*) AS cnt FROM #fd f WHERE f.fid = r.fid GROUP BY code) x), N'')
FROM @r r;
IF @mode = N'baseline'
  SET @res = (SELECT N'capability-feature-conformance.v1' AS contractId, N'baseline' AS mode, N'BASELINE' AS status, @e AS estateModelPk,
    @after AS [page.after], @size AS [page.size], (SELECT MAX(capability_id) FROM #cap) AS [page.last], (SELECT COUNT(*) FROM #cap) AS [page.count],
    (SELECT r.status, COUNT(*) AS capabilities FROM @r r GROUP BY r.status FOR JSON PATH) AS byStatus,
    (SELECT f.code, COUNT(DISTINCT f.fid) AS capabilities, COUNT(*) AS findings FROM #fd f GROUP BY f.code FOR JSON PATH) AS byCode,
    (SELECT k.capability_id AS capabilityId, r.status, r.signature FROM #cap k JOIN @r r ON r.fid = k.fid ORDER BY k.capability_id FOR JSON PATH) AS capabilities
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
ELSE
BEGIN
  DECLARE @fid int = (SELECT MIN(fid) FROM #cap);
  DECLARE @st varchar(20) = (SELECT status FROM @r WHERE fid = @fid), @sig nvarchar(max) = (SELECT signature FROM @r WHERE fid = @fid);
  IF @mode = N'acceptance'
  BEGIN
    SET @st = CASE WHEN EXISTS (SELECT 1 FROM #af) THEN 'REJECTED' ELSE 'ACCEPTED' END;
    SET @sig = N'status=' + @st + ISNULL((SELECT STRING_AGG(CONVERT(nvarchar(max), N';' + x.code + N'=' + CONVERT(nvarchar(10), x.cnt)), N'')
      WITHIN GROUP (ORDER BY x.code) FROM (SELECT code, COUNT(*) AS cnt FROM #af GROUP BY code) x), N'');
  END
  SET @res = (SELECT N'capability-feature-conformance.v1' AS contractId, @mode AS mode, @st AS status,
    k.capability_id AS capabilityId, k.cvpk AS capabilityVersionPk, @e AS estateModelPk,
    f.source AS [feature.source], f.fvpk AS [feature.featureVersionPk], f.content_digest AS [feature.contentDigest], f.bytes_ok AS [feature.bytesVerified],
    (SELECT COUNT(*) FROM #el e WHERE e.fid = @fid AND e.kind IN ('S', 'O')) AS [parse.scenarios],
    (SELECT COUNT(*) FROM #pk p WHERE p.fid = @fid) AS [parse.pickles],
    (SELECT COUNT(*) FROM #case c WHERE c.fid = @fid AND c.case_id IS NOT NULL) AS [parse.cases],
    (SELECT d.scenario_id AS scenarioId, d.is_root AS root,
       (SELECT COUNT(*) FROM #case c JOIN #pt t ON t.pk = c.pk AND t.tkey = N'scenario' AND t.tval = d.scenario_id WHERE c.fid = d.fid) AS cases,
       (SELECT STRING_AGG(CONVERT(nvarchar(max), v.variant), N',') WITHIN GROUP (ORDER BY v.variant) FROM #dvar v WHERE v.fid = d.fid AND v.scenario_id = d.scenario_id) AS variants,
       (SELECT STRING_AGG(CONVERT(nvarchar(max), o.operation_id), N',') FROM #dop o WHERE o.fid = d.fid AND o.scenario_id = d.scenario_id) AS operations,
       d.input_id AS [declared.input], d.input_contract AS [declared.inputContract], d.event_id AS [declared.event], d.event_authority AS [declared.eventAuthority],
       d.outcome_id AS [declared.outcome], d.outcome_contract AS [declared.outcomeContract], d.terminal AS [declared.terminal]
     FROM #dsc d WHERE d.fid = @fid ORDER BY d.is_root DESC, d.scenario_id FOR JSON PATH) AS scenarios,
    (SELECT c.line, c.case_id AS caseId, c.scenario_id AS scenarioId,
       (SELECT STRING_AGG(CONVERT(nvarchar(max), t.tag), N' ') WITHIN GROUP (ORDER BY t.tag) FROM #pt t WHERE t.pk = c.pk) AS tags,
       (SELECT COUNT(*) FROM #ps s WHERE s.pk = c.pk) AS steps, CONVERT(bit, CASE WHEN c.request IS NULL THEN 0 ELSE 1 END) AS request, c.rows_n AS assertions,
       JSON_QUERY(CASE WHEN @explain = 1 THEN (SELECT s.stype AS type, s.text, s.media AS mediaType, s.doc AS docString,
         (SELECT JSON_QUERY(N'[' + STRING_AGG(CONVERT(nvarchar(max), N'[' + x.cells + N']'), N',') WITHIN GROUP (ORDER BY x.row_i) + N']')
            FROM (SELECT pc.row_i, STRING_AGG(CONVERT(nvarchar(max), N'"' + STRING_ESCAPE(pc.val, 'json') + N'"'), N',') WITHIN GROUP (ORDER BY pc.col_i) AS cells
                  FROM #pc pc WHERE pc.pk = s.pk AND pc.ord = s.ord GROUP BY pc.row_i) x) AS dataTable
         FROM #ps s WHERE s.pk = c.pk ORDER BY s.ord FOR JSON PATH) END) AS stepsDetail,
       CASE WHEN @explain = 1 THEN c.request END AS requestText
     FROM #case c WHERE c.fid = @fid ORDER BY c.pk FOR JSON PATH) AS pickles,
    (SELECT x.code, x.scenario_id AS scenarioId, x.case_id AS caseId, x.line, x.fval AS featureValue, x.dval AS declaredValue
     FROM #fd x WHERE x.fid = @fid ORDER BY x.code, x.scenario_id, x.case_id, x.line FOR JSON PATH) AS findings,
    JSON_QUERY(@acceptance) AS acceptance,
    (SELECT a.code, a.step_id AS stepId, a.case_id AS caseId, a.fval AS evidenceValue, a.dval AS acceptedValue FROM #af a ORDER BY a.code, a.step_id FOR JSON PATH) AS acceptanceFindings,
    @sig AS [summary.signature]
    FROM #cap k LEFT JOIN #feat f ON f.fid = k.fid WHERE k.fid = @fid
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
END
SELECT @res AS value;
END
