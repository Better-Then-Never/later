// Lists message keys that no Dart file in lib/ or test/ uses.
//   node tool/l10n/unused_keys.js
const fs = require('fs');
const path = require('path');

const en = JSON.parse(fs.readFileSync('lib/l10n/app_en.arb', 'utf8'));
const keys = Object.keys(en).filter((k) => !k.startsWith('@'));

function walk(dir, out) {
  for (const f of fs.readdirSync(dir)) {
    const p = path.join(dir, f);
    if (fs.statSync(p).isDirectory()) {
      if (!p.endsWith(path.join('l10n', 'gen'))) walk(p, out);
    } else if (p.endsWith('.dart')) {
      out.push(fs.readFileSync(p, 'utf8'));
    }
  }
  return out;
}

const source = [...walk('lib', []), ...walk('test', [])].join('\n');
const unused = keys.filter((k) => !new RegExp(`\\b${k}\\b`).test(source));
console.log(unused.length ? unused.join('\n') : 'none');
