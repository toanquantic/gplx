# Ôn thi GPLX

App Flutter ôn thi lý thuyết giấy phép lái xe Việt Nam, chạy hoàn toàn offline. Dữ liệu là bộ 600 câu của Cục CSGT (áp dụng từ 01/6/2025), lấy từ thư mục `data/` của dự án.

App mở đủ 15 hạng: mô tô **A1, A, B1**; ô tô **B, C1, C**; xe khách **D1, D2, D**; kéo rơ moóc **BE, C1E, CE, D1E, D2E, DE**. Trang chủ hiện nổi bật hạng đang ôn, bấm "Đổi hạng" để chọn hạng khác. Danh sách nằm ở `classGroups` trong `lib/data/question_bank.dart`. Hạng B1 chưa xác minh được điểm đạt nên đề thi thử B1 chỉ chấm số câu đúng, không báo đạt hay trượt.

## Tính năng

- Lần đầu mở app chọn hạng thi, lần sau vào thẳng hạng đó; đổi hạng bằng link "Đổi hạng" trên thẻ hạng ở trang chủ và chọn ghi nhớ làm mặc định hoặc chỉ ôn thử lần này
- Xem tiến độ theo hạng (đã làm, đúng, sai)
- Ôn theo 6 chương (có thanh tiến độ và số câu sai từng chương), hoặc tất cả câu của hạng
- Ôn câu điểm liệt riêng theo hạng (A1/A 20 câu, B1 30 câu, ô tô 60 câu)
- Ôn lại câu làm sai, câu đã đánh dấu
- Danh sách câu dạng lưới tô màu đúng/sai, lọc câu sai hoặc câu chưa làm
- Thi thử: rút đề ngẫu nhiên theo cấu trúc chính thức, tính giờ, tự nộp khi hết giờ, chấm theo điểm đạt và luật điểm liệt
- Kết quả thi: điểm theo từng nhóm câu, câu điểm liệt, thời gian làm bài; xem lại câu sai kèm giải thích; mở lại bài cũ từ lịch sử thi
- Tra cứu 419 biển báo theo QCVN 41:2024 (mã, tên và ý nghĩa tóm tắt từ Phụ lục B–G), tìm theo mã, tên hoặc ý nghĩa, lọc theo nhóm biển
- Lời giải thích đã được đọc lại cả 600 câu, 179 câu viết lại (`assets/data/giai_thich_ra_soat.json`, kèm lý do)
- Trang giới thiệu ghi nguồn và giấy phép MIT của lời giải thích
- Nhắc học mỗi ngày (Android, iOS): bật ở trang chủ, mặc định 20:00, đổi giờ được. App đặt sẵn thông báo cho 7 ngày tới, mỗi ngày một lời nhắc tính từ tiến độ (số câu đến hạn ôn với bản Pro, số ngày còn lại đến ngày thi); hôm đó đã học thì không nhắc

Bản Pro (mở khóa một lần): ôn lại câu sai theo lịch giãn cách, thống kê theo chương và dự đoán khả năng đỗ, đề ưu tiên câu yếu, gói ôn trước ngày thi, mẹo nhớ nhanh. Mẹo nhớ nằm trong `assets/data/meo_nho.json`, do app tự biên soạn từ đáp án bộ 600 câu; test kiểm tra các con số trong mẹo khớp đáp án đúng.

Giao diện theo mockup "Mockup app Ôn thi GPLX" (phông Be Vietnam Pro, giấy phép OFL, đóng gói sẵn trong `assets/fonts/` để chạy offline), có cả giao diện tối.

## Chạy thử

```bash
flutter pub get
flutter run            # chọn thiết bị: Android, iOS, Chrome, desktop
flutter test           # dữ liệu, rút đề, chấm điểm, lịch sử thi, giao diện, mua Pro, tính năng Pro
```

## Build Android và iOS

GitHub Actions (`.github/workflows/build.yml`) chạy trên mỗi PR và mỗi lần push lên `main`:

- `flutter analyze` và `flutter test`
- Android: `flutter build apk --release`, tải file APK ở mục Artifacts của lần chạy (`on-thi-gplx-android-apk`) để cài thử trên điện thoại
- iOS: `flutter build ios --release --no-codesign` để chắc chắn bản iOS biên dịch được, kèm bản cho iOS Simulator (`on-thi-gplx-ios-simulator`). Chạy trên iPhone thật hoặc đưa lên App Store cần tài khoản Apple Developer và chứng chỉ ký

### Ký bản Android để đưa lên Google Play

Mã ứng dụng là `com.toanquantic.gplx` (không đổi được sau lần phát hành đầu). Chưa có khóa thì bản release ký bằng khóa debug, chỉ để cài thử.

1. Tạo khóa tải lên (một lần, giữ file và mật khẩu cẩn thận, mất là không cập nhật app được nữa nếu chưa bật Play App Signing):

   ```bash
   keytool -genkey -v -keystore upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Build trên máy: tạo `android/key.properties` (đã nằm trong `.gitignore`):

   ```properties
   storeFile=/đường/dẫn/tới/upload.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```

   rồi chạy `flutter build appbundle --release`.

3. Build trên GitHub Actions: vào Settings > Secrets and variables > Actions của repo, thêm `ANDROID_KEYSTORE_BASE64` (kết quả của `base64 -w0 upload.jks`), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`. Từ lần chạy sau, APK được ký bằng khóa này và có thêm file AAB (`on-thi-gplx-android-aab`) để tải lên Google Play Console.

### Phát hành lên Google Play và App Store

Workflow `Release` (`.github/workflows/release.yml`) chỉ chạy khi bấm tay ở tab Actions: build AAB và IPA đã ký, tùy chọn tải lên Google Play (bản nháp) và TestFlight. Các tài khoản, khóa và secrets cần chuẩn bị, cùng checklist trang store, xem [`docs/phat-hanh.md`](docs/phat-hanh.md). Chính sách quyền riêng tư soạn sẵn ở [`docs/privacy-policy.md`](docs/privacy-policy.md).

## Cấu trúc

| Thư mục | Nội dung |
|---|---|
| `lib/models/` | Câu hỏi, chương, hạng, cấu hình đề, biển báo |
| `lib/data/question_bank.dart` | Nạp JSON từ assets, lọc câu theo hạng, câu điểm liệt |
| `lib/logic/exam.dart` | Rút đề theo `cau_truc` và chấm điểm |
| `lib/state/progress.dart` | Tiến độ học lưu trên máy (shared_preferences) |
| `lib/monetization/` | Bản Pro mở khóa một lần (`pro_lifetime`): `EntitlementService`, mua qua `in_app_purchase` trên Android/iOS (web và desktop luôn miễn phí), `ProGate`, màn mua Pro và khôi phục giao dịch |
| `lib/ui/` | Các màn hình; `theme.dart` chứa bảng màu và các thẻ dùng chung |
| `assets/data/` | Bản sao dữ liệu từ `data/`; cập nhật bằng `tool/sync_data.sh` |

Đề thi đọc hoàn toàn từ `cau_hinh_de_thi.json`. Khi cấu trúc đề đổi từ 01/3/2027 theo Thông tư 108/2026, chỉ cần cập nhật file này (và bộ câu hỏi mới nếu có), không phải sửa code.

## Lưu trữ

Bộ đề chỉ có 600 câu (khoảng 450 KB JSON), nên app nạp thẳng vào bộ nhớ thay vì dùng SQLite. Tiến độ học lưu bằng `shared_preferences`, chạy được trên mọi nền tảng kể cả web. Khi cần đồng bộ nhiều máy hoặc dữ liệu lớn hơn có thể chuyển sang SQLite.
