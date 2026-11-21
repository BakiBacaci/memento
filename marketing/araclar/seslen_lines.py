# Replikleri seslen-tts ile tek tek WAV'a çevirir.
# python seslen_lines.py <replikler.json> <çıkış klasörü>
# replik: {"id": "r1", "ses": "hasan", "ton": "notr", "hiz": 0.95, "metin": "..."}
import json, sys, os, wave
from seslen_tts import Seslen, wav_yaz

src, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
s = Seslen()
for r in json.load(open(src, encoding="utf-8")):
    ayar = {"ses": r["ses"], "ton": r.get("ton", "otomatik")}
    if r.get("hiz"):
        ayar["hiz"] = r["hiz"]
    if r.get("yogunluk"):
        ayar["yogunluk"] = r["yogunluk"]
    f = os.path.join(out, r["id"] + ".wav")
    wav_yaz(f, s.tum(r["metin"], **ayar))
    with wave.open(f) as w:
        print(r["id"], r["ses"], r.get("ton"), round(w.getnframes() / w.getframerate(), 2), "sn", flush=True)
