import re
exec(open('tool/bien_bao_hinh/common.py').read())
HEAD=re.compile(r'\s*(G\s*\d+(\.\d+)*\.?|[a-zđ]\.)\s*\S')
heads=[]
for pi in range(156,200):
    for bb,t,xs in page_lines(d[pi]):
        if HEAD.match(t) and len(t.strip())<120: heads.append((pi,bb[1],t.strip()))
def code_of(t):
    mt=re.match(r'[a-zđ]\.\s*Vạch\s*(?:số\s*)?(\d+\.\d+)',t)
    if mt: return 'Vạch '+mt.group(1)
    mt=re.match(r'G2\.(\d)\.',t)
    if mt: return 'Vạch 7.'+mt.group(1)
cache={}
def objs(pi):
    if pi not in cache:
        p=d[pi]; o=[m.Rect(i['bbox']) for i in p.get_image_info()]+[dr['rect'] for dr in p.get_drawings()]
        o=[r for r in o if r.width>1 or r.height>1]
        longs=[bb for bb,t,_ in page_lines(p) if len(t.strip())>45]
        cache[pi]=(o,longs)
    return cache[pi]
res={}
for i,(pi,y,t) in enumerate(heads):
    c=code_of(t)
    if not c or c in res: continue
    end=heads[i+1] if i+1<len(heads) else (999,0,'')
    for pg in (pi,pi+1):
        if pg>end[0]: break
        lo=y if pg==pi else 40; hi=end[1] if pg==end[0] else 800
        o,longs=objs(pg)
        o=sorted([r for r in o if r.y0>=lo and r.y1<=hi+2],key=lambda r:r.y0)
        clusters=[]
        for r in o:
            if clusters:
                U=clusters[-1]
                sep=any(U.y1-2<=l[1] and l[3]<=r.y0+2 for l in longs)
                if r.y0<=U.y1+15 and not sep: clusters[-1]=U|r; continue
            clusters.append(m.Rect(r))
        clusters=[u for u in clusters if u.width>60 and u.height>15]
        if clusters:
            u=clusters[0]; res[c]=dict(page=pg,clip=[u.x0-2,u.y0-2,u.x1+2,u.y1+2]); break
json.dump(res,open('build/bien_bao_hinh/manual.json','w'),ensure_ascii=False,indent=0)
print(len(res),sorted(set(c for c in codes if c.startswith('Vạch'))-set(res)))
