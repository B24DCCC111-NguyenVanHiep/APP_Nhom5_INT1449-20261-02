# PR: feat(p3): màn chính, màn mục tiêu, controller + đăng nhập cho Thử thách

Nhánh `feature/p3-ui` → `main`. **Chưa chạy được `flutter analyze/test` trong môi trường soạn thảo, cần chạy trước khi merge.**

## File theo phân công (Người 3)
- `lib/ui/widgets/state_views.dart` (giữ nguyên tên/tham số cũ; thêm tham số tuỳ chọn và `InlineErrorBanner`)
- `lib/logic/steps_controller.dart`
- `lib/ui/home_screen.dart`
- `lib/ui/goal_screen.dart`
- `test/steps_controller_test.dart` (21 test controller + 9 widget test)

## File thêm ngoài phân công (phần mở rộng, cần nhóm biết)
- Chuỗi/định dạng: `lib/ui/strings.dart`, `lib/ui/formatters.dart`
- Gợi ý: `lib/logic/insight_provider.dart`
- Đăng nhập: `lib/models/user_account.dart`, `lib/data/auth_repository.dart`, `lib/data/local_auth_repository.dart`, `lib/data/fake_auth_repository.dart`, `lib/logic/auth_controller.dart`, `lib/ui/login_screen.dart`, `lib/ui/register_screen.dart`, `lib/ui/widgets/auth_gate.dart`, `lib/ui/widgets/account_sheet.dart`
- Test: `test/auth_controller_test.dart`
- Tài liệu: `docs/ai/p3-tom-tat-hoi-thoai.md`, mục README bên dưới

## File dùng chung được sửa
- `pubspec.yaml`: thêm **`crypto`** (băm mật khẩu) và **`flutter_secure_storage`** (lưu tài khoản/phiên mã hoá). Không thêm gì khác. `pubspec.lock` chưa cập nhật: chạy `flutter pub get` rồi commit. **Báo Người 5 để tránh xung đột pubspec.lock.**
- KHÔNG sửa: 3 file chung, `main.dart`, `app.dart`, `friends_screen.dart`, `app_database.dart`.

## Người 5 cần thêm vào `app.dart`
`MultiProvider` phải bọc NGOÀI `MaterialApp` (để các route mới mở như Thử thách/Mục tiêu cũng thấy provider):

```dart
import 'package:provider/provider.dart';
import 'data/local_auth_repository.dart';      // demo: dùng FakeAuthRepository
import 'logic/auth_controller.dart';
import 'logic/steps_controller.dart';

// trong build() của StepTrackerApp:
return MultiProvider(
  providers: [
    ChangeNotifierProvider<StepsController>(
      create: (_) => StepsController(
        sensor: sensor, repository: repository, notifier: notifier,
      )..start(),
    ),
    ChangeNotifierProvider<AuthController>(
      create: (_) => AuthController(repository: LocalAuthRepository())..start(),
    ),
  ],
  child: MaterialApp(
    title: 'Theo dõi bước chân',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
    home: const HomeScreen(),
  ),
);
```
`ChangeNotifierProvider(create:)` tự gọi `dispose()` của controller khi app đóng.

## Kiểm tra gợi ý khi review
- [ ] `flutter pub get && flutter analyze && flutter test`
- [ ] Chạy `--dart-define=DEMO=true`: Home → Đổi mục tiêu → Biểu đồ → Thử thách (hiện đăng nhập) → đăng ký → vào đúng Thử thách → icon tài khoản → Đăng xuất
- [ ] Chữ lớn (Cài đặt → cỡ chữ lớn nhất) không tràn; TalkBack đọc được vòng tiến độ

---

## Đoạn README cho phần của Người 3

### Màn chính & mục tiêu
`StepsController` nhận số bước cộng dồn từ cảm biến, tính hiệu số với lần đọc trước (`StepCalculator`), cộng vào ngày hôm nay, lưu qua `StepRepository` và báo giao diện. Sự kiện được xử lý tuần tự; ngày được tính lại mỗi lần nên chạy đúng khi qua nửa đêm. Km/kcal/phút là **số ước tính** (0,0007 km, 0,04 kcal, 100 bước/phút) chứ không phải đo chính xác.

### Tài khoản (chỉ cần khi vào "Thử thách")
- Đếm bước, mục tiêu, biểu đồ **không cần tài khoản**. Mở Thử thách mà chưa đăng nhập thì hiện đăng nhập/đăng ký; có nút "Dùng thử không cần tài khoản".
- **Dữ liệu tài khoản lưu ở đâu:** chỉ trên máy, trong `flutter_secure_storage` (Android Keystore / iOS Keychain), khoá `auth.accounts.v1` (danh sách tài khoản) và `auth.session.v1` (phiên). Không dùng SQLite của ứng dụng, không gửi lên mạng.
- **Băm mật khẩu thế nào:** không lưu mật khẩu thô. Mỗi tài khoản có salt ngẫu nhiên 16 byte; hash = PBKDF2-HMAC-SHA256(mật khẩu, salt, 10.000 vòng); so sánh bằng hàm thời gian không đổi; số vòng lưu kèm bản ghi để sau tăng được.
- **Giới hạn:** đây là tài khoản ngoại tuyến mức đồ án (đổi máy là mất, không khôi phục mật khẩu). Muốn dùng thật cần backend/Firebase Auth: chỉ việc viết một lớp `implements AuthRepository` rồi thay vào `app.dart`, UI không phải sửa.

### Chừa chỗ cho AI / blockchain (chưa làm thật)
- Thẻ khích lệ trên Home lấy từ `InsightProvider`; bản mặc định `StaticInsightProvider` trả câu cố định theo % tiến độ. Sau này chỉ cần thay implementation.
- `UserAccount.walletAddress` để dành cho ví thử nghiệm (Hardhat chainId 31337, chỉ tiền ảo).
- Mọi dịch vụ ngoài đi qua interface và có bản giả/demo. **Không đưa API key, mật khẩu, private key vào code hay lịch sử Git; khoá chỉ nằm ở máy chủ.**

### Dùng AI
Phần của Người 3 được soạn với sự hỗ trợ của Claude (Anthropic): sinh khung code, test và tài liệu; Người 3 đọc, chạy và chịu trách nhiệm từng file. Tóm tắt hội thoại và các quyết định thiết kế: `docs/ai/p3-tom-tat-hoi-thoai.md`.
