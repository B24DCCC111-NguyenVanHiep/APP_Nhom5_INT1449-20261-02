# Phân công 5 thành viên (chủ đề 29: Theo dõi bước chân)

## Cách làm việc
- Mỗi người một nhánh Git, chỉ sửa file của mình, merge vào `main` bằng pull request.
- Ba file "quy ước chung" ở cuối trang do cả nhóm dùng, không ai tự ý sửa.
- Mỗi file đều có 2 dòng đầu ghi "file này để làm gì" và ai phụ trách.
- Mỗi người tự viết test cho phần mình, commit đều mỗi ngày.

## Người 1: Cảm biến  (nhánh `feature/p1-sensor`)
| File | Để làm gì |
|---|---|
| `lib/data/pedometer_sensor_service.dart` | Đọc số bước thật từ điện thoại, xin quyền |
| `lib/data/fake_step_sensor_service.dart` | Bước giả để chạy demo trên máy ảo |
| `lib/logic/step_calculator.dart` | Tính số bước tăng thêm, xét đạt mục tiêu, tính phần trăm |
| `test/step_calculator_test.dart` | Kiểm tra các phép tính trên |

## Người 2: Lưu dữ liệu  (nhánh `feature/p2-database`)
| File | Để làm gì |
|---|---|
| `lib/data/app_database.dart` | Tạo cơ sở dữ liệu SQLite trên máy |
| `lib/data/sqlite_step_repository.dart` | Lưu và đọc số bước theo ngày, mục tiêu |
| `lib/data/in_memory_step_repository.dart` | Bản lưu tạm để người khác dùng khi SQLite chưa xong |
| `test/repository_test.dart` | Kiểm tra lưu và đọc đúng |

## Người 3: Màn hình chính  (nhánh `feature/p3-ui`)
| File | Để làm gì |
|---|---|
| `lib/logic/steps_controller.dart` | Bộ não màn chính: nhận bước, lưu lại, báo giao diện cập nhật |
| `lib/ui/home_screen.dart` | Màn hình chính hiện số bước và vòng tròn tiến độ |
| `lib/ui/goal_screen.dart` | Màn hình đặt mục tiêu |
| `lib/ui/widgets/state_views.dart` | Ba giao diện dùng chung: đang tải, lỗi, chưa có dữ liệu |
| `test/steps_controller_test.dart` | Kiểm tra controller và màn hình |

## Người 4: Biểu đồ  (nhánh `feature/p4-chart`)
| File | Để làm gì |
|---|---|
| `lib/logic/stats_calculator.dart` | Tính trung bình, số ngày đạt mục tiêu, điền ngày thiếu |
| `lib/ui/chart_screen.dart` | Màn hình biểu đồ 7 ngày và 30 ngày |
| `test/stats_test.dart` | Kiểm tra thống kê |

## Người 5 (nhóm trưởng): Kết nối, thông báo, bạn bè  (nhánh `feature/p5-friends`)
| File | Để làm gì |
|---|---|
| `lib/main.dart` | Điểm khởi động app; chọn cảm biến thật hay giả (chế độ demo) |
| `lib/app.dart` | Tạo các đối tượng chung và chuyển cho các màn hình dùng |
| `lib/services/notification_service.dart` | Gửi thông báo khi đạt mục tiêu |
| `lib/data/friends_repository.dart` | Lấy và gửi số bước của bạn bè (bản giả, sau đó Firestore) |
| `lib/ui/friends_screen.dart` | Màn hình bảng xếp hạng bạn bè |
| `test/friends_test.dart` | Kiểm tra bảng xếp hạng đúng thứ tự |

Việc chung của cả nhóm: README, báo cáo, slide (mỗi người viết phần của mình). Người 5 gom lại.

## File quy ước chung (cả nhóm dùng, không tự ý sửa)
| File | Để làm gì |
|---|---|
| `lib/models/daily_steps.dart` | Mô tả số bước của một ngày |
| `lib/data/step_repository.dart` | Quy ước cách lưu và đọc số bước |
| `lib/data/step_sensor_service.dart` | Quy ước cách lấy số bước từ cảm biến |

## Thứ tự làm
1. Người 5 push khung này lên `main`.
2. Người 1, 2, 3, 4, 5 làm song song. Người 2 làm `in_memory_step_repository` và người 1 làm `fake_step_sensor_service` trước, để người 3, 4 chạy được giao diện sớm.
3. Cuối tuần 2: người 5 nối bản thật vào `main.dart`, cả nhóm thử trên máy Android thật.
