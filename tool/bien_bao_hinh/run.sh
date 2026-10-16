#!/usr/bin/env bash
# Cắt hình từng biển báo từ PDF QCVN 41:2024/BGTVT (bản kèm Thông tư 51/2024/TT-BGTVT,
# https://datafiles.chinhphu.vn/cpp/files/vbpq/2024/11/51-bgtvt-kem.pdf) vào assets/data/signs/.
# Cần Python với pymupdf và pillow. Chạy từ thư mục gốc của app:
#   QCVN41_PDF=/đường/dẫn/51-bgtvt-kem.pdf tool/bien_bao_hinh/run.sh
# Cách khớp hình: ảnh trong Phụ lục B–F và Điều 47 lấy theo nhãn "Biển số ..." ngay dưới ảnh
# (match2.py, region.py); vạch kẻ lấy hình minh họa đầu tiên dưới tiêu đề mục ở Phụ lục G
# (vach.py); vài hình gộp nhiều biển hoặc nhãn lệch được cắt tay theo tọa độ trong fix.json.
set -euo pipefail
mkdir -p build/bien_bao_hinh
rm -rf build/bien_bao_hinh/out
python3 tool/bien_bao_hinh/match2.py
python3 tool/bien_bao_hinh/region.py
python3 tool/bien_bao_hinh/vach.py
python3 tool/bien_bao_hinh/render.py
python3 - <<'PY'
import json, shutil
names = json.load(open('build/bien_bao_hinh/names.json'))
for s in json.load(open('assets/data/bien_bao.json')):
    if s.get('hinh'):
        shutil.copy('build/bien_bao_hinh/out/%s.webp' % names[s['ma']], 'assets/data/' + s['hinh'])
PY
echo "Đã cắt hình vào assets/data/signs/"
