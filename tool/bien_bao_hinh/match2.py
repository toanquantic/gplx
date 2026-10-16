import os, pymupdf as m, re, json
d=m.open(os.environ.get('QCVN41_PDF','51-bgtvt-kem.pdf'))
codes=[s['ma'] for s in json.load(open('assets/data/bien_bao.json'))]
codeset=set(codes)
SEP=re.compile(r'[\s\x00-\x1f]+')
LABEL=re.compile(r'(?:([a-zđ])\)\s*)?(?:Biển\s*số|Vạch)\s*((?:DP|IE|R\.E,|S\.G,|S\.H,|P|W|R|I|S)\.?\s?\d+[a-z]?|\d+\.\d+[a-z]?)(?![^\s(,.;:)"])\s*(\([a-z,\s]+\))?')
def canon(c):
    if re.match(r'^\d',c): return 'Vạch '+c
    return c
found={}; log=[]
ALIAS={'DP.127a':'DP.127','R.413p':'R.412p','R.415a':'R.415','I.428a':'I.428'}
for pi in range(30,200):
    p=d[pi]
    lines=[]
    for b in p.get_text('rawdict')['blocks']:
        for l in b.get('lines',[]):
            chars=[((' ' if SEP.fullmatch(c['c']) else c['c']),(c['bbox'][0]+c['bbox'][2])/2) for s in l['spans'] for c in s['chars']]
            if chars: lines.append((l['bbox'],''.join(c for c,_ in chars),[x for _,x in chars]))
    for info in p.get_image_info(xrefs=True):
        x0,y0,x1,y1=info['bbox']; cx=(x0+x1)/2
        if x1-x0<20 or y1-y0<20: continue
        cands=[]
        for (lx0,ly0,lx1,ly1),t,xs in lines:
            if ly0>=y1-4 and ly0-y1<70 and lx0-30<=cx<=lx1+30:
                for mt in LABEL.finditer(t):
                    pre=t[:mt.start()].strip()
                    if pre and not re.search(r'(Biển\s*số|Vạch)\s*\S+$',pre) and not re.fullmatch(r'(?:.*\s)?(?:Hình\s*[A-Z]?\.?\s*\d+[a-z]?\s*[-–]?|[a-zđ]\))',pre): continue
                    code=canon(re.sub(r'\s','',mt.group(2))); grp=mt.group(3)
                    lx=(xs[mt.start()]+xs[mt.end()-1])/2
                    cands.append((ly0, abs(lx-cx), code, grp, t[:60]))
        if not cands: continue
        top=min(c[0] for c in cands)
        row=[c for c in cands if c[0]<top+3]
        best=min(row,key=lambda c:c[1])
        code,grp=best[2],best[3]
        code=ALIAS.get(code,code)
        ok = code in codeset and not grp and (len({c[2] for c in row})==1 or best[1]<60)
        log.append((pi,info['xref'],code,grp,ok,round(best[1])))
        if ok and code not in found:
            found[code]=dict(page=pi,xref=info['xref'],bbox=info['bbox'],w=info['width'],h=info['height'])
json.dump(found,open('build/bien_bao_hinh/found.json','w'),ensure_ascii=False)
missing=[c for c in codes if c not in found]
print(len(found),'found;',len(missing),'missing')
print(missing)
json.dump(log,open('build/bien_bao_hinh/log.json','w'),ensure_ascii=False)
