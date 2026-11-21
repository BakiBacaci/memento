// Gece sinematik Reels müziği: 24 sn, 90 BPM, La minör. Tek parça: müzik + efektler + yankı.
const fs = require('fs');
const SR = 44100, DUR = 24, N = SR * DUR;
const B = 60 / 90;
const T = { A: 0, B: 4 * B, C: 9 * B, D: 16 * B, E: 20 * B, F: 26 * B, G: 30 * B, END: 36 * B };
const L = new Float32Array(N), R = new Float32Array(N), SEND = new Float32Array(N);
const midi = (m) => 440 * Math.pow(2, (m - 69) / 12);
let seed = 3;
const rnd = () => { seed = (seed * 16807) % 2147483647; return seed / 2147483647 * 2 - 1; };

function add(t0, len, fn, gain = 1, pan = 0, send = 0) {
  const s0 = Math.floor(t0 * SR), n = Math.floor(len * SR);
  const gl = gain * Math.cos((pan + 1) * Math.PI / 4), gr = gain * Math.sin((pan + 1) * Math.PI / 4);
  for (let i = 0; i < n; i++) {
    const k = s0 + i;
    if (k < 0 || k >= N) continue;
    const v = fn(i / SR);
    L[k] += v * gl; R[k] += v * gr; SEND[k] += v * gain * send;
  }
}
// Piyano benzeri: birkaç harmonik, hızlı atak, yavaş sönüm
const piano = (f) => (x) => {
  const env = Math.min(1, x * 400) * Math.exp(-x * 2.2);
  return (Math.sin(2 * Math.PI * f * x) + .45 * Math.sin(4 * Math.PI * f * x) * Math.exp(-x * 3)
    + .2 * Math.sin(6 * Math.PI * f * x) * Math.exp(-x * 5)) * env;
};
const pluck = (f) => (x) => Math.min(1, x * 600) * Math.exp(-x * 7) *
  ((2 / Math.PI) * Math.asin(Math.sin(2 * Math.PI * f * x)) * .7 + .3 * Math.sin(4 * Math.PI * f * x));
function pad(t0, len, notes, gain, bright = 0) {
  notes.forEach((m, k) => add(t0, len, (x) => {
    const f = midi(m);
    const env = Math.min(1, x / .8) * Math.min(1, (len - x) / .9);
    const det = Math.sin(2 * Math.PI * f * 1.003 * x) + Math.sin(2 * Math.PI * f * .997 * x);
    return (det * .5 + bright * .25 * Math.sin(4 * Math.PI * f * x)) * env;
  }, gain, (k - (notes.length - 1) / 2) * .45, .5));
}
const kick = (t, g = .5) => add(t, .45, (x) => Math.sin(2 * Math.PI * (42 * x + 70 * (1 - Math.exp(-x * 28)) / 28)) * Math.exp(-x * 7), g);
function noiseSweep(t0, len, g, up = true, pan = 0, send = .3) {
  let lp = 0;
  add(t0, len, (x) => {
    const p = x / len;
    const a = up ? .01 + .5 * p * p : .5 * (1 - p) + .01;
    lp += a * (rnd() - lp);
    return lp * (up ? p : Math.sin(Math.PI * p));
  }, g, pan, send);
}
const click = (t, g = .05, f = 2400) => add(t, .03, (x) => (rnd() * .6 + Math.sin(2 * Math.PI * f * x)) * Math.exp(-x * 220), g, (rnd()) * .3, .1);

// Akorlar
const Am = [57, 60, 64, 71], F = [53, 57, 60, 67], C = [48, 55, 60, 64], G = [55, 59, 62, 69];

// ---- A: karanlık, alçak drone + saat tıkırtısı + yazı
add(0, T.B + .5, (x) => (Math.sin(2 * Math.PI * midi(33) * x) + .4 * Math.sin(2 * Math.PI * midi(40) * x)) * Math.min(1, x / 1.2), .12, 0, .2);
for (let b = 0; b < 4; b++) click(b * B, .025, 3200);
for (let k = 1; k <= 11; k++) click(.35 + k * .1, .06, 1800 + (k % 3) * 300);
noiseSweep(T.B - .9, 1.1, .35, true, 0, .5); // karanlığa dalış

// ---- B: ped + seyrek piyano
pad(T.B, T.C - T.B + .6, Am, .05);
[[0, 69], [1.5, 76], [3, 72], [4, 71]].forEach(([b, m]) => add(T.B + b * B, 3, piano(midi(m)), .1, .2, .6));

// ---- C: piyano arpejleri, yazı tıkırtısı, yükselen gerilim
const cChords = [F, C, G];
for (let b = 0; b < 7; b++) {
  const ch = cChords[Math.floor(b / 2.67) % 3];
  add(T.C + b * B, 2.5, piano(midi(ch[0] + 12)), .07, -.25, .55);
  add(T.C + b * B + B / 2, 2, piano(midi(ch[2] + 12)), .055, .25, .55);
}
pad(T.C, T.D - T.C, F, .045);
for (let k = 0; k < 18; k++) click(T.C + 1.3 + k * .09, .045, 2000 + (k % 4) * 250);
click(T.D - .45, .09, 1400);                       // Paylaş'a dokunuş
noiseSweep(T.D - 1.6, 1.6, .45, true, 0, .4);       // yükselen
add(T.D - 1.6, 1.6, (x) => Math.sin(2 * Math.PI * (200 * x + 300 * x * x)) * (x / 1.6) * .5, .06, 0, .3);

// ---- D: patlama
kick(T.D, .9);
add(T.D, 2.5, (x) => Math.sin(2 * Math.PI * midi(33) * x) * Math.exp(-x * 1.4), .35, 0, .2);
noiseSweep(T.D, .9, .4, false, 0, .6);
pad(T.D, T.F - T.D, Am, .06, 1);
// ritim: D..F
const dropChords = [Am, F, C, G];
for (let b = 16; b < 26; b++) {
  const t = b * B;
  const ch = dropChords[Math.floor((b - 16) / 4) % 4];
  if (b > 16) kick(t, .42);
  if (b % 2 === 1) add(t, .2, (x) => rnd() * Math.exp(-x * 30), .08, -.1, .3); // snap
  add(t + B / 2, .05, (x) => rnd() * Math.exp(-x * 80), .035, .4);             // hi-hat
  add(t, B * .95, (x) => Math.sin(2 * Math.PI * midi(ch[0] - 12) * x) * Math.min(1, x * 80) * Math.exp(-x * 1.5), .2); // bas
  for (let s = 0; s < 4; s++) {                                                   // parıltılı arpej
    const m = ch[[0, 1, 2, 3][s]] + 12;
    add(t + s * B / 4, .35, pluck(midi(m)), .045, s % 2 ? .45 : -.45, .45);
  }
}
// E: savrulma, kart gelişi, kalp atışı, kaydet
noiseSweep(T.E - .2, .45, .35, false, .6, .3);
noiseSweep(T.E + .25, .4, .25, false, -.6, .3);
[T.E + 2 * B, T.E + 3 * B].forEach((t, i) => {
  add(t, .3, (x) => Math.sin(2 * Math.PI * 55 * x) * Math.exp(-x * 14), i ? .35 : .5);
  add(t + .16, .3, (x) => Math.sin(2 * Math.PI * 50 * x) * Math.exp(-x * 16), i ? .25 : .38);
});
click(T.E + 4 * B, .08, 1500);

// ---- F: incelir; bildirim çanları
pad(T.F, T.G - T.F + .5, C, .05);
[0, 1, 2].forEach((i) => {
  const t = T.F + .2 + i * B;
  [88, 91, 93].slice(i, i + 1).forEach((m) => {
    add(t, 1.2, (x) => (Math.sin(2 * Math.PI * midi(m) * x) + .3 * Math.sin(2 * Math.PI * midi(m + 12) * x)) * Math.min(1, x * 500) * Math.exp(-x * 4), .06, .2, .6);
  });
  add(t, 1.2, piano(midi([76, 79, 81][i])), .05, -.2, .5);
});

// ---- G: final akor
kick(T.G, .55);
pad(T.G, T.END - T.G, [45, 57, 64, 71, 72], .065, .6);
[57, 64, 71, 76, 83].forEach((m, k) => add(T.G + k * .07, 4, piano(midi(m)), .07, (k - 2) * .3, .7));
for (let i = 0; i < 7; i++) noiseSweep(T.G + .1 + i * .07, .25, .05, false, (i - 3) * .25, .2);
add(T.G + 1.5 * B * 1.5, 3, piano(midi(81)), .06, 0, .7);

// ---- Yankı: Schroeder (4 tarak + 2 tümgeçiren), sağ/sol ayrı gecikmeler
function reverb(src, combs, aps) {
  const out = new Float32Array(N);
  combs.forEach((d) => {
    const n = Math.floor(d * SR), buf = new Float32Array(n); let idx = 0, lp = 0;
    for (let i = 0; i < N; i++) {
      const y = buf[idx];
      lp = y * .6 + lp * .4;
      buf[idx] = src[i] + lp * .82;
      out[i] += y * .25;
      idx = (idx + 1) % n;
    }
  });
  aps.forEach((d) => {
    const n = Math.floor(d * SR), buf = new Float32Array(n); let idx = 0;
    for (let i = 0; i < N; i++) {
      const b = buf[idx], x = out[i];
      const y = -x + b;
      buf[idx] = x + b * .5;
      out[i] = y;
      idx = (idx + 1) % n;
    }
  });
  return out;
}
const rvL = reverb(SEND, [.0297, .0371, .0411, .0437], [.005, .0017]);
const rvR = reverb(SEND, [.0301, .0353, .0423, .0451], [.0051, .0019]);

let peak = 0;
const mixL = new Float32Array(N), mixR = new Float32Array(N);
for (let i = 0; i < N; i++) {
  mixL[i] = L[i] + rvL[i] * .55; mixR[i] = R[i] + rvR[i] * .55;
  peak = Math.max(peak, Math.abs(mixL[i]), Math.abs(mixR[i]));
}
const norm = .9 / peak;
const buf = Buffer.alloc(44 + N * 4);
buf.write('RIFF', 0); buf.writeUInt32LE(36 + N * 4, 4); buf.write('WAVE', 8);
buf.write('fmt ', 12); buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(2, 22);
buf.writeUInt32LE(SR, 24); buf.writeUInt32LE(SR * 4, 28); buf.writeUInt16LE(4, 32); buf.writeUInt16LE(16, 34);
buf.write('data', 36); buf.writeUInt32LE(N * 4, 40);
for (let i = 0; i < N; i++) {
  const fade = Math.min(1, (N - i) / (1.0 * SR)) * Math.min(1, i / (.05 * SR));
  const s = (v) => Math.round(Math.tanh(v * norm * 1.1) * fade * 32767);
  buf.writeInt16LE(s(mixL[i]), 44 + i * 4); buf.writeInt16LE(s(mixR[i]), 46 + i * 4);
}
fs.writeFileSync(process.argv[2], buf);
console.log('müzik yazıldı');
