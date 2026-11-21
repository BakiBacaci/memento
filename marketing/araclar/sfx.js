// Kaydırma sesleri: beğeni (olumlu) ve geç (olumsuz) için üçer örnek.
const fs = require('fs');
const path = require('path');
const SR = 44100;
const out = process.argv[2];
fs.mkdirSync(out, { recursive: true });
const midi = (m) => 440 * Math.pow(2, (m - 69) / 12);
let seed = 9; const rnd = () => { seed = (seed * 16807) % 2147483647; return seed / 2147483647 * 2 - 1; };

function render(name, len, fn) {
  const n = Math.floor(len * SR), d = new Float32Array(n);
  for (let i = 0; i < n; i++) d[i] = fn(i / SR);
  let peak = 0; d.forEach((v) => { peak = Math.max(peak, Math.abs(v)); });
  const g = .6 / peak;
  const buf = Buffer.alloc(44 + n * 2);
  buf.write('RIFF', 0); buf.writeUInt32LE(36 + n * 2, 4); buf.write('WAVE', 8); buf.write('fmt ', 12);
  buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(1, 22); buf.writeUInt32LE(SR, 24);
  buf.writeUInt32LE(SR * 2, 28); buf.writeUInt16LE(2, 32); buf.writeUInt16LE(16, 34); buf.write('data', 36); buf.writeUInt32LE(n * 2, 40);
  for (let i = 0; i < n; i++) {
    const fade = Math.min(1, (n - i) / (SR * .01));
    buf.writeInt16LE(Math.round(Math.tanh(d[i] * g) * fade * 32767), 44 + i * 2);
  }
  fs.writeFileSync(path.join(out, name + '.wav'), buf);
}
const bell = (f, x, dec = 6) => Math.min(1, x * 1200) * Math.exp(-x * dec) * (Math.sin(2 * Math.PI * f * x) + .35 * Math.sin(2 * Math.PI * f * 2.76 * x) * Math.exp(-x * 14));
const mar = (f, x) => Math.min(1, x * 1500) * Math.exp(-x * 14) * (Math.sin(2 * Math.PI * f * x) + .5 * Math.sin(2 * Math.PI * f * 4 * x) * Math.exp(-x * 40));

// OLUMLU
render('begen-1-cin', .7, (x) => bell(midi(84), x) + (x > .07 ? bell(midi(91), x - .07) : 0));                       // iki notalı çın
render('begen-2-marimba', .5, (x) => mar(midi(76), x) + .6 * (x > .055 ? mar(midi(83), x - .055) : 0));              // tahta marimba
render('begen-3-parilti', .8, (x) => [0, .045, .09].reduce((a, d, i) => a + (x > d ? bell(midi([84, 88, 91][i]), x - d, 7) * (1 - i * .15) : 0), 0) + .05 * rnd() * Math.exp(-x * 30)); // parıltı arpej
// OLUMSUZ
let lp = 0;
render('gec-1-vuus', .28, (x) => { const p = x / .28; lp += (.03 + .35 * Math.sin(Math.PI * p)) * (rnd() - lp); return lp * Math.sin(Math.PI * p); }); // yumuşak hava
render('gec-2-tik', .18, (x) => Math.min(1, x * 2000) * Math.exp(-x * 45) * (Math.sin(2 * Math.PI * 620 * x) + .4 * Math.sin(2 * Math.PI * 1460 * x)));   // tahta tık
render('gec-3-inis', .45, (x) => mar(midi(74), x) * .8 + .6 * (x > .06 ? mar(midi(67), x - .06) : 0));              // alçalan iki nota
console.log('ok');
