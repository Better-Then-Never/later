// Builds the MapLibre map styles (assets/map/style_light.json,
// style_dark.json) from OpenFreeMap's Positron and Dark styles, recoloured
// from the app's colour tokens (lib/core/theme/app_colors.dart): the ground is
// the map's own ground colour, parks and woods the brand green and water the
// info blue mixed into it (calm, never a saturated ocean), roads white on
// the ground (low contrast, so capsules stand out), soft grey labels. Tiles,
// fonts (Noto Sans: Latin and Cyrillic) and sprites stay OpenFreeMap's.
// test/features/map_style_test.dart checks the files against the tokens.
//
//   node tool/map/make_map_style.js
//
// The tile source is an owner decision (docs/map/DECISION.md): to move to
// another provider, change BASE and the source URLs below.
const fs = require('fs');
const https = require('https');
const path = require('path');

const BASE = 'https://tiles.openfreemap.org/styles/';
const OUT = path.join(__dirname, '..', '..', 'assets', 'map');

function get(url) {
  return new Promise((resolve, reject) => {
    https
      .get(url, (res) => {
        let data = '';
        res.on('data', (c) => (data += c));
        res.on('end', () => resolve(JSON.parse(data)));
      })
      .on('error', reject);
  });
}

// The app's tokens (AppColors) the map's colours are mixed from.
const TOKENS = {
  brandGreen: '#56c92e',
  infoBlue: '#2196f3',
  groundLight: '#f3f3f0',
  groundDark: '#1b1b1b',
};

// [a] mixed into [b], [share] of [a] (the test mixes the same way).
function mix(a, b, share) {
  const ch = (hex, i) => parseInt(hex.slice(1 + 2 * i, 3 + 2 * i), 16);
  const out = [0, 1, 2].map((i) =>
    Math.round(ch(a, i) * share + ch(b, i) * (1 - share))
      .toString(16)
      .padStart(2, '0'),
  );
  return '#' + out.join('');
}

// How much of a token goes into the ground, by what a layer draws.
const SHARES = {
  light: { park: 0.26, wood: 0.14, water: 0.18 },
  dark: { park: 0.2, wood: 0.1, water: 0.14 },
};

// The map's palette, by what a layer draws.
const LIGHT = {
  background: TOKENS.groundLight,
  park: mix(TOKENS.brandGreen, TOKENS.groundLight, SHARES.light.park),
  wood: mix(TOKENS.brandGreen, TOKENS.groundLight, SHARES.light.wood),
  water: mix(TOKENS.infoBlue, TOKENS.groundLight, SHARES.light.water),
  waterLabel: '#5b84ab',
  residential: '#eeeeeb',
  building: '#e7e7e3',
  roadMinor: '#ffffff',
  roadMajor: '#ffffff',
  roadCasing: '#e2e2e2',
  motorway: '#f6f6f6',
  motorwayCasing: '#d9d9d9',
  rail: '#e6e6e6',
  label: '#444444',
  labelMinor: '#808080',
  boundary: '#cfcfcf',
};
const DARK = {
  background: TOKENS.groundDark,
  park: mix(TOKENS.brandGreen, TOKENS.groundDark, SHARES.dark.park),
  wood: mix(TOKENS.brandGreen, TOKENS.groundDark, SHARES.dark.wood),
  water: mix(TOKENS.infoBlue, TOKENS.groundDark, SHARES.dark.water),
  waterLabel: '#6f9ccc',
  residential: '#212121',
  building: '#262626',
  roadMinor: '#2e2e2e',
  roadMajor: '#333333',
  roadCasing: '#1a1a1a',
  motorway: '#3d3d3d',
  motorwayCasing: '#262626',
  rail: '#2a2a2a',
  label: '#d6d6d6',
  labelMinor: '#8c8c8c',
  boundary: '#3a3a3a',
};

function colourFor(id, type, p) {
  if (type === 'background') return ['background-color', p.background];
  if (/park/.test(id)) return ['fill-color', p.park];
  if (/wood|grass|landcover(?!_ice|_glacier)/.test(id) && type === 'fill') return ['fill-color', p.wood];
  if (/^water$/.test(id) && type === 'fill') return ['fill-color', p.water];
  if (/waterway/.test(id) && type === 'line') return ['line-color', p.water];
  if (/residential/.test(id)) return ['fill-color', p.residential];
  if (/^building/.test(id) && type === 'fill') return ['fill-color', p.building];
  if (/motorway.*casing/.test(id)) return ['line-color', p.motorwayCasing];
  if (/motorway.*(inner|subtle)/.test(id)) return ['line-color', p.motorway];
  if (/highway_major_casing/.test(id)) return ['line-color', p.roadCasing];
  if (/highway_major_(inner|subtle)/.test(id)) return ['line-color', p.roadMajor];
  if (/highway_(minor|path)/.test(id)) return ['line-color', p.roadMinor];
  if (/railway(?!.*dash)/.test(id)) return ['line-color', p.rail];
  if (/boundary/.test(id)) return ['line-color', p.boundary];
  if (type === 'symbol' && /water/.test(id)) return ['text-color', p.waterLabel];
  if (type === 'symbol' && /highway|road|airport|other|suburb|village/.test(id)) {
    return ['text-color', p.labelMinor];
  }
  if (type === 'symbol' && /label|place/.test(id)) return ['text-color', p.label];
  return null;
}

async function build(source, palette, name) {
  const style = await get(BASE + source);
  style.name = `Later ${name}`;
  // No style transitions: MapLibre faded every symbol it newly placed in
  // over 300 ms (pins and bubbles flashed see-through while zooming, old
  // tiles faded out as ghosts), and eased every paint change the app makes
  // (the selected pin lagged its own motion). The app animates its markers
  // itself (docs/map/FLASH_FIX.md).
  style.transition = { duration: 0, delay: 0 };
  for (const layer of style.layers) {
    const c = colourFor(layer.id, layer.type, palette);
    if (!c) continue;
    layer.paint = layer.paint || {};
    layer.paint[c[0]] = c[1];
    if (layer.type === 'symbol') {
      layer.paint['text-halo-color'] = palette.background;
    }
  }
  fs.mkdirSync(OUT, { recursive: true });
  fs.writeFileSync(path.join(OUT, `style_${name}.json`), JSON.stringify(style));
  console.log(`assets/map/style_${name}.json: ${style.layers.length} layers`);
}

(async () => {
  await build('positron', LIGHT, 'light');
  await build('dark', DARK, 'dark');
})();
