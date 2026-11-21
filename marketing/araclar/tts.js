// Google TTS (Google Çeviri'nin ücretsiz seslendirmesi) ile Türkçe dış ses.
const tts = require('google-tts-api');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const ffmpeg = require('ffmpeg-static');

const out = process.argv[2];
const lines = JSON.parse(fs.readFileSync(process.argv[3], 'utf8'));
fs.mkdirSync(out, { recursive: true });

(async () => {
  for (const [i, text] of lines.entries()) {
    const parts = await tts.getAllAudioBase64(text, { lang: 'tr', slow: false, host: 'https://translate.google.com' });
    const mp3 = Buffer.concat(parts.map((p) => Buffer.from(p.base64, 'base64')));
    const f = path.join(out, `vo${i}.mp3`);
    fs.writeFileSync(f, mp3);
    let info = '';
    try { execFileSync(ffmpeg, ['-i', f], { stdio: 'pipe' }); } catch (e) { info = e.stderr.toString(); }
    const m = info.match(/Duration: (\d+):(\d+):([\d.]+)/);
    console.log(i, m ? (+m[3]).toFixed(2) + 's' : '?', text);
  }
})().catch((e) => { console.error(e.message); process.exit(1); });
