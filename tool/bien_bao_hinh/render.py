import pymupdf as m, json, io, os, re, sys
from PIL import Image, ImageChops, ImageDraw, ImageFont
exec(open('tool/bien_bao_hinh/common.py').read())
found=json.load(open('build/bien_bao_hinh/found.json')); extra=json.load(open('build/bien_bao_hinh/extra.json'))
man=json.load(open('build/bien_bao_hinh/manual.json')) if os.path.exists('build/bien_bao_hinh/manual.json') else {}
os.makedirs('build/bien_bao_hinh/out',exist_ok=True)
def trim(im):
    bg=Image.new('RGB',im.size,(255,255,255))
    diff=ImageChops.difference(im,bg).convert('L').point(lambda v:255 if v>18 else 0)
    bb=diff.getbbox()
    return im.crop(bb) if bb else im
src={}
def grow(pi,bb):
    R=m.Rect(bb); imgs=[m.Rect(i['bbox']) for i in d[pi].get_image_info()]
    ch=True
    while ch:
        ch=False
        for r in imgs:
            if not R.contains(r) and (R+(-3,-3,3,3)).intersects(r) and r.width<300:
                R|=r; ch=True
    return list(R)
for c,v in found.items(): src[c]=(v['page'],v['bbox'])
for c,v in extra.items(): src.setdefault(c,(v['page'],v['clip']))
for c,v in man.items(): src[c]=(v['page'],v['clip'])
for c,v in json.load(open('tool/bien_bao_hinh/fix.json')).items(): src[c]=(v[0],v[1:])
def fname(c): return re.sub(r'[^A-Za-z0-9]+','_',c.replace('Vạch','vach')).strip('_').lower()
for c,(pi,clip) in src.items():
    pix=d[pi].get_pixmap(matrix=m.Matrix(3,3),clip=m.Rect(clip),alpha=False)
    im=trim(Image.open(io.BytesIO(pix.tobytes('png'))).convert('RGB'))
    im.thumbnail((360,360),Image.LANCZOS)
    im.save('build/bien_bao_hinh/out/%s.webp'%fname(c),'WEBP',quality=88,method=6)
json.dump({c:fname(c) for c in src},open('build/bien_bao_hinh/names.json','w'))
print(len(src),'rendered')
