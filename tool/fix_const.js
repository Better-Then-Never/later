// Removes `const` keywords that enclose values which are no longer constant
// (for example colours that became `context.palette.*`).
//
//   flutter analyze > analyze.txt; node tool/fix_const.js analyze.txt
//
// For each `invalid_constant`, `non_constant_list_element`,
// `const_with_non_constant_argument`, `non_constant_map_value` or
// `const_eval_method_invocation` error it finds the innermost `const` whose
// bracketed expression encloses the error position and deletes it. Run analyze
// again afterwards: removing an inner `const` can uncover an outer one.
const fs = require('fs');

const codes = [
  'invalid_constant',
  'non_constant_list_element',
  'const_with_non_constant_argument',
  'non_constant_map_value',
  'const_eval_method_invocation',
  'non_constant_default_value',
];
const lines = fs.readFileSync(process.argv[2], 'utf8').split(/\r?\n/);
const byFile = new Map();
for (const line of lines) {
  const m = line.match(/error - .* - (.+\.dart):(\d+):(\d+) - (\w+)/);
  if (!m || !codes.includes(m[4])) continue;
  const file = m[1].replace(/\\/g, '/');
  if (!byFile.has(file)) byFile.set(file, []);
  byFile.get(file).push([Number(m[2]), Number(m[3])]);
}

function matchClose(s, open) {
  const pairs = { '(': ')', '[': ']', '{': '}' };
  const want = pairs[s[open]];
  let depth = 0;
  for (let i = open; i < s.length; i++) {
    const c = s[i];
    if (c === "'" || c === '"') {
      // skip string literal
      const q = c;
      i++;
      while (i < s.length && s[i] !== q) { if (s[i] === '\\') i++; i++; }
      continue;
    }
    if (c === s[open]) depth++;
    else if (c === want) { depth--; if (depth === 0) return i; }
  }
  return -1;
}

let removed = 0;
for (const [file, positions] of byFile) {
  let s = fs.readFileSync(file, 'utf8');
  const crlf = s.includes('\r\n');
  s = s.replace(/\r\n/g, '\n');
  const lineStarts = [0];
  for (let i = 0; i < s.length; i++) if (s[i] === '\n') lineStarts.push(i + 1);
  const targets = new Set();
  for (const [line, col] of positions) {
    const pos = lineStarts[line - 1] + col - 1;
    const re = /\bconst\s+/g;
    let best = -1;
    let m;
    while ((m = re.exec(s)) && m.index < pos) {
      // The bracket that opens this const expression.
      let j = m.index + m[0].length;
      while (j < s.length && !'([{'.includes(s[j]) && s[j] !== ';' && s[j] !== ',') j++;
      if (!'([{'.includes(s[j])) continue;
      const close = matchClose(s, j);
      if (close > pos) best = m.index; // innermost enclosing wins (later index)
    }
    if (best >= 0) targets.add(best);
  }
  const sorted = [...targets].sort((a, b) => b - a);
  for (const t of sorted) {
    const m = /\bconst\s+/.exec(s.slice(t));
    s = s.slice(0, t) + s.slice(t + m[0].length);
    removed++;
  }
  if (crlf) s = s.replace(/\n/g, '\r\n');
  fs.writeFileSync(file, s);
}
console.log(`removed ${removed} const keyword(s) in ${byFile.size} file(s)`);
