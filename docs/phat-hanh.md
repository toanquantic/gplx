# Phát hành lên Google Play và App Store

Repo đã có sẵn phần ký và build. Những việc dưới đây cần chủ app tự làm vì cần tài khoản, thanh toán và khóa bí mật.

| | Android | iOS |
|---|---|---|
| Mã ứng dụng | `com.toanquantic.gplx` | `com.toanquantic.gplx` |
| Sản phẩm mua trong app | `pro_lifetime` (sản phẩm một lần, không phải gói thuê bao) | `pro_lifetime` (Non-Consumable) |
| Workflow | `.github/workflows/release.yml`, bấm tay ở tab Actions | như bên trái |

Mã ứng dụng không đổi được sau lần phát hành đầu. Muốn đổi thì phải đổi trước bước 1.

## 1. Tài khoản cần tạo

- **Google Play Console**: https://play.google.com/console, phí 25 USD một lần. Cần xác minh danh tính (CCCD) và số điện thoại. Tài khoản cá nhân mới phải chạy **thử nghiệm kín với ít nhất 12 người trong 14 ngày liên tục** trước khi được mở bản chính thức, nên làm sớm.
- **Apple Developer Program**: https://developer.apple.com/programs/enroll, 99 USD mỗi năm. Đăng ký cá nhân hoặc tổ chức (tổ chức cần mã D-U-N-S).
- Để bán bản Pro: Play Console cần **hồ sơ thanh toán (merchant)**, App Store Connect cần ký **Paid Apps Agreement** và điền thuế, tài khoản ngân hàng (Business > Agreements).

## 2. Khóa ký Android

1. Tạo khóa tải lên, giữ file và mật khẩu ở nơi an toàn (password manager, ổ dự phòng):

   ```bash
   keytool -genkey -v -keystore upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Khi tạo app trên Play Console, giữ mặc định **Play App Signing** (Google giữ khóa ký thật, khóa trên chỉ là khóa tải lên, mất còn xin cấp lại được).

## 3. Khóa App Store Connect API (cho iOS)

1. Vào https://developer.apple.com/account, mục Membership, chép **Team ID** (10 ký tự).
2. Vào Certificates, Identifiers & Profiles > Identifiers, tạo App ID `com.toanquantic.gplx`, bật **In-App Purchase**.
3. Vào App Store Connect > Users and Access > Integrations > App Store Connect API, tạo khóa **Team Key** với quyền **Admin** (cần quyền này để Xcode tự tạo chứng chỉ phân phối). Tải file `AuthKey_XXXXXXXXXX.p8` (chỉ tải được một lần), chép **Key ID** và **Issuer ID**.

Không cần tự tạo chứng chỉ `.p12` hay provisioning profile: workflow để Xcode tự tạo bằng khóa API này.

## 4. Tài khoản dịch vụ Google Play (để workflow tự tải bản lên)

Làm một lần, sau đó workflow Release bật `upload` sẽ tự đưa AAB lên Play.

1. Vào https://console.cloud.google.com, tạo dự án mới (ví dụ `gplx-release`).
2. Trong dự án đó, mở **APIs & Services > Library**, tìm **Google Play Android Developer API** và bấm **Enable**.
3. Mở **IAM & Admin > Service Accounts > Create service account**, đặt tên (ví dụ `play-upload`), bỏ qua phần cấp quyền, bấm Done. Chép địa chỉ email của nó (dạng `play-upload@gplx-release.iam.gserviceaccount.com`).
4. Bấm vào service account vừa tạo > tab **Keys** > **Add key > Create new key > JSON**. File JSON tải về chính là khóa, giữ kín như mật khẩu.
5. Vào Play Console > **Users and permissions** > **Invite new users**, dán email ở bước 3. Ở tab **App permissions** thêm app Ôn thi GPLX, tích **Release apps to testing tracks** (thêm **Release to production...** nếu muốn workflow đưa lên kênh production). Bấm Invite user.
6. GitHub repo > Settings > Secrets and variables > Actions > New repository secret: tên `PLAY_SERVICE_ACCOUNT_JSON`, giá trị là toàn bộ nội dung file JSON (mở bằng trình soạn thảo, chép hết).

Quyền mới cấp trên Play Console đôi khi cần chờ một lúc mới có hiệu lực; nếu lần chạy đầu báo lỗi quyền thì chạy lại sau.

## 5. Secrets cần thêm vào GitHub

Repo > Settings > Secrets and variables > Actions > New repository secret:

| Secret | Giá trị |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 upload.jks` (macOS: `base64 -i upload.jks`) |
| `ANDROID_KEYSTORE_PASSWORD` | mật khẩu keystore |
| `ANDROID_KEY_ALIAS` | `upload` (hoặc alias đã chọn) |
| `ANDROID_KEY_PASSWORD` | mật khẩu khóa |
| `PLAY_SERVICE_ACCOUNT_JSON` | toàn bộ nội dung file JSON của service account |
| `APPLE_TEAM_ID` | Team ID |
| `APP_STORE_CONNECT_KEY_ID` | Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID |
| `APP_STORE_CONNECT_KEY_P8_BASE64` | `base64 -w0 AuthKey_XXXXXXXXXX.p8` (macOS: `base64 -i ...`) |

Có 4 secret Android đầu tiên thì workflow Build thường cũng ký APK/AAB bằng khóa thật.

## 6. Tạo app trên hai store

**Google Play Console** > Create app: tên "Ôn thi GPLX", ngôn ngữ mặc định Tiếng Việt, App, Free.

**App Store Connect** > Apps > New App: nền tảng iOS, tên (tên phải chưa ai dùng trên App Store, nếu trùng thì thêm chữ, ví dụ "Ôn thi GPLX 600 câu"), ngôn ngữ chính Vietnamese, Bundle ID `com.toanquantic.gplx`, SKU tùy chọn (ví dụ `onthigplx`).

Tạo sản phẩm `pro_lifetime` ở cả hai bên (Play: Monetize > Products > In-app products; App Store: Monetization > In-App Purchases > Non-Consumable), đặt giá và tên, mô tả tiếng Việt. Apple yêu cầu ảnh chụp màn hình mua Pro để duyệt sản phẩm này, và sản phẩm đầu tiên phải gửi duyệt cùng phiên bản app.

## 7. Build và tải bản lên

1. Tab **Actions** > **Release** > **Run workflow**.
2. Lần đầu để `upload` tắt: workflow build AAB và IPA đã ký, tải ở mục Artifacts để kiểm tra.
3. **Google Play lần đầu**: tải tay file AAB lên Play Console (Testing > Internal testing > Create new release), vì API chỉ hoạt động sau khi app đã có bản đầu tiên.
4. Các lần sau bật `upload`:
   - Android: AAB lên kênh chọn ở `track` (mặc định internal) ở trạng thái **nháp**. Vào Play Console xem lại và bấm phát hành.
   - iOS: IPA lên App Store Connect, vài phút sau hiện trong TestFlight. Gửi duyệt bằng tay ở trang phiên bản app.

Số build tự tăng theo số lần chạy workflow (cộng 100). Đổi số phiên bản hiển thị (`1.0.0`) ở dòng `version:` trong `pubspec.yaml`.

## 8. Checklist trang store

### Chung

- [ ] **Chính sách quyền riêng tư** ở một địa chỉ công khai: nội dung đã soạn ở [`docs/privacy-policy.md`](privacy-policy.md), điền email liên hệ rồi đăng (GitHub Pages, Google Sites, Notion công khai...). Cả hai store bắt buộc.
- [ ] Email hỗ trợ (và trang web hỗ trợ cho Apple, có thể dùng chính trang chính sách).
- [ ] Tên app, mô tả ngắn, mô tả đầy đủ bằng tiếng Việt.
- [ ] **Ghi rõ không phải app của cơ quan nhà nước** ngay trong mô tả, kèm nguồn câu hỏi. Google Play có chính sách riêng về app liên quan đến thông tin chính phủ và sẽ từ chối nếu thiếu. Gợi ý: "Ứng dụng ôn tập độc lập, không phải sản phẩm của Cục Cảnh sát giao thông hay cơ quan nhà nước nào. Câu hỏi lấy từ bộ 600 câu sát hạch lý thuyết do Cục CSGT công bố, áp dụng từ 01/6/2025." Trong app đã có câu này ở trang Giới thiệu.
- [ ] Danh mục: Giáo dục (Education).

### Google Play

- [ ] Biểu tượng 512×512 PNG (xuất từ `branding/launcher_icon.svg`).
- [ ] Ảnh nổi bật (feature graphic) 1024×500.
- [ ] Ít nhất 2 ảnh chụp màn hình điện thoại (đã có vài ảnh trong `docs/screenshots/`, cần đủ tỉ lệ 16:9 hoặc 9:16, cạnh từ 320 đến 3840 px).
- [ ] **Data safety**: nhà phát triển không thu thập và không chia sẻ dữ liệu (mua hàng do Google xử lý). Mục video thực hành tải ảnh và phát video trực tiếp từ YouTube trong WebView; đọc lại hướng dẫn Data safety về nội dung bên thứ ba trong WebView trước khi chọn "Không thu thập dữ liệu", và giữ phần mô tả YouTube trong chính sách quyền riêng tư.
- [ ] **Content rating** (bảng hỏi IARC): không bạo lực, không nội dung người lớn, không tương tác người dùng; kết quả thường là mọi lứa tuổi (3+).
- [ ] **Target audience**: 18+ (người thi bằng lái), không nhắm tới trẻ em.
- [ ] Ads: Không có quảng cáo. Government apps: Không. Financial features: Không. Health: Không.
- [ ] Thử nghiệm kín 12 người trong 14 ngày (tài khoản cá nhân mới), rồi xin quyền phát hành production.

### App Store

- [ ] Ảnh chụp màn hình iPhone 6,9 inch (1320×2868 hoặc 1290×2796), 1 đến 10 ảnh.
- [ ] Ảnh chụp iPad 13 inch (2064×2752), vì app đang hỗ trợ cả iPad (`TARGETED_DEVICE_FAMILY = "1,2"`). Nếu không muốn làm ảnh iPad thì đổi thành chỉ iPhone trước lần gửi duyệt đầu.
- [ ] Phụ đề (subtitle) tối đa 30 ký tự, từ khóa tối đa 100 ký tự.
- [ ] **App Privacy**: nhà phát triển không thu thập dữ liệu. Mục video thực hành nhúng trình phát YouTube, nên đọc lại hướng dẫn App Privacy về dữ liệu bên thứ ba trước khi chọn "Data Not Collected", và giữ phần mô tả YouTube trong chính sách quyền riêng tư.
- [ ] **Age rating**: trả lời "Không" cho mọi mục, kết quả 4+.
- [ ] Export compliance: đã khai báo sẵn trong `Info.plist` (`ITSAppUsesNonExemptEncryption = false`), không phải trả lời mỗi lần tải bản lên.
- [ ] Ghi chú cho người duyệt: phần ôn thi chạy offline, mục video thực hành cần mạng để phát video YouTube; không cần tài khoản; bản Pro mua bằng In-App Purchase, có nút "Khôi phục giao dịch".
- [ ] Bản quyền (Copyright): ví dụ "2026 Tên của bạn".
