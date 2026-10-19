// The numbers of one cold start from its device log (tool/dev/coldstart.sh):
//
//   node tool/dev/coldstart_report.js launch <n> <ttid ms> <logcat -v epoch file>
//   node tool/dev/coldstart_report.js medians <coldstart_*.txt>
//
// Times are milliseconds from Android's launch of the activity: the
// "Displayed ... +Nms" line, logged at the first frame, gives that moment
// (its time minus N); every LATERSTART mark is timed from it.
const fs = require('fs');

const columns = ['ttid', 'run', 'home', 'shell', 'streets', 'own', 'all', 'pins', 'full', 'jank', 'worst'];

function ms(text) {
  // "+1s234ms", "+987ms", "+2s"
  const m = /^\+(?:(\d+)s)?(?:(\d+)ms)?$/.exec(text.trim());
  return m ? (Number(m[1] || 0) * 1000 + Number(m[2] || 0)) : null;
}

function launch(n, ttid, file) {
  const lines = fs.readFileSync(file, 'utf8').split(/\r?\n/);
  const at = (line) => Number(line.trim().split(/\s+/)[0]) * 1000;
  let base = null;
  let fully = null;
  const marks = {};
  let frames = null;
  for (const line of lines) {
    let m = /Displayed com\.btn\.later\/\.MainActivity(?: for user \d+)?: (\+\S+)/.exec(line);
    if (m && base === null) base = at(line) - ms(m[1]);
    m = /Fully drawn com\.btn\.later\/\.MainActivity(?: for user \d+)?: (\+\S+)/.exec(line);
    if (m && fully === null) fully = ms(m[1]);
    m = /LATERSTART (\w+)(.*)$/.exec(line);
    if (!m) continue;
    if (m[1] === 'frames') {
      const f = Object.fromEntries([...m[2].matchAll(/(\w+)=([\d.]+)/g)].map((x) => [x[1], Number(x[2])]));
      frames = f;
    } else if (!(m[1] in marks)) {
      marks[m[1]] = at(line);
    }
  }
  const rel = (name) => (base === null || !(name in marks) ? null : Math.round(marks[name] - base));
  const row = {
    ttid: Number(ttid) || null,
    run: rel('run'),
    home: rel('home'),
    shell: rel('shell'),
    streets: rel('streets'),
    own: rel('data_own'),
    all: rel('data_all'),
    pins: rel('pins_first'),
    // Android's own number when it logged one, else the app's mark.
    full: fully ?? rel('full'),
    jank: frames ? frames.over8 : null,
    worst: frames ? frames.worst : null,
  };
  const extra = Object.keys(marks)
    .filter((k) => !['run', 'home', 'shell', 'streets', 'data_own', 'data_all', 'pins_first', 'full'].includes(k))
    .map((k) => `${k}=${rel(k)}`)
    .join(' ');
  // The slowest frames on the launch's clock (they are timed from 'dart').
  const slowRaw = /LATERSTART frames .* slow=(\S*)/.exec(lines.find((l) => l.includes('LATERSTART frames')) || '');
  const dart = rel('dart');
  const slow = slowRaw && slowRaw[1] && dart !== null
    ? slowRaw[1].split(',').map((s) => { const [t, br] = s.split(':'); return `${Number(t) + dart}:${br}`; }).join(' ')
    : '';
  console.log(
    `launch ${n}: ` + columns.map((c) => `${c} ${row[c] ?? '?'}`).join(', ') +
      (frames ? ` (of ${frames.n} frames)` : '') + (extra ? `  [${extra}]` : '') + (slow ? `  slow ${slow}` : ''),
  );
}

function medians(file) {
  const rows = fs
    .readFileSync(file, 'utf8')
    .split(/\r?\n/)
    .filter((l) => l.startsWith('launch '));
  const median = (values) => {
    const v = values.filter((x) => x !== null).sort((a, b) => a - b);
    return v.length ? v[Math.floor((v.length - 1) / 2)] : '?';
  };
  const parsed = rows.map((r) =>
    Object.fromEntries(
      columns.map((c) => {
        const m = new RegExp(`(?:: |, )${c} ([\\d.?]+)`).exec(r);
        return [c, m && m[1] !== '?' ? Number(m[1]) : null];
      }),
    ),
  );
  console.log(`median of ${rows.length}: ` + columns.map((c) => `${c} ${median(parsed.map((p) => p[c]))}`).join(', '));
}

const [mode, ...args] = process.argv.slice(2);
if (mode === 'launch') launch(...args);
else if (mode === 'medians') medians(...args);
else {
  console.error('usage: coldstart_report.js launch <n> <ttid> <log> | medians <file>');
  process.exit(64);
}
