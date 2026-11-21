// 22 sn'lik müzik + efektler, tek parça olarak sentezlenir (WAV, 44.1 kHz stereo).
// 120 BPM, La minör, Am–F–C–G. Her şey ilk kareden sayılan aynı vuruş ızgarasında.
const fs = require('fs');
const SR = 44100, DUR = 22, N = SR * DUR;
const L = new Float32Array(N), R = new Float32Array(N);
const BEAT = 0.5, BAR = 2;
const midi = (m) => 440 * Math.pow(2, (m - 69) / 12);

function add(t0, len, fn, gain = 1, pan = 0) {
  const s0 = Math.floor(t0 * SR), n = Math.floor(len * SR);
  const gl = gain * Math.cos((pan + 1) * Math.PI / 4), gr = gain * Math.sin((pan + 1) * Math.PI / 4);
  for (let i = 0; i < n && s0 + i < N; i++) {
    if (s0 + i < 0) continue;
    const v = fn(i / SR);
    L[s0 + i] += v * gl; R[s0 + i] += v * gr;
  }
}
let seed = 7;
const rnd = () => { seed = (seed * 16807) % 2147483647; return seed / 2147483647 * 2 - 1; };

// Akorlar (kök, üçlü, beşli) — Am F C G, her biri 1 ölçü (2 sn)
const CH = [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]];
const chordAt = (t) => CH[Math.floor(t / BAR) % 4];

const END = 21.0; // müzik burada son akorda kalır
// Davul: ilk sahnede yalnız ped, vuruş 3,5'te (açılış) girer.
for (let b = 0; b * BEAT < END; b++) {
  const t = b * BEAT;
  if (t >= 3.5) {
    // Kick: her vuruş
    add(t, 0.32, (x) => Math.sin(2 * Math.PI * (45 * x + 60 * (1 - Math.exp(-x * 30)) / 30)) * Math.exp(-x * 9), 0.55);
    // Hi-hat: ara vuruşlar, yumuşak
    add(t + BEAT / 2, 0.05, (x) => { const n = rnd(); return n * Math.exp(-x * 90); }, 0.05, 0.3);
    // Clap: 2 ve 4
    if (b % 2 === 1) add(t, 0.18, (x) => rnd() * Math.exp(-x * 28) * 0.8, 0.09, -0.15);
  }
}
// Bas: sekizlik, akorun kökü
for (let e = 0; e * BEAT / 2 < END; e++) {
  const t = e * BEAT / 2;
  if (t < 3.5) continue;
  const f = midi(chordAt(t)[0] - 12);
  add(t, 0.24, (x) => {
    const env = Math.min(1, x * 200) * Math.exp(-x * 7);
    return (Math.sin(2 * Math.PI * f * x) + 0.25 * Math.sin(4 * Math.PI * f * x)) * env;
  }, 0.22);
}
// Pluck arpej: onaltılık değil sekizlik, akor tonları yukarı-aşağı
for (let e = 0; e * BEAT / 2 < END; e++) {
  const t = e * BEAT / 2;
  const c = chordAt(t);
  const seq = [c[0] + 12, c[1] + 12, c[2] + 12, c[1] + 24, c[2] + 12, c[1] + 12, c[0] + 24, c[2] + 12];
  const f = midi(seq[e % 8]);
  add(t, 0.4, (x) => {
    const env = Math.min(1, x * 300) * Math.exp(-x * 9);
    const tri = (2 / Math.PI) * Math.asin(Math.sin(2 * Math.PI * f * x));
    return tri * env;
  }, t < 3.5 ? 0.07 : 0.1, (e % 2 ? 0.35 : -0.35));
}
// Ped: her ölçüde akor, yavaş giriş
for (let bar = 0; bar * BAR < END + BAR; bar++) {
  const t = bar * BAR;
  const c = CH[bar % 4];
  const len = t >= END - 0.01 ? 0 : (t + BAR > END ? END - t : BAR) + 0.4;
  if (len <= 0) continue;
  c.forEach((m, k) => add(t, len, (x) => {
    const f = midi(m);
    const env = Math.min(1, x / 0.35) * Math.min(1, (len - x) / 0.4);
    return (Math.sin(2 * Math.PI * f * x) + 0.3 * Math.sin(2 * Math.PI * 2.003 * f * x)) * env;
  }, 0.035, (k - 1) * 0.5));
}
// Kapanış: Am akoru çınlar (21–22)
[57, 60, 64, 69].forEach((m, k) => add(END, 1.0, (x) => {
  const f = midi(m);
  return Math.sin(2 * Math.PI * f * x) * Math.exp(-x * 3) * Math.min(1, x * 200);
}, 0.09, (k - 1.5) * 0.4));
add(END, 0.5, (x) => Math.sin(2 * Math.PI * (45 * x + 60 * (1 - Math.exp(-x * 30)) / 30)) * Math.exp(-x * 6), 0.5);

// Efektler: kaydırma "vuuş"ları ve sahne geçişleri — yumuşak, müziğin altında.
function whoosh(t, len, g, pan) {
  let lp = 0;
  add(t, len, (x) => {
    const p = x / len;
    const a = 0.02 + 0.25 * Math.sin(Math.PI * p);      // süzgeç açılıp kapanır
    lp += a * (rnd() - lp);
    return lp * Math.sin(Math.PI * p);
  }, g, pan);
}
[2.85, 7.95, 9.35, 10.55].forEach((t, i) => whoosh(t - 0.05, 0.35, 0.5, i === 2 ? -0.5 : 0.5));
[3.5, 7, 12, 15.5, 19].forEach((t) => whoosh(t - 0.2, 0.3, 0.3, 0));
// Beğeni "pıt"ı: sağa kaydırılan kartlardan sonra, tonda (La)
[3.0, 8.1, 10.7].forEach((t) => add(t, 0.3, (x) => Math.sin(2 * Math.PI * midi(81) * x) * Math.exp(-x * 18), 0.07));
// Renk seçimi tıkları
[13.6, 14.1, 14.6].forEach((t) => add(t, 0.08, (x) => Math.sin(2 * Math.PI * midi(88) * x) * Math.exp(-x * 60), 0.05));

// Yumuşak sınırlayıcı + son 0,6 sn'de kısılma
let peak = 0;
for (let i = 0; i < N; i++) peak = Math.max(peak, Math.abs(L[i]), Math.abs(R[i]));
const norm = 0.85 / peak;
const buf = Buffer.alloc(44 + N * 4);
buf.write('RIFF', 0); buf.writeUInt32LE(36 + N * 4, 4); buf.write('WAVE', 8);
buf.write('fmt ', 12); buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(2, 22);
buf.writeUInt32LE(SR, 24); buf.writeUInt32LE(SR * 4, 28); buf.writeUInt16LE(4, 32); buf.writeUInt16LE(16, 34);
buf.write('data', 36); buf.writeUInt32LE(N * 4, 40);
for (let i = 0; i < N; i++) {
  const fade = Math.min(1, (N - i) / (0.6 * SR));
  const s = (v) => Math.round(Math.tanh(v * norm) * fade * 32767);
  buf.writeInt16LE(s(L[i]), 44 + i * 4); buf.writeInt16LE(s(R[i]), 46 + i * 4);
}
fs.writeFileSync(process.argv[2], buf);
console.log('müzik yazıldı', process.argv[2]);
