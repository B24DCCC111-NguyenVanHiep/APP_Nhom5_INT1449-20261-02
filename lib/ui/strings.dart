// FILE NÀY ĐỂ LÀM GÌ: Gom MỌI chuỗi hiển thị của phần Người 3 về một chỗ để sau này thêm tiếng Anh.
// Người phụ trách: Người 3

/// Lớp thuần Dart (không import Flutter) nên controller trong lib/logic cũng dùng được
/// cho thông báo lỗi. Muốn thêm tiếng Anh: đổi lớp này thành bản đọc theo Locale.
class AppStrings {
  AppStrings._();

  // ---- Chung ----
  static const appName = 'StepFlow';
  static const loading = 'Đang tải…';
  static const retry = 'Thử lại';
  static const grantPermission = 'Cấp quyền';
  static const close = 'Đóng';

  // ---- Màn chính ----
  static const homeTitle = 'Hôm nay';
  static const greetingMorning = 'Chào buổi sáng';
  static const greetingAfternoon = 'Chào buổi chiều';
  static const greetingEvening = 'Chào buổi tối';
  static const stepsUnit = 'bước chân';
  static const changeGoal = 'Đổi';
  static const changeGoalHint = 'Đổi mục tiêu bước mỗi ngày';
  static const kmLabel = 'km quãng đường';
  static const kcalLabel = 'kcal tiêu hao';
  static const minutesLabel = 'phút vận động';
  static const estimateNote =
      'Km, kcal và phút là số ước tính từ số bước, không phải đo chính xác.';
  static const chartTileTitle = 'Biểu đồ hoạt động';
  static const chartTileSubtitle = 'Xem 7 ngày và 30 ngày gần đây';
  static const challengeTileTitle = 'Thử thách bạn bè';
  static const challengeTileSubtitle = 'Cần tài khoản để tham gia xếp hạng';
  static const emptyTitle = 'Chưa có bước nào hôm nay';
  static const emptyHint =
      'Hãy đi bộ vài bước, ứng dụng đang chờ dữ liệu từ cảm biến.';
  static const noPermissionMessage =
      'Ứng dụng cần quyền nhận dạng hoạt động để đếm bước chân của bạn.';
  static const permissionDenied =
      'Quyền đếm bước chưa được cấp. Hãy cấp quyền để tiếp tục.';
  static const goalSaved = 'Đã lưu mục tiêu mới';
  static const accountTooltip = 'Tài khoản';

  static String percentOfGoal(int percent) => '$percent% mục tiêu';
  static String goalLabel(String goal) => 'Mục tiêu: $goal bước';
  static String ringSemantics(String steps, int percent, String goal) =>
      'Hôm nay bạn đã đi $steps bước, đạt $percent% mục tiêu $goal bước';

  // ---- Gợi ý (InsightProvider) ----
  static const insightStart = 'Hãy bắt đầu bằng một cuộc đi bộ ngắn nhé!';
  static const insightDone = 'Tuyệt vời! Bạn đã hoàn thành mục tiêu hôm nay.';
  static String insightRemaining(String remaining) =>
      'Bạn còn $remaining bước nữa để về đích hôm nay!';
  static String insightHalfway(String remaining) =>
      'Đã đi được nửa chặng, còn $remaining bước nữa thôi!';

  // ---- Lỗi của StepsController ----
  static const errorLoad =
      'Không đọc được dữ liệu bước chân. Vui lòng thử lại.';
  static const errorSensor = 'Không nhận được dữ liệu từ cảm biến bước chân.';
  static const errorSave = 'Không lưu được số bước. Vui lòng thử lại.';
  static const errorGeneric = 'Đã có lỗi không mong muốn. Vui lòng thử lại.';

  // ---- Màn mục tiêu ----
  static const goalTitle = 'Mục tiêu mỗi ngày';
  static const goalIntro = 'Chọn số bước bạn muốn đạt mỗi ngày.';
  static const goalFieldLabel = 'Số bước mỗi ngày';
  static const goalFieldHelper = 'Từ 1 đến 100.000 bước';
  static const goalFieldSuffix = 'bước';
  static const goalPresetsLabel = 'Gợi ý nhanh';
  static const save = 'Lưu';
  static const goalEmpty = 'Vui lòng nhập số bước mục tiêu.';
  static const goalOutOfRange = 'Mục tiêu phải từ 1 đến 100.000 bước.';
  static const goalSaveFailed =
      'Không lưu được mục tiêu. Vui lòng thử lại.';

  // ---- Tài khoản / đăng nhập ----
  static const loginTitle = 'Đăng nhập';
  static const loginIntro =
      'Đăng nhập để tham gia Thử thách cùng bạn bè. Đếm bước, mục tiêu và biểu đồ không cần tài khoản.';
  static const registerTitle = 'Tạo tài khoản';
  static const registerIntro =
      'Tài khoản chỉ lưu trên máy này (ngoại tuyến), mật khẩu được băm trước khi lưu.';
  static const nameLabel = 'Họ và tên';
  static const emailLabel = 'Email';
  static const passwordLabel = 'Mật khẩu';
  static const confirmLabel = 'Xác nhận mật khẩu';
  static const showPassword = 'Hiện mật khẩu';
  static const hidePassword = 'Ẩn mật khẩu';
  static const loginButton = 'Đăng nhập';
  static const goRegister = 'Tạo tài khoản mới';
  static const registerButton = 'Đăng ký';
  static const goLogin = 'Đã có tài khoản? Đăng nhập';
  static const guestButton = 'Dùng thử không cần tài khoản';
  static const signOut = 'Đăng xuất';
  static const accountTitle = 'Tài khoản';
  static const accountGuestInfo =
      'Bạn đang dùng ứng dụng không cần tài khoản. Chỉ cần đăng nhập khi vào Thử thách.';

  static const authNameEmpty = 'Vui lòng nhập họ và tên.';
  static const authEmailEmpty = 'Vui lòng nhập email.';
  static const authEmailInvalid =
      'Email chưa đúng định dạng (ví dụ: ban@example.com).';
  static const authPasswordEmpty = 'Vui lòng nhập mật khẩu.';
  static const authPasswordShort = 'Mật khẩu cần ít nhất 8 ký tự.';
  static const authConfirmMismatch = 'Mật khẩu xác nhận không khớp.';
  static const authEmailTaken =
      'Email này đã được đăng ký. Hãy đăng nhập hoặc dùng email khác.';
  static const authBadCredentials = 'Email hoặc mật khẩu không đúng.';
  static const authStorageError =
      'Không truy cập được nơi lưu tài khoản trên máy. Vui lòng thử lại.';
  static const authGenericError = 'Đã có lỗi xảy ra. Vui lòng thử lại.';

  static const weekdays = <String>[
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ nhật',
  ];
}
