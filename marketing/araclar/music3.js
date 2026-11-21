// Hızlı/eğlenceli Reels müziği: 128 BPM, Do majör (C–G–Am–F), 36 vuruş. Efektler aynı ızgarada.
const fs = require('fs');
const SR = 44100, BPM = 128, B = 60 / BPM, BEATS = 36, DUR = BEATS * B, N = Math.ceil(SR * DUR);
const S = { hook: 0, comp: 4, share: 10, deck: 12, prof: 20, streak: 28, end: 32 };
const L = new Float32Array(N), R = new Float32Array(N), SEND = new Float32Array(N);
const midi = (m) => 440 * Math.pow(2, (m - 69) / 12);
let seed = 5; const rnd = () => { seed = (seed * 16807) % 2147483647; return seed / 2147483647 * 2 - 1; };
function add(t0, len, fn, gain = 1, pan = 0, send = 0) {
  const s0 = Math.floor(t0 * SR), n = Math.floor(len * SR);
  const gl = gain * Math.cos((pan + 1) * Math.PI / 4), gr = gain * Math.sin((pan + 1) * Math.PI / 4);
  for (let i = 0; i < n; i++) { const k = s0 + i; if (k < 0 || k >= N) continue; const v = fn(i / SR); L[k] += v * gl; R[k] += v * gr; SEND[k] += v * gain * send; }
}
const at = (b) => b * B;
const kick = (t, g = .6) => add(t, .35, (x) => Math.sin(2 * Math.PI * (48 * x + 90 * (1 - Math.exp(-x * 35)) / 35)) * Math.exp(-x * 9), g);
const clap = (t, g = .16) => add(t, .22, (x) => rnd() * (Math.exp(-x * 25) + .5 * Math.exp(-Math.abs(x - .012) * 300)), g, 0, .3);
const hat = (t, g = .05, p = .3) => add(t, .05, (x) => rnd() * Math.exp(-x * 90), g, p);
const pluck = (f) => (x) => Math.min(1, x * 800) * Math.exp(-x * 9) * ((2 / Math.PI) * Math.asin(Math.sin(2 * Math.PI * f * x)) * .7 + .3 * Math.sin(4 * Math.PI * f * x));
const bell = (f) => (x) => Math.min(1, x * 900) * Math.exp(-x * 5) * (Math.sin(2 * Math.PI * f * x) + .4 * Math.sin(2 * Math.PI * f * 2.76 * x) * Math.exp(-x * 8));
function whoosh(t, len, g, pan = 0) { let lp = 0; add(t, len, (x) => { const p = x / len; lp += (.02 + .4 * Math.sin(Math.PI * p)) * (rnd() - lp); return lp * Math.sin(Math.PI * p); }, g, pan, .2); }
const blip = (t, m, g = .12) => add(t, .18, (x) => Math.sin(2 * Math.PI * midi(m) * x * (1 + .5 * Math.exp(-x * 40))) * Math.exp(-x * 18), g, 0, .3);

const CH = [[60, 64, 67], [55, 59, 62], [57, 60, 64], [53, 57, 60]]; // C G Am F
const chordAt = (b) => CH[Math.floor(b / 4) % 4];

// ---- kanca: üç çarpışma (kelimeler), sonra ritim girer
[0, 1, 2].forEach((b) => {
  add(at(b), .5, (x) => Math.sin(2 * Math.PI * (40 * x + 80 * (1 - Math.exp(-x * 30)) / 30)) * Math.exp(-x * 6), .75);
  clap(at(b), .22);
  add(at(b), .4, pluck(midi([72, 76, 79][b])), .12, 0, .4);
});
whoosh(at(3), B, .3);

// ---- ritim: 4..32 (dörtlük kick, 2-4 clap, sekizlik hat), seri bölümünde coşkulu
for (let b = 4; b < 32; b++) {
  const t = at(b), ch = chordAt(b);
  kick(t, b >= S.streak ? .7 : .6);
  if (b % 2 === 1) clap(t);
  hat(t + B / 2, .06, .35); hat(t + B / 4, .025, -.35); hat(t + 3 * B / 4, .025, -.35);
  // bas: ara vuruşta (house hissi)
  add(t + B / 2, B * .45, (x) => Math.sin(2 * Math.PI * midi(ch[0] - 24) * x) * Math.min(1, x * 200) * Math.exp(-x * 5), .32);
  // akor pluck: sekizlik
  for (let s = 0; s < 2; s++) ch.forEach((m, k) => add(t + s * B / 2, .3, pluck(midi(m + 12)), .035, (k - 1) * .4, .3));
  // melodi: her ölçüde kısa motif
  if (b % 4 === 0) [ch[2] + 12, ch[1] + 12, ch[2] + 12, ch[0] + 24].forEach((m, i) => add(t + i * B * .75, .5, bell(midi(m)), .05, .2, .5));
}
// ---- efektler
// renk değişimleri: yükselen blipler
[S.comp + 3, S.comp + 4, S.comp + 5].forEach((b, i) => blip(at(b), 79 + i * 3, .1));
// yazma tıkları
for (let i = 0; i < 16; i++) add(at(S.comp + .2) + i * .07, .03, (x) => rnd() * Math.exp(-x * 220), .05, rnd() * .3);
// Paylaş: dokunuş + fırlama
blip(at(S.share), 72, .14); whoosh(at(S.share + .9), B * 1.2, .35, .3);
// deste: her kaydırmada vuuş
[S.deck + 1, S.deck + 2, S.deck + 3].forEach((b) => whoosh(at(b) - .03, .3, .3, -.5));
// kalp patlaması: parlak akor + pıtırtı
[84, 88, 91, 96].forEach((m, i) => add(at(S.deck + 4) + i * .03, .8, bell(midi(m)), .07, (i - 1.5) * .3, .6));
for (let i = 0; i < 10; i++) add(at(S.deck + 4) + .05 + i * .045, .05, (x) => Math.sin(2 * Math.PI * midi(96 + (i % 5)) * x) * Math.exp(-x * 60), .035, rnd() * .6);
// geçişler
[S.comp, S.deck, S.prof, S.streak].forEach((b) => whoosh(at(b) - .15, .35, .22));
// bildirim zilleri: yükselen dizi
for (let i = 0; i < 6; i++) add(at(S.prof + 1 + i * .75), .5, bell(midi([84, 86, 88, 91, 93, 96][i])), .09, (i % 2 ? .3 : -.3), .4);
// seri sayacı: tık tık yükselen
for (let i = 0; i < 23; i++) { const p = i / 22; add(at(S.streak + .6) + (1 - Math.pow(1 - p, 3)) * at(2.6), .03, (x) => Math.sin(2 * Math.PI * (1200 + i * 40) * x) * Math.exp(-x * 120), .045); }
// kapanış: büyük vuruş + akor
kick(at(S.end), .85); clap(at(S.end), .25);
[48, 60, 64, 67, 72, 76].forEach((m, k) => add(at(S.end), 2.2, (x) => (Math.sin(2 * Math.PI * midi(m) * x) + .3 * Math.sin(4 * Math.PI * midi(m) * x)) * Math.min(1, x * 300) * Math.exp(-x * 1.6), .07, (k - 2.5) * .25, .5));
'memento'.split('').forEach((_, i) => add(at(S.end + i * .14), .15, pluck(midi(72 + [0, 2, 4, 7, 9, 12, 16][i])), .07, (i - 3) * .2, .4));

// yankı (kısa oda)
function reverb(src, combs) {
  const out = new Float32Array(N);
  combs.forEach((d) => { const n = Math.floor(d * SR), buf = new Float32Array(n); let idx = 0, lp = 0;
    for (let i = 0; i < N; i++) { const y = buf[idx]; lp = y * .55 + lp * .45; buf[idx] = src[i] + lp * .72; out[i] += y * .25; idx = (idx + 1) % n; } });
  return out;
}
const rvL = reverb(SEND, [.0253, .0313, .0371, .0411]), rvR = reverb(SEND, [.0269, .0331, .0389, .0427]);
let peak = 0; const mL = new Float32Array(N), mR = new Float32Array(N);
for (let i = 0; i < N; i++) { mL[i] = L[i] + rvL[i] * .4; mR[i] = R[i] + rvR[i] * .4; peak = Math.max(peak, Math.abs(mL[i]), Math.abs(mR[i])); }
const norm = .9 / peak;
const buf = Buffer.alloc(44 + N * 4);
buf.write('RIFF', 0); buf.writeUInt32LE(36 + N * 4, 4); buf.write('WAVE', 8); buf.write('fmt ', 12); buf.writeUInt32LE(16, 16);
buf.writeUInt16LE(1, 20); buf.writeUInt16LE(2, 22); buf.writeUInt32LE(SR, 24); buf.writeUInt32LE(SR * 4, 28); buf.writeUInt16LE(4, 32); buf.writeUInt16LE(16, 34);
buf.write('data', 36); buf.writeUInt32LE(N * 4, 40);
for (let i = 0; i < N; i++) {
  const fade = Math.min(1, (N - i) / (.5 * SR)) * Math.min(1, i / (.01 * SR));
  const s = (v) => Math.round(Math.tanh(v * norm * 1.15) * fade * 32767);
  buf.writeInt16LE(s(mL[i]), 44 + i * 4); buf.writeInt16LE(s(mR[i]), 46 + i * 4);
}
fs.writeFileSync(process.argv[2], buf);
console.log('müzik', DUR.toFixed(3), 'sn');
