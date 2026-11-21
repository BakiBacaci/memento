// Gemini 3.8 TTS: çok konuşmacılı diyaloğu tek seferde seslendirir.
// node gemini_tts.js <senaryo.json> <çıkış.wav> <model> <Konuşmacı=Ses> [<Konuşmacı=Ses>]
// senaryo.json: [{ "speaker": "Dede", "style": "sakin, sıcak", "text": "..." }, ...]
// Anahtar C:\dev\keys\gemini.txt'den okunur; URL'ye değil başlığa konur.
const fs = require('fs');

const [scriptFile, out, model, ...pairs] = process.argv.slice(2);
const key = fs.readFileSync('C:/dev/keys/gemini.txt', 'utf8').trim();
const turns = JSON.parse(fs.readFileSync(scriptFile, 'utf8'));
const voices = pairs.map((p) => {
  const [speaker, voiceName] = p.split('=');
  return { speaker, voiceConfig: { prebuiltVoiceConfig: { voiceName } } };
});

(async () => {
  const parts = turns.map((t) => ({
    text: t.text,
    speech_metadata: voices.length > 1
      ? { speaker: t.speaker, ...(t.style ? { style: t.style } : {}) }
      : (t.style ? { style: t.style } : undefined),
  }));
  const body = {
    contents: [{ role: 'user', parts }],
    generationConfig: {
      responseModalities: ['AUDIO'],
      speechConfig: voices.length > 1
        ? { multiSpeakerVoiceConfig: { speakerVoiceConfigs: voices } }
        : { voiceConfig: voices[0].voiceConfig },
    },
  };
  const r = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`, {
    method: 'POST',
    headers: { 'x-goog-api-key': key, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const j = await r.json();
  if (!r.ok) { console.error('HATA', r.status, JSON.stringify(j.error || j).slice(0, 500)); process.exit(1); }
  const part = j.candidates?.[0]?.content?.parts?.find((p) => p.inlineData);
  if (!part) { console.error('ses yok', JSON.stringify(j).slice(0, 400)); process.exit(1); }
  let data = Buffer.from(part.inlineData.data, 'base64');
  const mime = part.inlineData.mimeType || '';
  if (!mime.includes('wav') && data.slice(0, 4).toString() !== 'RIFF') {
    // Ham PCM geldiyse WAV başlığı ekle.
    const rate = +(mime.match(/rate=(\d+)/)?.[1] || 24000);
    const h = Buffer.alloc(44);
    h.write('RIFF', 0); h.writeUInt32LE(36 + data.length, 4); h.write('WAVE', 8); h.write('fmt ', 12);
    h.writeUInt32LE(16, 16); h.writeUInt16LE(1, 20); h.writeUInt16LE(1, 22); h.writeUInt32LE(rate, 24);
    h.writeUInt32LE(rate * 2, 28); h.writeUInt16LE(2, 32); h.writeUInt16LE(16, 34); h.write('data', 36); h.writeUInt32LE(data.length, 40);
    data = Buffer.concat([h, data]);
  }
  fs.writeFileSync(out, data);
  console.log('ok', out, mime, 'kullanım:', JSON.stringify(j.usageMetadata || {}));
})().catch((e) => { console.error(e.message); process.exit(1); });
