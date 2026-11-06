// Reads the acceptance cases of a canonical feature written in the case format: each Scenario carries its tags, a
// json request under Given, and an operation | path | equals table under Then.
export function readCases(text) {
  const cases = [];
  let tags = [], current = null, docString = null;
  for (const raw of text.replace(/\r\n/g, "\n").split("\n")) {
    const line = raw.trim();
    if (docString !== null) {
      if (line === '"""') { current.request = JSON.parse(docString.join("\n")); docString = null; } else docString.push(raw);
      continue;
    }
    if (line === "" || line.startsWith("#")) continue;
    if (line.startsWith("@")) { tags.push(...line.split(/\s+/)); continue; }
    if (/^(Feature|Rule|Background):/.test(line)) { tags = []; continue; }
    if (/^Scenario( Outline)?:/.test(line)) {
      current = { name: line.replace(/^Scenario( Outline)?:\s*/, ""), tags, steps: [], then: [] };
      tags = [];
      cases.push(current);
      continue;
    }
    if (!current) continue;
    if (line.startsWith('"""')) { docString = []; continue; }
    if (line.startsWith("|")) {
      const cells = line.slice(1, -1).split("|").map((cell) => cell.trim());
      if (cells.join("|") !== "operation|path|equals") current.then.push(cells);
      continue;
    }
    current.steps.push(line);
  }
  return cases.map((c) => ({ ...c, caseId: (c.tags.find((t) => t.startsWith("@case:")) || "").slice(6),
    status: (c.tags.find((t) => t.startsWith("@status:")) || "").slice(8) }));
}

// The judge: a JSON path read, deep equality, and a Then cell as JSON or text, with (absent) selecting nothing.
export const at = (value, pointer) => pointer.replace(/^\$\.?/, "").split(/\.|\[(\d+)\]/).filter((x) => x !== undefined && x !== "")
  .reduce((node, key) => (node === undefined || node === null || typeof node !== "object" ? undefined : node[key]), value);
export function equal(a, b) {
  if (a === null || b === null || typeof a !== "object" || typeof b !== "object") return a === b;
  if (Array.isArray(a) !== Array.isArray(b)) return false;
  if (Array.isArray(a)) return a.length === b.length && a.every((x, i) => equal(x, b[i]));
  const ka = Object.keys(a).sort(), kb = Object.keys(b).sort();
  return ka.length === kb.length && ka.every((k, i) => k === kb[i] && equal(a[k], b[k]));
}
export function expected(cell) {
  if (cell === "(absent)") return { absent: true };
  try { return { value: JSON.parse(cell) }; } catch { return { value: cell }; }
}
