// Builds the MapLibre map styles (assets/map/style_light.json,
// style_dark.json) from OpenFreeMap's Positron and Dark styles, recoloured
// with the app's own map palette (the Google styles in
// lib/features/map/map_styles.dart, F-15/D-22): green parks, blue water, white
// roads, soft greys; tiles, fonts and sprites stay OpenFreeMap's.
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

// The app's palette (map_styles.dart), by what a layer draws.
const LIGHT = {
  background: '#f3f3f0',
  park: '#c9e9b6',
  wood: '#d7ecc7',
  water: '#a9d3f2',
  waterLabel: '#3f74a8',
  residential: '#eeeeeb',
  building: '#e7e7e3',
  roadMinor: '#ffffff',
  roadMajor: '#ffffff',
  roadCasing: '#e2e2e2',
  motorway: '#f6f6f6',
  motorwayCasing: '#d9d9d9',
  rail: '#e6e6e6',
  label: '#333333',
  labelMinor: '#7a7a7a',
  boundary: '#cfcfcf',
};
const DARK = {
  background: '#1b1b1b',
  park: '#1e3a1c',
  wood: '#1d2a1c',
  water: '#16263a',
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
