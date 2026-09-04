#!/usr/bin/env python3
"""Fill en/pt translations for scripts/i18n_keys.json via teai (gemini-2.5-flash) and emit
JiuFlow/Resources/Localizations.json ({ja: {en, pt}}).

  scripts/i18n_translate.py            # translate only missing entries, then write the bundle
  scripts/i18n_translate.py --force    # retranslate everything

Cost: ~1.1k short strings ≈ 40k tokens in+out → cents on gemini-2.5-flash.
"""
import json, os, sys, time
sys.path.insert(0, os.path.expanduser("~/workspace/jiuflow/scripts"))
import teai_llm  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
KEYS = os.path.join(ROOT, "scripts", "i18n_keys.json")
OUT = os.path.join(ROOT, "JiuFlow", "Resources", "Localizations.json")
BATCH = 12
WORKERS = 10

GLOSSARY = """Glossary (ja → en / pt-BR), keep these exact:
道着=Gi/Kimono · ノーギ=No-Gi/Sem kimono · ドリル=Drills/Drills · スパーリング=Sparring/Sparring · ロール=Roll/Rola ·
オープンマット=Open Mat/Open Mat · 白帯=White Belt/Faixa Branca · 青帯=Blue Belt/Faixa Azul · 紫帯=Purple Belt/Faixa Roxa ·
茶帯=Brown Belt/Faixa Marrom · 黒帯=Black Belt/Faixa Preta · 大会=Tournament/Campeonato · 道場=Dojo/Academia ·
テクニック=Technique/Técnica · ゲームプラン=Game Plan/Plano de jogo · フロー=Flow/Fluxo · 記録=Log/Registro ·
練習日記=Practice Journal/Diário de treino · 体重=Weight/Peso · 階級=Weight Class/Categoria · サブミッション=Submission/Finalização ·
スイープ=Sweep/Raspagem · パスガード=Guard Pass/Passagem de guarda · エスケープ=Escape/Escape · テイクダウン=Takedown/Queda ·
三角絞め=Triangle/Triângulo · 腕十字=Armbar/Armlock · 良蔵先生=Ryozo Sensei/Professor Ryozo · JiuFlowメソッド=JiuFlow Method/Método JiuFlow ·
プレミアム=Premium/Premium · マイページ=My Page/Minha página · 学ぶ=Learn/Aprender · 練習=Train/Treinar · ホーム=Home/Início"""

PROMPT = """You are localizing a Brazilian Jiu-Jitsu training app (JiuFlow) from Japanese to English and Brazilian Portuguese.
Rules:
- Natural, concise app UI copy. Match the tone (casual, motivating). Keep emoji, punctuation like "…", "!" and line breaks (\\n) in place.
- Keep proper nouns/brand names (JiuFlow, SJJJF, IBJJF, Stripe, Apple Pay, YouTube, Instagram) and units/numbers unchanged.
- Do NOT translate content inside \\( … ) (Swift interpolation) — copy it verbatim.
- Use the glossary. BJJ terms should read like a native BJJ practitioner wrote them.
- Never mention competitors' product names. Avoid "頑張って"-style "work hard" copy → prefer "let's go / keep rolling" tone.
- Output ONLY a JSON array, one object per input line, same order: {{"ja": <source>, "en": <english>, "pt": <portuguese>}}.

{glossary}

Translate these {n} strings:
{items}
"""


def main():
    force = "--force" in sys.argv
    keys = json.load(open(KEYS, encoding="utf-8"))
    todo = [k for k, v in keys.items() if force or not v.get("en") or not v.get("pt")]
    print(f"keys={len(keys)} todo={len(todo)}")
    from concurrent.futures import ThreadPoolExecutor, as_completed
    import threading
    lock = threading.Lock()

    def run(chunk, idx):
        items = "\n".join(json.dumps(k, ensure_ascii=False) for k in chunk)
        prompt = PROMPT.format(glossary=GLOSSARY, n=len(chunk), items=items)
        for attempt in range(3):
            try:
                rows = teai_llm.chat(prompt, want_json=True)
                if isinstance(rows, dict):
                    rows = rows.get("translations") or list(rows.values())[0]
                got = {r["ja"]: r for r in rows if isinstance(r, dict) and "ja" in r}
                with lock:
                    for k in chunk:
                        r = got.get(k)
                        if r and r.get("en"):
                            keys[k] = {"en": (r.get("en") or "").strip(), "pt": (r.get("pt") or "").strip()}
                    json.dump(keys, open(KEYS, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
                missing = [k for k in chunk if k not in got]
                print(f"batch {idx}: ok {len(chunk) - len(missing)}/{len(chunk)}" + (f" missing={missing[:2]}" if missing else ""), flush=True)
                return
            except Exception as e:  # noqa: BLE001
                print(f"batch {idx}: attempt {attempt + 1} failed: {e}", flush=True)
                time.sleep(3)

    chunks = [todo[i:i + BATCH] for i in range(0, len(todo), BATCH)]
    with ThreadPoolExecutor(max_workers=WORKERS) as ex:
        futs = [ex.submit(run, c, i + 1) for i, c in enumerate(chunks)]
        for _ in as_completed(futs):
            pass
    # bundle (hand-authored format strings in i18n_manual.json win over LLM output)
    manual_path = os.path.join(ROOT, "scripts", "i18n_manual.json")
    if os.path.exists(manual_path):
        keys.update(json.load(open(manual_path, encoding="utf-8")))
        json.dump(keys, open(KEYS, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    # Swift source literals carry escapes (\\n, \\") verbatim; at runtime tr() receives the real characters.
    def unesc(x: str) -> str:
        return x.replace("\\n", "\n").replace('\\"', '"').replace("\\\\", "\\")
    table = {unesc(k): {"en": unesc(v["en"]), "pt": unesc(v.get("pt", ""))} for k, v in keys.items() if v.get("en")}
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(table, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=0, sort_keys=True)
    empty = [k for k, v in keys.items() if not v.get("en")]
    print(f"bundle written: {len(table)} entries → {OUT}; still empty: {len(empty)}")


if __name__ == "__main__":
    main()
