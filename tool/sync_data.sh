#!/usr/bin/env bash
# Chép dữ liệu ôn thi từ thư mục data/ của dự án vào assets của app.
# Chạy lại mỗi khi bộ đề hoặc cấu hình đề thi được cập nhật.
set -euo pipefail
SRC="${1:-$(dirname "$0")/../../../data}"
DEST="$(dirname "$0")/../assets/data"
mkdir -p "$DEST"
cp "$SRC"/{cau_hoi_600.json,cau_hinh_de_thi.json,giai_thich_cong_dong.json,hang_gplx.json,bien_bao.json} "$DEST"/
cp "$SRC"/nguon/LICENSE-MIT-thichuong.txt "$DEST"/
rm -rf "$DEST/images" && cp -r "$SRC/images" "$DEST/images"
echo "Đã chép dữ liệu từ $SRC"
