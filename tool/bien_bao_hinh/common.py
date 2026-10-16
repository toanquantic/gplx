import os
import pymupdf as m, re, json
d=m.open(os.environ.get('QCVN41_PDF','51-bgtvt-kem.pdf'))
codes=[s['ma'] for s in json.load(open('assets/data/bien_bao.json'))]
SEP=re.compile(r'[\s\x00-\x1f]+')
LABEL=re.compile(r'(?:([a-zđ])\)\s*)?(?:Biển\s*số|Vạch)\s*((?:DP|IE|R\.E,|S\.G,|S\.H,|P|W|R|I|S)\.?\s?\d+[a-z]?|\d+\.\d+[a-z]?)(?![^\s(,.;:)"])\s*(\([a-z,\s]+\))?')
ALIAS={'DP.127a':'DP.127','R.413p':'R.412p','R.415a':'R.415','I.428a':'I.428'}
def canon(c): return 'Vạch '+c if re.match(r'^\d',c) else c
def page_lines(p):
    out=[]
    for b in p.get_text('rawdict')['blocks']:
        for l in b.get('lines',[]):
            ch=[((' ' if SEP.fullmatch(c['c']) else c['c']),(c['bbox'][0]+c['bbox'][2])/2) for s in l['spans'] for c in s['chars']]
            if ch: out.append((l['bbox'],''.join(c for c,_ in ch),[x for _,x in ch]))
    return out
