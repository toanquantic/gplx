# Tìm vùng hình cho các mã chưa khớp ảnh raster: vùng phía trên nhãn/chú thích.
import pymupdf as m, re, json
exec(open('tool/bien_bao_hinh/common.py').read())
found=json.load(open('build/bien_bao_hinh/found.json'))
missing=[c for c in codes if c not in found]
extra={}
DR={}
for pi in range(30,200):
    p=d[pi]; L=page_lines(p); DR[pi]=p.get_drawings()
    for idx,(bb,t,xs) in enumerate(L):
        labs=[(mt,canon(re.sub(r'\s','',mt.group(2)))) for mt in LABEL.finditer(t)]
        for mt,code in labs:
            code=ALIAS.get(code,code)
            if code not in missing or code in extra or mt.group(3): continue
            # chỉ nhận nhãn đứng đầu dòng (chú thích hình), không nhận câu văn
            pre=t[:mt.start()].strip()
            if pre and not re.search(r'(Biển\s*số|Vạch)\s*\S+$',pre) and not re.fullmatch(r'Hình\s*[A-Z]?\.?\s*\d+[a-z]?\s*-?|[a-z]\)',pre): continue
            if len(t.strip())>len(mt.group(0))+60: continue
            lx=(xs[mt.start()]+xs[mt.end()-1])/2
            # chặn ngang theo các nhãn khác trên cùng dòng
            others=sorted({(xs2[o.start()]+xs2[o.end()-1])/2 for bb2,t2,xs2 in L if abs(bb2[1]-bb[1])<4 for o in LABEL.finditer(t2)})
            i=others.index(lx) if lx in others else 0
            X0=(others[i-1]+lx)/2 if i>0 else 55
            X1=(others[i+1]+lx)/2 if i+1<len(others) else 545
            y1=bb[1]-1
            # đáy của dòng chữ dài gần nhất phía trên
            y0=40
            for bb2,t2,_ in L:
                if bb2[3]<=y1-2 and len(t2.strip())>40 and not LABEL.search(t2) and bb2[3]>y0: y0=bb2[3]
                if bb2[3]<=y1-2 and LABEL.search(t2) and bb2[3]>y0 and bb2[1]<y1-20: y0=bb2[3]
            if y1-y0<20: continue
            R=m.Rect(X0,y0+1,X1,y1)
            objs=[m.Rect(i['bbox']) for i in p.get_image_info()]+[dr['rect'] for dr in DR[pi]]
            U=m.Rect()
            for o in objs:
                if o.width<0.5 and o.height<0.5: continue
                if R.contains(o) or (R & o).get_area()>0.8*max(o.get_area(),1e-6): U|=o
            if U.is_empty or U.width<25 or U.height<15: continue
            extra[code]=dict(page=pi,clip=[U.x0-1,U.y0-1,U.x1+1,U.y1+1],label=t.strip()[:60])
json.dump(extra,open('build/bien_bao_hinh/extra.json','w'),ensure_ascii=False,indent=0)
print(len(extra),'extra; still missing:',[c for c in missing if c not in extra])
