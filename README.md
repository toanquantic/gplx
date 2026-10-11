# Ôn thi GPLX

App Flutter ôn thi lý thuyết giấy phép lái xe Việt Nam, chạy hoàn toàn offline. Dữ liệu là bộ 600 câu của Cục CSGT (áp dụng từ 01/6/2025), lấy từ thư mục `data/` của dự án.

Đợt 1 mở các hạng **A1, A, B**. Muốn mở thêm C1, C chỉ cần thêm mã vào `enabledClasses` trong `lib/data/question_bank.dart`, vì dữ liệu và cấu hình đề đã có sẵn.

## Tính năng

- Chọn hạng, xem tiến độ (đã làm, đúng, sai)
- Ôn theo 6 chương, hoặc tất cả câu của hạng
- Ôn câu điểm liệt riêng theo hạng (A1/A 20 câu, B 60 câu)
- Ôn lại câu làm sai, câu đã đánh dấu
- Thi thử: rút đề ngẫu nhiên theo cấu trúc chính thức, tính giờ, tự nộp khi hết giờ, chấm theo điểm đạt và luật điểm liệt, xem lại từng câu
- Tra cứu 419 biển báo theo QCVN 41:2024 (mã và tên)
- Trang giới thiệu ghi nguồn và giấy phép MIT của lời giải thích

## Chạy thử

```bash
flutter pub get
flutter run            # chọn thiết bị: Android, iOS, Chrome, desktop
flutter test           # 28 test: dữ liệu, rút đề, chấm điểm, giao diện, mua Pro
```

## Cấu trúc

| Thư mục | Nội dung |
|---|---|
| `lib/models/` | Câu hỏi, chương, hạng, cấu hình đề, biển báo |
| `lib/data/question_bank.dart` | Nạp JSON từ assets, lọc câu theo hạng, câu điểm liệt |
| `lib/logic/exam.dart` | Rút đề theo `cau_truc` và chấm điểm |
| `lib/state/progress.dart` | Tiến độ học lưu trên máy (shared_preferences) |
| `lib/monetization/` | Bản Pro mở khóa một lần (`pro_lifetime`): `EntitlementService`, mua qua `in_app_purchase` trên Android/iOS (web và desktop luôn miễn phí), `ProGate`, màn mua Pro và khôi phục giao dịch |
| `lib/ui/` | Các màn hình |
| `assets/data/` | Bản sao dữ liệu từ `data/`; cập nhật bằng `tool/sync_data.sh` |

Đề thi đọc hoàn toàn từ `cau_hinh_de_thi.json`. Khi cấu trúc đề đổi từ 01/3/2027 theo Thông tư 108/2026, chỉ cần cập nhật file này (và bộ câu hỏi mới nếu có), không phải sửa code.

## Lưu trữ

Bộ đề chỉ có 600 câu (khoảng 450 KB JSON), nên app nạp thẳng vào bộ nhớ thay vì dùng SQLite. Tiến độ học lưu bằng `shared_preferences`, chạy được trên mọi nền tảng kể cả web. Khi cần đồng bộ nhiều máy hoặc dữ liệu lớn hơn có thể chuyển sang SQLite.
