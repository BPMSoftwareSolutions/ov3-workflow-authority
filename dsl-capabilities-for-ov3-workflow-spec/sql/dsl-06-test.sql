-- dsl-06-test.sql
--
-- Run this first, once. It runs the reviewed revisions as session procedures and installs nothing:
--   analysis.compile_capability_dsl (source/analysis.compile_capability_dsl.v3.sql), model.apply_capability_from_dsl
--   (source/model.apply_capability_from_dsl.v3.sql) and analysis.check_capability_feature_conformance (conformance/check_capability_feature_conformance.body.sql).
-- 1. Regressions: four sources compile with the revision to exactly the installed compiler's result.
-- 2. The new lines: feature, uses provider, input ... from and outcome from, each source as features/compile-capability-dsl.feature
--    states it. The feature bytes the sources pin are retained by the installed writer model.mint_content_artifact inside a
--    transaction that rolls back.
-- 3. The author path, inside a transaction that rolls back: it declares probe capability dsl02-probe-feature-first from
--    conformance/fixtures/compile/feature-pin.dsl, binds the feature bytes the source pins to the version it selected, keeps
--    the pin in the stored document, and the check finds the binding CONFORMANT. A source that drifts from its feature is
--    refused. Afterwards nothing of the probe remains.
-- WHERE: the estate database. Run the whole file in one session with no open transaction. About 8 minutes: each compile
-- takes about 22 s. RESULT SETS: base; the author path's own result sets; checks; verdict (PASSED when every check passed).
SET NOCOUNT ON;
IF @@TRANCOUNT>0
BEGIN
 RAISERROR(N'DSL06_OPEN_TRANSACTION: run this file in a session with no open transaction.',16,1);
 SET NOEXEC ON;
END
DECLARE @c varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),OBJECT_DEFINITION(OBJECT_ID(N'analysis.compile_capability_dsl')) COLLATE Latin1_General_100_BIN2_UTF8)),2));
DECLARE @a varchar(80)='sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),OBJECT_DEFINITION(OBJECT_ID(N'model.apply_capability_from_dsl')) COLLATE Latin1_General_100_BIN2_UTF8)),2));
SELECT N'base' AS result_set,@c AS compiler_installed,'sha256:e0fbb0387b5bd9f6f0c95c1eb36e8da3b3b0ac29e8bbdab86f8337e905cd3d5a' AS compiler_expected,@a AS author_path_installed,'sha256:21db231877532886e39141d4515aa299aec4c493213c4278830dba838b6cbfd5' AS author_path_expected;
IF @c IS NULL OR @c<>'sha256:e0fbb0387b5bd9f6f0c95c1eb36e8da3b3b0ac29e8bbdab86f8337e905cd3d5a' OR @a IS NULL OR @a<>'sha256:21db231877532886e39141d4515aa299aec4c493213c4278830dba838b6cbfd5'
BEGIN
 RAISERROR(N'DSL06_BASE_MOVED: an installed procedure is not the base the revisions were drafted against; read it before running this file.',16,1);
 SET NOEXEC ON;
END
DROP PROCEDURE IF EXISTS #dsl06_apply;
DROP PROCEDURE IF EXISTS #dsl06_compile;
DROP PROCEDURE IF EXISTS #dsl06_check;
DROP TABLE IF EXISTS #dsl06_check_rows;
CREATE TABLE #dsl06_check_rows(o int IDENTITY(1,1) PRIMARY KEY,area nvarchar(40) NOT NULL,item nvarchar(400) NOT NULL,expected nvarchar(max) NULL,actual nvarchar(max) NULL,passed bit NOT NULL);
GO
CREATE PROCEDURE #dsl06_check
  @input nvarchar(max),@estate_model_pk bigint=NULL,@result nvarchar(max)=NULL OUTPUT,@emit bit=1
AS
-- Body of analysis.check_capability_feature_conformance (parameters @input nvarchar(max), @estate_model_pk bigint,
-- @result nvarchar(max) OUTPUT, @emit bit): the result is returned in @result, and also selected as value when @emit is 1.
-- Read-only: it reads model.* and source.* and writes only its own temporary tables.
-- Canonical reference: features/check-capability-feature-conformance.feature.
--
-- Request (check-capability-feature-conformance-request.v1), one of:
--   {"capabilityId"}                                   the canonical feature bound to the selected version, exactly
--   {"featureText" | "featureDigest", "capabilityId"?} that text; with capabilityId, compared with its declaration
--   {"featureText" | "featureDigest", "document"}    that text against a compiled document, before anything is declared
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
DECLARE @docin nvarchar(max) = JSON_QUERY(@input, N'$.document');
DECLARE @base nvarchar(max) = JSON_QUERY(@input, N'$.baseline');
DECLARE @explain bit = CASE WHEN JSON_VALUE(@input, N'$.explain') = N'true' THEN 1 ELSE 0 END;
DECLARE @mode nvarchar(20) = CASE WHEN @base IS NOT NULL THEN N'baseline' WHEN @acc IS NOT NULL THEN N'acceptance'
  WHEN @docin IS NOT NULL THEN N'document' WHEN @ftext IS NOT NULL OR @fdig IS NOT NULL THEN N'text' ELSE N'bound' END;
DECLARE @after nvarchar(400) = ISNULL(JSON_VALUE(@base, N'$.after'), N'');
DECLARE @size int = ISNULL(TRY_CONVERT(int, JSON_VALUE(@base, N'$.size')), 100);
DECLARE @res nvarchar(max);

-- 1. Capabilities under check: exact identity in sidefx:capabilities of the selected estate, no fallback.
CREATE TABLE #cap(fid int IDENTITY(1,1) PRIMARY KEY, capability_pk bigint NULL, capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NULL,
  cvpk bigint NULL, lookup varchar(20) NOT NULL DEFAULT 'FOUND');
IF @mode = N'document'
  INSERT #cap(capability_id, lookup) VALUES(ISNULL(@capId, JSON_VALUE(@docin, N'$.capabilityId')), 'DOCUMENT');
ELSE IF @mode = N'baseline'
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
IF @mode = N'document'
  INSERT #dsc(fid, scenario_pk, scenario_id, svpk, is_root, input_id, input_contract, event_id, event_authority, outcome_id, outcome_contract, terminal, eavpk, envelope)
  SELECT k.fid, 0, s.scenarioId, 0, CASE WHEN s.root = N'true' THEN 1 ELSE 0 END, s.inputId, s.inputContract, s.eventId, s.eventAuthority,
    s.outcomeId, s.outcomeContract, CASE WHEN s.terminal = N'true' THEN 1 ELSE 0 END, NULL, s.scen
  FROM #cap k CROSS APPLY OPENJSON(@docin, N'$.scenarios') WITH (scenarioId nvarchar(400) N'$.scenarioId', root nvarchar(10) N'$.root',
    terminal nvarchar(10) N'$.terminal', inputId nvarchar(400) N'$.inputId', inputContract nvarchar(400) N'$.inputContract',
    eventId nvarchar(400) N'$.eventId', eventAuthority nvarchar(400) N'$.eventAuthority', outcomeId nvarchar(400) N'$.outcomeId',
    outcomeContract nvarchar(400) N'$.outcomeContract', scen nvarchar(max) N'$' AS JSON) s
  WHERE k.lookup = 'DOCUMENT' AND s.scenarioId IS NOT NULL AND EXISTS (SELECT 1 FROM #feat f WHERE f.fid = k.fid);
CREATE TABLE #dstep(fid int NOT NULL, scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL, ord int NOT NULL, stype varchar(20) NULL,
  text nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);
INSERT #dstep(fid, scenario_id, ord, stype, text)
SELECT d.fid, d.scenario_id, CONVERT(int, j.[key]), JSON_VALUE(j.value, N'$.keywordType'), x.text
FROM #dsc d CROSS APPLY OPENJSON(CASE WHEN ISJSON(d.envelope) = 1 THEN d.envelope END, N'$.semantics.scenario.steps') j
CROSS APPLY OPENJSON(CASE WHEN ISJSON(j.value) = 1 THEN j.value END) WITH (text nvarchar(max) N'$.text') x
WHERE @mode <> N'document';
-- A document's scenario states its steps as given, when and then.
INSERT #dstep(fid, scenario_id, ord, stype, text)
SELECT d.fid, d.scenario_id, v.ord, v.stype, v.txt FROM #dsc d
CROSS APPLY (VALUES (0, 'Context', JSON_VALUE(d.envelope, N'$.given')), (1, 'Action', JSON_VALUE(d.envelope, N'$.when')),
  (2, 'Outcome', JSON_VALUE(d.envelope, N'$.then'))) v(ord, stype, txt)
WHERE @mode = N'document' AND v.txt IS NOT NULL;
CREATE TABLE #dvar(fid int NOT NULL, scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL, variant nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL);
INSERT #dvar SELECT d.fid, d.scenario_id, ov.variant_id FROM #dsc d JOIN model.outcome_variant ov ON ov.scenario_version_pk = d.svpk WHERE ov.variant_id IS NOT NULL;
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
WHERE @mode = N'document' AND d.terminal = 1 AND NOT EXISTS (SELECT 1 FROM #dvar v WHERE v.fid = d.fid AND v.scenario_id = d.scenario_id);
CREATE TABLE #dop(fid int NOT NULL, scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL, operation_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL);
INSERT #dop SELECT d.fid, d.scenario_id, o.operation_id FROM #dsc d JOIN model.execution_operation o ON o.execution_authority_version_pk = d.eavpk WHERE o.operation_id IS NOT NULL;
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
WHERE @mode <> N'document' AND x.providerCapabilityId IS NOT NULL;

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

-- Provider tags equal the provider capabilities the scenario's operations name, in both directions. A tag that does not
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
    WHEN EXISTS (SELECT 1 FROM #fd f WHERE f.fid = k.fid) THEN CASE WHEN k.cvpk IS NULL AND k.lookup <> 'DOCUMENT' THEN 'MALFORMED' ELSE 'DRIFT' END
    ELSE CASE WHEN k.cvpk IS NULL AND k.lookup <> 'DOCUMENT' THEN 'WELL_FORMED' ELSE 'CONFORMANT' END END
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
SET @result = @res;
IF @emit = 1 SELECT @res AS value;
END
GO
CREATE PROCEDURE #dsl06_compile
  @input nvarchar(max),@estate_model_pk bigint
AS
BEGIN
  SET NOCOUNT ON;
  IF @input IS NULL OR ISJSON(@input)<>1 OR LEFT(LTRIM(@input),1)<>N'{'
    THROW 51000,N'COMPILE_DSL_REQUEST_INVALID',1;
  IF EXISTS(SELECT 1 FROM OPENJSON(@input) WHERE [key] NOT IN (N'source'))
    THROW 51000,N'COMPILE_DSL_REQUEST_SHAPE_INVALID',1;
  DECLARE @source nvarchar(max)=(SELECT [value] FROM OPENJSON(@input) WHERE [key]=N'source');
  IF @source IS NULL OR LEN(@source)=0 THROW 51000,N'COMPILE_DSL_SOURCE_REQUIRED',1;
  DECLARE @estate bigint=@estate_model_pk;
  IF @estate IS NULL SELECT @estate=estate_model_pk FROM source.current_model WHERE singleton_id=1;
  IF @estate IS NULL THROW 51000,N'COMPILE_DSL_ESTATE_REQUIRED',1;
  DECLARE @source_digest varchar(71)=N'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),@source COLLATE Latin1_General_100_BIN2_UTF8))),2));
  DECLARE @lines TABLE(line_no int PRIMARY KEY,line nvarchar(max));
  DECLARE @rest nvarchar(max)=@source,@line nvarchar(max),@ln int=0,@nl int;
  WHILE LEN(@rest)>0
  BEGIN
    SET @ln+=1;
    SET @nl=CHARINDEX(CHAR(10),@rest);
    SET @line=CASE WHEN @nl=0 THEN @rest ELSE LEFT(@rest,@nl-1) END;
    SET @rest=CASE WHEN @nl=0 THEN N'' ELSE SUBSTRING(@rest,@nl+1,LEN(@rest)) END;
    SET @line=LTRIM(RTRIM(REPLACE(REPLACE(@line,CHAR(13),N''),CHAR(9),N' ')));
    INSERT @lines VALUES(@ln,@line);
  END
  DECLARE @errors TABLE(seq int IDENTITY,line_no int,code nvarchar(40),message nvarchar(400));
  DECLARE @capability_id nvarchar(200)=NULL,@intent nvarchar(max)=NULL,@outcome nvarchar(max)=NULL;
  DECLARE @input_id nvarchar(200)=NULL,@input_schema nvarchar(max)=NULL;
  DECLARE @output_id nvarchar(200)=NULL,@output_schema nvarchar(max)=NULL;
  DECLARE @display_select nvarchar(100)=NULL,@display_format nvarchar(20)=NULL;
  DECLARE @scenarios TABLE(ordinal int IDENTITY PRIMARY KEY,scenario_id nvarchar(200) COLLATE Latin1_General_100_BIN2,root bit,terminal bit,given_txt nvarchar(max),when_txt nvarchar(max),then_txt nvarchar(max),line_no int,input_contract nvarchar(200),output_contract nvarchar(200),given_line int,when_line int,then_line int);
  DECLARE @operations TABLE(ordinal int IDENTITY PRIMARY KEY,scenario_ordinal int,operation_id nvarchar(200) COLLATE Latin1_General_100_BIN2,kind nvarchar(40),port_id nvarchar(200) COLLATE Latin1_General_100_BIN2,line_no int,target_scenario nvarchar(200),variants_json nvarchar(max),collection_path nvarchar(400),max_iterations int);
  -- Example inquiries, further contracts, scenario and operation outcome variants,
  -- selection routes and CLI input/readings.
  DECLARE @inquiries TABLE(ordinal int IDENTITY PRIMARY KEY,txt nvarchar(max),line_no int);
  DECLARE @extra_contracts TABLE(ordinal int IDENTITY PRIMARY KEY,contract_id nvarchar(200) COLLATE Latin1_General_100_BIN2,schema_json nvarchar(max),line_no int);
  DECLARE @scenario_variants TABLE(ordinal int IDENTITY PRIMARY KEY,scenario_ordinal int,variant_id nvarchar(200) COLLATE Latin1_General_100_BIN2,classification nvarchar(20),line_no int);
  DECLARE @op_variants TABLE(ordinal int IDENTITY PRIMARY KEY,operation_ordinal int,variant_id nvarchar(200) COLLATE Latin1_General_100_BIN2,classification nvarchar(20),is_terminal bit,line_no int);
  DECLARE @routes TABLE(ordinal int IDENTITY PRIMARY KEY,from_scenario nvarchar(200) COLLATE Latin1_General_100_BIN2,variant nvarchar(200) COLLATE Latin1_General_100_BIN2,to_scenario nvarchar(200) COLLATE Latin1_General_100_BIN2,line_no int);
  DECLARE @recurrences TABLE(ordinal int IDENTITY PRIMARY KEY,scenario_id nvarchar(200) COLLATE Latin1_General_100_BIN2,continue_variant nvarchar(200) COLLATE Latin1_General_100_BIN2,stop_variant nvarchar(200) COLLATE Latin1_General_100_BIN2,max_iterations int,line_no int);
  DECLARE @readings TABLE(ordinal int IDENTITY PRIMARY KEY,reading nvarchar(100),altitudes nvarchar(400));
  DECLARE @cli_input_type nvarchar(10)=N'json',@cli_input_path nvarchar(400)=NULL,@last_operation int=NULL,@items nvarchar(max);
  DECLARE @bindings TABLE(ordinal int IDENTITY PRIMARY KEY,scenario_ordinal int,port_id nvarchar(200) COLLATE Latin1_General_100_BIN2,form nvarchar(20),platform_id nvarchar(200),provider_id nvarchar(200),statement nvarchar(max),result_column nvarchar(200),config_json nvarchar(max),platform_line int,provider_line int,statement_line int,result_line int,config_line int,bind_line int);
  DECLARE @topology TABLE(ordinal int IDENTITY PRIMARY KEY,form nvarchar(20) COLLATE Latin1_General_100_BIN2,root_id nvarchar(200),join_id nvarchar(200),legs nvarchar(max),line_no int);
  DECLARE @provider_bindings TABLE(ordinal int IDENTITY PRIMARY KEY,id nvarchar(200) COLLATE Latin1_General_100_BIN2,content nvarchar(max),digest varchar(71),line_no int);
  DECLARE @cur_scenario int=NULL,@cur_binding int=NULL;
  -- Provider operations ("operation <id> uses provider <capability-id>"), their static request members (config:) and their
  -- dynamic ones ("input <member> from <scenario-or-operation> <json-path>"), each scenario's outcome ("outcome from
  -- <operation> <json-path>"), and the feature the source pins ("feature <capability-id> sha256:<hex>").
  DECLARE @provider_ops TABLE(op_ordinal int PRIMARY KEY,provider_id nvarchar(400) COLLATE Latin1_General_100_BIN2,config_json nvarchar(max),config_line int,
    prefix_ordinal int,compose_binding int,provider_scenario nvarchar(400),line_no int);
  DECLARE @provider_inputs TABLE(ordinal int IDENTITY PRIMARY KEY,op_ordinal int,member nvarchar(200) COLLATE Latin1_General_100_BIN2,
    source_ref nvarchar(400) COLLATE Latin1_General_100_BIN2,json_path nvarchar(400),carrier_path nvarchar(400),line_no int);
  DECLARE @scenario_outcomes TABLE(scenario_ordinal int PRIMARY KEY,source_ref nvarchar(400) COLLATE Latin1_General_100_BIN2,json_path nvarchar(400),
    carrier_path nvarchar(400),first_ordinal int,op_ordinal int,stmt_binding int,line_no int);
  DECLARE @cur_provider_op int=NULL,@feature_cap nvarchar(400)=NULL,@feature_hex varchar(64)=NULL,@feature_line int=NULL,@feature_text nvarchar(max)=NULL;
  DECLARE @check_procedure nvarchar(400)=N'#dsl06_check';
  DECLARE @i int=0,@n int=(SELECT MAX(line_no) FROM @lines),@sp int,@tok nvarchar(200),@tail nvarchar(max);
  WHILE @i<@n
  BEGIN
    SET @i+=1;
    SET @line=(SELECT line FROM @lines WHERE line_no=@i);
    IF @line=N'' OR LEFT(@line,1)=N'#' CONTINUE;
    IF LEFT(@line,11)=N'capability '
    BEGIN
      SET @tail=LTRIM(SUBSTRING(@line,12,LEN(@line)));
      IF @tail=N'' OR CHARINDEX(N' ',@tail)>0
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'capability: missing trailing value or unexpected tokens');
      ELSE IF @capability_id IS NOT NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'capability: repeated capability id');
      ELSE IF @tail NOT LIKE N'[a-z0-9]%' OR @tail LIKE N'%[^a-z0-9.-]%'
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'capability: id violates the id rule');
      ELSE SET @capability_id=@tail;
    END
    ELSE IF LEFT(@line,7)=N'intent:'
    BEGIN
      SET @tail=LTRIM(SUBSTRING(@line,8,LEN(@line)));
      IF @tail=N'' INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'intent: missing trailing value');
      ELSE SET @intent=@tail;
    END
    ELSE IF LEFT(@line,8)=N'outcome:'
    BEGIN
      SET @tail=LTRIM(SUBSTRING(@line,9,LEN(@line)));
      IF @tail=N'' INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'outcome: missing trailing value');
      ELSE SET @outcome=@tail;
    END
    ELSE IF LEFT(@line,15)=N'input contract ' OR LEFT(@line,16)=N'output contract '
    BEGIN
      DECLARE @is_input bit=CASE WHEN LEFT(@line,15)=N'input contract ' THEN 1 ELSE 0 END;
      SET @tail=LTRIM(SUBSTRING(@line,CASE WHEN @is_input=1 THEN 16 ELSE 17 END,LEN(@line)));
      SET @sp=CHARINDEX(N' ',@tail);
      IF @sp=0
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'contract: missing inline-json value');
      ELSE
      BEGIN
        SET @tok=LEFT(@tail,@sp-1);
        SET @rest=LTRIM(SUBSTRING(@tail,@sp+1,LEN(@tail)));
        IF @tok NOT LIKE N'[a-z0-9]%' OR @tok LIKE N'%[^a-z0-9.-]%'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'contract: id violates the id rule');
        ELSE IF (@is_input=1 AND @input_id IS NOT NULL) OR (@is_input=0 AND @output_id IS NOT NULL)
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'contract: repeated contract id');
        ELSE IF ISJSON(@rest)<>1 OR LEFT(@rest,1)<>N'{'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_CONTRACT_INVALID',N'contract: inline-json is not a JSON object');
        ELSE IF @is_input=1 BEGIN SET @input_id=@tok; SET @input_schema=@rest; END
        ELSE BEGIN SET @output_id=@tok; SET @output_schema=@rest; END
      END
    END
    ELSE IF LEFT(@line,12)=N'cli display '
    BEGIN
      SET @tail=LTRIM(SUBSTRING(@line,13,LEN(@line)));
      SET @sp=CHARINDEX(N' ',@tail);
      IF @sp=0 OR LTRIM(SUBSTRING(@tail,@sp+1,LEN(@tail))) NOT LIKE N'as %'
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'cli display: expected "<select> as <format>"');
      ELSE
      BEGIN
        SET @tok=LEFT(@tail,@sp-1);
        SET @rest=LTRIM(SUBSTRING(SUBSTRING(@tail,@sp+1,LEN(@tail)),3,LEN(@tail)));
        IF @display_select IS NOT NULL
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'cli display: repeated declaration');
        ELSE IF @rest<>N'json'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'cli display: unknown format');
        ELSE BEGIN SET @display_select=@tok; SET @display_format=@rest; END
      END
    END
    ELSE IF LEFT(@line,9)=N'scenario '
    BEGIN
      SET @tail=LTRIM(SUBSTRING(@line,10,LEN(@line)));
      IF @tail=N'' INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'scenario: missing id');
      ELSE
      BEGIN
        SET @sp=CHARINDEX(N' ',@tail);
        SET @tok=CASE WHEN @sp=0 THEN @tail ELSE LEFT(@tail,@sp-1) END;
        SET @rest=CASE WHEN @sp=0 THEN N'' ELSE LTRIM(SUBSTRING(@tail,@sp+1,LEN(@tail))) END;
        IF @tok NOT LIKE N'[a-z0-9]%' OR @tok LIKE N'%[^a-z0-9.-]%'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'scenario: id violates the id rule');
        ELSE IF EXISTS(SELECT 1 FROM @scenarios s WHERE s.scenario_id=@tok COLLATE Latin1_General_100_BIN2)
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'scenario: repeated scenario id');
        ELSE
        BEGIN
          DECLARE @sid nvarchar(200)=@tok;
          DECLARE @has_root bit=0,@has_terminal bit=0,@bad_flag nvarchar(100)=NULL,@sc_in nvarchar(200)=NULL,@sc_out nvarchar(200)=NULL;
          WHILE @rest<>N''
          BEGIN
            SET @sp=CHARINDEX(N' ',@rest);
            SET @tok=CASE WHEN @sp=0 THEN @rest ELSE LEFT(@rest,@sp-1) END;
            SET @rest=CASE WHEN @sp=0 THEN N'' ELSE LTRIM(SUBSTRING(@rest,@sp+1,LEN(@rest))) END;
            IF @tok=N'root' AND @has_root=0 SET @has_root=1
            ELSE IF @tok=N'terminal' AND @has_terminal=0 SET @has_terminal=1
            ELSE IF LEFT(@tok,6)=N'input=' AND @sc_in IS NULL AND LEN(@tok)>6 SET @sc_in=SUBSTRING(@tok,7,200)
            ELSE IF LEFT(@tok,7)=N'output=' AND @sc_out IS NULL AND LEN(@tok)>7 SET @sc_out=SUBSTRING(@tok,8,200)
            ELSE IF @bad_flag IS NULL SET @bad_flag=@tok;
          END
          IF @bad_flag IS NOT NULL
            INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'scenario: unknown flag '+@bad_flag);
          ELSE
          BEGIN
            INSERT @scenarios(scenario_id,root,terminal,line_no,input_contract,output_contract) VALUES(@sid,@has_root,@has_terminal,@i,@sc_in,@sc_out);
            SET @cur_scenario=SCOPE_IDENTITY();
            SET @last_operation=NULL;
            SET @cur_provider_op=NULL;
          END
        END
      END
    END
    ELSE IF LEFT(@line,6)=N'given:' OR LEFT(@line,5)=N'when:' OR LEFT(@line,5)=N'then:'
    BEGIN
      DECLARE @which nvarchar(10)=CASE WHEN LEFT(@line,6)=N'given:' THEN N'given' WHEN LEFT(@line,5)=N'when:' THEN N'when' ELSE N'then' END;
      SET @tail=LTRIM(SUBSTRING(@line,CASE WHEN @which=N'given' THEN 7 ELSE 6 END,LEN(@line)));
      IF @tail=N''
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',@which+N': missing trailing value');
      ELSE IF @cur_scenario IS NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',@which+N': no scenario to attach to');
      ELSE
      BEGIN
        IF @which=N'given' UPDATE @scenarios SET given_txt=@tail,given_line=@i WHERE ordinal=@cur_scenario;
        IF @which=N'when' UPDATE @scenarios SET when_txt=@tail,when_line=@i WHERE ordinal=@cur_scenario;
        IF @which=N'then' UPDATE @scenarios SET then_txt=@tail,then_line=@i WHERE ordinal=@cur_scenario;
      END
    END
    ELSE IF LEFT(@line,10)=N'operation '
    BEGIN
      SET @cur_provider_op=NULL;
      SET @tail=LTRIM(SUBSTRING(@line,11,LEN(@line)));
      SET @sp=CHARINDEX(N' ',@tail);
      IF @sp=0 INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'operation: expected "<id> kind <kind> port <port-id>"');
      ELSE
      BEGIN
        SET @tok=LEFT(@tail,@sp-1);
        SET @rest=LTRIM(SUBSTRING(@tail,@sp+1,LEN(@tail)));
        IF @cur_scenario IS NULL
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',N'operation: no scenario to attach to');
        ELSE IF @tok NOT LIKE N'[a-z0-9]%' OR @tok LIKE N'%[^a-z0-9.-]%'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'operation: id violates the id rule');
        ELSE IF EXISTS(SELECT 1 FROM @operations o WHERE o.operation_id=@tok COLLATE Latin1_General_100_BIN2)
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'operation: repeated operation id');
        ELSE IF LEFT(@rest,14)=N'uses provider '
        BEGIN
          -- operation <id> uses provider <capability-id>: the operation hands its job to that provider capability, named by
          -- identity. It compiles to the estate's dispatch that binds no technical debt: vault, credential and open, a
          -- statement that composes the provider's request from the config: and input lines, and the generic capability
          -- invocation of the provider, whose result lands at result. The operation keeps its id and states the provider.
          DECLARE @pop_id nvarchar(200)=@tok,@pop_provider nvarchar(400)=LTRIM(SUBSTRING(@rest,15,LEN(@rest)));
          DECLARE @pop_base nvarchar(200)=REPLACE(@pop_id,N'.',N'-');
          IF @pop_provider=N'' OR CHARINDEX(N' ',@pop_provider)>0
            INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'operation: expected "<id> uses provider <capability-id>"');
          ELSE IF EXISTS(SELECT 1 FROM @operations o WHERE o.operation_id IN (@pop_id+N'-vault',@pop_id+N'-credential',@pop_id+N'-open',@pop_id+N'-compose'))
            OR EXISTS(SELECT 1 FROM @bindings b WHERE b.scenario_ordinal=@cur_scenario
              AND b.port_id IN (@pop_base,@pop_base+N'-vault',@pop_base+N'-credential',@pop_base+N'-open',@pop_base+N'-compose'))
            INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'operation: an operation or port it compiles to is already declared');
          ELSE
          BEGIN
            IF @cur_binding IS NOT NULL
            BEGIN
              IF EXISTS(SELECT 1 FROM @bindings b WHERE b.ordinal=@cur_binding AND b.form=N'statement'
                AND (b.platform_id IS NULL OR b.provider_id IS NULL OR b.statement IS NULL OR b.result_column IS NULL))
                INSERT @errors(line_no,code,message) VALUES((SELECT b.bind_line FROM @bindings b WHERE b.ordinal=@cur_binding),N'DSL_REQUIRED_MISSING',N'bind: missing one of its four keys');
              IF EXISTS(SELECT 1 FROM @bindings b WHERE b.ordinal=@cur_binding AND b.form=N'platform'
                AND (b.platform_id IS NULL OR (b.provider_id IS NULL AND b.config_json IS NULL)))
                INSERT @errors(line_no,code,message) VALUES((SELECT b.bind_line FROM @bindings b WHERE b.ordinal=@cur_binding),N'DSL_REQUIRED_MISSING',N'platform bind: missing platform, config or provider');
              SET @cur_binding=NULL;
            END
            INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@pop_id+N'-vault',N'invoke-port',@pop_base+N'-vault',@i);
            DECLARE @pop_first int=SCOPE_IDENTITY();
            INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@pop_id+N'-credential',N'invoke-port',@pop_base+N'-credential',@i);
            INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@pop_id+N'-open',N'invoke-port',@pop_base+N'-open',@i);
            INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@pop_id+N'-compose',N'invoke-port',@pop_base+N'-compose',@i);
            INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@pop_id,N'invoke-port',@pop_base,@i);
            SET @last_operation=SCOPE_IDENTITY();
            INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
              VALUES(@cur_scenario,@pop_base+N'-vault',N'platform',N'sfx-vault-host-read-port.v1',N'{"providerId":"sfx-vault-file-host","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-vault-file"}}',@i,@i);
            INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
              VALUES(@cur_scenario,@pop_base+N'-credential',N'platform',N'sfx-estate-credential-port.v1',N'{"providerId":"sfx-estate-database-credential","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-estate-database"}}',@i,@i);
            INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
              VALUES(@cur_scenario,@pop_base+N'-open',N'platform',N'sfx-vault-reference-open-port.v1',N'{"providerId":"sfx-vault-secret-service-reference","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-vault-secret-service"}}',@i,@i);
            INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
              VALUES(@cur_scenario,@pop_base+N'-compose',N'platform',N'sfx-estate-run-statement-port.v1',NULL,@i,@i);
            DECLARE @pop_compose int=SCOPE_IDENTITY();
            INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
              VALUES(@cur_scenario,@pop_base,N'platform',N'generic-capability-invocation.v1',N'{"providerId":"ScenarioKernel.NodePlatform","authoritySource":"DATABASE","capabilityIdPath":"executionTarget","namespacePath":"executionNamespace","scenarioPath":"executionScenario","requestPath":"dispatchRequest","resultPath":"result","lineageMode":"retain-nested-execution"}',@i,@i);
            INSERT @provider_ops(op_ordinal,provider_id,prefix_ordinal,compose_binding,line_no) VALUES(@last_operation,@pop_provider,@pop_first,@pop_compose,@i);
            SET @cur_provider_op=@last_operation;
          END
        END
        ELSE IF @rest NOT LIKE N'kind % port %' AND @rest NOT LIKE N'kind invoke-scenario scenario %'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'operation: expected "kind invoke-port port <port-id>", "kind invoke-scenario scenario <scenario-id>", "kind for-each port <port-id> over <collection-path>" or "uses provider <capability-id>"');
        ELSE
        BEGIN
          DECLARE @op_id nvarchar(200)=@tok;
          SET @rest=LTRIM(SUBSTRING(@rest,6,LEN(@rest)));
          SET @sp=CHARINDEX(N' ',@rest);
          DECLARE @kind_value nvarchar(100)=CASE WHEN @sp=0 THEN @rest ELSE LEFT(@rest,@sp-1) END;
          SET @rest=CASE WHEN @sp=0 THEN N'' ELSE LTRIM(SUBSTRING(@rest,@sp+1,LEN(@rest))) END;
          IF @kind_value=N'invoke-scenario'
          BEGIN
            SET @tok=CASE WHEN LEFT(@rest,9)=N'scenario ' THEN LTRIM(SUBSTRING(@rest,10,LEN(@rest))) ELSE N'' END;
            IF @tok=N'' OR CHARINDEX(N' ',@tok)>0 OR @tok NOT LIKE N'[a-z0-9]%' OR @tok LIKE N'%[^a-z0-9.-]%'
              INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'operation: expected "kind invoke-scenario scenario <scenario-id>"');
            ELSE
            BEGIN
              INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no,target_scenario) VALUES(@cur_scenario,@op_id,N'invoke-scenario',NULL,@i,@tok);
              SET @last_operation=SCOPE_IDENTITY();
            END
          END
          ELSE IF @kind_value=N'for-each'
          BEGIN
            -- kind for-each port <port-id> over <collection-path> [max <n>]: a graph-level fold whose body is
            -- the bound port, invoked once per element of the collection at the path, in order.
            DECLARE @fe_items nvarchar(max)=N'["'+REPLACE(STRING_ESCAPE(@rest,'json'),N' ',N'","')+N'"]',
              @fe_port nvarchar(200)=NULL,@fe_path nvarchar(400)=NULL,@fe_max nvarchar(20)=NULL;
            IF (SELECT COUNT(*) FROM OPENJSON(@fe_items)) NOT IN (4,6)
              OR (SELECT value FROM OPENJSON(@fe_items) WHERE [key]=N'0')<>N'port'
              OR (SELECT value FROM OPENJSON(@fe_items) WHERE [key]=N'2')<>N'over'
              OR ((SELECT COUNT(*) FROM OPENJSON(@fe_items))=6 AND (SELECT value FROM OPENJSON(@fe_items) WHERE [key]=N'4')<>N'max')
              OR EXISTS(SELECT 1 FROM OPENJSON(@fe_items) WHERE value=N'')
              INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'operation: expected "kind for-each port <port-id> over <collection-path> [max <n>]"');
            ELSE
            BEGIN
              SELECT @fe_port=(SELECT value FROM OPENJSON(@fe_items) WHERE [key]=N'1'),
                @fe_path=(SELECT value FROM OPENJSON(@fe_items) WHERE [key]=N'3'),
                @fe_max=(SELECT value FROM OPENJSON(@fe_items) WHERE [key]=N'5');
              IF @fe_port NOT LIKE N'[a-z0-9]%' OR @fe_port LIKE N'%[^a-z0-9.-]%'
                INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'operation: port id violates the id rule');
              ELSE IF @fe_max IS NOT NULL AND (TRY_CONVERT(int,@fe_max) IS NULL OR TRY_CONVERT(int,@fe_max)<1)
                INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'operation: for-each max must be a positive integer');
              ELSE
              BEGIN
                -- The kernel requires a finite maximumIterations; without max it is the largest it admits.
                INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no,collection_path,max_iterations)
                VALUES(@cur_scenario,@op_id,N'for-each',@fe_port,@i,@fe_path,ISNULL(TRY_CONVERT(int,@fe_max),2147483647));
                SET @last_operation=SCOPE_IDENTITY();
              END
            END
          END
          ELSE IF @kind_value<>N'invoke-port'
            INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'operation: unknown kind');
          ELSE IF LEFT(@rest,5)<>N'port '
            INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'operation: missing port');
          ELSE
          BEGIN
            SET @tok=LTRIM(SUBSTRING(@rest,6,LEN(@rest)));
            IF @tok=N'' OR CHARINDEX(N' ',@tok)>0
              INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'operation: missing port id');
            ELSE IF @tok NOT LIKE N'[a-z0-9]%' OR @tok LIKE N'%[^a-z0-9.-]%'
              INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'operation: port id violates the id rule');
            ELSE
            BEGIN
              INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@op_id,N'invoke-port',@tok,@i);
              SET @last_operation=SCOPE_IDENTITY();
            END
          END
        END
      END
    END
    ELSE IF LEFT(@line,14)=N'platform bind ' OR LEFT(@line,5)=N'bind '
    BEGIN
      SET @cur_provider_op=NULL;
      DECLARE @form nvarchar(20)=CASE WHEN LEFT(@line,14)=N'platform bind ' THEN N'platform' ELSE N'statement' END;
      SET @tail=LTRIM(SUBSTRING(@line,CASE WHEN @form=N'platform' THEN 15 ELSE 6 END,LEN(@line)));
      IF @cur_scenario IS NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',N'bind: no scenario to attach to');
      ELSE IF @tail=N'' OR CHARINDEX(N' ',@tail)>0
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'bind: missing or invalid port id');
      ELSE
      BEGIN
        IF @cur_binding IS NOT NULL
        BEGIN
          IF EXISTS(SELECT 1 FROM @bindings b WHERE b.ordinal=@cur_binding AND b.form=N'statement'
            AND (b.platform_id IS NULL OR b.provider_id IS NULL OR b.statement IS NULL OR b.result_column IS NULL))
            INSERT @errors(line_no,code,message) VALUES((SELECT b.bind_line FROM @bindings b WHERE b.ordinal=@cur_binding),N'DSL_REQUIRED_MISSING',N'bind: missing one of its four keys');
          IF EXISTS(SELECT 1 FROM @bindings b WHERE b.ordinal=@cur_binding AND b.form=N'platform'
            AND (b.platform_id IS NULL OR (b.provider_id IS NULL AND b.config_json IS NULL)))
            INSERT @errors(line_no,code,message) VALUES((SELECT b.bind_line FROM @bindings b WHERE b.ordinal=@cur_binding),N'DSL_REQUIRED_MISSING',N'platform bind: missing platform, config or provider');
        END
        IF @tail NOT LIKE N'[a-z0-9]%' OR @tail LIKE N'%[^a-z0-9.-]%'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'bind: port id violates the id rule');
        ELSE IF EXISTS(SELECT 1 FROM @bindings b WHERE b.scenario_ordinal=@cur_scenario AND b.port_id=@tail COLLATE Latin1_General_100_BIN2)
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'bind: repeated port id in the scenario');
        ELSE
        BEGIN
          INSERT @bindings(scenario_ordinal,port_id,form,bind_line) VALUES(@cur_scenario,@tail,@form,@i);
          SET @cur_binding=SCOPE_IDENTITY();
        END
      END
    END
    ELSE IF LEFT(@line,9)=N'platform:' OR LEFT(@line,9)=N'provider:'
    BEGIN
      DECLARE @is_platform bit=CASE WHEN LEFT(@line,9)=N'platform:' THEN 1 ELSE 0 END;
      SET @tail=LTRIM(SUBSTRING(@line,10,LEN(@line)));
      IF @cur_binding IS NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',N'platform/provider: no bind to attach to');
      ELSE IF @tail=N'' OR CHARINDEX(N' ',@tail)>0
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'platform/provider: missing or invalid id');
      ELSE IF @tail NOT LIKE N'[a-z0-9A-Z]%' OR @tail LIKE N'%[^a-zA-Z0-9.-]%'
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'platform/provider: id violates the id rule');
      ELSE
      BEGIN
        IF @is_platform=1 AND (SELECT b.platform_id FROM @bindings b WHERE b.ordinal=@cur_binding) IS NOT NULL
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'platform: repeated key in bind');
        IF @is_platform=0 AND (SELECT b.provider_id FROM @bindings b WHERE b.ordinal=@cur_binding) IS NOT NULL
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'provider: repeated key in bind');
        IF @is_platform=1 UPDATE @bindings SET platform_id=@tail,platform_line=@i WHERE ordinal=@cur_binding;
        IF @is_platform=0 UPDATE @bindings SET provider_id=@tail,provider_line=@i WHERE ordinal=@cur_binding;
      END
    END
    ELSE IF LEFT(@line,7)=N'config:'
    BEGIN
      SET @tail=LTRIM(SUBSTRING(@line,8,LEN(@line)));
      IF @cur_provider_op IS NOT NULL
      BEGIN
        -- After a provider operation, config: holds the static members of the provider's request.
        IF @tail=N'' OR LEFT(@tail,1)<>N'{' OR ISJSON(@tail)<>1
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'config: expected a single-line JSON object');
        ELSE IF (SELECT p.config_json FROM @provider_ops p WHERE p.op_ordinal=@cur_provider_op) IS NOT NULL
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'config: repeated key in operation');
        ELSE
          UPDATE @provider_ops SET config_json=@tail,config_line=@i WHERE op_ordinal=@cur_provider_op;
      END
      ELSE IF @cur_binding IS NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',N'config: no bind to attach to');
      ELSE IF (SELECT b.form FROM @bindings b WHERE b.ordinal=@cur_binding)=N'statement'
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'config: not admitted for a statement bind');
      ELSE IF @tail=N'' OR LEFT(@tail,1)<>N'{' OR ISJSON(@tail)<>1
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'config: expected a single-line JSON object');
      ELSE IF (SELECT b.config_json FROM @bindings b WHERE b.ordinal=@cur_binding) IS NOT NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'config: repeated key in bind');
      ELSE
        UPDATE @bindings SET config_json=@tail,config_line=@i WHERE ordinal=@cur_binding;
    END
    ELSE IF LEFT(@line,10)=N'statement:' OR LEFT(@line,7)=N'result:'
    BEGIN
      DECLARE @is_statement bit=CASE WHEN LEFT(@line,10)=N'statement:' THEN 1 ELSE 0 END;
      SET @tail=LTRIM(SUBSTRING(@line,CASE WHEN @is_statement=1 THEN 11 ELSE 8 END,LEN(@line)));
      IF @cur_binding IS NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',N'statement/result: no bind to attach to');
      ELSE IF @tail=N'' OR (@is_statement=0 AND CHARINDEX(N' ',@tail)>0)
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'statement/result: missing or invalid value');
      ELSE IF (SELECT b.form FROM @bindings b WHERE b.ordinal=@cur_binding)=N'platform'
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'statement/result: not admitted for a platform bind');
      ELSE
      BEGIN
        IF @is_statement=1 AND (SELECT b.statement FROM @bindings b WHERE b.ordinal=@cur_binding) IS NOT NULL
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'statement: repeated key in bind');
        IF @is_statement=0 AND (SELECT b.result_column FROM @bindings b WHERE b.ordinal=@cur_binding) IS NOT NULL
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'result: repeated key in bind');
        IF @is_statement=1 UPDATE @bindings SET statement=@tail,statement_line=@i WHERE ordinal=@cur_binding;
        IF @is_statement=0 UPDATE @bindings SET result_column=@tail,result_line=@i WHERE ordinal=@cur_binding;
      END
    END
    ELSE IF LEFT(@line,10)=N'broadcast '
    BEGIN
      DECLARE @btail nvarchar(max)=LTRIM(SUBSTRING(@line,11,LEN(@line)));
      DECLARE @btok int=CHARINDEX(N' to ',@btail);
      IF @btok=0 OR CHARINDEX(N',',@btail)=0
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'broadcast: expected "<root> to <leg>,<leg>[,<leg>...]"');
      ELSE IF EXISTS(SELECT 1 FROM @topology WHERE form=N'broadcast')
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'broadcast: repeated construct');
      ELSE
      BEGIN
        DECLARE @broot nvarchar(200)=LTRIM(RTRIM(LEFT(@btail,@btok-1)));
        DECLARE @blegs nvarchar(max)=LTRIM(RTRIM(SUBSTRING(@btail,@btok+4,LEN(@btail))));
        IF @broot NOT LIKE N'[a-z0-9]%' OR @broot LIKE N'%[^a-z0-9.-]%'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'broadcast: root id violates the id rule');
        ELSE IF @blegs=N'' OR EXISTS(SELECT 1 FROM STRING_SPLIT(@blegs,N',') l WHERE LTRIM(RTRIM(l.value))=N'' OR LTRIM(RTRIM(l.value)) NOT LIKE N'[a-z0-9]%' OR LTRIM(RTRIM(l.value)) LIKE N'%[^a-z0-9.-]%')
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'broadcast: leg id violates the id rule');
        ELSE IF EXISTS(SELECT 1 FROM STRING_SPLIT(@blegs,N',') l GROUP BY LTRIM(RTRIM(l.value)) COLLATE Latin1_General_100_BIN2 HAVING COUNT(*)>1)
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'broadcast: repeated leg id');
        ELSE
          INSERT @topology(form,root_id,legs,line_no) VALUES(N'broadcast',@broot,@blegs,@i);
      END
    END
    ELSE IF LEFT(@line,5)=N'join '
    BEGIN
      DECLARE @jtail nvarchar(max)=LTRIM(SUBSTRING(@line,6,LEN(@line)));
      DECLARE @jidx int=CHARINDEX(N' from ',@jtail);
      IF @jidx=0 OR CHARINDEX(N',',@jtail)=0
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'join: expected "<join-scenario> from <leg>,<leg>[,<leg>...]"');
      ELSE IF EXISTS(SELECT 1 FROM @topology WHERE form=N'join')
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'join: repeated construct');
      ELSE
      BEGIN
        DECLARE @jroot nvarchar(200)=LTRIM(RTRIM(LEFT(@jtail,@jidx-1)));
        DECLARE @jlegs nvarchar(max)=LTRIM(RTRIM(SUBSTRING(@jtail,@jidx+6,LEN(@jtail))));
        IF @jroot NOT LIKE N'[a-z0-9]%' OR @jroot LIKE N'%[^a-z0-9.-]%'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'join: scenario id violates the id rule');
        ELSE IF @jlegs=N'' OR EXISTS(SELECT 1 FROM STRING_SPLIT(@jlegs,N',') l WHERE LTRIM(RTRIM(l.value))=N'' OR LTRIM(RTRIM(l.value)) NOT LIKE N'[a-z0-9]%' OR LTRIM(RTRIM(l.value)) LIKE N'%[^a-z0-9.-]%')
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'join: leg id violates the id rule');
        ELSE IF EXISTS(SELECT 1 FROM STRING_SPLIT(@jlegs,N',') l GROUP BY LTRIM(RTRIM(l.value)) COLLATE Latin1_General_100_BIN2 HAVING COUNT(*)>1)
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'join: repeated leg id');
        ELSE
          INSERT @topology(form,join_id,legs,line_no) VALUES(N'join',@jroot,@jlegs,@i);
      END
    END
    ELSE IF LEFT(@line,8)=N'inquiry:'
    BEGIN
      SET @tail=LTRIM(SUBSTRING(@line,9,LEN(@line)));
      IF @tail=N'' INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'inquiry: missing trailing value');
      ELSE IF (SELECT COUNT(*) FROM @inquiries)>=3
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'inquiry: a capability holds three example inquiries (relevant_inquery_1..3)');
      ELSE INSERT @inquiries(txt,line_no) VALUES(@tail,@i);
    END
    ELSE IF LEFT(@line,9)=N'contract '
    BEGIN
      SET @tail=LTRIM(SUBSTRING(@line,10,LEN(@line)));
      SET @sp=CHARINDEX(N' ',@tail);
      IF @sp=0
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'contract: missing inline-json value');
      ELSE
      BEGIN
        SET @tok=LEFT(@tail,@sp-1);
        SET @rest=LTRIM(SUBSTRING(@tail,@sp+1,LEN(@tail)));
        IF @tok NOT LIKE N'[a-z0-9]%' OR @tok LIKE N'%[^a-z0-9.-]%'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'contract: id violates the id rule');
        ELSE IF EXISTS(SELECT 1 FROM @extra_contracts e WHERE e.contract_id=@tok COLLATE Latin1_General_100_BIN2)
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'contract: repeated contract id');
        ELSE IF ISJSON(@rest)<>1 OR LEFT(@rest,1)<>N'{'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_CONTRACT_INVALID',N'contract: inline-json is not a JSON object');
        ELSE INSERT @extra_contracts(contract_id,schema_json,line_no) VALUES(@tok,@rest,@i);
      END
    END
    ELSE IF LEFT(@line,17)=N'provider binding '
    BEGIN
      -- provider binding <id> <inline-json>: a document-level provider-input-binding artifact. Its content is the JSON
      -- without the whitespace outside strings, addressed by sha256 over its UTF-8 bytes. A configuration names it as
      -- "@provider-binding:<id>" and receives the digest; the author path mints the content.
      SET @tail=LTRIM(SUBSTRING(@line,18,LEN(@line)));
      SET @sp=CHARINDEX(N' ',@tail);
      IF @sp=0
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'provider binding: expected "provider binding <id> <inline-json>"');
      ELSE
      BEGIN
        SET @tok=LEFT(@tail,@sp-1);
        SET @rest=LTRIM(SUBSTRING(@tail,@sp+1,LEN(@tail)));
        IF @tok NOT LIKE N'[a-z0-9]%' OR @tok LIKE N'%[^a-z0-9.-]%'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'provider binding: id violates the id rule');
        ELSE IF EXISTS(SELECT 1 FROM @provider_bindings pb WHERE pb.id=@tok COLLATE Latin1_General_100_BIN2)
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'provider binding: repeated id');
        ELSE IF ISJSON(@rest)<>1 OR LEFT(@rest,1)<>N'{'
          INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_CONTRACT_INVALID',N'provider binding: inline-json is not a JSON object');
        ELSE
        BEGIN
          DECLARE @pbc nvarchar(max)=N'',@pbpos int=1,@pbin bit=0,@pbch nchar(1);
          WHILE @pbpos<=LEN(@rest)
          BEGIN
            SET @pbch=SUBSTRING(@rest,@pbpos,1);
            IF @pbin=1
            BEGIN
              SET @pbc+=@pbch;
              IF @pbch=N'\' BEGIN SET @pbpos+=1; SET @pbc+=SUBSTRING(@rest,@pbpos,1); END
              ELSE IF @pbch=N'"' SET @pbin=0;
            END
            ELSE IF @pbch=N'"' BEGIN SET @pbin=1; SET @pbc+=@pbch; END
            ELSE IF @pbch NOT IN (N' ',CHAR(9),CHAR(10),CHAR(13)) SET @pbc+=@pbch;
            SET @pbpos+=1;
          END
          INSERT @provider_bindings(id,content,digest,line_no) VALUES(@tok,@pbc,
            N'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),@pbc COLLATE Latin1_General_100_BIN2_UTF8))),2)),@i);
        END
      END
    END
    ELSE IF LEFT(@line,9)=N'variants:' OR LEFT(@line,17)=N'outcome-variants:'
    BEGIN
      DECLARE @is_op_var bit=CASE WHEN LEFT(@line,17)=N'outcome-variants:' THEN 1 ELSE 0 END;
      SET @tail=LTRIM(SUBSTRING(@line,CASE WHEN @is_op_var=1 THEN 18 ELSE 10 END,LEN(@line)));
      SET @items=N'["'+REPLACE(REPLACE(STRING_ESCAPE(@tail,'json'),N' ',N''),N',',N'","')+N'"]';
      IF @tail=N''
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'variants: missing trailing value');
      ELSE IF @is_op_var=0 AND @cur_scenario IS NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',N'variants: no scenario to attach to');
      ELSE IF @is_op_var=1 AND @last_operation IS NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',N'outcome-variants: no operation to attach to');
      ELSE IF EXISTS(SELECT 1 FROM OPENJSON(@items) v
        WHERE v.value NOT LIKE N'[A-Za-z0-9]%:success' AND v.value NOT LIKE N'[A-Za-z0-9]%:failure'
          AND v.value NOT LIKE N'[A-Za-z0-9]%:success:terminal' AND v.value NOT LIKE N'[A-Za-z0-9]%:failure:terminal'
          OR CASE WHEN CHARINDEX(N':',v.value)>1 THEN LEFT(v.value,CHARINDEX(N':',v.value)-1) ELSE N'#' END LIKE N'%[^A-Za-z0-9_-]%')
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'variants: expected <variant>:success|failure[:terminal], comma separated');
      ELSE IF @is_op_var=0 AND EXISTS(SELECT 1 FROM OPENJSON(@items) v WHERE v.value LIKE N'%:terminal')
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'variants: a scenario variant takes no :terminal; it belongs on outcome-variants, and a scenario that ends the capability takes the terminal flag');
      ELSE IF @is_op_var=0
        INSERT @scenario_variants(scenario_ordinal,variant_id,classification,line_no)
        SELECT @cur_scenario,LEFT(v.value,CHARINDEX(N':',v.value)-1),
          CASE WHEN SUBSTRING(v.value,CHARINDEX(N':',v.value)+1,400) LIKE N'success%' THEN N'success' ELSE N'failure' END,@i
        FROM OPENJSON(@items) v ORDER BY CONVERT(int,v.[key]);
      ELSE
        INSERT @op_variants(operation_ordinal,variant_id,classification,is_terminal,line_no)
        SELECT @last_operation,LEFT(v.value,CHARINDEX(N':',v.value)-1),
          CASE WHEN SUBSTRING(v.value,CHARINDEX(N':',v.value)+1,400) LIKE N'success%' THEN N'success' ELSE N'failure' END,
          CASE WHEN v.value LIKE N'%:terminal' THEN 1 ELSE 0 END,@i
        FROM OPENJSON(@items) v ORDER BY CONVERT(int,v.[key]);
    END
    ELSE IF LEFT(@line,6)=N'recur '
    BEGIN
      -- recur <scenario> while <continue-variant> until <stop-variant> [max <n>]: a bounded recurrence. The
      -- scenario loops on itself while its outcome selects the continue variant and stops on the stop variant.
      SET @tail=LTRIM(SUBSTRING(@line,7,LEN(@line)));
      SET @items=N'["'+REPLACE(STRING_ESCAPE(@tail,'json'),N' ',N'","')+N'"]';
      IF (SELECT COUNT(*) FROM OPENJSON(@items)) NOT IN (5,7)
        OR (SELECT value FROM OPENJSON(@items) WHERE [key]=N'1')<>N'while'
        OR (SELECT value FROM OPENJSON(@items) WHERE [key]=N'3')<>N'until'
        OR ((SELECT COUNT(*) FROM OPENJSON(@items))=7 AND (SELECT value FROM OPENJSON(@items) WHERE [key]=N'5')<>N'max')
        OR EXISTS(SELECT 1 FROM OPENJSON(@items) WHERE value=N'')
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'recur: expected "recur <scenario> while <continue-variant> until <stop-variant> [max <n>]"');
      ELSE IF (SELECT COUNT(*) FROM OPENJSON(@items))=7
        AND ISNULL(TRY_CONVERT(int,(SELECT value FROM OPENJSON(@items) WHERE [key]=N'6')),0)<1
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'recur: max must be a positive integer');
      ELSE IF EXISTS(SELECT 1 FROM @recurrences x WHERE x.scenario_id=(SELECT value FROM OPENJSON(@items) WHERE [key]=N'0') COLLATE Latin1_General_100_BIN2)
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'recur: repeated recurrence for one scenario');
      ELSE
        -- The kernel requires a finite maximumIterations; without max it is the largest it admits.
        INSERT @recurrences(scenario_id,continue_variant,stop_variant,max_iterations,line_no)
        SELECT (SELECT value FROM OPENJSON(@items) WHERE [key]=N'0'),(SELECT value FROM OPENJSON(@items) WHERE [key]=N'2'),
          (SELECT value FROM OPENJSON(@items) WHERE [key]=N'4'),
          ISNULL(TRY_CONVERT(int,(SELECT value FROM OPENJSON(@items) WHERE [key]=N'6')),2147483647),@i;
    END
    ELSE IF LEFT(@line,6)=N'route '
    BEGIN
      -- route <from-scenario> <variant> to <to-scenario>: one selection transition.
      SET @tail=LTRIM(SUBSTRING(@line,7,LEN(@line)));
      SET @items=N'["'+REPLACE(STRING_ESCAPE(@tail,'json'),N' ',N'","')+N'"]';
      IF (SELECT COUNT(*) FROM OPENJSON(@items))<>4 OR (SELECT value FROM OPENJSON(@items) WHERE [key]=N'2')<>N'to'
        OR EXISTS(SELECT 1 FROM OPENJSON(@items) WHERE value=N'')
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'route: expected "route <from-scenario> <variant> to <to-scenario>"');
      ELSE
        INSERT @routes(from_scenario,variant,to_scenario,line_no)
        SELECT (SELECT value FROM OPENJSON(@items) WHERE [key]=N'0'),(SELECT value FROM OPENJSON(@items) WHERE [key]=N'1'),
          (SELECT value FROM OPENJSON(@items) WHERE [key]=N'3'),@i;
    END
    ELSE IF LEFT(@line,10)=N'cli input '
    BEGIN
      SET @tail=LTRIM(SUBSTRING(@line,11,LEN(@line)));
      IF @tail=N'json' BEGIN SET @cli_input_type=N'json'; SET @cli_input_path=NULL; END
      ELSE IF LEFT(@tail,5)=N'text ' AND LTRIM(SUBSTRING(@tail,6,LEN(@tail)))<>N'' AND CHARINDEX(N' ',LTRIM(SUBSTRING(@tail,6,LEN(@tail))))=0
      BEGIN SET @cli_input_type=N'text'; SET @cli_input_path=LTRIM(SUBSTRING(@tail,6,LEN(@tail))); END
      ELSE INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'cli input: expected "json" or "text <payload-path>"');
    END
    ELSE IF LEFT(@line,12)=N'cli reading '
    BEGIN
      SET @tail=LTRIM(SUBSTRING(@line,13,LEN(@line)));
      SET @sp=CHARINDEX(N' ',@tail);
      IF @sp=0 OR CHARINDEX(N' ',LTRIM(SUBSTRING(@tail,@sp+1,LEN(@tail))))>0
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'cli reading: expected "<reading> <altitude>[,<altitude>...]"');
      ELSE INSERT @readings(reading,altitudes) VALUES(LEFT(@tail,@sp-1),LTRIM(SUBSTRING(@tail,@sp+1,LEN(@tail))));
    END
    ELSE IF LEFT(@line,6)=N'input ' AND @line LIKE N'input % from %'
    BEGIN
      -- input <member> from <scenario-or-operation> <json-path>: a member of the provider's request, taken from the
      -- scenario's request (for the scenario's first operation) or from the result of the operation just before.
      DECLARE @in_items nvarchar(max)=N'["'+REPLACE(STRING_ESCAPE(LTRIM(SUBSTRING(@line,7,LEN(@line))),'json'),N' ',N'","')+N'"]';
      DECLARE @in_member nvarchar(200)=(SELECT value FROM OPENJSON(@in_items) WHERE [key]=N'0'),
        @in_ref nvarchar(400)=(SELECT value FROM OPENJSON(@in_items) WHERE [key]=N'2'),
        @in_path nvarchar(400)=(SELECT value FROM OPENJSON(@in_items) WHERE [key]=N'3');
      IF (SELECT COUNT(*) FROM OPENJSON(@in_items))<>4 OR (SELECT value FROM OPENJSON(@in_items) WHERE [key]=N'1')<>N'from'
        OR EXISTS(SELECT 1 FROM OPENJSON(@in_items) WHERE value=N'')
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'input: expected "input <member> from <scenario-or-operation> <json-path>"');
      ELSE IF @cur_provider_op IS NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',N'input: no provider operation to attach to');
      ELSE IF @in_member NOT LIKE N'[a-zA-Z_]%' OR @in_member LIKE N'%[^a-zA-Z0-9_]%'
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'input: member violates the member rule');
      ELSE IF NOT (@in_path=N'$' OR (LEFT(@in_path,2)=N'$.' AND SUBSTRING(@in_path,3,400) NOT LIKE N'%[^a-zA-Z0-9_.]%' AND @in_path NOT LIKE N'%..%' AND RIGHT(@in_path,1)<>N'.'))
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'input: json path must be $ or $.<member>[.<member>...]');
      ELSE IF EXISTS(SELECT 1 FROM @provider_inputs p WHERE p.op_ordinal=@cur_provider_op AND p.member=@in_member)
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'input: repeated member');
      ELSE
        INSERT @provider_inputs(op_ordinal,member,source_ref,json_path,line_no) VALUES(@cur_provider_op,@in_member,@in_ref,@in_path,@i);
    END
    ELSE IF LEFT(@line,13)=N'outcome from '
    BEGIN
      -- outcome from <operation> <json-path>: the scenario's outcome is that path of the result of the operation just
      -- before it. It compiles to vault, credential and open and a statement that selects the path.
      DECLARE @oc_items nvarchar(max)=N'["'+REPLACE(STRING_ESCAPE(LTRIM(SUBSTRING(@line,14,LEN(@line))),'json'),N' ',N'","')+N'"]';
      DECLARE @oc_ref nvarchar(400)=(SELECT value FROM OPENJSON(@oc_items) WHERE [key]=N'0'),
        @oc_path nvarchar(400)=(SELECT value FROM OPENJSON(@oc_items) WHERE [key]=N'1');
      DECLARE @oc_scenario nvarchar(200)=(SELECT scenario_id FROM @scenarios WHERE ordinal=@cur_scenario);
      DECLARE @oc_base nvarchar(200)=@oc_scenario+N'-outcome';
      IF (SELECT COUNT(*) FROM OPENJSON(@oc_items))<>2 OR EXISTS(SELECT 1 FROM OPENJSON(@oc_items) WHERE value=N'')
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'outcome from: expected "outcome from <operation> <json-path>"');
      ELSE IF @cur_scenario IS NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_REQUIRED_MISSING',N'outcome from: no scenario to attach to');
      ELSE IF EXISTS(SELECT 1 FROM @scenario_outcomes WHERE scenario_ordinal=@cur_scenario)
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'outcome from: repeated in the scenario');
      ELSE IF NOT (@oc_path=N'$' OR (LEFT(@oc_path,2)=N'$.' AND SUBSTRING(@oc_path,3,400) NOT LIKE N'%[^a-zA-Z0-9_.]%' AND @oc_path NOT LIKE N'%..%' AND RIGHT(@oc_path,1)<>N'.'))
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'outcome from: json path must be $ or $.<member>[.<member>...]');
      ELSE IF EXISTS(SELECT 1 FROM @operations o WHERE o.operation_id IN (@oc_scenario+N'.outcome-vault',@oc_scenario+N'.outcome-credential',@oc_scenario+N'.outcome-open',@oc_scenario+N'.outcome'))
        OR EXISTS(SELECT 1 FROM @bindings b WHERE b.scenario_ordinal=@cur_scenario
          AND b.port_id IN (@oc_base,@oc_base+N'-vault',@oc_base+N'-credential',@oc_base+N'-open'))
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'outcome from: an operation or port it compiles to is already declared');
      ELSE
      BEGIN
            IF @cur_binding IS NOT NULL
            BEGIN
              IF EXISTS(SELECT 1 FROM @bindings b WHERE b.ordinal=@cur_binding AND b.form=N'statement'
                AND (b.platform_id IS NULL OR b.provider_id IS NULL OR b.statement IS NULL OR b.result_column IS NULL))
                INSERT @errors(line_no,code,message) VALUES((SELECT b.bind_line FROM @bindings b WHERE b.ordinal=@cur_binding),N'DSL_REQUIRED_MISSING',N'bind: missing one of its four keys');
              IF EXISTS(SELECT 1 FROM @bindings b WHERE b.ordinal=@cur_binding AND b.form=N'platform'
                AND (b.platform_id IS NULL OR (b.provider_id IS NULL AND b.config_json IS NULL)))
                INSERT @errors(line_no,code,message) VALUES((SELECT b.bind_line FROM @bindings b WHERE b.ordinal=@cur_binding),N'DSL_REQUIRED_MISSING',N'platform bind: missing platform, config or provider');
              SET @cur_binding=NULL;
            END
        SET @cur_provider_op=NULL;
        INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@oc_scenario+N'.outcome-vault',N'invoke-port',@oc_base+N'-vault',@i);
        DECLARE @oc_first int=SCOPE_IDENTITY();
        INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@oc_scenario+N'.outcome-credential',N'invoke-port',@oc_base+N'-credential',@i);
        INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@oc_scenario+N'.outcome-open',N'invoke-port',@oc_base+N'-open',@i);
        INSERT @operations(scenario_ordinal,operation_id,kind,port_id,line_no) VALUES(@cur_scenario,@oc_scenario+N'.outcome',N'invoke-port',@oc_base,@i);
        SET @last_operation=SCOPE_IDENTITY();
        INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
          VALUES(@cur_scenario,@oc_base+N'-vault',N'platform',N'sfx-vault-host-read-port.v1',N'{"providerId":"sfx-vault-file-host","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-vault-file"}}',@i,@i);
        INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
          VALUES(@cur_scenario,@oc_base+N'-credential',N'platform',N'sfx-estate-credential-port.v1',N'{"providerId":"sfx-estate-database-credential","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-estate-database"}}',@i,@i);
        INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
          VALUES(@cur_scenario,@oc_base+N'-open',N'platform',N'sfx-vault-reference-open-port.v1',N'{"providerId":"sfx-vault-secret-service-reference","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-vault-secret-service"}}',@i,@i);
        INSERT @bindings(scenario_ordinal,port_id,form,platform_id,config_json,bind_line,platform_line)
          VALUES(@cur_scenario,@oc_base,N'platform',N'sfx-estate-run-statement-port.v1',NULL,@i,@i);
        INSERT @scenario_outcomes(scenario_ordinal,source_ref,json_path,first_ordinal,op_ordinal,stmt_binding,line_no)
          VALUES(@cur_scenario,@oc_ref,@oc_path,@oc_first,@last_operation,SCOPE_IDENTITY(),@i);
      END
    END
    ELSE IF LEFT(@line,8)=N'feature '
    BEGIN
      -- feature <capability-id> sha256:<hex>: the source implements the feature whose bytes are retained under that
      -- digest. The compiler reads exactly those bytes, never a binding, and refuses a source that drifts from them.
      DECLARE @ft_items nvarchar(max)=N'["'+REPLACE(STRING_ESCAPE(LTRIM(SUBSTRING(@line,9,LEN(@line))),'json'),N' ',N'","')+N'"]';
      DECLARE @ft_cap nvarchar(400)=(SELECT value FROM OPENJSON(@ft_items) WHERE [key]=N'0'),
        @ft_digest nvarchar(400)=(SELECT value FROM OPENJSON(@ft_items) WHERE [key]=N'1');
      IF (SELECT COUNT(*) FROM OPENJSON(@ft_items))<>2 OR LEFT(ISNULL(@ft_digest,N''),7)<>N'sha256:'
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'feature: expected "feature <capability-id> sha256:<hex>"');
      ELSE IF @feature_line IS NOT NULL
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_DUPLICATE_ID',N'feature: repeated feature line');
      ELSE IF LEN(@ft_digest)<>71 OR SUBSTRING(@ft_digest,8,64) COLLATE Latin1_General_100_BIN2 LIKE N'%[^0-9a-f]%'
        INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_VALUE_INVALID',N'feature: the digest is sha256: and 64 lowercase hex digits');
      ELSE
        SELECT @feature_cap=@ft_cap,@feature_hex=SUBSTRING(@ft_digest,8,64),@feature_line=@i;
    END
    ELSE
      INSERT @errors(line_no,code,message) VALUES(@i,N'DSL_SYNTAX',N'line does not match any construct form');
  END
  IF @cur_binding IS NOT NULL
  BEGIN
    IF EXISTS(SELECT 1 FROM @bindings b WHERE b.ordinal=@cur_binding AND b.form=N'statement'
      AND (b.platform_id IS NULL OR b.provider_id IS NULL OR b.statement IS NULL OR b.result_column IS NULL))
      INSERT @errors(line_no,code,message) VALUES((SELECT b.bind_line FROM @bindings b WHERE b.ordinal=@cur_binding),N'DSL_REQUIRED_MISSING',N'bind: missing one of its four keys');
    IF EXISTS(SELECT 1 FROM @bindings b WHERE b.ordinal=@cur_binding AND b.form=N'platform'
      AND (b.platform_id IS NULL OR (b.provider_id IS NULL AND b.config_json IS NULL)))
      INSERT @errors(line_no,code,message) VALUES((SELECT b.bind_line FROM @bindings b WHERE b.ordinal=@cur_binding),N'DSL_REQUIRED_MISSING',N'platform bind: missing platform, config or provider');
  END
  -- A configuration names a provider binding as "@provider-binding:<id>" and receives its digest. A name that no provider
  -- binding line declares refuses.
  DECLARE @pbi int=(SELECT MIN(ordinal) FROM @provider_bindings);
  WHILE @pbi IS NOT NULL
  BEGIN
    UPDATE b SET config_json=REPLACE(b.config_json,N'"@provider-binding:'+pb.id COLLATE DATABASE_DEFAULT+N'"',N'"'+pb.digest COLLATE DATABASE_DEFAULT+N'"')
    FROM @bindings b CROSS JOIN @provider_bindings pb WHERE pb.ordinal=@pbi AND b.config_json IS NOT NULL;
    SET @pbi=(SELECT MIN(ordinal) FROM @provider_bindings WHERE ordinal>@pbi);
  END
  INSERT @errors(line_no,code,message)
  SELECT b.config_line,N'DSL_VALUE_INVALID',N'config: names a provider binding that no provider binding line declares'
  FROM @bindings b WHERE b.config_json LIKE N'%"@provider-binding:%';
  -- The feature the source pins: its retained bytes are what the source is checked against.
  IF @feature_line IS NOT NULL
  BEGIN
    IF @capability_id IS NOT NULL AND @feature_cap<>@capability_id COLLATE Latin1_General_100_BIN2
      INSERT @errors(line_no,code,message) VALUES(@feature_line,N'DSL_VALUE_INVALID',N'feature: names another capability than the capability line');
    SELECT @feature_text=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
    FROM source.content_object co
    WHERE co.content_digest=CONVERT(binary(32),@feature_hex,2) AND HASHBYTES('SHA2_256',co.content_bytes)=co.content_digest;
    IF @feature_text IS NULL
      INSERT @errors(line_no,code,message) VALUES(@feature_line,N'DSL_FEATURE_NOT_RETAINED',N'feature: no bytes are retained under sha256:'+@feature_hex);
  END
  -- A provider operation names a capability of the selected estate exactly, and dispatches to its root scenario.
  UPDATE p SET provider_scenario=(SELECT TOP (1) s.scenario_id FROM model.estate_capability ec
      JOIN model.capability c ON c.capability_pk=ec.capability_pk
      JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
      JOIN model.capability_root_scenario r ON r.capability_version_pk=ec.capability_version_pk
      JOIN model.scenario s ON s.scenario_pk=r.scenario_pk
      WHERE ec.estate_model_pk=@estate AND c.capability_id COLLATE Latin1_General_100_BIN2=p.provider_id)
  FROM @provider_ops p;
  INSERT @errors(line_no,code,message)
  SELECT p.line_no,N'DSL_PROVIDER_UNKNOWN',N'operation: provider capability not declared in the selected estate: '+p.provider_id
  FROM @provider_ops p WHERE p.provider_scenario IS NULL;
  -- Lineage follows the declared operation order: a request member comes from the scenario's request when its operation is
  -- the scenario's first, or from the operation just before it. A provider operation's result lands at result.
  UPDATE i SET carrier_path=CASE
      WHEN prev.ordinal IS NULL AND i.source_ref=sc.scenario_id THEN i.json_path
      WHEN prev.operation_id=i.source_ref AND pp.op_ordinal IS NOT NULL THEN N'$.result'+SUBSTRING(i.json_path,2,400)
      WHEN prev.operation_id=i.source_ref AND so.scenario_ordinal IS NULL THEN i.json_path END
  FROM @provider_inputs i JOIN @provider_ops po ON po.op_ordinal=i.op_ordinal
  JOIN @operations o ON o.ordinal=po.op_ordinal JOIN @scenarios sc ON sc.ordinal=o.scenario_ordinal
  OUTER APPLY (SELECT TOP (1) o2.ordinal,o2.operation_id FROM @operations o2
    WHERE o2.scenario_ordinal=o.scenario_ordinal AND o2.ordinal<po.prefix_ordinal ORDER BY o2.ordinal DESC) prev
  LEFT JOIN @provider_ops pp ON pp.op_ordinal=prev.ordinal
  LEFT JOIN @scenario_outcomes so ON so.op_ordinal=prev.ordinal;
  INSERT @errors(line_no,code,message)
  SELECT i.line_no,N'DSL_VALUE_INVALID',N'input: '+i.source_ref+N' does not lead to this operation; name the scenario for its first operation, or the operation just before it'
  FROM @provider_inputs i WHERE i.carrier_path IS NULL;
  INSERT @errors(line_no,code,message)
  SELECT i.line_no,N'DSL_DUPLICATE_ID',N'input: member '+i.member+N' is also a config member'
  FROM @provider_inputs i JOIN @provider_ops p ON p.op_ordinal=i.op_ordinal
  WHERE p.config_json IS NOT NULL AND EXISTS(SELECT 1 FROM OPENJSON(p.config_json) j WHERE j.[key]=i.member COLLATE Latin1_General_100_BIN2);
  UPDATE so SET carrier_path=CASE
      WHEN prev.operation_id=so.source_ref AND pp.op_ordinal IS NOT NULL THEN N'$.result'+SUBSTRING(so.json_path,2,400)
      WHEN prev.operation_id=so.source_ref THEN so.json_path END
  FROM @scenario_outcomes so
  OUTER APPLY (SELECT TOP (1) o2.ordinal,o2.operation_id FROM @operations o2
    WHERE o2.scenario_ordinal=so.scenario_ordinal AND o2.ordinal<so.first_ordinal ORDER BY o2.ordinal DESC) prev
  LEFT JOIN @provider_ops pp ON pp.op_ordinal=prev.ordinal;
  INSERT @errors(line_no,code,message)
  SELECT so.line_no,N'DSL_VALUE_INVALID',N'outcome from: '+so.source_ref+N' is not the operation just before it'
  FROM @scenario_outcomes so WHERE so.carrier_path IS NULL;
  INSERT @errors(line_no,code,message)
  SELECT so.line_no,N'DSL_VALUE_INVALID',N'outcome from: operations follow it in the scenario'
  FROM @scenario_outcomes so WHERE EXISTS(SELECT 1 FROM @operations o WHERE o.scenario_ordinal=so.scenario_ordinal AND o.ordinal>so.op_ordinal);
  IF @capability_id IS NULL
    INSERT @errors(line_no,code,message) VALUES(0,N'DSL_REQUIRED_MISSING',N'no capability line');
  IF NOT EXISTS(SELECT 1 FROM @scenarios)
    INSERT @errors(line_no,code,message) VALUES(0,N'DSL_REQUIRED_MISSING',N'no scenario declared');
  IF EXISTS(SELECT 1 FROM @topology WHERE form=N'broadcast') AND NOT EXISTS(SELECT 1 FROM @topology WHERE form=N'join')
    INSERT @errors(line_no,code,message) VALUES((SELECT MIN(line_no) FROM @topology WHERE form=N'broadcast'),N'DSL_REQUIRED_MISSING',N'broadcast without join: the fan-out has no convergence scenario');
  -- A join converges the legs of the capability's broadcast; with no broadcast it would declare nothing, so it refuses.
  IF EXISTS(SELECT 1 FROM @topology WHERE form=N'join') AND NOT EXISTS(SELECT 1 FROM @topology WHERE form=N'broadcast')
    INSERT @errors(line_no,code,message) VALUES((SELECT MIN(line_no) FROM @topology WHERE form=N'join'),N'DSL_REQUIRED_MISSING',N'join without broadcast: a join converges the legs of a broadcast, and none is declared');
  IF EXISTS(SELECT 1 FROM @topology WHERE form=N'broadcast')
  BEGIN
    INSERT @errors(line_no,code,message)
    SELECT t.line_no,N'DSL_VALUE_INVALID',N'broadcast: scenario is not declared: '+LTRIM(RTRIM(s.value))
    FROM @topology t CROSS APPLY STRING_SPLIT(t.root_id+N','+t.legs,N',') s
    WHERE t.form=N'broadcast' AND NOT EXISTS(SELECT 1 FROM @scenarios sc WHERE sc.scenario_id=LTRIM(RTRIM(s.value)) COLLATE Latin1_General_100_BIN2);
  END
  IF EXISTS(SELECT 1 FROM @topology WHERE form=N'join')
  BEGIN
    INSERT @errors(line_no,code,message)
    SELECT t.line_no,N'DSL_VALUE_INVALID',N'join: scenario is not declared: '+LTRIM(RTRIM(s.value))
    FROM @topology t CROSS APPLY STRING_SPLIT(t.join_id+N','+t.legs,N',') s
    WHERE t.form=N'join' AND NOT EXISTS(SELECT 1 FROM @scenarios sc WHERE sc.scenario_id=LTRIM(RTRIM(s.value)) COLLATE Latin1_General_100_BIN2);
  END
  IF EXISTS(SELECT 1 FROM @topology WHERE form=N'broadcast') AND EXISTS(SELECT 1 FROM @topology WHERE form=N'join')
  BEGIN
    IF EXISTS(
      SELECT LTRIM(RTRIM(l.value)) COLLATE Latin1_General_100_BIN2 AS leg FROM @topology t CROSS APPLY STRING_SPLIT(t.legs,N',') l WHERE t.form=N'broadcast'
      EXCEPT
      SELECT LTRIM(RTRIM(l.value)) COLLATE Latin1_General_100_BIN2 FROM @topology t CROSS APPLY STRING_SPLIT(t.legs,N',') l WHERE t.form=N'join')
    OR EXISTS(
      SELECT LTRIM(RTRIM(l.value)) COLLATE Latin1_General_100_BIN2 AS leg FROM @topology t CROSS APPLY STRING_SPLIT(t.legs,N',') l WHERE t.form=N'join'
      EXCEPT
      SELECT LTRIM(RTRIM(l.value)) COLLATE Latin1_General_100_BIN2 FROM @topology t CROSS APPLY STRING_SPLIT(t.legs,N',') l WHERE t.form=N'broadcast')
      INSERT @errors(line_no,code,message) VALUES((SELECT MIN(line_no) FROM @topology),N'DSL_VALUE_INVALID',N'broadcast and join disagree on the leg set');
  END
  -- Edge contract preflight: the kernel refuses an edge whose adjacent endpoint
  -- contracts differ when kind <> return and no binding authority is declared
  -- (SemanticExecutionGraphCompiler.cs:929 and its five sibling implementations).
  -- The DSL construct emits no binding authority, so a fan-out document whose
  -- input and output contract ids differ refuses HERE with the kernel's code,
  -- naming every declared edge and both contract ids.
  IF EXISTS(SELECT 1 FROM @topology WHERE form=N'broadcast') AND @input_id IS NOT NULL AND @output_id IS NOT NULL
    AND @output_id COLLATE Latin1_General_100_BIN2 <> @input_id COLLATE Latin1_General_100_BIN2
  BEGIN
    INSERT @errors(line_no,code,message)
    SELECT t.line_no,N'EDGE_CONTRACT_MISMATCH',
      N'Edge edge:'+f.edge+N': outcome contract '+@output_id+N' != input contract '+@input_id+N'. Different endpoint contracts require binding authority; the DSL construct declares none, so both contract lines must share one contract id.'
    FROM @topology t
    CROSS APPLY (SELECT LTRIM(RTRIM(l.value)) AS leg FROM STRING_SPLIT(t.legs,N',') l) x
    CROSS APPLY (VALUES
      (N'enter-'+(CASE WHEN x.leg LIKE @capability_id+N'-%' THEN SUBSTRING(x.leg,LEN(@capability_id)+2,400) ELSE x.leg END)),
      (N'settle-'+(CASE WHEN x.leg LIKE @capability_id+N'-%' THEN SUBSTRING(x.leg,LEN(@capability_id)+2,400) ELSE x.leg END)),
      (N'fail-'+(CASE WHEN x.leg LIKE @capability_id+N'-%' THEN SUBSTRING(x.leg,LEN(@capability_id)+2,400) ELSE x.leg END))) f(edge)
    WHERE t.form=N'broadcast';
  END
  IF @input_id IS NULL OR @output_id IS NULL
    INSERT @errors(line_no,code,message) VALUES(0,N'DSL_REQUIRED_MISSING',N'a scenario without input or output contract declared');
  IF EXISTS(SELECT 1 FROM @operations o WHERE o.kind IN (N'invoke-port',N'for-each') AND NOT EXISTS(
      SELECT 1 FROM @bindings b WHERE b.scenario_ordinal=o.scenario_ordinal AND b.port_id=o.port_id COLLATE Latin1_General_100_BIN2))
    INSERT @errors(line_no,code,message)
    SELECT MIN(o.line_no),N'DSL_REQUIRED_MISSING',N'operation without a matching bind port' FROM @operations o
    WHERE o.kind IN (N'invoke-port',N'for-each') AND NOT EXISTS(SELECT 1 FROM @bindings b WHERE b.scenario_ordinal=o.scenario_ordinal AND b.port_id=o.port_id COLLATE Latin1_General_100_BIN2);
  -- Scenario contracts, routes and route variants resolve inside the document; a
  -- selection edge whose endpoint contracts differ is the kernel's EDGE_CONTRACT_MISMATCH.
  INSERT @errors(line_no,code,message)
  SELECT e.line_no,N'DSL_DUPLICATE_ID',N'contract: repeated contract id' FROM @extra_contracts e
  WHERE e.contract_id=@input_id COLLATE Latin1_General_100_BIN2 OR e.contract_id=@output_id COLLATE Latin1_General_100_BIN2;
  INSERT @errors(line_no,code,message)
  SELECT s.line_no,N'DSL_VALUE_INVALID',N'scenario: contract not declared in the document: '+x.c
  FROM @scenarios s CROSS APPLY (VALUES(s.input_contract),(s.output_contract)) x(c)
  WHERE x.c IS NOT NULL AND x.c<>ISNULL(@input_id,N'') AND x.c<>ISNULL(@output_id,N'')
    AND NOT EXISTS(SELECT 1 FROM @extra_contracts e WHERE e.contract_id=x.c COLLATE Latin1_General_100_BIN2);
  INSERT @errors(line_no,code,message)
  SELECT r.line_no,N'DSL_VALUE_INVALID',N'route: scenario is not declared: '+x.sid
  FROM @routes r CROSS APPLY (VALUES(r.from_scenario),(r.to_scenario)) x(sid)
  WHERE NOT EXISTS(SELECT 1 FROM @scenarios s WHERE s.scenario_id=x.sid COLLATE Latin1_General_100_BIN2);
  INSERT @errors(line_no,code,message)
  SELECT r.line_no,N'UNDECLARED_BRANCH_VARIANT',N'route: variant '+r.variant+N' is not declared on scenario '+r.from_scenario
  FROM @routes r JOIN @scenarios f ON f.scenario_id=r.from_scenario
  WHERE NOT EXISTS(SELECT 1 FROM @scenario_variants v WHERE v.scenario_ordinal=f.ordinal AND v.variant_id=r.variant);
  INSERT @errors(line_no,code,message)
  SELECT r.line_no,N'EDGE_CONTRACT_MISMATCH',N'route '+r.from_scenario+N' '+r.variant+N': outcome contract '+c.fo+N' != input contract '+c.ti
  FROM @routes r JOIN @scenarios f ON f.scenario_id=r.from_scenario JOIN @scenarios t ON t.scenario_id=r.to_scenario
  CROSS APPLY (SELECT COALESCE(f.output_contract,@output_id) fo,COALESCE(t.input_contract,@input_id) ti) c
  WHERE c.fo<>c.ti COLLATE Latin1_General_100_BIN2;
  -- One capability is one entry: its CLI interface addresses its one root scenario, so a second root refuses.
  INSERT @errors(line_no,code,message)
  SELECT s.line_no,N'DSL_DUPLICATE_ID',N'scenario: a second root scenario; each independently invocable entry is its own capability'
  FROM @scenarios s WHERE s.root=1 AND s.ordinal>(SELECT MIN(x.ordinal) FROM @scenarios x WHERE x.root=1);
  -- An invoke-scenario operation names a scenario of this document.
  INSERT @errors(line_no,code,message)
  SELECT o.line_no,N'DSL_VALUE_INVALID',N'operation: scenario is not declared: '+o.target_scenario
  FROM @operations o WHERE o.kind=N'invoke-scenario'
    AND NOT EXISTS(SELECT 1 FROM @scenarios s WHERE s.scenario_id=o.target_scenario COLLATE Latin1_General_100_BIN2);
  -- Routes and invoke-scenario operations may not form a cycle, a route back to its own scenario included: the declared
  -- loop is a recur line, which carries its bound.
  DECLARE @edges TABLE(from_s nvarchar(200) COLLATE Latin1_General_100_BIN2,to_s nvarchar(200) COLLATE Latin1_General_100_BIN2,line_no int);
  INSERT @edges(from_s,to_s,line_no) SELECT r.from_scenario,r.to_scenario,r.line_no FROM @routes r;
  INSERT @edges(from_s,to_s,line_no) SELECT s.scenario_id,o.target_scenario,o.line_no
  FROM @operations o JOIN @scenarios s ON s.ordinal=o.scenario_ordinal WHERE o.kind=N'invoke-scenario';
  DECLARE @reach TABLE(origin nvarchar(200) COLLATE Latin1_General_100_BIN2,node nvarchar(200) COLLATE Latin1_General_100_BIN2,PRIMARY KEY(origin,node));
  DECLARE @reach_added int;
  INSERT @reach(origin,node) SELECT DISTINCT from_s,to_s FROM @edges;
  SET @reach_added=@@ROWCOUNT;
  WHILE @reach_added>0
  BEGIN
    INSERT @reach(origin,node) SELECT DISTINCT x.origin,e.to_s FROM @reach x JOIN @edges e ON e.from_s=x.node
    WHERE NOT EXISTS(SELECT 1 FROM @reach y WHERE y.origin=x.origin AND y.node=e.to_s);
    SET @reach_added=@@ROWCOUNT;
  END
  INSERT @errors(line_no,code,message)
  SELECT MIN(e.line_no),N'DSL_VALUE_INVALID',N'routes or invoke-scenario operations form a cycle through '+e.from_s+N': a loop is declared with recur, which carries its bound'
  FROM @edges e
  WHERE e.to_s=e.from_s OR EXISTS(SELECT 1 FROM @reach x WHERE x.origin=e.to_s AND x.node=e.from_s)
  GROUP BY e.from_s;
  -- A recurrence loops a declared scenario on itself: both variants are declared on it, and its outcome
  -- contract equals its input contract, because the recurrence edge joins the two.
  INSERT @errors(line_no,code,message)
  SELECT r.line_no,N'DSL_VALUE_INVALID',N'recur: scenario is not declared: '+r.scenario_id FROM @recurrences r
  WHERE NOT EXISTS(SELECT 1 FROM @scenarios s WHERE s.scenario_id=r.scenario_id);
  INSERT @errors(line_no,code,message)
  SELECT r.line_no,N'UNDECLARED_BRANCH_VARIANT',N'recur: variant '+v.variant+N' is not declared on scenario '+r.scenario_id
  FROM @recurrences r CROSS APPLY (VALUES(r.continue_variant),(r.stop_variant)) v(variant)
  JOIN @scenarios s ON s.scenario_id=r.scenario_id
  WHERE NOT EXISTS(SELECT 1 FROM @scenario_variants sv WHERE sv.scenario_ordinal=s.ordinal AND sv.variant_id=v.variant COLLATE Latin1_General_100_BIN2);
  INSERT @errors(line_no,code,message)
  SELECT r.line_no,N'EDGE_CONTRACT_MISMATCH',N'recur '+r.scenario_id+N': outcome contract '+c.fo+N' != input contract '+c.ti
  FROM @recurrences r JOIN @scenarios s ON s.scenario_id=r.scenario_id
  CROSS APPLY (SELECT COALESCE(s.output_contract,@output_id) fo,COALESCE(s.input_contract,@input_id) ti) c
  WHERE c.fo<>c.ti COLLATE Latin1_General_100_BIN2;
  DECLARE @known_platform TABLE(id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
  DECLARE @known_provider TABLE(id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
  INSERT @known_platform(id)
  SELECT MIN(x.id) FROM (
    SELECT so.declared_id AS id FROM model.estate_definition ed
    JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ed.semantic_object_definition_pk
    JOIN model.semantic_object so ON so.semantic_object_pk=d.semantic_object_pk
    JOIN model.identity_namespace n ON n.namespace_pk=so.namespace_pk
    WHERE ed.estate_model_pk=@estate AND n.namespace_id=N'sidefx:platform-capabilities' AND so.object_kind=N'CAPABILITY'
    UNION ALL
    SELECT JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),N'$.semantics.platformCapabilityId')
    FROM model.estate_definition ed
    JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ed.semantic_object_definition_pk
    JOIN model.semantic_object so ON so.semantic_object_pk=d.semantic_object_pk
    JOIN model.identity_namespace n ON n.namespace_pk=so.namespace_pk
    JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
    WHERE ed.estate_model_pk=@estate AND n.namespace_id LIKE N'sidefx:capability:%' AND so.object_kind=N'PORT'
  ) x WHERE x.id IS NOT NULL GROUP BY x.id COLLATE Latin1_General_100_BIN2;
  INSERT @known_provider(id)
  SELECT MIN(x.id) FROM (
    SELECT so.declared_id AS id FROM model.estate_definition ed
    JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ed.semantic_object_definition_pk
    JOIN model.semantic_object so ON so.semantic_object_pk=d.semantic_object_pk
    JOIN model.identity_namespace n ON n.namespace_pk=so.namespace_pk
    WHERE ed.estate_model_pk=@estate AND n.namespace_id=N'sidefx:providers' AND so.object_kind=N'PROVIDER'
    UNION ALL
    SELECT JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),N'$.semantics.configuration.providerId')
    FROM model.estate_definition ed
    JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ed.semantic_object_definition_pk
    JOIN model.semantic_object so ON so.semantic_object_pk=d.semantic_object_pk
    JOIN model.identity_namespace n ON n.namespace_pk=so.namespace_pk
    JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
    WHERE ed.estate_model_pk=@estate AND n.namespace_id LIKE N'sidefx:capability:%' AND so.object_kind=N'PORT'
  ) x WHERE x.id IS NOT NULL GROUP BY x.id COLLATE Latin1_General_100_BIN2;
  INSERT @errors(line_no,code,message)
  SELECT b.platform_line,N'DSL_PROVIDER_UNKNOWN',N'platform not declared in the estate: '+b.platform_id
  FROM @bindings b WHERE b.platform_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM @known_platform k WHERE k.id=b.platform_id COLLATE Latin1_General_100_BIN2);
  INSERT @errors(line_no,code,message)
  SELECT b.provider_line,N'DSL_PROVIDER_UNKNOWN',N'provider not declared in the estate: '+b.provider_id
  FROM @bindings b WHERE b.provider_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM @known_provider k WHERE k.id=b.provider_id COLLATE Latin1_General_100_BIN2);
  DECLARE @status nvarchar(20),@document nvarchar(max)=NULL,@document_digest varchar(71)=NULL,@diagnostics nvarchar(max)=NULL;
  IF EXISTS(SELECT 1 FROM @errors)
  BEGIN
    SET @status=N'REFUSED';
    SET @diagnostics=(SELECT e.code,e.line_no AS line,e.message FROM @errors e ORDER BY CASE WHEN e.line_no=0 THEN 1 ELSE 0 END,e.line_no,e.seq FOR JSON PATH);
  END
  ELSE
  BEGIN
    SET @status=N'COMPILED';
    -- Each provider operation's composing statement builds the dispatch the generic invocation reads: the provider, its
    -- root scenario and its request, the config: members as written and each input member from its path.
    UPDATE b SET config_json=JSON_MODIFY(JSON_MODIFY(N'{"providerId":"sfx-estate-database-run-statement","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-estate-database"}}',N'$.statement',
        N'DECLARE @r nvarchar(max)=N'''+REPLACE(ISNULL(p.config_json,N'{}'),N'''',N'''''')+N''';'
        +ISNULL((SELECT STRING_AGG(CONVERT(nvarchar(max),N' SET @r=CASE WHEN JSON_QUERY(@input,N'''+i.carrier_path+N''') IS NOT NULL THEN JSON_MODIFY(@r,N''$."'
          +i.member COLLATE DATABASE_DEFAULT+N'"'',JSON_QUERY(@input,N'''+i.carrier_path+N''')) ELSE JSON_MODIFY(@r,N''$."'+i.member COLLATE DATABASE_DEFAULT
          +N'"'',JSON_VALUE(@input,N'''+i.carrier_path+N''')) END;'),N'') WITHIN GROUP (ORDER BY i.ordinal) FROM @provider_inputs i WHERE i.op_ordinal=p.op_ordinal),N'')
        +N' SELECT (SELECT N'''+p.provider_id COLLATE DATABASE_DEFAULT+N''' AS executionTarget,N''sidefx:capabilities'' AS executionNamespace,N'''
        +p.provider_scenario+N''' AS executionScenario,N''json'' AS inputType,JSON_QUERY(@r) AS dispatchRequest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value;'),
      N'$.resultColumn',N'value')
    FROM @bindings b JOIN @provider_ops p ON p.compose_binding=b.ordinal;
    UPDATE b SET config_json=JSON_MODIFY(JSON_MODIFY(N'{"providerId":"sfx-estate-database-run-statement","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-estate-database"}}',N'$.statement',
        N'SELECT JSON_QUERY(@input,N'''+so.carrier_path+N''') AS value;'),N'$.resultColumn',N'value')
    FROM @bindings b JOIN @scenario_outcomes so ON so.stmt_binding=b.ordinal;
    UPDATE o SET variants_json=(SELECT STRING_AGG(CONVERT(nvarchar(max),N'{"variantId":"'+ov.variant_id COLLATE DATABASE_DEFAULT+N'","classification":"'+ov.classification+N'"'
        +CASE WHEN ov.is_terminal=1 THEN N',"terminal":true' ELSE N'' END+N'}'),N',') WITHIN GROUP (ORDER BY ov.ordinal)
      FROM @op_variants ov WHERE ov.operation_ordinal=o.ordinal)
    FROM @operations o;
    DECLARE @in_schema nvarchar(max)=N'',@out_schema nvarchar(max)=N'';
    DECLARE @cpos int=1,@cin bit=0,@cc nchar(1);
    WHILE @cpos<=LEN(@input_schema)
    BEGIN
      SET @cc=SUBSTRING(@input_schema,@cpos,1);
      IF @cin=1
      BEGIN
        SET @in_schema+=@cc;
        IF @cc=N'\' BEGIN SET @cpos+=1; SET @in_schema+=SUBSTRING(@input_schema,@cpos,1); END
        ELSE IF @cc=N'"' SET @cin=0;
      END
      ELSE IF @cc=N'"' BEGIN SET @cin=1; SET @in_schema+=@cc; END
      ELSE IF @cc NOT IN (N' ',CHAR(9),CHAR(10),CHAR(13)) SET @in_schema+=@cc;
      SET @cpos+=1;
    END
    SET @cpos=1; SET @cin=0;
    WHILE @cpos<=LEN(@output_schema)
    BEGIN
      SET @cc=SUBSTRING(@output_schema,@cpos,1);
      IF @cin=1
      BEGIN
        SET @out_schema+=@cc;
        IF @cc=N'\' BEGIN SET @cpos+=1; SET @out_schema+=SUBSTRING(@output_schema,@cpos,1); END
        ELSE IF @cc=N'"' SET @cin=0;
      END
      ELSE IF @cc=N'"' BEGIN SET @cin=1; SET @out_schema+=@cc; END
      ELSE IF @cc NOT IN (N' ',CHAR(9),CHAR(10),CHAR(13)) SET @out_schema+=@cc;
      SET @cpos+=1;
    END
    SET @document=N'{"document":"sidefx-capability-authority.v1","capabilityId":"'+@capability_id+N'"';
    IF @feature_line IS NOT NULL
      SET @document+=N',"feature":{"capabilityId":"'+@feature_cap+N'","digest":"sha256:'+@feature_hex+N'"}';
    IF @intent IS NOT NULL OR @outcome IS NOT NULL
      SET @document+=N',"meaning":{'+CASE WHEN @intent IS NOT NULL THEN N'"intent":"'+REPLACE(REPLACE(@intent,N'\',N'\\'),N'"',N'\"')+N'"' ELSE N'' END
        +CASE WHEN @intent IS NOT NULL AND @outcome IS NOT NULL THEN N',' ELSE N'' END
        +CASE WHEN @outcome IS NOT NULL THEN N'"outcome":"'+REPLACE(REPLACE(@outcome,N'\',N'\\'),N'"',N'\"')+N'"' ELSE N'' END+N'}';
    SET @document+=N',"cli":{"input":{"type":"'+@cli_input_type+N'","contract":"'+@input_id+N'"'
      +CASE WHEN @cli_input_path IS NOT NULL THEN N',"path":"'+@cli_input_path+N'"' ELSE N'' END+N'}'
      +CASE WHEN @display_select IS NOT NULL THEN N',"display":{"select":"'+@display_select+N'","as":"'+@display_format+N'"}' ELSE N'' END
      +COALESCE(N',"readings":['+(SELECT STRING_AGG(CONVERT(nvarchar(max),N'{"reading":"'+r.reading+N'","altitudes":["'+REPLACE(r.altitudes,N',',N'","')+N'"]}'),N',') WITHIN GROUP (ORDER BY r.ordinal) FROM @readings r)+N']',N'')+N'}';
    SET @document+=N',"contracts":[{"id":"'+@input_id+N'","schema":'+@in_schema+N'}'+CASE WHEN @output_id<>@input_id THEN N',{"id":"'+@output_id+N'","schema":'+@out_schema+N'}' ELSE N'' END
      +COALESCE((SELECT STRING_AGG(CONVERT(nvarchar(max),N',{"id":"'+e.contract_id COLLATE DATABASE_DEFAULT+N'","schema":'+e.schema_json+N'}'),N'') WITHIN GROUP (ORDER BY e.ordinal) FROM @extra_contracts e),N'')+N']';
    SET @document+=N',"scenarios":[';
    DECLARE @si int=0,@sc int=(SELECT COUNT(*) FROM @scenarios);
    WHILE @si<@sc
    BEGIN
      SET @si+=1;
      DECLARE @s nvarchar(max)=N'';
      SET @rest=(SELECT scenario_id FROM @scenarios WHERE ordinal=@si);
      SET @s+=N'{"scenarioId":"'+@rest+N'","name":"'+UPPER(LEFT(REPLACE(@rest,N'-',N' '),1))+SUBSTRING(REPLACE(@rest,N'-',N' '),2,LEN(@rest))+N'"'
        +N',"inputId":"'+@rest+N'-request","inputContract":"'+COALESCE((SELECT input_contract FROM @scenarios WHERE ordinal=@si),@input_id)+N'"'
        -- The root scenario's execution authority is the capability's; every other scenario has its own.
        +N',"eventId":"'+@rest+N'-requested","eventAuthority":"'+CASE WHEN (SELECT root FROM @scenarios WHERE ordinal=@si)=1 THEN @capability_id ELSE @rest END+N'.v1"'
        -- The outcome identity is distinct from its scenario, and so from the capability the root scenario is named after.
        +N',"outcomeId":"'+@rest+N'-outcome","outcomeContract":"'+COALESCE((SELECT output_contract FROM @scenarios WHERE ordinal=@si),@output_id)+N'"'
        +N',"root":'+CASE WHEN (SELECT root FROM @scenarios WHERE ordinal=@si)=1 THEN N'true' ELSE N'false' END
        +N',"terminal":'+CASE WHEN (SELECT terminal FROM @scenarios WHERE ordinal=@si)=1 THEN N'true' ELSE N'false' END;
      IF EXISTS(SELECT 1 FROM @scenario_variants WHERE scenario_ordinal=@si)
        SET @s+=N',"variants":['+(SELECT STRING_AGG(CONVERT(nvarchar(max),N'{"variantId":"'+v.variant_id COLLATE DATABASE_DEFAULT+N'","classification":"'+v.classification+N'"}'),N',') WITHIN GROUP (ORDER BY v.ordinal)
          FROM @scenario_variants v WHERE v.scenario_ordinal=@si)+N']';
      IF (SELECT given_txt FROM @scenarios WHERE ordinal=@si) IS NOT NULL
        SET @s+=N',"given":"'+REPLACE(REPLACE((SELECT given_txt FROM @scenarios WHERE ordinal=@si),N'\',N'\\'),N'"',N'\"')+N'"';
      IF (SELECT when_txt FROM @scenarios WHERE ordinal=@si) IS NOT NULL
        SET @s+=N',"when":"'+REPLACE(REPLACE((SELECT when_txt FROM @scenarios WHERE ordinal=@si),N'\',N'\\'),N'"',N'\"')+N'"';
      IF (SELECT then_txt FROM @scenarios WHERE ordinal=@si) IS NOT NULL
        SET @s+=N',"then":"'+REPLACE(REPLACE((SELECT then_txt FROM @scenarios WHERE ordinal=@si),N'\',N'\\'),N'"',N'\"')+N'"';
      SET @s+=N',"operations":['+COALESCE((SELECT STRING_AGG(CONVERT(nvarchar(max),CASE WHEN o.kind=N'for-each'
            -- A for-each operation hands its body provider the operation itself as configuration, so the
            -- body port's configuration members are carried on the operation beside the fold members.
            THEN JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(
                CASE WHEN o.variants_json IS NULL THEN ISNULL(fb.cfg,N'{}')
                  ELSE JSON_MODIFY(ISNULL(fb.cfg,N'{}'),N'$.outcomeVariants',JSON_QUERY(N'['+o.variants_json+N']')) END,
                N'$.operationId',o.operation_id COLLATE DATABASE_DEFAULT),N'$.kind',N'for-each'),N'$.portId',o.port_id COLLATE DATABASE_DEFAULT),
                N'$.bodyCapabilityId',fb.platform_id),N'$.collectionValuePath',o.collection_path),N'$.maximumIterations',o.max_iterations) COLLATE DATABASE_DEFAULT
            ELSE N'{"operationId":"'+o.operation_id COLLATE DATABASE_DEFAULT
          +CASE WHEN o.kind=N'invoke-scenario' THEN N'","kind":"invoke-scenario","scenarioId":"'+o.target_scenario ELSE N'","kind":"invoke-port","portId":"'+o.port_id COLLATE DATABASE_DEFAULT END
          +N'"'+COALESCE(N',"outcomeVariants":['+o.variants_json+N']',N'')+ISNULL(px.extra,N'')+N'}' END),N',') WITHIN GROUP (ORDER BY o.ordinal)
        FROM @operations o
        OUTER APPLY (SELECT N',"providerCapabilityId":"'+p.provider_id COLLATE DATABASE_DEFAULT+N'"'
            +COALESCE(N',"inputs":['+(SELECT STRING_AGG(CONVERT(nvarchar(max),N'{"member":"'+i.member COLLATE DATABASE_DEFAULT+N'","from":"'
              +i.source_ref COLLATE DATABASE_DEFAULT+N'","path":"'+i.json_path+N'"}'),N',') WITHIN GROUP (ORDER BY i.ordinal)
              FROM @provider_inputs i WHERE i.op_ordinal=p.op_ordinal)+N']',N'') AS extra
          FROM @provider_ops p WHERE p.op_ordinal=o.ordinal) px
        OUTER APPLY (SELECT TOP (1) b.platform_id,CASE WHEN b.form=N'statement'
            THEN (SELECT b.statement AS [statement],b.result_column AS resultColumn,b.provider_id AS providerId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)
            ELSE b.config_json END AS cfg
          FROM @bindings b WHERE b.scenario_ordinal=o.scenario_ordinal AND b.port_id=o.port_id COLLATE Latin1_General_100_BIN2 ORDER BY b.ordinal) fb
        WHERE o.scenario_ordinal=@si),N'')+N']';
      SET @s+=N',"portBindings":['+COALESCE((SELECT STRING_AGG(
          CASE WHEN b.form=N'statement'
            THEN N'{"portId":"'+b.port_id COLLATE DATABASE_DEFAULT+N'","platformCapabilityId":"'+b.platform_id+N'","configuration":{"statement":"'+REPLACE(REPLACE(b.statement,N'\',N'\\'),N'"',N'\"')+N'","resultColumn":"'+b.result_column+N'","providerId":"'+b.provider_id+N'"}}'
            ELSE N'{"portId":"'+b.port_id COLLATE DATABASE_DEFAULT+N'","platformCapabilityId":"'+b.platform_id+N'","configuration":'+CASE WHEN b.config_json IS NOT NULL THEN CASE WHEN b.provider_id IS NOT NULL THEN JSON_MODIFY(b.config_json,N'$.providerId',b.provider_id) ELSE b.config_json END ELSE N'{"providerId":"'+b.provider_id+N'"}' END+N'}' END,N',') WITHIN GROUP (ORDER BY b.ordinal)
        FROM @bindings b WHERE b.scenario_ordinal=@si),N'')+N']}';
      SET @document+=CASE WHEN @si=1 THEN N'' ELSE N',' END+@s;
    END

    SET @document+=N']';
    -- Routing: the broadcast/join fan-out, selection routes and declared recurrences, in that order; the
    -- executionGraph when the capability declares a fan-out or a recurrence.
    -- Every transition carries its semanticProgress, by the law the estate's declared routes follow: a selection that ends
    -- at a terminal scenario is terminating and any other selection narrowing; broadcast expanding; join converging; a
    -- failure collected at its join slot converging; recurrence recurring.
    DECLARE @sel_items nvarchar(max)=(SELECT STRING_AGG(CONVERT(nvarchar(max),
        N'{"transitionId":"route-'+r.from_scenario COLLATE DATABASE_DEFAULT+N'-'+r.variant COLLATE DATABASE_DEFAULT+N'","fromScenario":"'+r.from_scenario COLLATE DATABASE_DEFAULT
        +N'","variant":"'+r.variant COLLATE DATABASE_DEFAULT+N'","toScenario":"'+r.to_scenario COLLATE DATABASE_DEFAULT+N'","topologyKind":"selection","semanticProgress":"'
        +CASE WHEN t.terminal=1 THEN N'terminating' ELSE N'narrowing' END+N'"}'),N',') WITHIN GROUP (ORDER BY r.ordinal)
      FROM @routes r LEFT JOIN @scenarios t ON t.scenario_id=r.to_scenario);
    DECLARE @bc_items nvarchar(max)=NULL,@exec nvarchar(max)=NULL;
    IF EXISTS(SELECT 1 FROM @topology WHERE form=N'broadcast')
    BEGIN
      DECLARE @troot nvarchar(200),@tlegs nvarchar(max),@tjoin nvarchar(200);
      SELECT @troot=root_id,@tlegs=legs FROM @topology WHERE form=N'broadcast';
      SET @tjoin=(SELECT join_id FROM @topology WHERE form=N'join');
      DECLARE @fan nvarchar(500)=@capability_id+N'.fan',@conv nvarchar(500)=@capability_id+N'.converge',@auth nvarchar(500)=@capability_id+N'.dispatch';
      DECLARE @legcnt int=(SELECT COUNT(*) FROM STRING_SPLIT(@tlegs,N','));
      DECLARE @legnames TABLE(ord int IDENTITY PRIMARY KEY,name nvarchar(400),leg nvarchar(400));
      INSERT @legnames(name,leg)
      SELECT CASE WHEN LTRIM(RTRIM(l.value)) LIKE @capability_id+N'-%' THEN SUBSTRING(LTRIM(RTRIM(l.value)),LEN(@capability_id)+2,400) ELSE LTRIM(RTRIM(l.value)) END,
             LTRIM(RTRIM(l.value))
      FROM STRING_SPLIT(@tlegs,N',') l ORDER BY (SELECT NULL);
      SET @bc_items=(SELECT STRING_AGG(CONVERT(nvarchar(max),seg.seg),N',') WITHIN GROUP (ORDER BY seg.ord) FROM (
          SELECT c.ord,
            N'{"transitionId":"enter-'+c.name+N'","fromScenario":"'+@troot+N'","variant":"SUCCESS","toScenario":"'+c.leg+N'","topologyKind":"broadcast","groupId":"'+@fan+N'","semanticProgress":"expanding"},'
           +N'{"transitionId":"settle-'+c.name+N'","fromScenario":"'+c.leg+N'","variant":"SUCCESS","toScenario":"'+@tjoin+N'","topologyKind":"join","groupId":"'+@conv+N'","joinSlotId":"'+c.name+N'","semanticProgress":"converging"},'
           +N'{"transitionId":"fail-'+c.name+N'","fromScenario":"'+c.leg+N'","variant":"SUCCESS","toScenario":"'+@tjoin+N'","topologyKind":"failure","groupId":"'+@conv+N'","joinSlotId":"'+c.name+N'","semanticProgress":"converging"}'
           AS seg
          FROM @legnames c) seg);
      SET @exec=N'{"graphType":"sda-semantic-execution-graph.v2","requiredExecutionFeatures":["declared-concurrent-dispatch.v1"],"readyArbitration":"causal-activation-order.v1","executionBudget":{"maximumInFlightEffects":'+CONVERT(nvarchar(10),@legcnt)+N',"deadlineMs":60000},"dispatchAuthorities":[{"dispatchAuthorityId":"'+@auth+N'","mode":"concurrent","legCount":'+CONVERT(nvarchar(10),@legcnt)+N',"maximumActiveBranches":'+CONVERT(nvarchar(10),@legcnt)+N',"maximumInFlightEffects":'+CONVERT(nvarchar(10),@legcnt)+N',"readyOrder":"declared-edge-order","branchFailure":"collect","ownership":"join-before-return"}],"edgeGroups":['
        +N'{"groupId":"'+@fan+N'","kind":"broadcast","policy":"all","edgeIds":['+COALESCE((SELECT STRING_AGG(CONVERT(nvarchar(max),N'"edge:enter-'+c.name+N'"'),N',') WITHIN GROUP (ORDER BY c.ord) FROM @legnames c),N'')+N'],"dispatchAuthorityId":"'+@auth+N'","completionJoinGroupId":"'+@conv+N'"},'
        +N'{"groupId":"'+@conv+N'","kind":"join","policy":"all-required","edgeIds":['+COALESCE((SELECT STRING_AGG(CONVERT(nvarchar(max),N'"edge:settle-'+c.name+N'"'),N',') WITHIN GROUP (ORDER BY c.ord) FROM @legnames c),N'')+N'],"joinCellId":"cell:scenario:'+@tjoin+N'","requiredSlotIds":['+COALESCE((SELECT STRING_AGG(N'"'+c.name+N'"',N',') WITHIN GROUP (ORDER BY c.ord) FROM @legnames c),N'')+N']}]}';
    END
    DECLARE @rec_items nvarchar(max)=NULL,@rec_groups nvarchar(max)=NULL,@rec_auths nvarchar(max)=NULL;
    IF EXISTS(SELECT 1 FROM @recurrences)
    BEGIN
      -- One recurrence edge per recur line, in its own bounded group, with its authority and the authority's digest.
      SELECT @rec_items=STRING_AGG(CONVERT(nvarchar(max),N'{"transitionId":"recur-'+r.scenario_id COLLATE DATABASE_DEFAULT+N'","fromScenario":"'+r.scenario_id COLLATE DATABASE_DEFAULT
          +N'","variant":"'+r.continue_variant COLLATE DATABASE_DEFAULT+N'","toScenario":"'+r.scenario_id COLLATE DATABASE_DEFAULT
          +N'","topologyKind":"recurrence","groupId":"'+@capability_id+N'.recur-'+r.scenario_id COLLATE DATABASE_DEFAULT
          +N'","recurrenceAuthorityId":"'+@capability_id+N'.recurrence.'+r.scenario_id COLLATE DATABASE_DEFAULT+N'","semanticProgress":"recurring"}'),N',')
          WITHIN GROUP (ORDER BY r.ordinal),
        @rec_groups=STRING_AGG(CONVERT(nvarchar(max),N'{"groupId":"'+@capability_id+N'.recur-'+r.scenario_id COLLATE DATABASE_DEFAULT
          +N'","kind":"recurrence","policy":"bounded","edgeIds":["edge:recur-'+r.scenario_id COLLATE DATABASE_DEFAULT+N'"]}'),N',') WITHIN GROUP (ORDER BY r.ordinal),
        @rec_auths=STRING_AGG(CONVERT(nvarchar(max),JSON_MODIFY(a.body,N'$.authorityDigest',N'sha256:'+LOWER(CONVERT(varchar(64),
          HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),a.body COLLATE Latin1_General_100_BIN2_UTF8))),2)))),N',') WITHIN GROUP (ORDER BY r.ordinal)
      FROM @recurrences r
      CROSS APPLY (SELECT N'{"recurrenceAuthorityId":"'+@capability_id+N'.recurrence.'+r.scenario_id COLLATE DATABASE_DEFAULT
          +N'","continuationVariant":"'+r.continue_variant COLLATE DATABASE_DEFAULT+N'","stopVariant":"'+r.stop_variant COLLATE DATABASE_DEFAULT
          +N'","maximumIterations":'+CONVERT(nvarchar(20),r.max_iterations)+N',"cancellationPolicy":"complete-current"}' AS body) a;
      -- A capability without a fan-out carries a recurrence-only graph: sequential, one effect at a time, and a
      -- deadline the kernel requires to be finite, so it is the largest it admits.
      IF @exec IS NULL
        SET @exec=N'{"graphType":"sda-semantic-execution-graph.v2","requiredExecutionFeatures":["declared-concurrent-dispatch.v1"],"readyArbitration":"causal-activation-order.v1","executionBudget":{"maximumInFlightEffects":1,"deadlineMs":2147483647},"dispatchAuthorities":[],"edgeGroups":[]}';
      DECLARE @rgs TABLE(i int PRIMARY KEY,g nvarchar(max));
      INSERT @rgs(i,g) SELECT CONVERT(int,[key]),value FROM OPENJSON(N'['+@rec_groups+N']');
      DECLARE @rgi int=(SELECT MIN(i) FROM @rgs);
      WHILE @rgi IS NOT NULL
      BEGIN
        SET @exec=JSON_MODIFY(@exec,N'append $.edgeGroups',JSON_QUERY((SELECT g FROM @rgs WHERE i=@rgi)));
        SET @rgi=(SELECT MIN(i) FROM @rgs WHERE i>@rgi);
      END
      SET @exec=JSON_MODIFY(@exec,N'$.recurrenceAuthorities',JSON_QUERY(N'['+@rec_auths+N']'));
    END
    DECLARE @all_items nvarchar(max)=(SELECT STRING_AGG(x.items,N',') WITHIN GROUP (ORDER BY x.o)
      FROM (VALUES(1,@bc_items),(2,@sel_items),(3,@rec_items)) x(o,items) WHERE x.items IS NOT NULL);
    IF @all_items IS NOT NULL SET @document+=N',"routing":['+@all_items+N']';
    IF @exec IS NOT NULL SET @document+=N',"executionGraph":'+@exec;
    IF EXISTS(SELECT 1 FROM @inquiries)
      SET @document+=N',"inquiries":['+(SELECT STRING_AGG(CONVERT(nvarchar(max),N'"'+STRING_ESCAPE(q.txt,'json')+N'"'),N',') WITHIN GROUP (ORDER BY q.ordinal) FROM @inquiries q)+N']';
    SET @document+=N'}';
    SET @document_digest=N'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),@document COLLATE Latin1_General_100_BIN2_UTF8))),2));
    -- A pinned source is checked against its feature's bytes, as the no-drift check checks a declaration. Each finding
    -- refuses as DSL_FEATURE_DRIFT at the source line it concerns, its code first in the message.
    IF @feature_text IS NOT NULL
    BEGIN
      DECLARE @check_request nvarchar(max)=(SELECT @feature_text AS featureText,JSON_QUERY(@document) AS [document] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
      DECLARE @check_result nvarchar(max)=NULL;
      IF OBJECT_ID(CASE WHEN LEFT(@check_procedure,1)=N'#' THEN N'tempdb..'+@check_procedure ELSE @check_procedure END) IS NULL
        INSERT @errors(line_no,code,message) VALUES(@feature_line,N'DSL_FEATURE_DRIFT',N'CHECK_NOT_INSTALLED: '+@check_procedure+N' is not installed, so the source cannot be checked against its feature');
      ELSE
      BEGIN
        EXEC @check_procedure @input=@check_request,@estate_model_pk=@estate,@result=@check_result OUTPUT,@emit=0;
        IF ISNULL(JSON_VALUE(@check_result,N'$.status'),N'')<>N'CONFORMANT'
        BEGIN
          INSERT @errors(line_no,code,message)
          SELECT COALESCE(
              CASE WHEN f.code=N'SCENARIO_STEP_NOT_IN_FEATURE' THEN (SELECT TOP (1) CASE WHEN s.given_txt=f.declaredValue THEN s.given_line
                WHEN s.when_txt=f.declaredValue THEN s.when_line WHEN s.then_txt=f.declaredValue THEN s.then_line END FROM @scenarios s WHERE s.scenario_id=f.scenarioId) END,
              CASE WHEN f.code=N'PROVIDER_BINDING_UNTAGGED' THEN (SELECT TOP (1) o.line_no FROM @operations o WHERE o.operation_id=f.featureValue) END,
              (SELECT TOP (1) s.line_no FROM @scenarios s WHERE s.scenario_id=f.scenarioId),
              @feature_line),
            N'DSL_FEATURE_DRIFT',
            LEFT(f.code+N': '+CASE
              WHEN f.code=N'PROVIDER_BINDING_UNTAGGED' THEN N'operation '+ISNULL(f.featureValue,N'?')+N' uses '+ISNULL(f.declaredValue,N'?')+N', and no case of its scenario tags @provider:'+ISNULL(f.declaredValue,N'?')
              WHEN f.code=N'PROVIDER_TAG_UNBOUND' THEN N'@provider:'+ISNULL(f.featureValue,N'?')+N' is tagged, and no operation of '+ISNULL(f.scenarioId,N'the scenario')+N' uses it'
              WHEN f.code LIKE N'CASE[_]%' THEN CASE WHEN f.caseId IS NULL THEN N'the case' ELSE N'case '+f.caseId END+N' at feature line '+ISNULL(CONVERT(nvarchar(10),f.line),N'?')
              WHEN f.featureValue IS NOT NULL AND f.declaredValue IS NOT NULL THEN N'feature '+f.featureValue+N', source '+f.declaredValue
              ELSE COALESCE(f.declaredValue,f.featureValue,f.caseId,f.scenarioId,N'') END,400)
          FROM OPENJSON(@check_result,N'$.findings') WITH (code nvarchar(60) N'$.code',scenarioId nvarchar(400) N'$.scenarioId',caseId nvarchar(400) N'$.caseId',
            line int N'$.line',featureValue nvarchar(max) N'$.featureValue',declaredValue nvarchar(max) N'$.declaredValue') f;
          IF NOT EXISTS(SELECT 1 FROM OPENJSON(ISNULL(@check_result,N'{}'),N'$.findings'))
            INSERT @errors(line_no,code,message) VALUES(@feature_line,N'DSL_FEATURE_DRIFT',N'STATUS: '+ISNULL(JSON_VALUE(@check_result,N'$.status'),N'(no result)'));
        END
      END
      IF EXISTS(SELECT 1 FROM @errors)
      BEGIN
        SET @status=N'REFUSED';
        SET @document=NULL;
        SET @document_digest=NULL;
        SET @diagnostics=(SELECT e.code,e.line_no AS line,e.message FROM @errors e ORDER BY CASE WHEN e.line_no=0 THEN 1 ELSE 0 END,e.line_no,e.seq FOR JSON PATH);
      END
    END
  END
  -- The result carries the provider binding artifacts the author path mints, as compile-capability-dsl-result.v1 requires.
  DECLARE @pb_json nvarchar(max)=COALESCE((SELECT pb.id AS providerBindingId,pb.digest AS digest,JSON_QUERY(pb.content) AS content
    FROM @provider_bindings pb ORDER BY pb.ordinal FOR JSON PATH),N'[]');
  SELECT (SELECT N'compile-capability-dsl-result.v1' AS contractId,@status AS status,@source_digest AS sourceDigest,
    JSON_QUERY(@document) AS [document],@document_digest AS documentDigest,
    JSON_QUERY(@pb_json) AS providerBindings,
    JSON_QUERY(COALESCE(@diagnostics,N'[]')) AS diagnostics
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) value;
END;
GO
CREATE PROCEDURE #dsl06_apply
  @document nvarchar(max)
AS
BEGIN
  SET NOCOUNT ON;
  IF @@TRANCOUNT=0 OR XACT_STATE()<>1 THROW 51000,N'CAPABILITY_FROM_DSL_TRANSACTION_REQUIRED',1;
  IF @document IS NULL OR ISJSON(@document)<>1 OR LEFT(LTRIM(@document),1)<>N'{'
    THROW 51000,N'CAPABILITY_FROM_DSL_DOCUMENT_INVALID',1;
  IF JSON_VALUE(@document,N'$.contractId')<>N'capability-from-dsl-change.v1'
    THROW 51000,N'CAPABILITY_FROM_DSL_CONTRACT_REQUIRED',1;
  IF EXISTS(SELECT 1 FROM OPENJSON(@document) WHERE [key] NOT IN (N'contractId',N'source',N'isMcpTooling',N'verificationCapabilityId',N'preflight',N'route'))
    THROW 51000,N'CAPABILITY_FROM_DSL_MEMBER_INVALID',1;
  DECLARE @source nvarchar(max)=(SELECT [value] FROM OPENJSON(@document) WHERE [key]=N'source');
  IF @source IS NULL OR LEN(@source)=0 THROW 51000,N'CAPABILITY_FROM_DSL_SOURCE_REQUIRED',1;
  DECLARE @is_mcp bit=CASE WHEN JSON_VALUE(@document,N'$.isMcpTooling')=N'true' THEN 1 ELSE 0 END;
  DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
  IF @estate IS NULL THROW 51000,N'CAPABILITY_FROM_DSL_ESTATE_REQUIRED',1;
  DECLARE @cres TABLE(value nvarchar(max));
  DECLARE @cinput nvarchar(max)=(SELECT @source AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT @cres EXEC #dsl06_compile @input=@cinput,@estate_model_pk=@estate;
  DECLARE @res nvarchar(max)=(SELECT value FROM @cres);
  IF ISJSON(@res)<>1 OR JSON_VALUE(@res,N'$.status')<>N'COMPILED'
  BEGIN
    DECLARE @code nvarchar(40)=COALESCE(JSON_VALUE(@res,N'$.diagnostics[0].code'),N'DSL_REFUSED');
    DECLARE @line int=TRY_CONVERT(int,JSON_VALUE(@res,N'$.diagnostics[0].line'));
    DECLARE @dmsg nvarchar(400)=JSON_VALUE(@res,N'$.diagnostics[0].message');
    SELECT N'capability_from_dsl_refused' AS result_set,N'REFUSED' AS status,@code AS code,@line AS line,
      @dmsg AS message,JSON_VALUE(@res,N'$.sourceDigest') AS source_digest;
    DECLARE @throw_msg nvarchar(2048)=N'CAPABILITY_FROM_DSL_REFUSED: '+@code+N' at line '+COALESCE(CONVERT(nvarchar(10),@line),N'?')+N': '+COALESCE(@dmsg,N'');
    THROW 51000,@throw_msg,1;
  END
  DECLARE @doc nvarchar(max)=JSON_QUERY(@res,N'$.document');
  DECLARE @cap nvarchar(200)=JSON_VALUE(@doc,N'$.capabilityId');
  DECLARE @sdigest nvarchar(71)=JSON_VALUE(@res,N'$.sourceDigest');
  DECLARE @ddigest nvarchar(71)=JSON_VALUE(@res,N'$.documentDigest');
  IF @doc IS NULL OR @cap IS NULL
    THROW 51000,N'CAPABILITY_FROM_DSL_COMPILE_INCOMPLETE',1;
  -- A capability that is not in the estate before this declaration is born by it (scaffold CREATE).
  DECLARE @existed bit=CASE WHEN EXISTS(SELECT 1 FROM model.estate_capability ec JOIN model.capability c ON c.capability_pk=ec.capability_pk
    WHERE ec.estate_model_pk=@estate AND c.capability_id=@cap) THEN 1 ELSE 0 END;
  SELECT N'capability_from_dsl' AS result_set,N'COMPILED' AS status,@cap AS capability_id,
    @sdigest AS source_digest,@ddigest AS document_digest,CONVERT(bit,@is_mcp) AS is_mcp_tooling;
  -- Each provider binding the source declares is minted as raw content-addressed authority before the document that names
  -- its digest is declared. Its content must hash to the digest the compiler reported.
  DECLARE @pbi int=0,@pbn int=(SELECT COUNT(*) FROM OPENJSON(@res,N'$.providerBindings'));
  WHILE @pbi<@pbn
  BEGIN
    DECLARE @pb nvarchar(max)=JSON_QUERY(@res,N'$.providerBindings['+CONVERT(nvarchar(10),@pbi)+N']');
    DECLARE @pbid nvarchar(200)=JSON_VALUE(@pb,N'$.providerBindingId'),@pbdigest nvarchar(71)=JSON_VALUE(@pb,N'$.digest');
    DECLARE @pbbytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),JSON_QUERY(@pb,N'$.content') COLLATE Latin1_General_100_BIN2_UTF8));
    DECLARE @pbhash binary(32)=HASHBYTES('SHA2_256',@pbbytes);
    IF @pbid IS NULL OR @pbbytes IS NULL OR ISNULL(@pbdigest,N'')<>N'sha256:'+LOWER(CONVERT(varchar(64),@pbhash,2))
      THROW 51000,N'CAPABILITY_FROM_DSL_PROVIDER_BINDING_INTEGRITY',1;
    IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@pbhash)
      INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@pbhash,@pbbytes,DATALENGTH(@pbbytes));
    SELECT N'provider_binding_minted' AS result_set,@pbid AS provider_binding_id,@pbdigest AS digest;
    SET @pbi+=1;
  END
  EXEC model.declare_capability_document @document=@doc;
  -- A source that pins its feature is bound to that feature at the end of this change, not to the one bound before.
  DECLARE @feature_digest nvarchar(80)=JSON_VALUE(@doc,N'$.feature.digest');
  IF @feature_digest IS NULL
    EXEC model.repoint_capability_feature @capability_id=@cap;
  IF @is_mcp=1 EXEC model.set_capability_mcp_tooling N'sidefx:capabilities',@cap,1;
  DECLARE @topology_routing nvarchar(max)=JSON_QUERY(@doc,N'$.routing');
  DECLARE @topology_graph nvarchar(max)=JSON_QUERY(@doc,N'$.executionGraph');
  IF @topology_routing IS NOT NULL OR @topology_graph IS NOT NULL
    EXEC model.declare_capability_topology @capability_id=@cap,@routing=@topology_routing,@execution_graph=@topology_graph;
  EXEC model.carry_capability_transformations @capability_id=@cap,@document=@doc;
  -- The document's example inquiries are written in the same change.
  IF JSON_QUERY(@doc,N'$.inquiries') IS NOT NULL
  BEGIN
    DECLARE @inquiry_doc nvarchar(max)=(SELECT N'sidefx:capabilities' AS namespaceId,
      JSON_QUERY((SELECT @cap AS capabilityId,JSON_QUERY(@doc,N'$.inquiries') AS inquiries FOR JSON PATH)) AS entries FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    EXEC model.set_capability_inquiry_examples @document=@inquiry_doc;
  END
  DECLARE @retain_doc nvarchar(max)=(SELECT @cap AS capabilityId,@source AS source,N'capability-from-dsl' AS authoringRef FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  EXEC model.retain_capability_dsl_source @document=@retain_doc;
  -- The declaration is recorded in the engineering change ledger, with its source and document digests.
  INSERT model.engineering_change(change_id,change_kind,mode,disposition,source_digest,note,object_name,object_type,after_digest,capability_id,
    evidence_kind,evidence_ref,changed_at)
  VALUES(NEWID(),N'capability-from-dsl','commit','COMMITTED',TRY_CONVERT(binary(32),SUBSTRING(@sdigest,8,64),2),
    CASE WHEN @existed=1 THEN N'scaffold EXISTING' ELSE N'scaffold CREATE' END,@cap,'CAPABILITY',TRY_CONVERT(binary(32),SUBSTRING(@ddigest,8,64),2),
    @cap,'writer',@sdigest,SYSUTCDATETIME());
  -- Conformance by construction. An unlabelled capability is labelled with its id (the
  -- populate-default-definition-labels rule), and the scaffold's <capability>-transform.v1 is
  -- removed when the reachability law reports it disposed, so no authored capability carries it.
  IF analysis.fv_definition_label(N'sidefx:capabilities',@cap) IS NULL
    EXEC model.fix_capability_label @capability_id=@cap,@version_label=@cap,@validate_full=0;
  DECLARE @scaffold_tid nvarchar(400)=@cap+N'-transform.v1',@scaffold_ns nvarchar(400)=N'sidefx:capability:'+@cap;
  IF EXISTS(SELECT 1 FROM analysis.fv_declared_reachability_conformance(@estate,@cap) r
    WHERE r.dim_key=N'declared_object_disposed' AND r.subject=@scaffold_tid COLLATE Latin1_General_100_BIN2)
    EXEC model.remove_transformation @transformation_id=@scaffold_tid,@acknowledge_retained_references=1,@namespace=@scaffold_ns;
  -- Technical debt by construction: the flag of the declared capability is derived from what it binds.
  EXEC model.derive_capability_technical_debt @capability_id=@cap,@quiet=1;
  -- The feature binding follows the version this change finally selected: the topology and the label above can select a
  -- later capability version than the document's declaration did.
  IF @feature_digest IS NULL
    EXEC model.repoint_capability_feature @capability_id=@cap;
  ELSE
  BEGIN
    -- Feature first: the source pins the feature whose retained bytes it was compiled against. Those exact bytes become the
    -- canonical feature of the selected version, and the change commits only when the no-drift check finds the binding
    -- CONFORMANT; any other answer rolls the whole declaration back.
    DECLARE @feature_text nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
      FROM source.content_object co WHERE co.content_digest=TRY_CONVERT(binary(32),SUBSTRING(@feature_digest,8,64),2));
    IF @feature_text IS NULL THROW 51000,N'CAPABILITY_FROM_DSL_FEATURE_NOT_RETAINED',1;
    EXEC model.declare_capability_feature @capability_id=@cap,@feature_text=@feature_text;
    DECLARE @feature_version bigint=(SELECT TOP (1) fv.feature_version_pk FROM model.feature_version fv
      JOIN model.capability c ON c.capability_pk=fv.capability_pk
      JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
      JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=fv.semantic_object_definition_pk
      JOIN source.content_object env ON env.content_object_pk=d.canonical_content_pk
      WHERE c.capability_id=@cap COLLATE Latin1_General_100_BIN2
        AND JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),env.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),N'$.semantics.content_digest')=SUBSTRING(@feature_digest,8,64)
      ORDER BY fv.feature_version_pk DESC);
    IF @feature_version IS NULL THROW 51000,N'CAPABILITY_FROM_DSL_FEATURE_NOT_DECLARED',1;
    EXEC model.repoint_capability_feature @capability_id=@cap,@feature_version_pk=@feature_version;
    DECLARE @conformance nvarchar(max)=NULL,@conformance_request nvarchar(max)=(SELECT @cap AS capabilityId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    EXEC #dsl06_check @input=@conformance_request,@estate_model_pk=@estate,@result=@conformance OUTPUT,@emit=0;
    SELECT N'capability_feature_conformance' AS result_set,JSON_VALUE(@conformance,N'$.status') AS status,
      JSON_VALUE(@conformance,N'$.summary.signature') AS signature,@feature_digest AS feature_digest,@feature_version AS feature_version_pk;
    IF ISNULL(JSON_VALUE(@conformance,N'$.status'),N'')<>N'CONFORMANT'
    BEGIN
      DECLARE @drift nvarchar(2048)=N'CAPABILITY_FROM_DSL_FEATURE_DRIFT: '+ISNULL(JSON_VALUE(@conformance,N'$.summary.signature'),N'(the check returned nothing)');
      THROW 51000,@drift,1;
    END
  END
  SELECT N'capability_from_dsl_applied' AS result_set,@cap AS capability_id,N'INSTALLED' AS disposition,
    @sdigest AS source_digest,@ddigest AS document_digest,CASE WHEN @existed=1 THEN N'EXISTING' ELSE N'CREATE' END AS scaffold;
END;
GO
DECLARE @in nvarchar(max),@old nvarchar(max),@new nvarchar(max),@e bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @t TABLE(v nvarchar(max));
SET @in=(SELECT N'# dsl-01 probe: every compiled transition carries its semanticProgress.
capability dsl01-probe-topology
intent: Test source of dsl-01; compiled only, never declared.
outcome: dsl01-probe-io.v1
input contract dsl01-probe-io.v1 {"type":"object"}
output contract dsl01-probe-io.v1 {"type":"object"}
scenario intake root
variants: accepted:success,rejected:failure
operation dsl01-probe-topology.intake kind invoke-port port dsl01-pass
outcome-variants: passed:success,stopped:failure:terminal
platform bind dsl01-pass
platform: sda-authority-transformation-port.v1
config: {"expression":{"op":"path","from":"input","path":""}}
scenario review
variants: approved:success,again:success,declined:failure
scenario dispatch
scenario leg-a
scenario leg-b
scenario settled terminal
scenario closed terminal
route intake accepted to review
route intake rejected to closed
route review approved to dispatch
route review declined to closed
recur review while again until approved max 3
broadcast dispatch to leg-a,leg-b
join settled from leg-a,leg-b
' AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC analysis.compile_capability_dsl @input=@in,@estate_model_pk=@e;
SELECT @old=v FROM @t; DELETE @t;
SET @in=(SELECT N'# dsl-01 probe: every compiled transition carries its semanticProgress.
capability dsl01-probe-topology
intent: Test source of dsl-01; compiled only, never declared.
outcome: dsl01-probe-io.v1
input contract dsl01-probe-io.v1 {"type":"object"}
output contract dsl01-probe-io.v1 {"type":"object"}
scenario intake root
variants: accepted:success,rejected:failure
operation dsl01-probe-topology.intake kind invoke-port port dsl01-pass
outcome-variants: passed:success,stopped:failure:terminal
platform bind dsl01-pass
platform: sda-authority-transformation-port.v1
config: {"expression":{"op":"path","from":"input","path":""}}
scenario review
variants: approved:success,again:success,declined:failure
scenario dispatch
scenario leg-a
scenario leg-b
scenario settled terminal
scenario closed terminal
route intake accepted to review
route intake rejected to closed
route review approved to dispatch
route review declined to closed
recur review while again until approved max 3
broadcast dispatch to leg-a,leg-b
join settled from leg-a,leg-b
' AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC #dsl06_compile @input=@in,@estate_model_pk=@e;
SELECT @new=v FROM @t; DELETE @t;
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'regression',N'topology probe: the revision returns exactly the installed compiler''s result',JSON_VALUE(@old,N'$.status')+N' '+ISNULL(JSON_VALUE(@old,N'$.documentDigest'),N''),JSON_VALUE(@new,N'$.status')+N' '+ISNULL(JSON_VALUE(@new,N'$.documentDigest'),N''),CASE WHEN @old=@new COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
GO
DECLARE @in nvarchar(max),@old nvarchar(max),@new nvarchar(max),@e bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @t TABLE(v nvarchar(max));
SET @in=(SELECT N'# dsl-01 probe: lines the compiler accepted before and must now refuse.
capability dsl01-probe-refusals
intent: Test source of dsl-01; compiled only, never declared.
outcome: dsl01-probe-io.v1
input contract dsl01-probe-io.v1 {"type":"object"}
output contract dsl01-probe-io.v1 {"type":"object"}
scenario entry root
variants: again:success,next:success
scenario second-entry root
scenario ping
variants: pong:success
scenario pong
variants: ping:success
scenario caller
operation dsl01-probe-refusals.call kind invoke-scenario scenario no-such-scenario
operation dsl01-probe-refusals.self kind invoke-scenario scenario caller
scenario marked
variants: done:success:terminal
scenario settle terminal
route entry again to entry
route entry next to ping
route ping pong to pong
route pong ping to ping
join settle from ping,pong
' AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC analysis.compile_capability_dsl @input=@in,@estate_model_pk=@e;
SELECT @old=v FROM @t; DELETE @t;
SET @in=(SELECT N'# dsl-01 probe: lines the compiler accepted before and must now refuse.
capability dsl01-probe-refusals
intent: Test source of dsl-01; compiled only, never declared.
outcome: dsl01-probe-io.v1
input contract dsl01-probe-io.v1 {"type":"object"}
output contract dsl01-probe-io.v1 {"type":"object"}
scenario entry root
variants: again:success,next:success
scenario second-entry root
scenario ping
variants: pong:success
scenario pong
variants: ping:success
scenario caller
operation dsl01-probe-refusals.call kind invoke-scenario scenario no-such-scenario
operation dsl01-probe-refusals.self kind invoke-scenario scenario caller
scenario marked
variants: done:success:terminal
scenario settle terminal
route entry again to entry
route entry next to ping
route ping pong to pong
route pong ping to ping
join settle from ping,pong
' AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC #dsl06_compile @input=@in,@estate_model_pk=@e;
SELECT @new=v FROM @t; DELETE @t;
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'regression',N'refusal probe: the revision returns exactly the installed compiler''s result',JSON_VALUE(@old,N'$.status')+N' '+ISNULL(JSON_VALUE(@old,N'$.documentDigest'),N''),JSON_VALUE(@new,N'$.status')+N' '+ISNULL(JSON_VALUE(@new,N'$.documentDigest'),N''),CASE WHEN @old=@new COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
GO
DECLARE @in nvarchar(max),@old nvarchar(max),@new nvarchar(max),@e bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @t TABLE(v nvarchar(max));
SET @in=(SELECT N'# dsl-01 probe: a provider binding line, and a configuration that names it.
capability dsl01-probe-binding
intent: Test source of dsl-01; compiled only, never declared.
outcome: dsl01-probe-io.v1
input contract dsl01-probe-io.v1 {"type":"object"}
output contract dsl01-probe-io.v1 {"type":"object"}
provider binding dsl01-probe-binding.v1 { "bindingType": "sidefx-provider-input-binding.v1", "id": "dsl01-probe-binding.v1", "note": "spaces  inside a string stay" }
scenario dsl01-probe-binding root terminal
operation dsl01-probe-binding.pass kind invoke-port port dsl01-pass
platform bind dsl01-pass
platform: sda-authority-transformation-port.v1
config: {"expression":{"op":"literal","value":"@provider-binding:dsl01-probe-binding.v1"}}
' AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC analysis.compile_capability_dsl @input=@in,@estate_model_pk=@e;
SELECT @old=v FROM @t; DELETE @t;
SET @in=(SELECT N'# dsl-01 probe: a provider binding line, and a configuration that names it.
capability dsl01-probe-binding
intent: Test source of dsl-01; compiled only, never declared.
outcome: dsl01-probe-io.v1
input contract dsl01-probe-io.v1 {"type":"object"}
output contract dsl01-probe-io.v1 {"type":"object"}
provider binding dsl01-probe-binding.v1 { "bindingType": "sidefx-provider-input-binding.v1", "id": "dsl01-probe-binding.v1", "note": "spaces  inside a string stay" }
scenario dsl01-probe-binding root terminal
operation dsl01-probe-binding.pass kind invoke-port port dsl01-pass
platform bind dsl01-pass
platform: sda-authority-transformation-port.v1
config: {"expression":{"op":"literal","value":"@provider-binding:dsl01-probe-binding.v1"}}
' AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC #dsl06_compile @input=@in,@estate_model_pk=@e;
SELECT @new=v FROM @t; DELETE @t;
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'regression',N'binding probe: the revision returns exactly the installed compiler''s result',JSON_VALUE(@old,N'$.status')+N' '+ISNULL(JSON_VALUE(@old,N'$.documentDigest'),N''),JSON_VALUE(@new,N'$.status')+N' '+ISNULL(JSON_VALUE(@new,N'$.documentDigest'),N''),CASE WHEN @old=@new COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
GO
DECLARE @in nvarchar(max),@old nvarchar(max),@new nvarchar(max),@e bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @t TABLE(v nvarchar(max));
SET @in=(SELECT N'capability reveal-estate-workflows
intent: Reveal the admitted workflows of one capability as a read-only lens: its declared entries, the closure of each admitted entry over admitted transitions only, every routing transition with its topology, semanticProgress and status, and the findings that hold a transition or an entry, from one pinned definition
outcome: workflow-lens.v1 RESOLVED, PARTIAL_WITH_HELD_GAPS, NOT_DECLARED, NOT_FOUND or STALE, with entries, workflows, execution edges, findings, a summary signature and a projection digest
inquiry: Reveal the admitted workflows of this capability.
inquiry: Which routes can run from this capability''s entry, and which are held?
inquiry: Why is this route shown or held?
input contract reveal-estate-workflows-request.v1 {"type":"object","additionalProperties":false,"required":["capabilityId"],"properties":{"capabilityId":{"type":"string","minLength":1,"maxLength":400},"entryScenarioId":{"type":"string","minLength":1,"maxLength":400},"expectedDefinitionDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"}}}
output contract workflow-lens.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"workflow-lens.v1"},"status":{"enum":["RESOLVED","PARTIAL_WITH_HELD_GAPS","NOT_DECLARED","NOT_FOUND","STALE"]}}}
cli display outcome as json
scenario reveal-estate-workflows root terminal
given: an inspection request naming a capability of the selected estate, optionally one entry scenario and the definition digest it pins
when: the declared entries are resolved and the closure of each admitted entry is derived over admitted transitions only
then: a workflow lens in which every held transition and entry is named with its findings, or NOT_FOUND, STALE or NOT_DECLARED
operation reveal-estate-workflows.vault kind invoke-port port reveal-estate-workflows-vault
operation reveal-estate-workflows.credential kind invoke-port port reveal-estate-workflows-credential
operation reveal-estate-workflows.open kind invoke-port port reveal-estate-workflows-open
operation reveal-estate-workflows.reveal kind invoke-port port reveal-estate-workflows-port
platform bind reveal-estate-workflows-vault
platform: sfx-vault-host-read-port.v1
config: {"providerId":"sfx-vault-file-host","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-vault-file"}}
platform bind reveal-estate-workflows-credential
platform: sfx-estate-credential-port.v1
config: {"providerId":"sfx-estate-database-credential","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-estate-database"}}
platform bind reveal-estate-workflows-open
platform: sfx-vault-reference-open-port.v1
config: {"providerId":"sfx-vault-secret-service-reference","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-vault-secret-service"}}
platform bind reveal-estate-workflows-port
platform: sfx-estate-run-statement-port.v1
config: {"providerId":"sfx-estate-database-run-statement","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-estate-database"},"statement":"SET ARITHABORT ON;\nDECLARE @estate_model_pk bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);\nEXEC analysis.reveal_estate_workflows @input=@input,@estate_model_pk=@estate_model_pk;","resultColumn":"value","commandTimeout":120}
' AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC analysis.compile_capability_dsl @input=@in,@estate_model_pk=@e;
SELECT @old=v FROM @t; DELETE @t;
SET @in=(SELECT N'capability reveal-estate-workflows
intent: Reveal the admitted workflows of one capability as a read-only lens: its declared entries, the closure of each admitted entry over admitted transitions only, every routing transition with its topology, semanticProgress and status, and the findings that hold a transition or an entry, from one pinned definition
outcome: workflow-lens.v1 RESOLVED, PARTIAL_WITH_HELD_GAPS, NOT_DECLARED, NOT_FOUND or STALE, with entries, workflows, execution edges, findings, a summary signature and a projection digest
inquiry: Reveal the admitted workflows of this capability.
inquiry: Which routes can run from this capability''s entry, and which are held?
inquiry: Why is this route shown or held?
input contract reveal-estate-workflows-request.v1 {"type":"object","additionalProperties":false,"required":["capabilityId"],"properties":{"capabilityId":{"type":"string","minLength":1,"maxLength":400},"entryScenarioId":{"type":"string","minLength":1,"maxLength":400},"expectedDefinitionDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"}}}
output contract workflow-lens.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"workflow-lens.v1"},"status":{"enum":["RESOLVED","PARTIAL_WITH_HELD_GAPS","NOT_DECLARED","NOT_FOUND","STALE"]}}}
cli display outcome as json
scenario reveal-estate-workflows root terminal
given: an inspection request naming a capability of the selected estate, optionally one entry scenario and the definition digest it pins
when: the declared entries are resolved and the closure of each admitted entry is derived over admitted transitions only
then: a workflow lens in which every held transition and entry is named with its findings, or NOT_FOUND, STALE or NOT_DECLARED
operation reveal-estate-workflows.vault kind invoke-port port reveal-estate-workflows-vault
operation reveal-estate-workflows.credential kind invoke-port port reveal-estate-workflows-credential
operation reveal-estate-workflows.open kind invoke-port port reveal-estate-workflows-open
operation reveal-estate-workflows.reveal kind invoke-port port reveal-estate-workflows-port
platform bind reveal-estate-workflows-vault
platform: sfx-vault-host-read-port.v1
config: {"providerId":"sfx-vault-file-host","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-vault-file"}}
platform bind reveal-estate-workflows-credential
platform: sfx-estate-credential-port.v1
config: {"providerId":"sfx-estate-database-credential","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-estate-database"}}
platform bind reveal-estate-workflows-open
platform: sfx-vault-reference-open-port.v1
config: {"providerId":"sfx-vault-secret-service-reference","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-vault-secret-service"}}
platform bind reveal-estate-workflows-port
platform: sfx-estate-run-statement-port.v1
config: {"providerId":"sfx-estate-database-run-statement","dependency":{"objectKind":"DEPENDENCY","namespace":"sidefx:dependencies","id":"sfx-estate-database"},"statement":"SET ARITHABORT ON;\nDECLARE @estate_model_pk bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);\nEXEC analysis.reveal_estate_workflows @input=@input,@estate_model_pk=@estate_model_pk;","resultColumn":"value","commandTimeout":120}
' AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC #dsl06_compile @input=@in,@estate_model_pk=@e;
SELECT @new=v FROM @t; DELETE @t;
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'regression',N'reveal draft DSL: the revision returns exactly the installed compiler''s result',JSON_VALUE(@old,N'$.status')+N' '+ISNULL(JSON_VALUE(@old,N'$.documentDigest'),N''),JSON_VALUE(@new,N'$.status')+N' '+ISNULL(JSON_VALUE(@new,N'$.documentDigest'),N''),CASE WHEN @old=@new COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
GO
-- 2. The new lines. Each result is kept in a variable until the transaction has rolled back, so every check row survives it.
SET NOCOUNT ON;
DECLARE @e bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1),@in nvarchar(max),
 @err nvarchar(2048)=NULL,@stage nvarchar(80)=N'retain the pinned features',@r0 nvarchar(max),@r1 nvarchar(max),@r2 nvarchar(max),@r3 nvarchar(max),@r4 nvarchar(max),@r5 nvarchar(max),@r6 nvarchar(max),@r7 nvarchar(max);
DECLARE @t TABLE(v nvarchar(max));
DECLARE @m TABLE(v nvarchar(max));
BEGIN TRY
 BEGIN TRANSACTION;
 INSERT @m(v) EXEC model.mint_content_artifact @document=N'{"artifactKind":"capability-feature:dsl02-probe-feature-first","text":"# Fixture for compile-capability-dsl cases compile-feature-pin and compile-feature-drift: the canonical feature of probe\n# capability dsl02-probe-feature-first, retained by its digest before its DSL is compiled. Never declared.\n\n@capability:dsl02-probe-feature-first\n@root-scenario:dsl02-probe-feature-first\n@scenario:dsl02-probe-feature-first\n@input:dsl02-probe-feature-first-request\n@input-contract:dsl02-probe-feature-first-request.v1\n@event:dsl02-probe-feature-first-requested\n@event-authority:dsl02-probe-feature-first.v1\n@outcome:dsl02-probe-feature-first-outcome\n@outcome-contract:dsl02-probe-feature-first-result.v1\n@outcome-terminal\nFeature: Read one value through the provider the feature names\n\n  @case:probe-read\n  @provider:sql-database-reader\n  Scenario: The provider reads the value\n    Given a request naming a value\n      \"\"\"json\n      {\"value\":\"x\"}\n      \"\"\"\n    When the provider reads it\n    Then the result carries the value\n      | operation                      | path     | equals |\n      | dsl02-probe-feature-first.read | $.status | READ   |\n"}';
 INSERT @m(v) EXEC model.mint_content_artifact @document=N'{"artifactKind":"capability-feature:reveal-estate-workflows","text":"# reveal-estate-workflows: canonical feature, review copy for the owner and the owner''s team, 2026-11-02, tightened the\n# same day after the owner''s review.\n#\n# What this file is: the canonical reference for capability reveal-estate-workflows (specification\n# ov3.estate-workflow-discovery.v1, section 5, work package W3). It comes first. The DSL, the estate declaration, the\n# runs and the acceptance each trace to it by identity. Nothing is declared yet, and the flight that would declare it\n# is on hold.\n#\n# How to read it:\n#   - The Feature tags state the one circuit scenario and its identities, named as the compiler names them: input,\n#     input contract, event, event authority, outcome, outcome contract and terminal. The DSL must declare exactly\n#     these. The draft DSL does (compile run 91a0e162).\n#   - Each Scenario is one acceptance case, and @case:<id> is its identity. A case id is unique in this file.\n#   - Every case uses the circuit''s own Given, When and Then: the DSL scenario''s given, when and then lines,\n#     word for word.\n#     The json docstring under Given is the case''s request, exactly. The table under Then lists the assertions. Each row\n#     names the operation whose result it reads, a JSON path in that result (workflow-lens.v1) and the value it must\n#     equal. \"[]\" means an empty array.\n#   - @provider:<capability-id> names the provider capability that operation reveal-estate-workflows.reveal uses. The\n#     DSL is re-expressed before the build as \"operation reveal-estate-workflows.reveal uses provider\n#     sql-database-reader\". The draft still binds the four platform ports, which is drift.\n#   - A run proves a case only when its request is this case''s request and its own result meets this case''s rows.\n#     The no-drift check (features/check-capability-feature-conformance.feature) applies both rules.\n#\n# Status tags:\n#   @status:probed  the procedure body ran read-only through sql-database-reader with exactly this request (run id\n#                   in a comment); the capability is not declared yet\n#\n# Not covered by a case: ROUTE_VARIANT_UNDECLARED. The procedure holds a selection whose variant its from scenario\n# does not declare, but no live capability has one, so there is no request to pin.\n\n@capability:reveal-estate-workflows\n@root-scenario:reveal-estate-workflows\n@scenario:reveal-estate-workflows\n@input:reveal-estate-workflows-request\n@input-contract:reveal-estate-workflows-request.v1\n@event:reveal-estate-workflows-requested\n@event-authority:reveal-estate-workflows.v1\n@outcome:reveal-estate-workflows-outcome\n@outcome-contract:workflow-lens.v1\n@outcome-terminal\nFeature: Reveal the admitted workflows of a capability\n  As a SideFX estate reviewer\n  I want each workflow a capability admits, from its declared entry over admitted transitions only\n  So that providers, product dependencies and undeclared arrows cannot pass for workflow routes\n\n  Rule: An entry comes from declared entry authority, never from the shape of the graph\n\n    @case:reveal-resolved\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: A capability whose entry and transitions are all admitted resolves\n      Given an inspection request naming a capability of the selected estate, optionally one entry scenario and the definition digest it pins\n        \"\"\"json\n        {\"capabilityId\":\"dispatch-pair-demo\"}\n        \"\"\"\n      And dispatch-pair-demo declares its root scenario, its CLI input contract and six transitions that each carry semanticProgress\n      When the declared entries are resolved and the closure of each admitted entry is derived over admitted transitions only\n      Then a workflow lens in which every held transition and entry is named with its findings, or NOT_FOUND, STALE or NOT_DECLARED\n        | operation                      | path                | equals                                      |\n        | reveal-estate-workflows.reveal | $.status            | RESOLVED                                    |\n        | reveal-estate-workflows.reveal | $.summary.signature | entries=1/1;edges=6/6;reached=4;terminals=1 |\n      # Run f6b88ab2. This is the first-call proof. Evidence: conformance/controls/reveal-resolved.f6b88ab2.evidence.json.\n\n    @case:reveal-entry-without-cli-input\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: A root scenario without a CLI input contract is not an entry\n      Given an inspection request naming a capability of the selected estate, optionally one entry scenario and the definition digest it pins\n        \"\"\"json\n        {\"capabilityId\":\"project-model-provider-protocol\"}\n        \"\"\"\n      And project-model-provider-protocol declares a root scenario but no CLI input contract\n      When the declared entries are resolved and the closure of each admitted entry is derived over admitted transitions only\n      Then a workflow lens in which every held transition and entry is named with its findings, or NOT_FOUND, STALE or NOT_DECLARED\n        | operation                      | path                     | equals                                        |\n        | reveal-estate-workflows.reveal | $.status                 | NOT_DECLARED                                  |\n        | reveal-estate-workflows.reveal | $.entries[0].status      | held                                          |\n        | reveal-estate-workflows.reveal | $.entries[0].findings[0] | ENTRY_CLI_INPUT_MISSING                       |\n        | reveal-estate-workflows.reveal | $.summary.signature      | entries=0/1;edges=16/16;reached=0;terminals=0 |\n      # Run 04e36e84. Its 16 transitions are still listed, each admitted.\n\n    @case:reveal-leg-is-not-an-entry\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: A scenario that is not a declared entry is refused as an entry\n      Given an inspection request naming a capability of the selected estate, optionally one entry scenario and the definition digest it pins\n        \"\"\"json\n        {\"capabilityId\":\"dispatch-pair-demo\",\"entryScenarioId\":\"dispatch-pair-demo-leg-a\"}\n        \"\"\"\n      And dispatch-pair-demo-leg-a is a leg of dispatch-pair-demo and not its root\n      When the declared entries are resolved and the closure of each admitted entry is derived over admitted transitions only\n      Then a workflow lens in which every held transition and entry is named with its findings, or NOT_FOUND, STALE or NOT_DECLARED\n        | operation                      | path                | equals                                      |\n        | reveal-estate-workflows.reveal | $.status            | NOT_DECLARED                                |\n        | reveal-estate-workflows.reveal | $.entryScenarioId   | dispatch-pair-demo-leg-a                    |\n        | reveal-estate-workflows.reveal | $.workflows         | []                                          |\n        | reveal-estate-workflows.reveal | $.summary.signature | entries=1/1;edges=6/6;reached=0;terminals=0 |\n      # Run 09b0b2f1.\n\n    @case:reveal-no-transitions\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: A capability with no transitions is its own workflow\n      Given an inspection request naming a capability of the selected estate, optionally one entry scenario and the definition digest it pins\n        \"\"\"json\n        {\"capabilityId\":\"compile-capability-dsl\"}\n        \"\"\"\n      And compile-capability-dsl declares one root terminal scenario and no routing\n      When the declared entries are resolved and the closure of each admitted entry is derived over admitted transitions only\n      Then a workflow lens in which every held transition and entry is named with its findings, or NOT_FOUND, STALE or NOT_DECLARED\n        | operation                      | path                | equals                                      |\n        | reveal-estate-workflows.reveal | $.status            | RESOLVED                                    |\n        | reveal-estate-workflows.reveal | $.summary.signature | entries=1/1;edges=0/0;reached=1;terminals=1 |\n      # Run 7554ea8c.\n\n  Rule: A transition is traversed only when it is admitted\n\n    @case:reveal-held-selections\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: Selections without semanticProgress and an unbounded recurrence are held\n      Given an inspection request naming a capability of the selected estate, optionally one entry scenario and the definition digest it pins\n        \"\"\"json\n        {\"capabilityId\":\"request-capability-from-objective-v3\"}\n        \"\"\"\n      And request-capability-from-objective-v3 declares three selections without semanticProgress and a recurrence without max\n      When the declared entries are resolved and the closure of each admitted entry is derived over admitted transitions only\n      Then a workflow lens in which every held transition and entry is named with its findings, or NOT_FOUND, STALE or NOT_DECLARED\n        | operation                      | path                             | equals                                          |\n        | reveal-estate-workflows.reveal | $.status                         | PARTIAL_WITH_HELD_GAPS                          |\n        | reveal-estate-workflows.reveal | $.executionEdges[0].findings[0]  | ROUTE_SEMANTIC_PROGRESS_MISSING                 |\n        | reveal-estate-workflows.reveal | $.executionEdges[3].transitionId | recur-request-capability-from-objective-v3-turn |\n        | reveal-estate-workflows.reveal | $.executionEdges[3].findings[0]  | RECURRENCE_UNBOUNDED                            |\n        | reveal-estate-workflows.reveal | $.summary.signature              | entries=1/1;edges=0/4;reached=1;terminals=0     |\n      # Run 3f81051e. The workflow stops at its entry.\n\n    @case:reveal-held-fan-out\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: A fan-out declared before the compiler wrote semanticProgress is held\n      Given an inspection request naming a capability of the selected estate, optionally one entry scenario and the definition digest it pins\n        \"\"\"json\n        {\"capabilityId\":\"concurrent-fanout-demo\"}\n        \"\"\"\n      And concurrent-fanout-demo declares a broadcast and its join without semanticProgress\n      When the declared entries are resolved and the closure of each admitted entry is derived over admitted transitions only\n      Then a workflow lens in which every held transition and entry is named with its findings, or NOT_FOUND, STALE or NOT_DECLARED\n        | operation                      | path                            | equals                                      |\n        | reveal-estate-workflows.reveal | $.status                        | PARTIAL_WITH_HELD_GAPS                      |\n        | reveal-estate-workflows.reveal | $.executionEdges[0].findings[0] | ROUTE_SEMANTIC_PROGRESS_MISSING             |\n        | reveal-estate-workflows.reveal | $.summary.signature             | entries=1/1;edges=0/6;reached=1;terminals=0 |\n      # Run e8c7ed61. All six transitions are held.\n\n  Rule: The lens answers only for what it can pin\n\n    @case:reveal-stale-pin\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: A pinned definition digest that differs refuses\n      Given an inspection request naming a capability of the selected estate, optionally one entry scenario and the definition digest it pins\n        \"\"\"json\n        {\"capabilityId\":\"dispatch-pair-demo\",\"expectedDefinitionDigest\":\"sha256:0000000000000000000000000000000000000000000000000000000000000000\"}\n        \"\"\"\n      And the pinned digest is not the selected definition digest of dispatch-pair-demo\n      When the declared entries are resolved and the closure of each admitted entry is derived over admitted transitions only\n      Then a workflow lens in which every held transition and entry is named with its findings, or NOT_FOUND, STALE or NOT_DECLARED\n        | operation                      | path                       | equals                                                                  |\n        | reveal-estate-workflows.reveal | $.status                   | STALE                                                                   |\n        | reveal-estate-workflows.reveal | $.expectedDefinitionDigest | sha256:0000000000000000000000000000000000000000000000000000000000000000 |\n      # Run d1175d72. Evidence: conformance/controls/reveal-stale.d1175d72.evidence.json.\n\n    @case:reveal-not-found\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: An unknown capability is not found\n      Given an inspection request naming a capability of the selected estate, optionally one entry scenario and the definition digest it pins\n        \"\"\"json\n        {\"capabilityId\":\"no-such-capability-dsl01\"}\n        \"\"\"\n      And the selected estate has no capability no-such-capability-dsl01\n      When the declared entries are resolved and the closure of each admitted entry is derived over admitted transitions only\n      Then a workflow lens in which every held transition and entry is named with its findings, or NOT_FOUND, STALE or NOT_DECLARED\n        | operation                      | path           | equals                   |\n        | reveal-estate-workflows.reveal | $.status       | NOT_FOUND                |\n        | reveal-estate-workflows.reveal | $.capabilityId | no-such-capability-dsl01 |\n      # Run bec5e723.\n"}';
 INSERT @m(v) EXEC model.mint_content_artifact @document=N'{"artifactKind":"capability-feature:check-capability-feature-conformance","text":"# check-capability-feature-conformance: canonical feature, review copy for the owner and the owner''s team, 2026-11-02,\n# tightened the same day after the owner''s review.\n#\n# What this file is: the canonical reference for the read-only check that keeps every capability circuit from\n# drifting from its canonical .feature. It comes first: the capability is not declared yet. Its procedure body,\n# conformance/check_capability_feature_conformance.body.sql (analysis.check_capability_feature_conformance once\n# installed), ran read-only as a session procedure through sql-database-reader. Each probed case below ran with exactly\n# its request, and conformance/run-check.mjs re-runs them from this file. The run ids of the latest full re-run are in\n# the README.\n#\n# Its declaration comes from conformance/check-capability-feature-conformance.dsl, which pins this file''s bytes and names\n# its provider: \"operation check-capability-feature-conformance.check uses provider sql-database-reader\". OV3 installs\n# the procedure and declares the capability in the flight sql/dsl-10 records; the author path binds this file to it and\n# commits only when this check finds the binding CONFORMANT. The compiler and the author path call the check with\n# @emit 0 and read @result, so neither nests an INSERT ... EXEC.\n#\n# What the estate has today (live reads, 2026-11-02):\n#   - 669 capabilities are selected in sidefx:capabilities. 451 have a CANONICAL feature row for some version, and 406\n#     have one for their selected version. model.estate_capability_feature holds 489 rows (runs 7e2a8058, e23af81e).\n#   - Read exactly, by role and selected version, the estate-wide baseline (runs f222a984, 037a132a, 9d96f6fe; again\n#     with the final body in a864cec2, fca3a2f7, 4c0b5e30, no capability changed) finds:\n#     . 263 NOT_BOUND: 218 have no feature row at all, and 45 are bound only at another version, compose-implementation-design\n#       among them.\n#     . 406 DRIFT, 0 CONFORMANT. 375 of the 406 bound features are the scaffold greeting (run 54ab1386); none\n#       uses @case or @provider.\n#     . Identity drift: OUTCOME_IDENTITY_MISMATCH in 390, EVENT_IDENTITY_MISMATCH 389, OUTCOME_CONTRACT_MISMATCH 380,\n#       INPUT_CONTRACT_MISMATCH 177, INPUT_IDENTITY_MISMATCH 66.\n#     . Declared steps missing from the feature: SCENARIO_STEP_NOT_IN_FEATURE in 396 capabilities (1,183 steps).\n#     . FEATURE_PIN_STALE 27. The case codes in 405 capabilities only show that no feature has cases yet.\n#   - The estate''s own reader, analysis.read_capability_gherkin_rows, gives an untagged scenario the @scenario tag of\n#     the scenario before it, and it does not read Scenario Outline. This check does not use it. It parses Gherkin\n#     itself, and its pickles equal those of @cucumber/gherkin (case conf-parse-tag-scope and the two after it).\n#   - The declared Gherkin steps and identity tags of each scenario version are kept in its definition\n#     (semantics.scenario.steps, run 7749b714). The check reads identities from the declared rows, and steps from that\n#     definition.\n#\n# How to read it:\n#   - The Feature tags state the check''s one circuit scenario and the identities its DSL must declare, named as the\n#     compiler names them.\n#   - Each Scenario, and each Examples row of an Outline, is one acceptance case with its own @case:<id> or case\n#     column. Every case uses the circuit''s Given, When and Then word for word. The json docstring is the request. A\n#     member written as {\"$textOf\": <path>} or {\"$jsonOf\": <path>} is the text, or the parsed JSON, of that file in this\n#     folder. Its \"$sha256\" must match the file. An evidence file is pinned instead by the evidenceDigest of the\n#     acceptance record that names it, and the check verifies those bytes itself. The table under Then lists the\n#     assertions: operation, JSON path in the result (capability-feature-conformance.v1), and the value it must equal.\n#     \"(absent)\" means the path selects nothing.\n#   - A run proves a case only through its own call: a flight step through the k-th dispatch, which is its k-th\n#     attempt; a direct call through its request, attested in the run by its canonical digest. Each step reports only\n#     its first failing layer: tag, provider identity, step binding, attempt, call, graph, outcome, result.\n#\n# Feature first, without a circle: the feature''s bytes are retained by digest; the compiler compiles the DSL against\n# exactly those bytes and runs this check on the compiled document (document mode); the author path (declared change\n# capability-from-dsl) declares the document and, at the end of the same change, binds those bytes to the version it\n# selected, committing only when this check returns CONFORMANT for the binding; the first call''s evidence then accepts\n# each case. All three parts are written and probed read-only: this check, the compiler revision\n# (features/compile-capability-dsl.feature) and the author path revision, which sql/dsl-06-test.sql tests in a\n# transaction that rolls back and sql/dsl-07 installs.\n#\n# Requests (check-capability-feature-conformance-request.v1): {\"capabilityId\"} for the bound feature;\n# {\"featureText\" or \"featureDigest\", \"capabilityId\"?} for a text, against a declaration when the capability is named;\n# {\"featureText\" or \"featureDigest\", \"document\"} for a text against a compiled document; {\"acceptance\", \"evidenceText\",\n# \"featureText\"?} for acceptance; {\"baseline\"} for a page of the estate.\n#\n# Status tags:\n#   @status:probed     the body ran read-only through sql-database-reader with exactly this request (run id in a comment)\n#   @status:not-built  it needs a write that has not happened yet: the install and declaration OV3 flies\n\n@capability:check-capability-feature-conformance\n@root-scenario:check-capability-feature-conformance\n@scenario:check-capability-feature-conformance\n@input:check-capability-feature-conformance-request\n@input-contract:check-capability-feature-conformance-request.v1\n@event:check-capability-feature-conformance-requested\n@event-authority:check-capability-feature-conformance.v1\n@outcome:check-capability-feature-conformance-outcome\n@outcome-contract:capability-feature-conformance.v1\n@outcome-terminal\nFeature: A capability''s circuit never drifts from its canonical feature\n  As the owner of the estate\n  I want every capability circuit checked against its canonical .feature by identity, and every case accepted only from its own call\n  So that the feature, its DSL, its declaration, its runs and its acceptance always describe the same thing, and OV3 can tell which link broke\n\n  Rule: The check reads exactly the canonical feature bound to the selected version, with no fallback\n\n    @case:conf-greeting-drift\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: The greeting scaffold bound to compile-capability-dsl is drift on three named identities and three steps\n      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins\n        \"\"\"json\n        {\"capabilityId\":\"compile-capability-dsl\"}\n        \"\"\"\n      And the CANONICAL feature of its selected version is the scaffold \"Write the configured text to standard output\"\n      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call\n      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity\n        | operation                                  | path                        | equals                                                                                                                                                                                                |\n        | check-capability-feature-conformance.check | $.status                    | DRIFT                                                                                                                                                                                                 |\n        | check-capability-feature-conformance.check | $.feature.featureVersionPk  | 182894                                                                                                                                                                                                |\n        | check-capability-feature-conformance.check | $.feature.contentDigest     | sha256:9f2f5b4ea73e97b4b3134f56b845fe698587dcd536b5899ba9a388e98376f7ab                                                                                                                               |\n        | check-capability-feature-conformance.check | $.feature.bytesVerified     | true                                                                                                                                                                                                  |\n        | check-capability-feature-conformance.check | $.findings[3].code          | EVENT_IDENTITY_MISMATCH                                                                                                                                                                               |\n        | check-capability-feature-conformance.check | $.findings[3].featureValue  | compile-capability-dsl                                                                                                                                                                                |\n        | check-capability-feature-conformance.check | $.findings[3].declaredValue | compile-capability-dsl-requested                                                                                                                                                                      |\n        | check-capability-feature-conformance.check | $.findings[4].code          | OUTCOME_CONTRACT_MISMATCH                                                                                                                                                                             |\n        | check-capability-feature-conformance.check | $.findings[4].featureValue  | compile-capability-dsl-greeting.v1                                                                                                                                                                    |\n        | check-capability-feature-conformance.check | $.findings[5].code          | OUTCOME_IDENTITY_MISMATCH                                                                                                                                                                             |\n        | check-capability-feature-conformance.check | $.findings[5].featureValue  | compile-capability-dsl-greeting                                                                                                                                                                       |\n        | check-capability-feature-conformance.check | $.summary.signature         | status=DRIFT;CASE_ASSERTION_MISSING=1;CASE_IDENTITY_MISSING=1;CASE_REQUEST_MISSING=1;EVENT_IDENTITY_MISMATCH=1;OUTCOME_CONTRACT_MISMATCH=1;OUTCOME_IDENTITY_MISMATCH=1;SCENARIO_STEP_NOT_IN_FEATURE=3 |\n      # Run e5dbe9ac. This is the first negative control. The declared steps it lacks are those of\n      # features/compile-capability-dsl.feature.\n\n    @case:conf-retained-bytes-by-digest\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: Feature bytes retained under a digest are read and verified by that digest\n      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins\n        \"\"\"json\n        {\"capabilityId\":\"compile-capability-dsl\",\"featureDigest\":\"sha256:9f2f5b4ea73e97b4b3134f56b845fe698587dcd536b5899ba9a388e98376f7ab\"}\n        \"\"\"\n      And source.content_object retains the greeting''s bytes under that digest\n      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call\n      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity\n        | operation                                  | path                    | equals   |\n        | check-capability-feature-conformance.check | $.feature.source        | retained |\n        | check-capability-feature-conformance.check | $.feature.bytesVerified | true     |\n        | check-capability-feature-conformance.check | $.status                | DRIFT    |\n      # Run c2d6f5b5. This is how the author path will check a feature before any binding exists.\n\n    @case:conf-not-bound-other-version\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: A feature bound only to another version of the capability is not the canonical feature\n      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins\n        \"\"\"json\n        {\"capabilityId\":\"compose-implementation-design\"}\n        \"\"\"\n      And its CANONICAL row names capability version 4942363 while the selected version is 4942364\n      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call\n      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity\n        | operation                                  | path                | equals           |\n        | check-capability-feature-conformance.check | $.status            | NOT_BOUND        |\n        | check-capability-feature-conformance.check | $.feature           | (absent)         |\n        | check-capability-feature-conformance.check | $.summary.signature | status=NOT_BOUND |\n      # Run c2d6f5b5. Run e23af81e found 45 capabilities in this state.\n\n    @case:conf-not-found-case-differs\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: A capability id that differs only in case is not found\n      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins\n        \"\"\"json\n        {\"capabilityId\":\"Compile-Capability-DSL\"}\n        \"\"\"\n      And the selected estate declares compile-capability-dsl in lower case only\n      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call\n      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity\n        | operation                                  | path     | equals    |\n        | check-capability-feature-conformance.check | $.status | NOT_FOUND |\n      # Run c2d6f5b5.\n\n  Rule: The check parses Gherkin itself, and a tag set belongs to the next element only\n\n    @case:conf-parse-tag-scope\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: A scenario without a scenario tag traces to no scenario, not to the scenario before it\n      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins\n        \"\"\"json\n        {\"featureText\":{\"$textOf\":\"conformance/fixtures/parser/tag-scope.feature\",\"$sha256\":\"139303fc406cf8ea697e5729b5205f1deb4fb6974a26b628abd4a496e8f6df02\"}}\n        \"\"\"\n      And its first scenario is tagged @scenario:first and its second has no @scenario tag\n      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call\n      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity\n        | operation                                  | path                    | equals                                  |\n        | check-capability-feature-conformance.check | $.status                | MALFORMED                               |\n        | check-capability-feature-conformance.check | $.summary.signature     | status=MALFORMED;SCENARIO_TAG_MISSING=1 |\n        | check-capability-feature-conformance.check | $.pickles[0].scenarioId | first                                   |\n        | check-capability-feature-conformance.check | $.pickles[1].caseId     | second-case                             |\n        | check-capability-feature-conformance.check | $.pickles[1].scenarioId | (absent)                                |\n      # Run e5dbe9ac. Its pickles equal those of @cucumber/gherkin: tags, step types and text, docstrings, tables.\n\n    @case:conf-parse-outline\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: Each Examples row is one case, with its own Examples tags and its placeholders filled\n      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins\n        \"\"\"json\n        {\"featureText\":{\"$textOf\":\"conformance/fixtures/parser/outline.feature\",\"$sha256\":\"ed2fa832793e8d7241720bc54279f0e9f938f83b377b1ce784048c90540b28e1\"}}\n        \"\"\"\n      And a Scenario Outline has two Examples blocks, the first tagged @provider:sql-database-reader, with three rows in all\n      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call\n      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity\n        | operation                                  | path                | equals                                                                                            |\n        | check-capability-feature-conformance.check | $.status            | WELL_FORMED                                                                                       |\n        | check-capability-feature-conformance.check | $.parse.pickles     | 3                                                                                                 |\n        | check-capability-feature-conformance.check | $.pickles[0].caseId | row-one                                                                                           |\n        | check-capability-feature-conformance.check | $.pickles[0].tags   | @capability:fixture-outline @provider:sql-database-reader @scenario:fixture-outline @status:probe |\n        | check-capability-feature-conformance.check | $.pickles[2].caseId | row-three                                                                                         |\n        | check-capability-feature-conformance.check | $.pickles[2].tags   | @capability:fixture-outline @scenario:fixture-outline @status:probe                               |\n      # Run e5dbe9ac. The estate''s reader does not recognize Scenario Outline at all.\n\n    @case:conf-parse-docstring\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: A docstring''s lines are content, never tags or steps\n      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins\n        \"\"\"json\n        {\"featureText\":{\"$textOf\":\"conformance/fixtures/parser/docstring.feature\",\"$sha256\":\"cc114cb7d6bbb9cc979c3bcc3ac82b2189b97efbce2165667abb7503e0b9f8e2\"}}\n        \"\"\"\n      And a docstring holds an @scenario line, a Then line and the other kind of delimiter\n      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call\n      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity\n        | operation                                  | path               | equals                                                                   |\n        | check-capability-feature-conformance.check | $.status           | WELL_FORMED                                                              |\n        | check-capability-feature-conformance.check | $.pickles[0].tags  | @capability:fixture-docstring @case:doc-case @scenario:fixture-docstring |\n        | check-capability-feature-conformance.check | $.pickles[0].steps | 3                                                                        |\n      # Run e5dbe9ac.\n\n  Rule: Identities, steps and cases agree with the declaration in both directions, and each drift is named alone\n\n    @case:conf-compile-feature-conforms\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: The replacement feature of compile-capability-dsl conforms to its declared circuit before it is bound\n      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins\n        \"\"\"json\n        {\"capabilityId\":\"compile-capability-dsl\",\"featureText\":{\"$textOf\":\"features/compile-capability-dsl.feature\",\"$sha256\":\"7f758d7545e4bedfd32b2c8f69c2d5ea7f21dfe54cc97bbb9868cb85c73a301c\"}}\n        \"\"\"\n      And the text states the declared identities, the three declared steps in every case, and $.status values COMPILED and REFUSED only\n      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call\n      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity\n        | operation                                  | path                | equals            |\n        | check-capability-feature-conformance.check | $.status            | CONFORMANT        |\n        | check-capability-feature-conformance.check | $.parse.cases       | 11                |\n        | check-capability-feature-conformance.check | $.summary.signature | status=CONFORMANT |\n      # Run 5fae01e0, with the eleven cases of this revision. Binding this text in place of the greeting is a write of the\n      # author path, not of this check.\n\n    @provider:sql-database-reader\n    @status:probed\n    Scenario Outline: Each kind of drift is named by its own code\n      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins\n        \"\"\"json\n        {\"capabilityId\":\"compile-capability-dsl\",\"featureText\":{\"$textOf\":\"conformance/fixtures/drift/<fixture>.feature\",\"$sha256\":\"<sha256>\"}}\n        \"\"\"\n      And the fixture conforms to the declared circuit of compile-capability-dsl except for <drift>\n      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call\n      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity\n        | operation                                  | path                | equals      |\n        | check-capability-feature-conformance.check | $.status            | <status>    |\n        | check-capability-feature-conformance.check | $.summary.signature | <signature> |\n\n      Examples:\n        | case                         | fixture                 | drift                                                      | sha256                                                           | status     | signature                                     |\n        | conf-drift-none              | base-conforms           | nothing                                                    | 54d815256aba8b082f9a4f2f20a540a8a23468c2b0e75d9bdb7a9e16b44feb79 | CONFORMANT | status=CONFORMANT                             |\n        | conf-drift-capability        | feature-capability      | a @capability tag naming another capability                | 5268f33d875fa4e07411661e0fb5513c2a2c1249491988c16ef0f3c50e72b27f | DRIFT      | status=DRIFT;FEATURE_CAPABILITY_MISMATCH=1    |\n        | conf-drift-root              | root-scenario           | a @root-scenario that is not the declared entry            | 180b11be4d5cfd2ca1886279061f5f7b86daa4968d42d17f5395725b40d8aa76 | DRIFT      | status=DRIFT;ROOT_SCENARIO_MISMATCH=1         |\n        | conf-drift-scenario-tag      | scenario-undeclared     | a scenario tag that names no declared scenario             | b40a7c9a3304d9f6a821207a6a4fe0d3cf023de92b0eba960bdad6040e285804 | DRIFT      | status=DRIFT;FEATURE_SCENARIO_UNDECLARED=1    |\n        | conf-drift-scenario-untagged | scenario-not-in-feature | a declared scenario that no case tags                      | 63c1c62e1baa4acd946e6f0c7505771d269c6ca63407050f8a0ae82d17c4a535 | DRIFT      | status=DRIFT;SCENARIO_NOT_IN_FEATURE=1        |\n        | conf-drift-case-untagged     | scenario-tag-missing    | a case that tags no scenario                               | 793fecc0df05344409c44b3bf57eb7259dcf483d91b15a45d0ddbdf89155423f | DRIFT      | status=DRIFT;SCENARIO_TAG_MISSING=1           |\n        | conf-drift-input             | input-identity          | an @input the scenario does not declare                    | 70fb0fcbe8bcf6b21475e09fee07d24914dafef602435711e845ea7f45926705 | DRIFT      | status=DRIFT;INPUT_IDENTITY_MISMATCH=1        |\n        | conf-drift-input-contract    | input-contract          | an @input-contract the scenario does not declare           | 763c45009a326cd7f359f71f8e8a099b905ffe776b1c58d463a3bfbdd6c863d2 | DRIFT      | status=DRIFT;INPUT_CONTRACT_MISMATCH=1        |\n        | conf-drift-event             | event-identity          | the greeting''s @event                                      | 4f9adc6afb38f8f5ad0c97ecfde32a1936402e898766202382f838e2c5753798 | DRIFT      | status=DRIFT;EVENT_IDENTITY_MISMATCH=1        |\n        | conf-drift-event-authority   | event-authority         | an @event-authority the scenario does not declare          | a16fc47b47533965943a375853a15a1145ca02173778d450d31f390d945fd029 | DRIFT      | status=DRIFT;EVENT_AUTHORITY_MISMATCH=1       |\n        | conf-drift-outcome           | outcome-identity        | the greeting''s @outcome                                    | 76471d9863bb36795fe9cd6aca42b3440eb30a1a23430ddc654739658db7aa12 | DRIFT      | status=DRIFT;OUTCOME_IDENTITY_MISMATCH=1      |\n        | conf-drift-outcome-contract  | outcome-contract        | the greeting''s @outcome-contract                           | c84ecb367a885bb90e6687a38233a7eba2d81d7895ce82f1c33f2c7657c43894 | DRIFT      | status=DRIFT;OUTCOME_CONTRACT_MISMATCH=1      |\n        | conf-drift-terminal          | outcome-terminal        | no @outcome-terminal on a terminal scenario                | 35ccec411a511a64927806883afbe36667daece880370bc38c2c9ac00920190b | DRIFT      | status=DRIFT;OUTCOME_TERMINAL_MISMATCH=1      |\n        | conf-drift-step              | declared-step           | a declared step that no case holds                         | b506d1051bc84bb96372dc595475e14c58fa2d011aa12db599174c4cbc6f1be3 | DRIFT      | status=DRIFT;SCENARIO_STEP_NOT_IN_FEATURE=1   |\n        | conf-drift-provider          | provider-unknown        | a provider tag that differs only in case                   | dbe6c5352e84273bcf7645bcb369777063f2eb12bf38b0bd860616873776f9ac | DRIFT      | status=DRIFT;PROVIDER_UNKNOWN=1               |\n        | conf-drift-provider-unbound  | provider-unbound        | a provider tag that no operation of the scenario uses      | 00354cf6f9e01081e3353d3b8b7adb8b2eb74aa5b67d1c201a336a1f2dd49f6c | DRIFT      | status=DRIFT;PROVIDER_TAG_UNBOUND=1           |\n        | conf-drift-status            | outcome-undeclared      | a $.status the circuit cannot return                       | ab201ea851c92b72643d9bbeaa6460cc0877fdf72d29003be6c5619437312f7f | DRIFT      | status=DRIFT;OUTCOME_UNDECLARED=1             |\n        | conf-drift-operation         | operation-undeclared    | an assertion on an operation the scenario does not declare | fad000704ba75ac2311c1a405e4c2145ec8dbc3690db20717635661bfb58d3f4 | DRIFT      | status=DRIFT;ASSERTION_OPERATION_UNDECLARED=1 |\n        | conf-drift-case-missing      | case-identity-missing   | a case without @case                                       | c638d45b54be8a6dc3873b84b426b4acc254621ae1fcee76417d2b711e5af9a8 | DRIFT      | status=DRIFT;CASE_IDENTITY_MISSING=1          |\n        | conf-drift-case-duplicate    | case-identity-duplicate | two cases with one @case                                   | ce61bd572e387178ee9d7ef188e128c08f809ec46669f395238f246c0fb5dfff | DRIFT      | status=DRIFT;CASE_IDENTITY_DUPLICATE=1        |\n        | conf-drift-case-ambiguous    | case-identity-ambiguous | one case with two @case tags                               | f94915d20db851dc52150e09afaee21b70ba818ffd9865efd8d831f5ad86f381 | DRIFT      | status=DRIFT;CASE_IDENTITY_AMBIGUOUS=1        |\n        | conf-drift-request-missing   | case-request-missing    | a case without a json request                              | afa7018d45a1def3e8bacd8d85489beffd35eaae7adfd6c726a770aa5f701d80 | DRIFT      | status=DRIFT;CASE_REQUEST_MISSING=1           |\n        | conf-drift-request-invalid   | case-request-invalid    | a json request that does not parse                         | fd339cd9373fe553247d6e259e0d6640f68beb05a9b4de893ff0e8795eddadea | DRIFT      | status=DRIFT;CASE_REQUEST_INVALID=1           |\n        | conf-drift-assertions        | case-assertion-missing  | a case without an operation, path and equals table         | 09458938b39ea6e27c16c013794af0aa3d5c7701935593d09ce660162d572d54 | DRIFT      | status=DRIFT;CASE_ASSERTION_MISSING=1         |\n        | conf-drift-status-unasserted | case-status-unasserted  | assertions that never read $.status                        | 4066a9c8c4d86031979e6072032d52051f1b09f415d1d843242a84aad8ccb462 | DRIFT      | status=DRIFT;CASE_STATUS_UNASSERTED=1         |\n        | conf-drift-parse             | parse-error             | a tag line that no keyword follows                         | 04aee29bfce507e2399faac1e89da4a9bd31c5be062c616f390cbe8e8c1b5c72 | DRIFT      | status=DRIFT;GHERKIN_PARSE_ERROR=1            |\n      # Run f8aa9214: each fixture changes one line of base-conforms, and each finds exactly its own code.\n\n  Rule: A feature is checked against a compiled document before anything is declared, providers included\n\n    @case:conf-document-conforms\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: The probe feature conforms to the document its pinned source compiles to\n      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins\n        \"\"\"json\n        {\"featureText\":{\"$textOf\":\"conformance/fixtures/compile/feature-first-probe.feature\",\"$sha256\":\"a27afaf641cbb246f8c330346bce96f9731c1bed1ab6408341414daf7881addc\"},\"document\":{\"$jsonOf\":\"conformance/fixtures/compile/feature-pin.document.json\",\"$sha256\":\"f228baa7177cedd7f6fbc114826a2ca595eb9c3648529421446ba38dc948f1c5\"}}\n        \"\"\"\n      And the document is what the revised compiler produced for conformance/fixtures/compile/feature-pin.dsl, sha256:74acfefa...\n      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call\n      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity\n        | operation                                  | path                | equals            |\n        | check-capability-feature-conformance.check | $.status            | CONFORMANT        |\n        | check-capability-feature-conformance.check | $.mode              | document          |\n        | check-capability-feature-conformance.check | $.summary.signature | status=CONFORMANT |\n      # This is the check the compiler runs on a source that pins its feature (compile case compile-feature-pin).\n\n    @case:conf-document-provider-drift\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: A provider tag no operation uses, and an operation''s provider no case tags, are each named\n      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins\n        \"\"\"json\n        {\"featureText\":{\"$textOf\":\"conformance/fixtures/compile/feature-first-probe-asks-model.feature\",\"$sha256\":\"9f4f0b54f8221620339f45fce7769427a3919934f563680dedccd0ef0e53f386\"},\"document\":{\"$jsonOf\":\"conformance/fixtures/compile/feature-pin.document.json\",\"$sha256\":\"f228baa7177cedd7f6fbc114826a2ca595eb9c3648529421446ba38dc948f1c5\"}}\n        \"\"\"\n      And the feature''s case is tagged @provider:ask-model, while operation dsl02-probe-feature-first.read uses provider sql-database-reader\n      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call\n      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity\n        | operation                                  | path                        | equals                                                          |\n        | check-capability-feature-conformance.check | $.status                    | DRIFT                                                           |\n        | check-capability-feature-conformance.check | $.summary.signature         | status=DRIFT;PROVIDER_BINDING_UNTAGGED=1;PROVIDER_TAG_UNBOUND=1 |\n        | check-capability-feature-conformance.check | $.findings[0].featureValue  | dsl02-probe-feature-first.read                                  |\n        | check-capability-feature-conformance.check | $.findings[0].declaredValue | sql-database-reader                                             |\n        | check-capability-feature-conformance.check | $.findings[1].featureValue  | ask-model                                                       |\n      # A declaration reads the same comparison from the operations its execution authority keeps (bound mode).\n\n    @case:conf-self-conforms\n    @provider:sql-database-reader\n    @status:not-built\n    Scenario: The declared check conforms to its own canonical feature\n      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins\n        \"\"\"json\n        {\"capabilityId\":\"check-capability-feature-conformance\"}\n        \"\"\"\n      And OV3 has declared check-capability-feature-conformance from conformance/check-capability-feature-conformance.dsl, which pins this feature\n      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call\n      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity\n        | operation                                  | path                | equals            |\n        | check-capability-feature-conformance.check | $.status            | CONFORMANT        |\n        | check-capability-feature-conformance.check | $.summary.signature | status=CONFORMANT |\n      # The first call of the check''s own flight (sql/dsl-11). In bound mode it compares the provider each operation''s\n      # execution authority names with the @provider tags, and the feature digest the installed document pins with the\n      # bound feature (DSL_FEATURE_STALE when they differ).\n\n  Rule: An acceptance case has an identity, a request and its own assertions\n\n    @case:conf-reveal-well-formed\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: The reveal feature states eight cases, each with a request and a status assertion\n      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins\n        \"\"\"json\n        {\"featureText\":{\"$textOf\":\"reveal-estate-workflows/reveal-estate-workflows.feature\",\"$sha256\":\"2935b6314d7b77271681a039e6f1e17b1f5985a5ff406e6b32a1d7c9dbe23b48\"}}\n        \"\"\"\n      And reveal-estate-workflows is not declared, so only the feature''s own rules apply\n      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call\n      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity\n        | operation                                  | path                | equals             |\n        | check-capability-feature-conformance.check | $.status            | WELL_FORMED        |\n        | check-capability-feature-conformance.check | $.parse.cases       | 8                  |\n        | check-capability-feature-conformance.check | $.summary.signature | status=WELL_FORMED |\n      # Run 2c503ff8.\n\n    @case:conf-reveal-stale-assertion-removed\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: Removing the STALE assertion leaves the STALE case without a status assertion\n      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins\n        \"\"\"json\n        {\"featureText\":{\"$textOf\":\"conformance/fixtures/reveal-without-stale-assertion.feature\",\"$sha256\":\"e3661c01493c528c68a707c6e1997104a377db31b1e976e672741d52e880e559\"}}\n        \"\"\"\n      And the fixture is the reveal feature without the row \"$.status | STALE\" of case reveal-stale-pin\n      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call\n      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity\n        | operation                                  | path                 | equals                                    |\n        | check-capability-feature-conformance.check | $.status             | MALFORMED                                 |\n        | check-capability-feature-conformance.check | $.summary.signature  | status=MALFORMED;CASE_STATUS_UNASSERTED=1 |\n        | check-capability-feature-conformance.check | $.findings[0].caseId | reveal-stale-pin                          |\n      # Run 2c503ff8. A check keyed only by the circuit scenario would still pass: all eight cases tag the same scenario.\n\n  Rule: A run proves a case only through its own call, from pinned evidence\n\n    @case:conf-accept-census\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: The recorded census provider calls are accepted from pinned evidence\n      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins\n        \"\"\"json\n        {\"acceptance\":{\"$jsonOf\":\"conformance/controls/census-1.acceptance.json\",\"$sha256\":\"91a7997c784833639dba357b07911bcfc3e5a34e8895bd64a23617f981ce7530\"},\"evidenceText\":{\"$textOf\":\"conformance/controls/census-1.bee2eee7.evidence.json\"}}\n        \"\"\"\n      And the record is the census acceptance contract: plan claude-code-opus-5-5-ov3-harness-census at revision 1, digest 698d488c..., and per step its provider tag, accepted graph digest, returned outcome and expectation\n      And the evidence is 27 dispatch events and the step results of run bee2eee7, pinned as sha256:5ced6205...\n      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call\n      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity\n        | operation                                  | path                                  | equals                                                                  |\n        | check-capability-feature-conformance.check | $.status                              | ACCEPTED                                                                |\n        | check-capability-feature-conformance.check | $.acceptance.evidenceVerified         | true                                                                    |\n        | check-capability-feature-conformance.check | $.acceptance.steps[0].stepId          | write-census                                                            |\n        | check-capability-feature-conformance.check | $.acceptance.steps[0].dispatchCursor  | 778                                                                     |\n        | check-capability-feature-conformance.check | $.acceptance.steps[0].graphDigest     | sha256:f6563ca4e5e09732a861f0743c092e8023df1cf31c57cc6144deb226d60e8751 |\n        | check-capability-feature-conformance.check | $.acceptance.steps[0].returnedOutcome | MODEL_RESPONSE_OBTAINED                                                 |\n        | check-capability-feature-conformance.check | $.acceptance.steps[1].stepId          | check-census                                                            |\n        | check-capability-feature-conformance.check | $.acceptance.steps[1].dispatchCursor  | 934                                                                     |\n        | check-capability-feature-conformance.check | $.acceptance.steps[1].graphDigest     | sha256:dbb29dc8172312c3546bb706e32b30c32b59cb1ecad3b4dfff7e35826f6f0596 |\n        | check-capability-feature-conformance.check | $.acceptance.steps[1].returnedOutcome | READ                                                                    |\n        | check-capability-feature-conformance.check | $.acceptance.steps[1].actual          | CENSUS_READY                                                            |\n      # Run a49f244e. This is the positive control. The provider returned READ, and CENSUS_READY is the step''s own\n      # expectation ($.value.status) met by its own call: the 6th dispatch is its attempt 1. read-spec''s reader call\n      # (dispatch 660) also returned READ, and cannot stand in for check-census.\n\n    @provider:sql-database-reader\n    @status:probed\n    Scenario Outline: Census acceptance fails when the evidence cannot prove a required call\n      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins\n        \"\"\"json\n        {\"acceptance\":{\"$jsonOf\":\"conformance/controls/census-negative/<control>.acceptance.json\",\"$sha256\":\"<sha256>\"},\"evidenceText\":{\"$textOf\":\"conformance/controls/<evidence>\"}}\n        \"\"\"\n      And the census positive control is changed in one place: <defect>\n      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call\n      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity\n        | operation                                  | path                | equals      |\n        | check-capability-feature-conformance.check | $.status            | REJECTED    |\n        | check-capability-feature-conformance.check | $.summary.signature | <signature> |\n\n      Examples:\n        | case                        | control               | defect                                                         | sha256                                                           | evidence                                            | signature                                       |\n        | conf-census-capability-tag  | capability-tag-only   | a required provider named only by a capability tag             | 80faf2e259327b96250f4aeb98b10259b59a803ba479664c01531b994c0e1dc9 | census-1.bee2eee7.evidence.json                     | status=REJECTED;PROVIDER_TAG_MISSING=1          |\n        | conf-census-tag-case        | tag-case-differs      | a provider tag differing only in case                          | 3bf4a2542c899cea403801e1fed5e40285c94276cd9ebcccc23e80d3828d049a | census-1.bee2eee7.evidence.json                     | status=REJECTED;PROVIDER_UNKNOWN=1              |\n        | conf-census-tag-not-bound   | tag-not-step-binding  | a tag for a capability absent from the accepted step binding   | 7e2896786e9d316ddf2f42f451e0b878dfd4cf5450a0a5e8871a42c67a5cb320 | census-1.bee2eee7.evidence.json                     | status=REJECTED;PROVIDER_TAG_NOT_STEP_BINDING=1 |\n        | conf-census-plan            | other-plan-revision   | a different plan revision or digest                            | fabc3abfb8f15969433d2e2961ad7ec658b71a3d9f4941095590811a999506dc | census-1.bee2eee7.evidence.json                     | status=REJECTED;PLAN_MISMATCH=1                 |\n        | conf-census-graph           | other-graph-digest    | a different provider graph digest from the accepted pin        | e544edd04e481bf410eec72e2a0500d9026675595a2de4aa7d151cb5e9c2c78d | census-1.bee2eee7.evidence.json                     | status=REJECTED;GRAPH_DIGEST_MISMATCH=1         |\n        | conf-census-substituted     | substituted-provider  | a substituted provider returning a plausible census            | 96b4b8a2be94bce585b458c866a929c4e9071c45025ed82e53be1b7a95c86bd2 | census-negative/substituted-provider.evidence.json  | status=REJECTED;PROVIDER_SUBSTITUTED=1          |\n        | conf-census-graph-only      | graph-without-outcome | only a captured graph and no invocation outcome                | 00dee85ced930415a26faf7154c243559c2de7013bf394df1b266d475058ad67 | census-negative/graph-without-outcome.evidence.json | status=REJECTED;OUTCOME_NOT_RETURNED=1          |\n        | conf-census-another-run     | another-run           | the right provider invoked only in another run                 | 7d6e8ea31bd45c28952f102ea6f62def5e8f23cdcc1c8429930b88a203555c10 | census-negative/another-run.evidence.json           | status=REJECTED;RUN_MISMATCH=1                  |\n        | conf-census-another-step    | another-step          | the right provider invoked only in another step                | a6b39e706edbb6bd2a2dea171dd620652af8687810fa9ee685409ed26789d654 | census-negative/another-step.evidence.json          | status=REJECTED;CALL_IN_ANOTHER_STEP=2          |\n        | conf-census-another-attempt | another-attempt       | the right provider invoked only in another attempt             | 91ad3b745007bbc60f802659465c47b37501aecb50637c85ca677a3aa4378dea | census-negative/another-attempt.evidence.json       | status=REJECTED;OUTCOME_MISMATCH=1              |\n        | conf-census-outcome         | unsatisfying-outcome  | a returned outcome that does not satisfy the step              | 7bc8ff2839371f94f2902f6c50e374dc09c4b70b1617fc31e6f8bbe2dbf38f2f | census-negative/unsatisfying-outcome.evidence.json  | status=REJECTED;OUTCOME_MISMATCH=1              |\n        | conf-census-gap             | attribution-gap       | an evidence gap that prevents attribution of the required call | c63e6436d4bed77cb391dc32cda61eb2f0c2d897e56ad2d93ed0b92b1842a1a6 | census-negative/attribution-gap.evidence.json       | status=REJECTED;EVIDENCE_ATTRIBUTION_GAP=1      |\n        | conf-census-tampered        | tampered-evidence     | evidence bytes that are not the pinned bytes                   | 91a7997c784833639dba357b07911bcfc3e5a34e8895bd64a23617f981ce7530 | census-negative/tampered-evidence.evidence.json     | status=REJECTED;EVIDENCE_DIGEST_MISMATCH=1      |\n      # Run a49f244e. The first ten rows are the census contract''s negative controls; another step, another attempt\n      # and tampered bytes are added. A changed evidence file is pinned again in its own record, so each row can fail\n      # only on its own defect.\n\n    @case:conf-accept-reveal-stale\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: The STALE run proves the STALE case through its own request and result\n      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins\n        \"\"\"json\n        {\"acceptance\":{\"$jsonOf\":\"conformance/controls/reveal-stale-pin.acceptance.json\",\"$sha256\":\"6f301c9b03f2795627ecd1a191759d46668fa53aea33b9609abeb0ce13001ae4\"},\"featureText\":{\"$textOf\":\"reveal-estate-workflows/reveal-estate-workflows.feature\",\"$sha256\":\"2935b6314d7b77271681a039e6f1e17b1f5985a5ff406e6b32a1d7c9dbe23b48\"},\"evidenceText\":{\"$textOf\":\"conformance/controls/reveal-stale.d1175d72.evidence.json\"}}\n        \"\"\"\n      And the record names case reveal-stale-pin, operation reveal-estate-workflows.reveal and run d1175d72\n      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call\n      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity\n        | operation                                  | path                              | equals                                                                  |\n        | check-capability-feature-conformance.check | $.status                          | ACCEPTED                                                                |\n        | check-capability-feature-conformance.check | $.acceptance.requestMatches       | true                                                                    |\n        | check-capability-feature-conformance.check | $.acceptance.graphDigest          | sha256:dbb29dc8172312c3546bb706e32b30c32b59cb1ecad3b4dfff7e35826f6f0596 |\n        | check-capability-feature-conformance.check | $.acceptance.assertions[0].actual | STALE                                                                   |\n      # Run 2c503ff8. The case''s request and assertions come from the feature text, not from the record.\n\n    @provider:sql-database-reader\n    @status:probed\n    Scenario Outline: A STALE proof that is not the STALE case''s own call is rejected\n      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins\n        \"\"\"json\n        {\"acceptance\":{\"$jsonOf\":\"conformance/controls/<record>\",\"$sha256\":\"<sha256>\"},\"featureText\":{\"$textOf\":\"<feature>\"},\"evidenceText\":{\"$textOf\":\"conformance/controls/<evidence>\"}}\n        \"\"\"\n      And <defect>\n      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call\n      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity\n        | operation                                  | path                | equals      |\n        | check-capability-feature-conformance.check | $.status            | REJECTED    |\n        | check-capability-feature-conformance.check | $.summary.signature | <signature> |\n\n      Examples:\n        | case                          | record                                                      | sha256                                                           | feature                                                     | evidence                                                 | defect                                                           | signature                                   |\n        | conf-reveal-resolved-as-stale | reveal-negative/resolved-run-as-stale-proof.acceptance.json | eaa9aefc2bbbe24883d2b7cc7e52200287dd1dce2e0ba2c9b8a90a467c8e8ff2 | reveal-estate-workflows/reveal-estate-workflows.feature     | reveal-resolved.f6b88ab2.evidence.json                   | the RESOLVED run is offered as the STALE case''s proof            | status=REJECTED;EVIDENCE_REQUEST_MISMATCH=1 |\n        | conf-reveal-unasserted        | reveal-stale-pin.acceptance.json                            | 6f301c9b03f2795627ecd1a191759d46668fa53aea33b9609abeb0ce13001ae4 | conformance/fixtures/reveal-without-stale-assertion.feature | reveal-stale.d1175d72.evidence.json                      | the STALE case has lost its status assertion                     | status=REJECTED;CASE_STATUS_UNASSERTED=1    |\n        | conf-reveal-wrong-result      | reveal-negative/stale-request-wrong-result.acceptance.json  | d17f4d1f7d48827632be49011f2767d3d49c9fc0670d039fc174ff22bd26c953 | reveal-estate-workflows/reveal-estate-workflows.feature     | reveal-negative/stale-request-wrong-result.evidence.json | the STALE case''s own request returned a result that is not STALE | status=REJECTED;ASSERTION_FAILED=1          |\n      # Run 2c503ff8. The reviewer''s two tests are the first two rows: both fail.\n\n  Rule: The estate baseline reads every selected capability, bound or not\n\n    @case:conf-baseline-first-page\n    @provider:sql-database-reader\n    @status:probed\n    Scenario: The first page of the baseline lists the first hundred selected capabilities by identity\n      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins\n        \"\"\"json\n        {\"baseline\":{\"after\":\"\",\"size\":100}}\n        \"\"\"\n      And the estate selects 669 capabilities in sidefx:capabilities\n      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call\n      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity\n        | operation                                  | path         | equals           |\n        | check-capability-feature-conformance.check | $.status     | BASELINE         |\n        | check-capability-feature-conformance.check | $.page.count | 100              |\n        | check-capability-feature-conformance.check | $.page.last  | complete-api-run |\n      # Run f222a984; pages two and three are runs 037a132a and 9d96f6fe. Over all 669: 406 DRIFT, 263 NOT_BOUND,\n      # 0 CONFORMANT (totals in the header). New capabilities move the page boundaries.\n\n    @case:conf-author-path-check\n    @provider:sql-database-reader\n    @status:not-built\n    Scenario: The author path commits a declaration only when its pinned feature conforms\n      Given a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins\n        \"\"\"json\n        {\"capabilityId\":\"check-capability-feature-conformance\"}\n        \"\"\"\n      And the declared change capability-from-dsl has declared conformance/check-capability-feature-conformance.dsl and, at the end of its transaction, bound the feature bytes the source pins\n      When the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call\n      Then CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity\n        | operation                                  | path     | equals     |\n        | check-capability-feature-conformance.check | $.status | CONFORMANT |\n      # The revised author path (source/model.apply_capability_from_dsl.v3.sql) makes this call with @emit 0, and throws\n      # CAPABILITY_FROM_DSL_FEATURE_DRIFT for any other status, so nothing of the declaration is kept. sql/dsl-06-test.sql\n      # runs it on a probe capability in a transaction that rolls back; the declare step of the check''s flight runs it.\n"}';
SET @stage=N'compile: feature pin';
SET @in=(SELECT N'# Fixture of case compile-feature-pin: pins the retained feature bytes and names its provider (proposed lines).
capability dsl02-probe-feature-first
feature dsl02-probe-feature-first sha256:a27afaf641cbb246f8c330346bce96f9731c1bed1ab6408341414daf7881addc
intent: Fixture of compile-capability-dsl; compiled only, never declared.
outcome: dsl02-probe-feature-first-result.v1
input contract dsl02-probe-feature-first-request.v1 {"type":"object"}
output contract dsl02-probe-feature-first-result.v1 {"type":"object","properties":{"status":{"enum":["READ"]}}}
scenario dsl02-probe-feature-first root terminal
given: a request naming a value
when: the provider reads it
then: the result carries the value
operation dsl02-probe-feature-first.read uses provider sql-database-reader
config: {"dataSource":"sfx-estate-database","statement":"SELECT @input AS value;","resultColumn":"value"}
outcome from dsl02-probe-feature-first.read $
' AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC #dsl06_compile @input=@in,@estate_model_pk=@e;
SELECT @r0=v FROM @t; DELETE @t;
SET @stage=N'compile: feature pin, nothing retained';
SET @in=(SELECT N'# Fixture of case compile-feature-pin-unretained: pins a digest under which no bytes are retained.
capability dsl02-probe-feature-first
feature dsl02-probe-feature-first sha256:0000000000000000000000000000000000000000000000000000000000000000
intent: Fixture of compile-capability-dsl; compiled only, never declared.
outcome: dsl02-probe-feature-first-result.v1
input contract dsl02-probe-feature-first-request.v1 {"type":"object"}
output contract dsl02-probe-feature-first-result.v1 {"type":"object","properties":{"status":{"enum":["READ"]}}}
scenario dsl02-probe-feature-first root terminal
given: a request naming a value
when: the provider reads it
then: the result carries the value
operation dsl02-probe-feature-first.read uses provider sql-database-reader
config: {"dataSource":"sfx-estate-database","statement":"SELECT @input AS value;","resultColumn":"value"}
outcome from dsl02-probe-feature-first.read $
' AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC #dsl06_compile @input=@in,@estate_model_pk=@e;
SELECT @r1=v FROM @t; DELETE @t;
SET @stage=N'compile: feature drift';
SET @in=(SELECT N'# Fixture of case compile-feature-drift: its then line is not a step of the pinned feature.
capability dsl02-probe-feature-first
feature dsl02-probe-feature-first sha256:a27afaf641cbb246f8c330346bce96f9731c1bed1ab6408341414daf7881addc
intent: Fixture of compile-capability-dsl; compiled only, never declared.
outcome: dsl02-probe-feature-first-result.v1
input contract dsl02-probe-feature-first-request.v1 {"type":"object"}
output contract dsl02-probe-feature-first-result.v1 {"type":"object","properties":{"status":{"enum":["READ"]}}}
scenario dsl02-probe-feature-first root terminal
given: a request naming a value
when: the provider reads it
then: the result holds the value
operation dsl02-probe-feature-first.read uses provider sql-database-reader
config: {"dataSource":"sfx-estate-database","statement":"SELECT @input AS value;","resultColumn":"value"}
outcome from dsl02-probe-feature-first.read $
' AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC #dsl06_compile @input=@in,@estate_model_pk=@e;
SELECT @r2=v FROM @t; DELETE @t;
SET @stage=N'compile: provider differing in case';
SET @in=(SELECT N'# Fixture of case compile-uses-unknown-provider: the provider id differs from sql-database-reader only in case.
capability dsl02-probe-feature-first
feature dsl02-probe-feature-first sha256:a27afaf641cbb246f8c330346bce96f9731c1bed1ab6408341414daf7881addc
intent: Fixture of compile-capability-dsl; compiled only, never declared.
outcome: dsl02-probe-feature-first-result.v1
input contract dsl02-probe-feature-first-request.v1 {"type":"object"}
output contract dsl02-probe-feature-first-result.v1 {"type":"object","properties":{"status":{"enum":["READ"]}}}
scenario dsl02-probe-feature-first root terminal
given: a request naming a value
when: the provider reads it
then: the result carries the value
operation dsl02-probe-feature-first.read uses provider Sql-Database-Reader
config: {"dataSource":"sfx-estate-database","statement":"SELECT @input AS value;","resultColumn":"value"}
outcome from dsl02-probe-feature-first.read $
' AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC #dsl06_compile @input=@in,@estate_model_pk=@e;
SELECT @r3=v FROM @t; DELETE @t;
SET @stage=N'compile: input from';
SET @in=(SELECT N'# Fixture of case compile-input-from: an operation''s input member names the earlier result it consumes (proposed lines).
capability dsl02-probe-input-from
intent: Fixture of compile-capability-dsl; compiled only, never declared.
outcome: dsl02-probe-input-from-result.v1
input contract dsl02-probe-input-from-request.v1 {"type":"object"}
output contract dsl02-probe-input-from-result.v1 {"type":"object"}
scenario dsl02-probe-input-from root terminal
given: a request naming a value
when: the value is read and then put to the model
then: the model''s answer about the value
operation dsl02-probe-input-from.read uses provider sql-database-reader
config: {"dataSource":"sfx-estate-database","statement":"SELECT @input AS value;","resultColumn":"value"}
operation dsl02-probe-input-from.ask uses provider ask-model
input prompt from dsl02-probe-input-from.read $.value
' AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC #dsl06_compile @input=@in,@estate_model_pk=@e;
SELECT @r4=v FROM @t; DELETE @t;
SET @stage=N'compile: greeting pinned';
SET @in=(SELECT N'# Fixture of check case conf-compile-greeting-pin: a source for compile-capability-dsl that pins the greeting scaffold the
# estate retains under sha256:9f2f5b4e... It must refuse, naming each drift.
capability compile-capability-dsl
feature compile-capability-dsl sha256:9f2f5b4ea73e97b4b3134f56b845fe698587dcd536b5899ba9a388e98376f7ab
intent: Compile capability DSL into the declared document, or refuse with named diagnostics
outcome: compile-capability-dsl-result.v1 COMPILED or REFUSED
input contract compile-capability-dsl-request.v1 {"type":"object","additionalProperties":false,"required":["source"],"properties":{"source":{"type":"string","minLength":1,"maxLength":65536}}}
output contract compile-capability-dsl-result.v1 {"type":"object","required":["contractId","status"],"properties":{"status":{"enum":["COMPILED","REFUSED"]}}}
scenario compile-capability-dsl root terminal
given: DSL source text on the declared grammar
when: the resolver parses every line and validates the whole document
then: the compiled capability document with its digests, or the named DSL_* refusals with line numbers
operation compile-capability-dsl.compile uses provider sql-database-reader
config: {"dataSource":"sfx-estate-database","statement":"EXEC analysis.compile_capability_dsl @input=@input,@estate_model_pk=NULL;","resultColumn":"value"}
input input from compile-capability-dsl $
outcome from compile-capability-dsl.compile $.value
' AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC #dsl06_compile @input=@in,@estate_model_pk=@e;
SELECT @r5=v FROM @t; DELETE @t;
SET @stage=N'compile: reveal revision 2';
SET @in=(SELECT N'capability reveal-estate-workflows
feature reveal-estate-workflows sha256:2935b6314d7b77271681a039e6f1e17b1f5985a5ff406e6b32a1d7c9dbe23b48
intent: Reveal the admitted workflows of one capability as a read-only lens: its declared entries, the closure of each admitted entry over admitted transitions only, every routing transition with its topology, semanticProgress and status, and the findings that hold a transition or an entry, from one pinned definition
outcome: workflow-lens.v1 RESOLVED, PARTIAL_WITH_HELD_GAPS, NOT_DECLARED, NOT_FOUND or STALE, with entries, workflows, execution edges, findings, a summary signature and a projection digest
inquiry: Reveal the admitted workflows of this capability.
inquiry: Which routes can run from this capability''s entry, and which are held?
inquiry: Why is this route shown or held?
input contract reveal-estate-workflows-request.v1 {"type":"object","additionalProperties":false,"required":["capabilityId"],"properties":{"capabilityId":{"type":"string","minLength":1,"maxLength":400},"entryScenarioId":{"type":"string","minLength":1,"maxLength":400},"expectedDefinitionDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"}}}
output contract workflow-lens.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"workflow-lens.v1"},"status":{"enum":["RESOLVED","PARTIAL_WITH_HELD_GAPS","NOT_DECLARED","NOT_FOUND","STALE"]}}}
cli display outcome as json
scenario reveal-estate-workflows root terminal
given: an inspection request naming a capability of the selected estate, optionally one entry scenario and the definition digest it pins
when: the declared entries are resolved and the closure of each admitted entry is derived over admitted transitions only
then: a workflow lens in which every held transition and entry is named with its findings, or NOT_FOUND, STALE or NOT_DECLARED
operation reveal-estate-workflows.reveal uses provider sql-database-reader
config: {"dataSource":"sfx-estate-database","statement":"SET ARITHABORT ON; DECLARE @estate_model_pk bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1); EXEC analysis.reveal_estate_workflows @input=@input,@estate_model_pk=@estate_model_pk;","resultColumn":"value"}
input input from reveal-estate-workflows $
outcome from reveal-estate-workflows.reveal $.value
' AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC #dsl06_compile @input=@in,@estate_model_pk=@e;
SELECT @r6=v FROM @t; DELETE @t;
SET @stage=N'compile: the check''s own source';
SET @in=(SELECT N'capability check-capability-feature-conformance
feature check-capability-feature-conformance sha256:49bf06230349e792eeba7041a7f7ecf2cd2c894aa5635ae2ec5c5b2130ab02b9
intent: Check a capability''s circuit against its canonical feature by identity, and accept each case only from the pinned evidence of its own call
outcome: capability-feature-conformance.v1 CONFORMANT, DRIFT, WELL_FORMED, MALFORMED, NOT_BOUND, NOT_FOUND, ACCEPTED, REJECTED or BASELINE, with each finding named by its code and identity
inquiry: Does this capability''s circuit drift from its canonical feature?
inquiry: Which identity, step or case drifted, and where?
inquiry: Does this run prove this case through its own call?
input contract check-capability-feature-conformance-request.v1 {"type":"object","additionalProperties":false,"properties":{"capabilityId":{"type":"string","minLength":1,"maxLength":400},"featureText":{"type":"string","minLength":1},"featureDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},"document":{"type":"object"},"acceptance":{"type":"object"},"evidenceText":{"type":"string","minLength":1},"baseline":{"type":"object"},"explain":{"type":"boolean"}}}
output contract capability-feature-conformance.v1 {"type":"object","additionalProperties":true,"required":["contractId","status"],"properties":{"contractId":{"const":"capability-feature-conformance.v1"},"status":{"type":"string"}}}
cli display outcome as json
scenario check-capability-feature-conformance root terminal
variants: CONFORMANT:success,DRIFT:success,WELL_FORMED:success,MALFORMED:success,NOT_BOUND:success,NOT_FOUND:success,ACCEPTED:success,REJECTED:success,BASELINE:success
given: a capability of the selected estate, a feature text, or an acceptance record with the run evidence it pins
when: the feature is parsed scope by scope and each identity, step and case is compared with its declaration or with the evidence of its own call
then: CONFORMANT, WELL_FORMED or ACCEPTED, or each drift named by its code and identity
operation check-capability-feature-conformance.check uses provider sql-database-reader
config: {"dataSource":"sfx-estate-database","statement":"SET ARITHABORT ON; DECLARE @estate_model_pk bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1); EXEC analysis.check_capability_feature_conformance @input=@input,@estate_model_pk=@estate_model_pk;","resultColumn":"value"}
input input from check-capability-feature-conformance $
outcome from check-capability-feature-conformance.check $.value
' AS source FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
INSERT @t(v) EXEC #dsl06_compile @input=@in,@estate_model_pk=@e;
SELECT @r7=v FROM @t; DELETE @t;
 ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
 SET @err=ERROR_MESSAGE();
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
END CATCH
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'the section ran to its end',N'(no error)',ISNULL(@stage+N': '+@err,N'(no error)'),CASE WHEN @err IS NULL THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'feature pin: $.status',N'COMPILED',ISNULL(JSON_VALUE(@r0,N'$.status'),N'(absent)'),CASE WHEN ISNULL(JSON_VALUE(@r0,N'$.status'),N'(absent)')=N'COMPILED' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'feature pin: $.document.feature.digest',N'sha256:a27afaf641cbb246f8c330346bce96f9731c1bed1ab6408341414daf7881addc',ISNULL(JSON_VALUE(@r0,N'$.document.feature.digest'),N'(absent)'),CASE WHEN ISNULL(JSON_VALUE(@r0,N'$.document.feature.digest'),N'(absent)')=N'sha256:a27afaf641cbb246f8c330346bce96f9731c1bed1ab6408341414daf7881addc' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'feature pin: $.document.scenarios[0].operations[4].providerCapabilityId',N'sql-database-reader',ISNULL(JSON_VALUE(@r0,N'$.document.scenarios[0].operations[4].providerCapabilityId'),N'(absent)'),CASE WHEN ISNULL(JSON_VALUE(@r0,N'$.document.scenarios[0].operations[4].providerCapabilityId'),N'(absent)')=N'sql-database-reader' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'feature pin, nothing retained: $.status',N'REFUSED',ISNULL(JSON_VALUE(@r1,N'$.status'),N'(absent)'),CASE WHEN ISNULL(JSON_VALUE(@r1,N'$.status'),N'(absent)')=N'REFUSED' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'feature pin, nothing retained: $.diagnostics[0].code',N'DSL_FEATURE_NOT_RETAINED',ISNULL(JSON_VALUE(@r1,N'$.diagnostics[0].code'),N'(absent)'),CASE WHEN ISNULL(JSON_VALUE(@r1,N'$.diagnostics[0].code'),N'(absent)')=N'DSL_FEATURE_NOT_RETAINED' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'feature pin, nothing retained: $.diagnostics[0].line',N'3',ISNULL(JSON_VALUE(@r1,N'$.diagnostics[0].line'),N'(absent)'),CASE WHEN ISNULL(JSON_VALUE(@r1,N'$.diagnostics[0].line'),N'(absent)')=N'3' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'feature drift: $.status',N'REFUSED',ISNULL(JSON_VALUE(@r2,N'$.status'),N'(absent)'),CASE WHEN ISNULL(JSON_VALUE(@r2,N'$.status'),N'(absent)')=N'REFUSED' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'feature drift: $.diagnostics[0].code',N'DSL_FEATURE_DRIFT',ISNULL(JSON_VALUE(@r2,N'$.diagnostics[0].code'),N'(absent)'),CASE WHEN ISNULL(JSON_VALUE(@r2,N'$.diagnostics[0].code'),N'(absent)')=N'DSL_FEATURE_DRIFT' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'feature drift: $.diagnostics[0].message',N'SCENARIO_STEP_NOT_IN_FEATURE: the result holds the value',ISNULL(JSON_VALUE(@r2,N'$.diagnostics[0].message'),N'(absent)'),CASE WHEN ISNULL(JSON_VALUE(@r2,N'$.diagnostics[0].message'),N'(absent)')=N'SCENARIO_STEP_NOT_IN_FEATURE: the result holds the value' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'provider differing in case: $.status',N'REFUSED',ISNULL(JSON_VALUE(@r3,N'$.status'),N'(absent)'),CASE WHEN ISNULL(JSON_VALUE(@r3,N'$.status'),N'(absent)')=N'REFUSED' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'provider differing in case: $.diagnostics[0].code',N'DSL_PROVIDER_UNKNOWN',ISNULL(JSON_VALUE(@r3,N'$.diagnostics[0].code'),N'(absent)'),CASE WHEN ISNULL(JSON_VALUE(@r3,N'$.diagnostics[0].code'),N'(absent)')=N'DSL_PROVIDER_UNKNOWN' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'provider differing in case: $.diagnostics[0].line',N'12',ISNULL(JSON_VALUE(@r3,N'$.diagnostics[0].line'),N'(absent)'),CASE WHEN ISNULL(JSON_VALUE(@r3,N'$.diagnostics[0].line'),N'(absent)')=N'12' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'input from: $.status',N'COMPILED',ISNULL(JSON_VALUE(@r4,N'$.status'),N'(absent)'),CASE WHEN ISNULL(JSON_VALUE(@r4,N'$.status'),N'(absent)')=N'COMPILED' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'input from: $.document.scenarios[0].operations[9].inputs[0].from',N'dsl02-probe-input-from.read',ISNULL(JSON_VALUE(@r4,N'$.document.scenarios[0].operations[9].inputs[0].from'),N'(absent)'),CASE WHEN ISNULL(JSON_VALUE(@r4,N'$.document.scenarios[0].operations[9].inputs[0].from'),N'(absent)')=N'dsl02-probe-input-from.read' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'greeting pinned: $.status',N'REFUSED',ISNULL(JSON_VALUE(@r5,N'$.status'),N'(absent)'),CASE WHEN ISNULL(JSON_VALUE(@r5,N'$.status'),N'(absent)')=N'REFUSED' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'greeting pinned: $.diagnostics[3].message',N'EVENT_IDENTITY_MISMATCH: feature compile-capability-dsl, source compile-capability-dsl-requested',ISNULL(JSON_VALUE(@r5,N'$.diagnostics[3].message'),N'(absent)'),CASE WHEN ISNULL(JSON_VALUE(@r5,N'$.diagnostics[3].message'),N'(absent)')=N'EVENT_IDENTITY_MISMATCH: feature compile-capability-dsl, source compile-capability-dsl-requested' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'reveal revision 2: $.status',N'COMPILED',ISNULL(JSON_VALUE(@r6,N'$.status'),N'(absent)'),CASE WHEN ISNULL(JSON_VALUE(@r6,N'$.status'),N'(absent)')=N'COMPILED' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'reveal revision 2: $.document.feature.digest',N'sha256:2935b6314d7b77271681a039e6f1e17b1f5985a5ff406e6b32a1d7c9dbe23b48',ISNULL(JSON_VALUE(@r6,N'$.document.feature.digest'),N'(absent)'),CASE WHEN ISNULL(JSON_VALUE(@r6,N'$.document.feature.digest'),N'(absent)')=N'sha256:2935b6314d7b77271681a039e6f1e17b1f5985a5ff406e6b32a1d7c9dbe23b48' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'the check''s own source: $.status',N'COMPILED',ISNULL(JSON_VALUE(@r7,N'$.status'),N'(absent)'),CASE WHEN ISNULL(JSON_VALUE(@r7,N'$.status'),N'(absent)')=N'COMPILED' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'the check''s own source: $.document.feature.digest',N'sha256:49bf06230349e792eeba7041a7f7ecf2cd2c894aa5635ae2ec5c5b2130ab02b9',ISNULL(JSON_VALUE(@r7,N'$.document.feature.digest'),N'(absent)'),CASE WHEN ISNULL(JSON_VALUE(@r7,N'$.document.feature.digest'),N'(absent)')=N'sha256:49bf06230349e792eeba7041a7f7ecf2cd2c894aa5635ae2ec5c5b2130ab02b9' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'new lines',N'the check''s own source: $.document.scenarios[0].operations[4].providerCapabilityId',N'sql-database-reader',ISNULL(JSON_VALUE(@r7,N'$.document.scenarios[0].operations[4].providerCapabilityId'),N'(absent)'),CASE WHEN ISNULL(JSON_VALUE(@r7,N'$.document.scenarios[0].operations[4].providerCapabilityId'),N'(absent)')=N'sql-database-reader' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END);
GO
-- 3. The author path. Its results are kept in variables until the transaction has rolled back.
SET NOCOUNT ON;
SET XACT_ABORT OFF;
DECLARE @m TABLE(v nvarchar(max));
DECLARE @e bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1),@doc nvarchar(max),
 @bound nvarchar(80)=NULL,@kept nvarchar(80)=NULL,@cr nvarchar(max)=NULL,@drift nvarchar(2048)=NULL,@err nvarchar(2048)=NULL,@stage nvarchar(80)=N'retain the probe feature',
 @before int=(SELECT COUNT(*) FROM model.capability WHERE capability_id=N'dsl02-probe-feature-first'),@after int,@req nvarchar(max)=N'{"capabilityId":"dsl02-probe-feature-first"}';
BEGIN TRY
 BEGIN TRANSACTION;
 INSERT @m(v) EXEC model.mint_content_artifact @document=N'{"artifactKind":"capability-feature:dsl02-probe-feature-first","text":"# Fixture for compile-capability-dsl cases compile-feature-pin and compile-feature-drift: the canonical feature of probe\n# capability dsl02-probe-feature-first, retained by its digest before its DSL is compiled. Never declared.\n\n@capability:dsl02-probe-feature-first\n@root-scenario:dsl02-probe-feature-first\n@scenario:dsl02-probe-feature-first\n@input:dsl02-probe-feature-first-request\n@input-contract:dsl02-probe-feature-first-request.v1\n@event:dsl02-probe-feature-first-requested\n@event-authority:dsl02-probe-feature-first.v1\n@outcome:dsl02-probe-feature-first-outcome\n@outcome-contract:dsl02-probe-feature-first-result.v1\n@outcome-terminal\nFeature: Read one value through the provider the feature names\n\n  @case:probe-read\n  @provider:sql-database-reader\n  Scenario: The provider reads the value\n    Given a request naming a value\n      \"\"\"json\n      {\"value\":\"x\"}\n      \"\"\"\n    When the provider reads it\n    Then the result carries the value\n      | operation                      | path     | equals |\n      | dsl02-probe-feature-first.read | $.status | READ   |\n"}';
 SET @stage=N'declare the pinned probe';
 SET @doc=N'{"contractId":"capability-from-dsl-change.v1","source":"# Fixture of case compile-feature-pin: pins the retained feature bytes and names its provider (proposed lines).\ncapability dsl02-probe-feature-first\nfeature dsl02-probe-feature-first sha256:a27afaf641cbb246f8c330346bce96f9731c1bed1ab6408341414daf7881addc\nintent: Fixture of compile-capability-dsl; compiled only, never declared.\noutcome: dsl02-probe-feature-first-result.v1\ninput contract dsl02-probe-feature-first-request.v1 {\"type\":\"object\"}\noutput contract dsl02-probe-feature-first-result.v1 {\"type\":\"object\",\"properties\":{\"status\":{\"enum\":[\"READ\"]}}}\nscenario dsl02-probe-feature-first root terminal\ngiven: a request naming a value\nwhen: the provider reads it\nthen: the result carries the value\noperation dsl02-probe-feature-first.read uses provider sql-database-reader\nconfig: {\"dataSource\":\"sfx-estate-database\",\"statement\":\"SELECT @input AS value;\",\"resultColumn\":\"value\"}\noutcome from dsl02-probe-feature-first.read $\n","isMcpTooling":false,"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"capability-from-dsl","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}';
 EXEC #dsl06_apply @document=@doc;
 SET @stage=N'read the binding and the stored document';
 SELECT @bound=N'sha256:'+JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),env.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),N'$.semantics.content_digest')
 FROM model.estate_capability ec JOIN model.capability c ON c.capability_pk=ec.capability_pk
 JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
 JOIN model.estate_capability_feature f ON f.estate_model_pk=ec.estate_model_pk AND f.capability_pk=ec.capability_pk AND f.capability_version_pk=ec.capability_version_pk AND f.binding_role=N'CANONICAL'
 JOIN model.feature_version fv ON fv.feature_version_pk=f.feature_version_pk
 JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=fv.semantic_object_definition_pk
 JOIN source.content_object env ON env.content_object_pk=d.canonical_content_pk
 WHERE ec.estate_model_pk=@e AND c.capability_id=N'dsl02-probe-feature-first';
 SELECT TOP (1) @kept=JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),N'$.feature.digest')
 FROM analysis.v_selected_semantic_definition d
 JOIN source.content_object co ON co.content_digest=TRY_CONVERT(binary(32),JSON_VALUE(d.definition_json,N'$.semantics.document_digest'),2)
 WHERE d.estate_model_pk=@e AND d.object_kind='CAPABILITY_DOCUMENT' AND d.namespace_id=N'sidefx:capability-documents' AND d.declared_id=N'dsl02-probe-feature-first';
 SET @stage=N'check the binding';
 EXEC #dsl06_check @input=@req,@estate_model_pk=@e,@result=@cr OUTPUT,@emit=0;
 SET @stage=N'declare a source that drifts from its feature';
 SET @doc=N'{"contractId":"capability-from-dsl-change.v1","source":"# Fixture of case compile-feature-drift: its then line is not a step of the pinned feature.\ncapability dsl02-probe-feature-first\nfeature dsl02-probe-feature-first sha256:a27afaf641cbb246f8c330346bce96f9731c1bed1ab6408341414daf7881addc\nintent: Fixture of compile-capability-dsl; compiled only, never declared.\noutcome: dsl02-probe-feature-first-result.v1\ninput contract dsl02-probe-feature-first-request.v1 {\"type\":\"object\"}\noutput contract dsl02-probe-feature-first-result.v1 {\"type\":\"object\",\"properties\":{\"status\":{\"enum\":[\"READ\"]}}}\nscenario dsl02-probe-feature-first root terminal\ngiven: a request naming a value\nwhen: the provider reads it\nthen: the result holds the value\noperation dsl02-probe-feature-first.read uses provider sql-database-reader\nconfig: {\"dataSource\":\"sfx-estate-database\",\"statement\":\"SELECT @input AS value;\",\"resultColumn\":\"value\"}\noutcome from dsl02-probe-feature-first.read $\n","isMcpTooling":false,"verificationCapabilityId":"read-harness-authoring-state","preflight":{"input":{"changeKind":"capability-from-dsl","includeDefinitions":true},"expected":{"disposition":"terminated"}},"route":{"resolvedDisposition":"terminated"}}';
 BEGIN TRY
  EXEC #dsl06_apply @document=@doc;
  SET @drift=N'(declared)';
 END TRY
 BEGIN CATCH
  SET @drift=ERROR_MESSAGE();
 END CATCH
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
 SET @err=ERROR_MESSAGE();
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
END CATCH
SET @after=(SELECT COUNT(*) FROM model.capability WHERE capability_id=N'dsl02-probe-feature-first');
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'author path',N'the section ran to its end',N'(no error)',ISNULL(@stage+N': '+@err,N'(no error)'),CASE WHEN @err IS NULL THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'author path',N'the selected version is bound to the feature bytes the source pins',N'sha256:a27afaf641cbb246f8c330346bce96f9731c1bed1ab6408341414daf7881addc',@bound,CASE WHEN ISNULL(@bound,N'')=N'sha256:a27afaf641cbb246f8c330346bce96f9731c1bed1ab6408341414daf7881addc' THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'author path',N'the stored document keeps the feature pin',N'sha256:a27afaf641cbb246f8c330346bce96f9731c1bed1ab6408341414daf7881addc',@kept,CASE WHEN ISNULL(@kept,N'')=N'sha256:a27afaf641cbb246f8c330346bce96f9731c1bed1ab6408341414daf7881addc' THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'author path',N'the check finds the binding CONFORMANT',N'status=CONFORMANT',JSON_VALUE(@cr,N'$.summary.signature'),CASE WHEN ISNULL(JSON_VALUE(@cr,N'$.summary.signature'),N'')=N'status=CONFORMANT' THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'author path',N'a source that drifts from its feature is refused',N'CAPABILITY_FROM_DSL_REFUSED: DSL_FEATURE_DRIFT at line 11: SCENARIO_STEP_NOT_IN_FEATURE: the result holds the value',@drift,CASE WHEN ISNULL(@drift,N'')=N'CAPABILITY_FROM_DSL_REFUSED: DSL_FEATURE_DRIFT at line 11: SCENARIO_STEP_NOT_IN_FEATURE: the result holds the value' THEN 1 ELSE 0 END);
INSERT #dsl06_check_rows(area,item,expected,actual,passed) VALUES(N'author path',N'nothing of the probe declaration remains',CONVERT(nvarchar(10),@before),CONVERT(nvarchar(10),@after),CASE WHEN @after=@before THEN 1 ELSE 0 END);
GO
SELECT N'checks' AS result_set,o,area,item,expected,actual,passed FROM #dsl06_check_rows ORDER BY o;
SELECT N'verdict' AS result_set,CASE WHEN COUNT(*)=SUM(CONVERT(int,passed)) THEN N'PASSED' ELSE N'FAILED' END AS verdict,COUNT(*) AS checks,SUM(CONVERT(int,passed)) AS passed FROM #dsl06_check_rows;
DROP PROCEDURE IF EXISTS #dsl06_apply;
DROP PROCEDURE IF EXISTS #dsl06_compile;
DROP PROCEDURE IF EXISTS #dsl06_check;
GO
SET NOEXEC OFF;
