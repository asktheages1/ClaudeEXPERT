#!/usr/bin/env python3
"""Split raw CC doc pages into Read-sized parts and write docs/cc/INDEX.md.

Usage: python3 -I tools/docs_split.py <raw_dir> <out_dir> <fetch_date>
Each part is <= MAX bytes (36 KB; at the worst measured 1.8 B/token that is ~20k tokens,
under the 25k-token Read limit). Cuts happen at '## '/'### ' headings when possible,
never inside a fenced code block.
"""
import hashlib, os, re, sys

MAX = 36000
raw, out, date = sys.argv[1], sys.argv[2], sys.argv[3]
pages = [l.strip() for l in open(os.path.join(os.path.dirname(__file__), 'docs_pages.txt'))
         if l.strip() and not l.startswith('#')]
for f in os.listdir(out):
    if f.endswith('.md'):
        os.remove(os.path.join(out, f))
rows = []
for p in pages:
    text = open(os.path.join(raw, p + '.md'), encoding='utf-8').read()
    sha = hashlib.sha256(text.encode()).hexdigest()[:16]
    chunks, cur, size, fence = [], [], 0, False
    for ln in text.split('\n'):
        b = len(ln.encode()) + 1
        head = (not fence) and re.match(r'#{2,3} ', ln)
        if cur and not fence and (size + b > MAX or (head and size > MAX * 0.6)):
            chunks.append(cur); cur, size = [], 0
        cur.append(ln); size += b
        if ln.lstrip().startswith('```'):
            fence = not fence
    if cur:
        chunks.append(cur)
    n = len(chunks)
    for i, c in enumerate(chunks, 1):
        name = f'{p}.md' if n == 1 else f'{p}.part{i}of{n}.md'
        body = f'[{"Part %d/%d of " % (i, n) if n > 1 else ""}https://code.claude.com/docs/en/{p}.md, fetched {date}]\n\n' + '\n'.join(c)
        open(os.path.join(out, name), 'w', encoding='utf-8').write(body)
        heads = [h[3:].strip() for h in c if h.startswith('## ')]
        rows.append((p, name, len(body.encode()), sha if i == 1 else '', '; '.join(heads)[:300]))
with open(os.path.join(out, 'INDEX.md'), 'w', encoding='utf-8') as f:
    f.write(f'# docs/cc index\n\nVerbatim copies of official Claude Code doc pages, fetched {date}. '
            'Refresh: `bash tools/refresh-docs.sh`, then `git diff docs/cc` shows what changed upstream. '
            'Each part fits one Read call. Bytes / ~2.7 = approximate tokens for English markdown.\n\n'
            '| Page | File | Bytes | sha256[:16] of full page | `##` sections in this file |\n|---|---|---|---|---|\n')
    for r in rows:
        f.write('| %s | %s | %d | %s | %s |\n' % (r[0], r[1], r[2], r[3], r[4].replace('|', '/')))
print(len(rows), 'files')
