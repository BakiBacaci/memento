// Microsoft Edge'in sinir ağı sesleri (ücretsiz, hesap gerekmez).
// node edge_tts.js <çıkış.mp3> <ses> <hız ör. -5%> <metin dosyası>
const { MsEdgeTTS, OUTPUT_FORMAT } = require('msedge-tts');
const fs = require('fs');
const path = require('path');

const [out, voice, rate, file] = process.argv.slice(2);
const text = fs.readFileSync(file, 'utf8').trim();

(async () => {
  const tts = new MsEdgeTTS();
  await tts.setMetadata(voice, OUTPUT_FORMAT.AUDIO_24KHZ_96KBITRATE_MONO_MP3);
  const dir = path.join(path.dirname(out), '_tmp_' + Date.now());
  fs.mkdirSync(dir, { recursive: true });
  const { audioFilePath } = await tts.toFile(dir, text, { rate });
  fs.renameSync(audioFilePath, out);
  fs.rmSync(dir, { recursive: true, force: true });
  tts.close();
  console.log('ok', out);
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
