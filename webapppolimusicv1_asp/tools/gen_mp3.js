// Genera las 4 pistas MP3 que faltan recortando segmentos distintos
// del unico mp3 disponible en los assets (SongFiles/bensound-adventure.mp3).
// Los archivos resultantes son MP3 reales (frames de audio validos) con su ID3 tag.
const fs = require('fs');
const path = require('path');

const SRC = path.join(__dirname, '..', 'SongFiles', 'bensound-adventure.mp3');
const OUT = path.join(__dirname, '..', 'SongFiles');

// el material origen dura ~187 s: se reparten desplazamientos distintos
const plan = {
  'bensound-dreams.mp3':   { start: 2,   secs: 75 },
  'bensound-energy.mp3':   { start: 42,  secs: 70 },
  'bensound-scifi.mp3':    { start: 92,  secs: 70 },
  'bensound-tomorrow.mp3': { start: 112, secs: 70 }
};

const TITLES = {
  'bensound-dreams.mp3':   'Dreams',
  'bensound-energy.mp3':   'Energy',
  'bensound-scifi.mp3':    'Scifi',
  'bensound-tomorrow.mp3': 'Tomorrow'
};

function readFrames(buf) {
  // salta cabecera ID3v2 si existe
  let off = 0;
  if (buf.length > 10 && buf.slice(0, 3).toString('latin1') === 'ID3') {
    const size = ((buf[6] & 0x7f) << 21) | ((buf[7] & 0x7f) << 14) | ((buf[8] & 0x7f) << 7) | (buf[9] & 0x7f);
    off = 10 + size;
  }
  const bitrates = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0];
  const rates = [44100, 48000, 32000, 0];
  const frames = [];
  while (off + 4 <= buf.length) {
    if (buf[off] === 0xff && (buf[off + 1] & 0xe0) === 0xe0) {
      const header = (buf[off] << 24) | (buf[off + 1] << 16) | (buf[off + 2] << 8) | buf[off + 3];
      const version = (buf[off + 1] >> 3) & 3;      // 3 = MPEG1
      const layer = (buf[off + 1] >> 1) & 3;        // 1 = Layer III
      const brIdx = (buf[off + 2] >> 4) & 0xf;
      const srIdx = (buf[off + 2] >> 2) & 3;
      const padding = ((buf[off + 2] >> 1) & 1) === 1;
      if ((version === 3 || version === 2) && layer === 1 && bitrates[brIdx] > 0 && rates[srIdx] > 0) {
        const bitrate = bitrates[brIdx] * 1000;
        const sampleRate = rates[srIdx] >> (version === 2 ? 1 : 0);
        const spf = version === 3 ? 1152 : 576;     // samples per frame (Layer III)
        const len = Math.floor((spf / 8) * bitrate / sampleRate) + (padding ? 1 : 0);
        if (off + len <= buf.length) {
          frames.push({ off, len, spf, sampleRate });
          off += len;
          continue;
        }
      }
    }
    off++;
  }
  return frames;
}

function buildId3(title) {
  // ID3v2.3 con un frame TIT2 (titulo de la pista)
  const text = Buffer.from(title, 'utf8');
  const body = Buffer.alloc(text.length + 1);
  body[0] = 0x00;                    // UTF-8
  text.copy(body, 1);
  const frame = Buffer.concat([Buffer.from('TIT2'), Buffer.from([0, 0, 0, 0, 0, 0, body.length >> 16 & 0x7f, body.length & 0x7f]), body]);
  const size = frame.length;
  const header = Buffer.from([0x49, 0x44, 0x33, 0x03, 0x00, 0x00]);
  const sizeBytes = Buffer.from([(size >> 21) & 0x7f, (size >> 14) & 0x7f, (size >> 7) & 0x7f, size & 0x7f]);
  return Buffer.concat([header, sizeBytes, frame]);
}

const src = fs.readFileSync(SRC);
const frames = readFrames(src);
console.log('frames detectados:', frames.length);
const perSecond = frames[0].sampleRate / frames[0].spf;
console.log('duracion aprox del origen:', (frames.length / perSecond).toFixed(1), 's');

for (const [file, cfg] of Object.entries(plan)) {
  const from = Math.floor(cfg.start * perSecond);
  const count = Math.floor(cfg.secs * perSecond);
  if (from + count > frames.length) {
    console.error('No hay suficientes frames para', file);
    continue;
  }
  const parts = [buildId3(TITLES[file])];
  for (let i = from; i < from + count; i++) {
    parts.push(src.slice(frames[i].off, frames[i].off + frames[i].len));
  }
  const out = Buffer.concat(parts);
  fs.writeFileSync(path.join(OUT, file), out);
  console.log('creado', file, cfg.secs, 's', (out.length / 1024).toFixed(0), 'KB');
}
