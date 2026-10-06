# Báo cáo và nhật ký kiểm thử frontend

Ngày bắt đầu: 2026-10-02. Phạm vi: thư mục `frontend` (workspace hiện tại).

## Mục tiêu và nguyên tắc

Khảo sát kiến trúc, ghi baseline, bổ sung unit/widget tests có giá trị, sửa lỗi được chứng minh và chạy regression. Không truy cập dữ liệu production. Phân biệt kết quả chạy thực tế với nhận xét từ source. Báo cáo này được cập nhật xuyên suốt quá trình.

## Nhật ký

1. `git status --short`: sạch tại thời điểm bắt đầu. Tìm `AGENTS.md` trong repository: không thấy.
2. Kiểm tra `pubspec.yaml`, `firebase.json`, `main.dart`, validators, models, widgets và repositories. Kiến trúc Flutter UI → Provider → Repository → Firestore/HTTP; Firebase khởi tạo trực tiếp trong main. Có URL Django local trong PostRepository nhưng repository cha không có backend.
3. Công cụ trong PATH: Flutter, Dart, Python, Firebase CLI. Không tìm thấy k6/adb trong PATH (chưa kết luận chưa cài).
4. Baseline source: `test/widget_test.dart` dựng MaterialApp trống nhưng mong có counter và nút cộng. Test này không đại diện ứng dụng.
5. Chạy `flutter --version; flutter doctor -v; flutter devices` trong sandbox: không có output; Flutter launcher cần lock/cache tại `C:\flutter\bin\cache` ngoài workspace. Đã yêu cầu chạy ngoài sandbox và chạy được. Kiểm tra process qua CIM bị từ chối quyền; dừng phiên Flutter sandbox do chính agent khởi chạy bằng Ctrl+C.
6. Môi trường: Windows 10, Flutter 3.38.9 stable, Dart 3.10.8, DevTools 2.51.1. Android SDK 36.1.0 có sẵn nhưng thiếu cmdline-tools, trạng thái license chưa xác định. Thiết bị được phát hiện: Windows, Chrome, Edge; không có Android kết nối. Không tự chấp nhận license hay cài SDK.
7. `flutter analyze --no-pub`: exit 1; 195 issues gồm 0 error, 91 warning, 104 info. Lưu `baseline_analyze.log`.
8. `flutter test --no-pub --reporter expanded`: exit 1; 0 pass, 1 fail. Counter test thất bại tại kỳ vọng text `0`; widget được dựng không có counter. Lưu `baseline_test.log`.
9. Thêm `test/validators_test.dart` và `test/models_test.dart`; chạy `flutter test --no-pub test/validators_test.dart test/models_test.dart --reporter expanded`: exit 1; 35 pass, 12 fail. Cả 12 failure thuộc giá trị nhiên liệu/hộp số hợp lệ. Lưu `regression_before.log`.
10. Sửa hai danh sách trong `CarValidator` thành chữ thường, giữ nguyên giá trị trả về và cơ chế so sánh không phân biệt hoa thường. Không đổi quy tắc nghiệp vụ khác. Thay counter test sai bằng ba widget test của AuthTextField/AuthDropdownField. Lần apply_patch đầu bị từ chối vì delete/add trùng đường dẫn, không thay đổi file; lần update tiếp theo thành công.
11. `flutter test --no-pub --coverage --reporter expanded`: exit 0, 50 pass, 0 fail. `flutter analyze --no-pub`: exit 1, 193 issues (0 error, 90 warning, 103 info). Hai vấn đề giảm do bỏ import không dùng và dựng widget không const trong test mẫu; không coi lint còn lại là PASS.
12. `flutter build web --no-pub`: log xác nhận `Built build/web`, bước biên dịch 78.8 giây. Có thông báo Wasm dry run thành công; PowerShell bọc stderr thành NativeCommandError trong log, nhưng đây không phải build failure. Phiên lệnh kết thúc trong lúc hội thoại bị ngắt nên không còn lấy được exit code qua session. Đây là kiểm tra biên dịch, không phải kiểm thử web E2E.
13. Người dùng ngắt rồi yêu cầu tiếp tục. Kiểm tra file/log và git status trước khi tiếp tục. Lệnh format + coverage-path riêng trước lần ngắt chưa thấy thực thi, nên chạy lại để định dạng test và tạo báo cáo coverage riêng.

## Thiết kế test và rủi ro được bao phủ

| File | Số test | Mục đích |
| --- | ---: | --- |
| `test/validators_test.dart` | 39 | Email sai/rỗng; password thiếu/rỗng/ngắn/thiếu chữ hoặc số; phone sai độ dài/đầu số/ký tự; xác nhận mật khẩu; required field; nhiên liệu/hộp số hợp lệ và không hợp lệ; biển số; vị trí rỗng; tên có khoảng trắng và biên 50 ký tự; trạng thái user và moderation |
| `test/models_test.dart` | 8 | Bảo toàn dữ liệu Car/Post khi map round-trip; giá số nguyên/số thực; seller nullable; từ chối giá sai kiểu; Firestore Timestamp; ISO datetime có timezone; chuỗi ngày không hợp lệ |
| `test/widget_test.dart` | 3 | Form email hiển thị lỗi rồi xóa lỗi khi sửa; ẩn/hiện mật khẩu không mất input; dropdown yêu cầu lựa chọn và trả đúng lựa chọn |

Các test chạy local, không cần Firebase.initializeApp, không gọi Firestore/Cloudinary/Django. Timestamp chỉ dùng như kiểu dữ liệu. Không thêm dependency. Ba widget test kiểm tra component thật, chưa đại diện toàn bộ luồng đăng nhập/đăng tin.

## Thay đổi ứng dụng đã được chứng minh bằng test

- Lỗi: `validateTransmission` và `validateFuelType` lower-case input nhưng whitelist còn chữ hoa.
- Bằng chứng trước sửa: 12 test hợp lệ thất bại. Sau sửa: toàn bộ 50 test đạt.
- Phạm vi tác động: helper validator. Chưa chứng minh lỗi này xuất hiện trong luồng UI hiện tại; tìm kiếm chưa thấy UI gọi CarValidator.
- Không thay test để né lỗi. Counter test ban đầu được thay vì fixture không có tính năng mà test yêu cầu.

## Trạng thái hoàn thành

Hoàn tất vòng kiểm thử local và build web trong phạm vi môi trường hiện có. Chưa hoàn tất kiểm thử toàn hệ thống. Không sửa hàng loạt 193 cảnh báo/thông tin ngoài phạm vi; chi tiết đầy đủ ở phụ lục.

### Chạy lại

Từ thư mục `frontend` với SDK có quyền ghi cache:

```powershell
flutter analyze --no-pub
flutter test --no-pub --coverage --coverage-path=coverage/local_suite.lcov.info --reporter expanded
flutter build web --no-pub
```

Máy mới cần chuẩn bị dependencies trước khi dùng `--no-pub`. File `.log` và thư mục `coverage` có thể bị gitignore; phụ lục báo cáo sẽ giữ bản sao kết quả để không phụ thuộc các file bị ignore.

## Rủi ro phát hiện qua đọc source (chưa phải kết quả runtime)

- `CarValidator`: đã xác nhận và sửa, xem phần bằng chứng ở trên.
- `AuthValidator`: thông báo yêu cầu ký tự đặc biệt nhưng regex không bắt buộc; cần xác nhận chính sách mật khẩu trước khi đổi hành vi.
- `Post.fromMap`: ngày thiếu/sai kiểu bị thay bằng DateTime.now(), có thể che dữ liệu lỗi; cần quyết định nghiệp vụ.
- `PostRepository.getPostsWithCarAndImages`: đọc toàn bộ posts, sau đó await car/model/user/images trong vòng lặp; nguy cơ N+1 và độ trễ tăng theo dữ liệu. Chưa có đo thời gian thực tế.
- Auto-increment post dùng đọc max ID rồi ghi, không transaction: nguy cơ ghi đè khi đồng thời; chưa chạy concurrency test.

## Phần cần môi trường bổ sung

Firebase security rules/emulator, backend Django/test database, tài khoản/dữ liệu test, thiết bị Android và giới hạn tải để chạy integration/API/load/performance. Chưa chạy và không tính các phần này là PASS.

| Hạng mục | Trạng thái / cần bổ sung |
| --- | --- |
| Android APK / device E2E | Chưa chạy build APK; doctor báo toolchain chưa đầy đủ, chưa có thiết bị kết nối |
| iOS | Chưa chạy; môi trường hiện tại là Windows |
| Firebase rules / phân quyền thật | Chưa chạy; không thấy rules và cấu hình emulator trong frontend |
| Django API | Chưa chạy; cần đường dẫn backend, hướng dẫn chạy, test DB và contract endpoint |
| Concurrency/idempotency | Chưa chạy; cần test backend/emulator và dữ liệu tách biệt |
| Homepage profiling | Chưa đo; cần thiết bị, tài khoản, dataset và mốc định nghĩa tải xong. N+1 hiện mới là phát hiện từ source |
| Load k6 | Chưa chạy; cần endpoint test, tải tối đa, thời lượng, ngưỡng chấp nhận |
| CI regression | Chưa cấu hình trong đợt này; có thể dùng các lệnh trên sau khi chuẩn hóa SDK |

Đã hỏi người dùng về vị trí Django và môi trường Firebase/Android; chưa có câu trả lời trong đợt này. Không phát sinh request đến production. Không suy ra p95/p99 hoặc tốc độ homepage từ thời gian chạy unit test.

## Xác minh cuối cùng và coverage

Sau khi format 3 file test, chạy lại test với coverage/local_suite.lcov.info: exit 0, 50 PASS, 0 FAIL, 0 SKIP. git diff --check: exit 0 (chỉ có thông báo Git chuyển LF/CRLF).

Coverage theo dòng trong LCOV của lần chạy riêng; không phải branch coverage, không chứng minh toàn hệ thống đúng. Những file không có trong LCOV cũng chưa được chứng minh đã kiểm thử.

| File | Hit / Lines |
| --- | ---: |
| lib\models\car_model.dart | 26 / 26 |
| lib\models\post_model.dart | 20 / 22 |
| lib\main.dart | 1 / 23 |
| lib\repositories\car_repository.dart | 0 / 34 |
| lib\repositories\image_repository.dart | 0 / 60 |
| lib\repositories\model_repository.dart | 0 / 27 |
| lib\repositories\post_repository.dart | 0 / 182 |
| lib\repositories\user_repository.dart | 0 / 128 |
| lib\services\storage_service.dart | 0 / 16 |
| lib\providers\post_provider.dart | 0 / 54 |
| lib\providers\brand_provider.dart | 0 / 17 |
| lib\providers\user_provider.dart | 0 / 178 |
| lib\services\firebase_options.dart | 0 / 11 |
| lib\navigation\app_router.dart | 0 / 141 |
| lib\providers\model_provider.dart | 0 / 25 |
| lib\providers\car_provider.dart | 0 / 15 |
| lib\providers\favorite_provider.dart | 0 / 55 |
| lib\models\brand_model.dart | 0 / 8 |
| lib\models\favorite_model.dart | 0 / 10 |
| lib\models\image_model.dart | 0 / 12 |
| lib\models\model_model.dart | 0 / 12 |
| lib\models\post_with_car_and_images.dart | 0 / 14 |
| lib\models\user_model.dart | 0 / 41 |
| lib\utils\validators\user_validator.dart | 8 / 8 |
| lib\ui\screen\auth\register_screen.dart | 1 / 66 |
| lib\ui\screen\user\sell_screen.dart | 1 / 74 |
| lib\ui\screen\user\buy_screen.dart | 1 / 271 |
| lib\ui\screen\user\profile_screen.dart | 0 / 142 |
| lib\ui\screen\auth\login_user_screen.dart | 1 / 66 |
| lib\ui\screen\user\introduction.dart | 1 / 30 |
| lib\ui\screen\user\model_list_screen.dart | 0 / 47 |
| lib\ui\screen\auth\register_success_screen.dart | 1 / 40 |
| lib\ui\screen\user\condition_origin_screen.dart | 0 / 94 |
| lib\ui\screen\user\confirm_post_screen.dart | 0 / 505 |
| lib\ui\screen\user\favorite_screen.dart | 1 / 99 |
| lib\ui\screen\user\fuel_transmission_screen.dart | 0 / 64 |
| lib\ui\screen\user\image_upload_screen.dart | 0 / 95 |
| lib\ui\screen\user\price_title_description_screen.dart | 0 / 86 |
| lib\ui\screen\user\year_selection_screen.dart | 0 / 29 |
| lib\ui\widgets\user\buy_app_screen.dart | 1 / 7 |
| lib\ui\screen\user\my_post_screen.dart | 1 / 139 |
| lib\ui\screen\user\notifications_screen.dart | 1 / 44 |
| lib\ui\screen\user\post_detail_screen.dart | 0 / 159 |
| lib\ui\widgets\user\sell_app_screen.dart | 1 / 7 |
| lib\repositories\brand_repository.dart | 0 / 20 |
| lib\repositories\favorite_repository.dart | 0 / 42 |
| lib\utils\validators\auth_validator.dart | 16 / 16 |
| lib\ui\widgets\user\auth_text_field.dart | 18 / 18 |
| lib\ui\screen\auth\widgets\auth_header.dart | 0 / 9 |
| lib\ui\widgets\user\auth_dropdown_field.dart | 13 / 13 |
| lib\ui\widgets\user\buy_bottom_navigation_bar.dart | 1 / 17 |
| lib\ui\screen\user\location_filter_screen.dart | 1 / 21 |
| lib\ui\widgets\user\sell_bottom_navigation_bar.dart | 1 / 15 |
| lib\utils\validators\car_validator.dart | 12 / 12 |
| lib\utils\validators\post_validator.dart | 4 / 4 |

Tổng trong LCOV: 132 / 3370 dòng; 3.92%.

## Phụ lục: log thực thi

### baseline_analyze.log

```text
Analyzing frontend...                                           

   info - Don't invoke 'print' in production code - lib\models\post_model.dart:35:7 - avoid_print
warning - Unused import: '../providers/favorite_provider.dart' - lib\navigation\app_router.dart:26:8 - unused_import
warning - Unused import: '../ui/screen/user/post_detail_screen.dart' - lib\navigation\app_router.dart:29:8 - unused_import
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:146:55 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:147:52 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:148:59 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:163:55 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:164:52 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:165:59 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:166:65 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:182:55 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:183:52 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:184:59 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:185:65 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:187:19 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:189:19 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:191:19 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:207:55 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:208:52 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:209:59 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:210:65 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:212:19 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:214:19 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:216:19 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:218:19 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:220:19 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:235:55 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:236:52 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:237:59 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:238:65 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:239:59 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:240:53 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:241:52 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:242:57 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:243:65 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:244:51 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:245:51 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:246:63 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:259:55 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:260:52 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:261:59 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:262:65 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:263:59 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:264:53 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:265:52 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:266:57 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:267:65 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:268:51 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:269:51 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:270:63 - dead_null_aware_expression
warning - This cast always throws an exception because the expression always evaluates to 'null' - lib\providers\car_provider.dart:37:66 - cast_from_null_always_fails
   info - Don't invoke 'print' in production code - lib\providers\car_type_provider.dart:21:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\car_type_provider.dart:34:7 - avoid_print
warning - Unused import: 'package:cloud_firestore/cloud_firestore.dart' - lib\providers\favorite_provider.dart:2:8 - unused_import
   info - The private field _favoritePostsWithDetails could be 'final' - lib\providers\favorite_provider.dart:17:30 - prefer_final_fields
   info - Don't invoke 'print' in production code - lib\providers\favorite_provider.dart:44:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\favorite_provider.dart:153:11 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\favorite_provider.dart:157:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\favorite_provider.dart:171:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\favorite_provider.dart:181:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\favorite_provider.dart:192:7 - avoid_print
warning - Unused import: 'package:online_car_marketplace_app/models/car_model.dart' - lib\providers\post_provider.dart:6:8 - unused_import
   info - Don't invoke 'print' in production code - lib\providers\post_provider.dart:65:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\post_provider.dart:85:9 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\post_provider.dart:90:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\role_provider.dart:21:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\role_provider.dart:34:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\user_provider.dart:203:7 - avoid_print
   info - Don't use 'BuildContext's across async gaps - lib\providers\user_provider.dart:334:28 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\providers\user_provider.dart:339:28 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\providers\user_provider.dart:371:28 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\providers\user_provider.dart:382:28 - use_build_context_synchronously
   info - Don't invoke 'print' in production code - lib\repositories\model_repository.dart:49:7 - avoid_print
warning - The receiver can't be null, so the null-aware operator '?.' is unnecessary - lib\repositories\post_repository.dart:73:16 - invalid_null_aware_operator
warning - The '!' will have no effect because the receiver can't be null - lib\repositories\post_repository.dart:75:75 - unnecessary_non_null_assertion
   info - Don't invoke 'print' in production code - lib\repositories\post_repository.dart:81:13 - avoid_print
warning - The '!' will have no effect because the receiver can't be null - lib\repositories\post_repository.dart:81:67 - unnecessary_non_null_assertion
warning - The receiver can't be null, so the null-aware operator '?.' is unnecessary - lib\repositories\post_repository.dart:165:14 - invalid_null_aware_operator
warning - The '!' will have no effect because the receiver can't be null - lib\repositories\post_repository.dart:167:73 - unnecessary_non_null_assertion
   info - Don't invoke 'print' in production code - lib\repositories\post_repository.dart:173:11 - avoid_print
warning - The '!' will have no effect because the receiver can't be null - lib\repositories\post_repository.dart:173:65 - unnecessary_non_null_assertion
   info - Don't invoke 'print' in production code - lib\repositories\post_repository.dart:191:9 - avoid_print
warning - The receiver can't be null, so the null-aware operator '?.' is unnecessary - lib\repositories\post_repository.dart:246:16 - invalid_null_aware_operator
warning - The '!' will have no effect because the receiver can't be null - lib\repositories\post_repository.dart:248:75 - unnecessary_non_null_assertion
   info - Don't invoke 'print' in production code - lib\repositories\post_repository.dart:254:13 - avoid_print
warning - The '!' will have no effect because the receiver can't be null - lib\repositories\post_repository.dart:254:67 - unnecessary_non_null_assertion
   info - Don't invoke 'print' in production code - lib\repositories\post_repository.dart:260:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\post_repository.dart:279:9 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\post_repository.dart:298:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\post_repository.dart:409:9 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\post_repository.dart:413:7 - avoid_print
warning - The value of the field '_pendingRegistrations' isn't used - lib\repositories\user_repository.dart:10:27 - unused_field
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:96:7 - avoid_print
   info - Use 'rethrow' to rethrow a caught exception - lib\repositories\user_repository.dart:97:7 - use_rethrow_when_possible
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:272:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:273:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:276:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:283:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:286:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:294:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:297:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:300:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:302:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:304:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:311:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:314:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:315:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\services\storage_service.dart:26:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\services\storage_service.dart:28:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\services\storage_service.dart:45:7 - avoid_print
   info - The variable name 'car_types' isn't a lowerCamelCase identifier - lib\ui\screen\admin\category_management_screen.dart:14:15 - non_constant_identifier_names
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\admin\login_admin_screen.dart:60:13 - use_build_context_synchronously
warning - Unused import: '../auth/widgets/auth_header.dart' - lib\ui\screen\auth\login_user_screen.dart:8:8 - unused_import
warning - Duplicate import - lib\ui\screen\auth\register_screen.dart:9:8 - duplicate_import
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\ui\screen\user\buy_screen.dart:387:38 - deprecated_member_use
warning - The receiver can't be null, so the null-aware operator '?.' is unnecessary - lib\ui\screen\user\buy_screen.dart:414:39 - invalid_null_aware_operator
warning - The left operand can't be null, so the right operand is never executed - lib\ui\screen\user\buy_screen.dart:447:69 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\ui\screen\user\buy_screen.dart:461:72 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\ui\screen\user\buy_screen.dart:465:72 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\ui\screen\user\buy_screen.dart:476:69 - dead_null_aware_expression
warning - The operand can't be 'null', so the condition is always 'true' - lib\ui\screen\user\buy_screen.dart:480:64 - unnecessary_null_comparison
   info - 'groupValue' is deprecated and shouldn't be used. Use a RadioGroup ancestor to manage group value instead. This feature was deprecated after v3.32.0-0.0.pre - lib\ui\screen\user\condition_origin_screen.dart:95:21 - deprecated_member_use
   info - 'onChanged' is deprecated and shouldn't be used. Use RadioGroup to handle value change instead. This feature was deprecated after v3.32.0-0.0.pre - lib\ui\screen\user\condition_origin_screen.dart:96:21 - deprecated_member_use
   info - 'groupValue' is deprecated and shouldn't be used. Use a RadioGroup ancestor to manage group value instead. This feature was deprecated after v3.32.0-0.0.pre - lib\ui\screen\user\condition_origin_screen.dart:107:21 - deprecated_member_use
   info - 'onChanged' is deprecated and shouldn't be used. Use RadioGroup to handle value change instead. This feature was deprecated after v3.32.0-0.0.pre - lib\ui\screen\user\condition_origin_screen.dart:108:21 - deprecated_member_use
   info - 'groupValue' is deprecated and shouldn't be used. Use a RadioGroup ancestor to manage group value instead. This feature was deprecated after v3.32.0-0.0.pre - lib\ui\screen\user\condition_origin_screen.dart:155:21 - deprecated_member_use
   info - 'onChanged' is deprecated and shouldn't be used. Use RadioGroup to handle value change instead. This feature was deprecated after v3.32.0-0.0.pre - lib\ui\screen\user\condition_origin_screen.dart:156:21 - deprecated_member_use
   info - 'groupValue' is deprecated and shouldn't be used. Use a RadioGroup ancestor to manage group value instead. This feature was deprecated after v3.32.0-0.0.pre - lib\ui\screen\user\condition_origin_screen.dart:167:21 - deprecated_member_use
   info - 'onChanged' is deprecated and shouldn't be used. Use RadioGroup to handle value change instead. This feature was deprecated after v3.32.0-0.0.pre - lib\ui\screen\user\condition_origin_screen.dart:168:21 - deprecated_member_use
   info - The private field _imageUrlsToDelete could be 'final' - lib\ui\screen\user\confirm_post_screen.dart:60:16 - prefer_final_fields
warning - The declaration '_getCurrentConfirmPostData' isn't referenced - lib\ui\screen\user\confirm_post_screen.dart:95:24 - unused_element
   info - Don't invoke 'print' in production code - lib\ui\screen\user\confirm_post_screen.dart:196:9 - avoid_print
   info - Type could be non-nullable - lib\ui\screen\user\confirm_post_screen.dart:214:24 - unnecessary_nullable_for_final_variable_declarations
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\confirm_post_screen.dart:319:28 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\confirm_post_screen.dart:329:7 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\confirm_post_screen.dart:331:28 - use_build_context_synchronously
   info - Unnecessary braces in a string interpolation - lib\ui\screen\user\confirm_post_screen.dart:513:40 - unnecessary_brace_in_string_interps
warning - The receiver can't be null, so the null-aware operator '?.' is unnecessary - lib\ui\screen\user\favorite_screen.dart:78:35 - invalid_null_aware_operator
   info - Unnecessary escape in string literal - lib\ui\screen\user\favorite_screen.dart:78:57 - unnecessary_string_escapes
warning - The left operand can't be null, so the right operand is never executed - lib\ui\screen\user\favorite_screen.dart:111:65 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\ui\screen\user\favorite_screen.dart:125:68 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\ui\screen\user\favorite_screen.dart:129:68 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\ui\screen\user\favorite_screen.dart:140:65 - dead_null_aware_expression
warning - The operand can't be 'null', so the condition is always 'true' - lib\ui\screen\user\favorite_screen.dart:144:60 - unnecessary_null_comparison
   info - 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre - lib\ui\screen\user\fuel_transmission_screen.dart:78:15 - deprecated_member_use
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\fuel_transmission_screen.dart:102:27 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\fuel_transmission_screen.dart:108:29 - prefer_const_constructors
   info - 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre - lib\ui\screen\user\fuel_transmission_screen.dart:111:15 - deprecated_member_use
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\image_upload_screen.dart:135:29 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\image_upload_screen.dart:137:29 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\image_upload_screen.dart:139:38 - prefer_const_constructors
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\ui\screen\user\introduction.dart:44:35 - deprecated_member_use
warning - The value of the local variable 'postProvider' isn't used - lib\ui\screen\user\location_filter_screen.dart:26:11 - unused_local_variable
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\model_list_screen.dart:52:16 - prefer_const_constructors
   info - Don't invoke 'print' in production code - lib\ui\screen\user\model_list_screen.dart:89:19 - avoid_print
warning - Unused import: '../../widgets/user/sell_bottom_navigation_bar.dart' - lib\ui\screen\user\my_post_screen.dart:14:8 - unused_import
warning - The '!' will have no effect because the receiver can't be null - lib\ui\screen\user\my_post_screen.dart:62:88 - unnecessary_non_null_assertion
warning - The operand can't be 'null', so the condition is always 'true' - lib\ui\screen\user\my_post_screen.dart:68:27 - unnecessary_null_comparison
warning - The '!' will have no effect because the receiver can't be null - lib\ui\screen\user\my_post_screen.dart:69:70 - unnecessary_non_null_assertion
   info - Don't invoke 'print' in production code - lib\ui\screen\user\my_post_screen.dart:95:7 - avoid_print
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\my_post_screen.dart:122:60 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\my_post_screen.dart:123:58 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\my_post_screen.dart:124:62 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\my_post_screen.dart:125:60 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\my_post_screen.dart:140:30 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\my_post_screen.dart:145:30 - use_build_context_synchronously
   info - Don't invoke 'print' in production code - lib\ui\screen\user\my_post_screen.dart:148:9 - avoid_print
warning - The '!' will have no effect because the receiver can't be null - lib\ui\screen\user\my_post_screen.dart:318:66 - unnecessary_non_null_assertion
warning - The '!' will have no effect because the receiver can't be null - lib\ui\screen\user\my_post_screen.dart:318:84 - unnecessary_non_null_assertion
warning - Unused import: 'package:go_router/go_router.dart' - lib\ui\screen\user\notifications_screen.dart:3:8 - unused_import
warning - The declaration '_buildNotificationSection' isn't referenced - lib\ui\screen\user\notifications_screen.dart:57:10 - unused_element
warning - The declaration '_buildNotificationItem' isn't referenced - lib\ui\screen\user\notifications_screen.dart:78:10 - unused_element
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\ui\screen\user\notifications_screen.dart:88:50 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\ui\screen\user\notifications_screen.dart:97:32 - deprecated_member_use
warning - The value of the local variable 'carLocation' isn't used - lib\ui\screen\user\post_detail_screen.dart:39:11 - unused_local_variable
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\ui\screen\user\post_detail_screen.dart:104:51 - deprecated_member_use
warning - The receiver can't be 'null' because of short-circuiting, so the null-aware operator '?.' can't be used - lib\ui\screen\user\post_detail_screen.dart:165:84 - invalid_null_aware_operator
warning - The receiver can't be 'null' because of short-circuiting, so the null-aware operator '?.' can't be used - lib\ui\screen\user\post_detail_screen.dart:167:81 - invalid_null_aware_operator
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\ui\screen\user\post_detail_screen.dart:263:38 - deprecated_member_use
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\post_detail_screen.dart:382:28 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\post_detail_screen.dart:395:28 - use_build_context_synchronously
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\price_title_description_screen.dart:108:27 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\price_title_description_screen.dart:117:29 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\price_title_description_screen.dart:134:27 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\price_title_description_screen.dart:142:29 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\price_title_description_screen.dart:161:27 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\price_title_description_screen.dart:169:29 - prefer_const_constructors
   info - Invalid use of a private type in a public API - lib\ui\screen\user\profile_screen.dart:16:3 - library_private_types_in_public_api
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\profile_screen.dart:92:32 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\profile_screen.dart:113:44 - use_build_context_synchronously
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\ui\screen\user\sell_screen.dart:188:46 - deprecated_member_use
   info - 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre - lib\ui\widgets\user\auth_dropdown_field.dart:22:7 - deprecated_member_use
   info - Don't invoke 'print' in production code - lib\utils\validators\user_validator.dart:16:7 - avoid_print
warning - Unused import: 'package:online_car_marketplace_app/main.dart' - test\widget_test.dart:11:8 - unused_import
   info - Use 'const' with the constructor to improve performance - test\widget_test.dart:16:29 - prefer_const_constructors

flutter : 195 issues found. (ran in 21.5s)
At line:2 char:1
+ flutter analyze --no-pub *> baseline_analyze.log; $analysisCode = $LA ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (195 issues found. (ran in 21.5s):String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 

```

### baseline_test.log

```text
00:00 +0: loading C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/widget_test.dart
00:00 +0: Counter increments smoke test
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "0": []>
   Which: means none were found but one was expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure> (file:///C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/widget_test.dart:19:5)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/widget_test.dart line 19
The test description was:
  Counter increments smoke test
════════════════════════════════════════════════════════════════════════════════════════════════════
00:00 +0 -1: Counter increments smoke test [E]
  Test failed. See exception logs above.
  The test description was: Counter increments smoke test
  
00:00 +0 -1: Some tests failed.

```

### regression_before.log

```text
00:00 +0: loading C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart
00:00 +0: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid email: null
00:00 +1: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid email: 
00:00 +2: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid email: plain
00:00 +3: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid email: a@
00:00 +4: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid email: @example.com
00:00 +5: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries accept ordinary email
00:00 +6: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid password: null
00:00 +7: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid password: 
00:00 +8: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid password: Ab1!xyz
00:00 +9: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid password: abcdefgh
00:00 +10: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid password: 12345678
00:00 +11: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries accept password at eight-character boundary
00:00 +12: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid phone: null
00:00 +13: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid phone: 
00:00 +14: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid phone: 1234567890
00:00 +15: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid phone: 012345678
00:00 +16: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid phone: 01234567890
00:00 +17: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid phone: 0abcdefghi
00:00 +18: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries accept ten-digit phone starting with zero
00:00 +19: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries confirmation requires matching nonempty password
00:00 +20: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries required field rejects absent values
00:00 +21: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported transmission Tự động
00:00 +22: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported transmission Tự động
00:00 +22 -1: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/models_test.dart: car accepts integer API price as double
00:00 +22 -1: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported transmission Tự động [E]
  Exception: Hộp số không hợp lệ (chỉ chấp nhận: tự động, số sàn)
  package:online_car_marketplace_app/utils/validators/car_validator.dart 12:7  CarValidator.validateTransmission
  test\validators_test.dart 49:29                                              main.<fn>.<fn>
  
00:00 +23 -1: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/models_test.dart: car preserves nullable seller
00:00 +24 -1: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported transmission Số sàn
00:00 +24 -2: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/models_test.dart: car rejects nonnumeric price instead of silently coercing
00:00 +24 -2: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported transmission Số sàn [E]
  Exception: Hộp số không hợp lệ (chỉ chấp nhận: tự động, số sàn)
  package:online_car_marketplace_app/utils/validators/car_validator.dart 12:7  CarValidator.validateTransmission
  test\validators_test.dart 49:29                                              main.<fn>.<fn>
  
00:00 +25 -2: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported transmission tự động
00:00 +25 -3: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/models_test.dart: post reads Firestore timestamp and preserves complete record
00:00 +25 -3: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported transmission tự động [E]
  Exception: Hộp số không hợp lệ (chỉ chấp nhận: tự động, số sàn)
  package:online_car_marketplace_app/utils/validators/car_validator.dart 12:7  CarValidator.validateTransmission
  test\validators_test.dart 49:29                                              main.<fn>.<fn>
  
00:00 +26 -3: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported transmission số sàn
00:00 +26 -4: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/models_test.dart: post reads API timestamp with timezone offset
00:00 +26 -4: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported transmission số sàn [E]
  Exception: Hộp số không hợp lệ (chỉ chấp nhận: tự động, số sàn)
  package:online_car_marketplace_app/utils/validators/car_validator.dart 12:7  CarValidator.validateTransmission
  test\validators_test.dart 49:29                                              main.<fn>.<fn>
  
00:00 +27 -4: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel Xăng
00:00 +28 -4: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel Xăng
00:00 +28 -5: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel Xăng [E]
  Exception: Loại nhiên liệu không hợp lệ (chỉ chấp nhận: xăng, dầu, điện, hybrid)
  package:online_car_marketplace_app/utils/validators/car_validator.dart 20:7  CarValidator.validateFuelType
  test\validators_test.dart 54:29                                              main.<fn>.<fn>
  
00:00 +28 -5: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/models_test.dart: post preserves nullable seller
00:00 +29 -5: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel Dầu
00:00 +29 -6: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel Dầu [E]
  Exception: Loại nhiên liệu không hợp lệ (chỉ chấp nhận: xăng, dầu, điện, hybrid)
  package:online_car_marketplace_app/utils/validators/car_validator.dart 20:7  CarValidator.validateFuelType
  test\validators_test.dart 54:29                                              main.<fn>.<fn>
  
00:00 +29 -6: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel Điện
00:00 +29 -7: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel Điện [E]
  Exception: Loại nhiên liệu không hợp lệ (chỉ chấp nhận: xăng, dầu, điện, hybrid)
  package:online_car_marketplace_app/utils/validators/car_validator.dart 20:7  CarValidator.validateFuelType
  test\validators_test.dart 54:29                                              main.<fn>.<fn>
  
00:00 +29 -7: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel Hybrid
00:00 +29 -8: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel Hybrid [E]
  Exception: Loại nhiên liệu không hợp lệ (chỉ chấp nhận: xăng, dầu, điện, hybrid)
  package:online_car_marketplace_app/utils/validators/car_validator.dart 20:7  CarValidator.validateFuelType
  test\validators_test.dart 54:29                                              main.<fn>.<fn>
  
00:00 +29 -8: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel xăng
00:00 +29 -9: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel xăng [E]
  Exception: Loại nhiên liệu không hợp lệ (chỉ chấp nhận: xăng, dầu, điện, hybrid)
  package:online_car_marketplace_app/utils/validators/car_validator.dart 20:7  CarValidator.validateFuelType
  test\validators_test.dart 54:29                                              main.<fn>.<fn>
  
00:00 +29 -9: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel dầu
00:00 +29 -10: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel dầu [E]
  Exception: Loại nhiên liệu không hợp lệ (chỉ chấp nhận: xăng, dầu, điện, hybrid)
  package:online_car_marketplace_app/utils/validators/car_validator.dart 20:7  CarValidator.validateFuelType
  test\validators_test.dart 54:29                                              main.<fn>.<fn>
  
00:00 +29 -10: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel điện
00:00 +29 -11: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel điện [E]
  Exception: Loại nhiên liệu không hợp lệ (chỉ chấp nhận: xăng, dầu, điện, hybrid)
  package:online_car_marketplace_app/utils/validators/car_validator.dart 20:7  CarValidator.validateFuelType
  test\validators_test.dart 54:29                                              main.<fn>.<fn>
  
00:00 +29 -11: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel hybrid
00:00 +29 -12: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel hybrid [E]
  Exception: Loại nhiên liệu không hợp lệ (chỉ chấp nhận: xăng, dầu, điện, hybrid)
  package:online_car_marketplace_app/utils/validators/car_validator.dart 20:7  CarValidator.validateFuelType
  test\validators_test.dart 54:29                                              main.<fn>.<fn>
  
00:00 +29 -12: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions reject unsupported fuel and transmission
00:00 +30 -12: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions license plate accepts documented examples
00:00 +31 -12: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions reject malformed plate and blank location
00:00 +32 -12: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: User and moderation boundaries trim name and enforce one through fifty characters
00:00 +33 -12: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: User and moderation boundaries accept known user states; reject unknown state
Giá trị status không hợp lệ: 'unknown'
00:00 +34 -12: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: User and moderation boundaries accept moderation states and default pending state
00:00 +35 -12: Some tests failed.

```

### final_test.log

```text
00:00 +0: loading C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/models_test.dart
00:00 +0: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/models_test.dart: car preserves all fields through map conversion
00:00 +1: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/models_test.dart: car accepts integer API price as double
00:00 +2: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/models_test.dart: car preserves nullable seller
00:00 +3: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/models_test.dart: car rejects nonnumeric price instead of silently coercing
00:00 +4: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/models_test.dart: post reads Firestore timestamp and preserves complete record
00:00 +5: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/models_test.dart: post reads API timestamp with timezone offset
00:00 +6: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/models_test.dart: post rejects malformed date string
00:00 +7: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/models_test.dart: post preserves nullable seller
00:00 +8: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid email: null
00:00 +9: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid email: 
00:00 +10: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid email: plain
00:00 +11: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid email: a@
00:00 +12: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid email: @example.com
00:00 +13: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries accept ordinary email
00:00 +14: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid password: null
00:00 +15: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid password: 
00:00 +16: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid password: Ab1!xyz
00:00 +17: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid password: abcdefgh
00:00 +18: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid password: 12345678
00:00 +19: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries accept password at eight-character boundary
00:00 +20: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid phone: null
00:00 +21: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid phone: 
00:00 +22: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid phone: 1234567890
00:00 +23: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid phone: 012345678
00:00 +24: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid phone: 01234567890
00:00 +25: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries reject invalid phone: 0abcdefghi
00:00 +26: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries accept ten-digit phone starting with zero
00:00 +27: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries confirmation requires matching nonempty password
00:00 +28: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Authentication input boundaries required field rejects absent values
00:00 +29: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported transmission Tự động
00:00 +30: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported transmission Số sàn
00:00 +31: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported transmission tự động
00:00 +32: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported transmission số sàn
00:00 +33: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel Xăng
00:00 +34: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel Dầu
00:00 +35: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel Điện
00:00 +36: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel Hybrid
00:00 +37: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel xăng
00:00 +38: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel dầu
00:00 +39: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel điện
00:00 +40: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions accept supported fuel hybrid
00:00 +41: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions reject unsupported fuel and transmission
00:00 +42: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions license plate accepts documented examples
00:00 +43: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: Car validation regressions reject malformed plate and blank location
00:00 +44: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: User and moderation boundaries trim name and enforce one through fifty characters
00:00 +45: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: User and moderation boundaries accept known user states; reject unknown state
Giá trị status không hợp lệ: 'unknown'
00:00 +46: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/validators_test.dart: User and moderation boundaries accept moderation states and default pending state
00:00 +47: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/widget_test.dart: email form rejects invalid input then accepts correction
00:03 +48: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/widget_test.dart: password masking can be toggled without losing input
00:03 +49: C:/OnlineCarAppFlutterGITHUB/intelli-car-app/frontend/test/widget_test.dart: dropdown requires selection and delivers chosen value
00:05 +50: All tests passed!

```

### final_analyze.log

```text
Analyzing frontend...                                           

   info - Don't invoke 'print' in production code - lib\models\post_model.dart:35:7 - avoid_print
warning - Unused import: '../providers/favorite_provider.dart' - lib\navigation\app_router.dart:26:8 - unused_import
warning - Unused import: '../ui/screen/user/post_detail_screen.dart' - lib\navigation\app_router.dart:29:8 - unused_import
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:146:55 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:147:52 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:148:59 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:163:55 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:164:52 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:165:59 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:166:65 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:182:55 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:183:52 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:184:59 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:185:65 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:187:19 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:189:19 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:191:19 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:207:55 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:208:52 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:209:59 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:210:65 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:212:19 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:214:19 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:216:19 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:218:19 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:220:19 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:235:55 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:236:52 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:237:59 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:238:65 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:239:59 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:240:53 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:241:52 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:242:57 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:243:65 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:244:51 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:245:51 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:246:63 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:259:55 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:260:52 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:261:59 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:262:65 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:263:59 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:264:53 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:265:52 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:266:57 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:267:65 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:268:51 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:269:51 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\navigation\app_router.dart:270:63 - dead_null_aware_expression
warning - This cast always throws an exception because the expression always evaluates to 'null' - lib\providers\car_provider.dart:37:66 - cast_from_null_always_fails
   info - Don't invoke 'print' in production code - lib\providers\car_type_provider.dart:21:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\car_type_provider.dart:34:7 - avoid_print
warning - Unused import: 'package:cloud_firestore/cloud_firestore.dart' - lib\providers\favorite_provider.dart:2:8 - unused_import
   info - The private field _favoritePostsWithDetails could be 'final' - lib\providers\favorite_provider.dart:17:30 - prefer_final_fields
   info - Don't invoke 'print' in production code - lib\providers\favorite_provider.dart:44:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\favorite_provider.dart:153:11 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\favorite_provider.dart:157:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\favorite_provider.dart:171:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\favorite_provider.dart:181:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\favorite_provider.dart:192:7 - avoid_print
warning - Unused import: 'package:online_car_marketplace_app/models/car_model.dart' - lib\providers\post_provider.dart:6:8 - unused_import
   info - Don't invoke 'print' in production code - lib\providers\post_provider.dart:65:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\post_provider.dart:85:9 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\post_provider.dart:90:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\role_provider.dart:21:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\role_provider.dart:34:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\providers\user_provider.dart:203:7 - avoid_print
   info - Don't use 'BuildContext's across async gaps - lib\providers\user_provider.dart:334:28 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\providers\user_provider.dart:339:28 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\providers\user_provider.dart:371:28 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\providers\user_provider.dart:382:28 - use_build_context_synchronously
   info - Don't invoke 'print' in production code - lib\repositories\model_repository.dart:49:7 - avoid_print
warning - The receiver can't be null, so the null-aware operator '?.' is unnecessary - lib\repositories\post_repository.dart:73:16 - invalid_null_aware_operator
warning - The '!' will have no effect because the receiver can't be null - lib\repositories\post_repository.dart:75:75 - unnecessary_non_null_assertion
   info - Don't invoke 'print' in production code - lib\repositories\post_repository.dart:81:13 - avoid_print
warning - The '!' will have no effect because the receiver can't be null - lib\repositories\post_repository.dart:81:67 - unnecessary_non_null_assertion
warning - The receiver can't be null, so the null-aware operator '?.' is unnecessary - lib\repositories\post_repository.dart:165:14 - invalid_null_aware_operator
warning - The '!' will have no effect because the receiver can't be null - lib\repositories\post_repository.dart:167:73 - unnecessary_non_null_assertion
   info - Don't invoke 'print' in production code - lib\repositories\post_repository.dart:173:11 - avoid_print
warning - The '!' will have no effect because the receiver can't be null - lib\repositories\post_repository.dart:173:65 - unnecessary_non_null_assertion
   info - Don't invoke 'print' in production code - lib\repositories\post_repository.dart:191:9 - avoid_print
warning - The receiver can't be null, so the null-aware operator '?.' is unnecessary - lib\repositories\post_repository.dart:246:16 - invalid_null_aware_operator
warning - The '!' will have no effect because the receiver can't be null - lib\repositories\post_repository.dart:248:75 - unnecessary_non_null_assertion
   info - Don't invoke 'print' in production code - lib\repositories\post_repository.dart:254:13 - avoid_print
warning - The '!' will have no effect because the receiver can't be null - lib\repositories\post_repository.dart:254:67 - unnecessary_non_null_assertion
   info - Don't invoke 'print' in production code - lib\repositories\post_repository.dart:260:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\post_repository.dart:279:9 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\post_repository.dart:298:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\post_repository.dart:409:9 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\post_repository.dart:413:7 - avoid_print
warning - The value of the field '_pendingRegistrations' isn't used - lib\repositories\user_repository.dart:10:27 - unused_field
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:96:7 - avoid_print
   info - Use 'rethrow' to rethrow a caught exception - lib\repositories\user_repository.dart:97:7 - use_rethrow_when_possible
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:272:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:273:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:276:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:283:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:286:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:294:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:297:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:300:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:302:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:304:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:311:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:314:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\repositories\user_repository.dart:315:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\services\storage_service.dart:26:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\services\storage_service.dart:28:7 - avoid_print
   info - Don't invoke 'print' in production code - lib\services\storage_service.dart:45:7 - avoid_print
   info - The variable name 'car_types' isn't a lowerCamelCase identifier - lib\ui\screen\admin\category_management_screen.dart:14:15 - non_constant_identifier_names
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\admin\login_admin_screen.dart:60:13 - use_build_context_synchronously
warning - Unused import: '../auth/widgets/auth_header.dart' - lib\ui\screen\auth\login_user_screen.dart:8:8 - unused_import
warning - Duplicate import - lib\ui\screen\auth\register_screen.dart:9:8 - duplicate_import
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\ui\screen\user\buy_screen.dart:387:38 - deprecated_member_use
warning - The receiver can't be null, so the null-aware operator '?.' is unnecessary - lib\ui\screen\user\buy_screen.dart:414:39 - invalid_null_aware_operator
warning - The left operand can't be null, so the right operand is never executed - lib\ui\screen\user\buy_screen.dart:447:69 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\ui\screen\user\buy_screen.dart:461:72 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\ui\screen\user\buy_screen.dart:465:72 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\ui\screen\user\buy_screen.dart:476:69 - dead_null_aware_expression
warning - The operand can't be 'null', so the condition is always 'true' - lib\ui\screen\user\buy_screen.dart:480:64 - unnecessary_null_comparison
   info - 'groupValue' is deprecated and shouldn't be used. Use a RadioGroup ancestor to manage group value instead. This feature was deprecated after v3.32.0-0.0.pre - lib\ui\screen\user\condition_origin_screen.dart:95:21 - deprecated_member_use
   info - 'onChanged' is deprecated and shouldn't be used. Use RadioGroup to handle value change instead. This feature was deprecated after v3.32.0-0.0.pre - lib\ui\screen\user\condition_origin_screen.dart:96:21 - deprecated_member_use
   info - 'groupValue' is deprecated and shouldn't be used. Use a RadioGroup ancestor to manage group value instead. This feature was deprecated after v3.32.0-0.0.pre - lib\ui\screen\user\condition_origin_screen.dart:107:21 - deprecated_member_use
   info - 'onChanged' is deprecated and shouldn't be used. Use RadioGroup to handle value change instead. This feature was deprecated after v3.32.0-0.0.pre - lib\ui\screen\user\condition_origin_screen.dart:108:21 - deprecated_member_use
   info - 'groupValue' is deprecated and shouldn't be used. Use a RadioGroup ancestor to manage group value instead. This feature was deprecated after v3.32.0-0.0.pre - lib\ui\screen\user\condition_origin_screen.dart:155:21 - deprecated_member_use
   info - 'onChanged' is deprecated and shouldn't be used. Use RadioGroup to handle value change instead. This feature was deprecated after v3.32.0-0.0.pre - lib\ui\screen\user\condition_origin_screen.dart:156:21 - deprecated_member_use
   info - 'groupValue' is deprecated and shouldn't be used. Use a RadioGroup ancestor to manage group value instead. This feature was deprecated after v3.32.0-0.0.pre - lib\ui\screen\user\condition_origin_screen.dart:167:21 - deprecated_member_use
   info - 'onChanged' is deprecated and shouldn't be used. Use RadioGroup to handle value change instead. This feature was deprecated after v3.32.0-0.0.pre - lib\ui\screen\user\condition_origin_screen.dart:168:21 - deprecated_member_use
   info - The private field _imageUrlsToDelete could be 'final' - lib\ui\screen\user\confirm_post_screen.dart:60:16 - prefer_final_fields
warning - The declaration '_getCurrentConfirmPostData' isn't referenced - lib\ui\screen\user\confirm_post_screen.dart:95:24 - unused_element
   info - Don't invoke 'print' in production code - lib\ui\screen\user\confirm_post_screen.dart:196:9 - avoid_print
   info - Type could be non-nullable - lib\ui\screen\user\confirm_post_screen.dart:214:24 - unnecessary_nullable_for_final_variable_declarations
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\confirm_post_screen.dart:319:28 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\confirm_post_screen.dart:329:7 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\confirm_post_screen.dart:331:28 - use_build_context_synchronously
   info - Unnecessary braces in a string interpolation - lib\ui\screen\user\confirm_post_screen.dart:513:40 - unnecessary_brace_in_string_interps
warning - The receiver can't be null, so the null-aware operator '?.' is unnecessary - lib\ui\screen\user\favorite_screen.dart:78:35 - invalid_null_aware_operator
   info - Unnecessary escape in string literal - lib\ui\screen\user\favorite_screen.dart:78:57 - unnecessary_string_escapes
warning - The left operand can't be null, so the right operand is never executed - lib\ui\screen\user\favorite_screen.dart:111:65 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\ui\screen\user\favorite_screen.dart:125:68 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\ui\screen\user\favorite_screen.dart:129:68 - dead_null_aware_expression
warning - The left operand can't be null, so the right operand is never executed - lib\ui\screen\user\favorite_screen.dart:140:65 - dead_null_aware_expression
warning - The operand can't be 'null', so the condition is always 'true' - lib\ui\screen\user\favorite_screen.dart:144:60 - unnecessary_null_comparison
   info - 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre - lib\ui\screen\user\fuel_transmission_screen.dart:78:15 - deprecated_member_use
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\fuel_transmission_screen.dart:102:27 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\fuel_transmission_screen.dart:108:29 - prefer_const_constructors
   info - 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre - lib\ui\screen\user\fuel_transmission_screen.dart:111:15 - deprecated_member_use
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\image_upload_screen.dart:135:29 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\image_upload_screen.dart:137:29 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\image_upload_screen.dart:139:38 - prefer_const_constructors
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\ui\screen\user\introduction.dart:44:35 - deprecated_member_use
warning - The value of the local variable 'postProvider' isn't used - lib\ui\screen\user\location_filter_screen.dart:26:11 - unused_local_variable
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\model_list_screen.dart:52:16 - prefer_const_constructors
   info - Don't invoke 'print' in production code - lib\ui\screen\user\model_list_screen.dart:89:19 - avoid_print
warning - Unused import: '../../widgets/user/sell_bottom_navigation_bar.dart' - lib\ui\screen\user\my_post_screen.dart:14:8 - unused_import
warning - The '!' will have no effect because the receiver can't be null - lib\ui\screen\user\my_post_screen.dart:62:88 - unnecessary_non_null_assertion
warning - The operand can't be 'null', so the condition is always 'true' - lib\ui\screen\user\my_post_screen.dart:68:27 - unnecessary_null_comparison
warning - The '!' will have no effect because the receiver can't be null - lib\ui\screen\user\my_post_screen.dart:69:70 - unnecessary_non_null_assertion
   info - Don't invoke 'print' in production code - lib\ui\screen\user\my_post_screen.dart:95:7 - avoid_print
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\my_post_screen.dart:122:60 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\my_post_screen.dart:123:58 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\my_post_screen.dart:124:62 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\my_post_screen.dart:125:60 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\my_post_screen.dart:140:30 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\my_post_screen.dart:145:30 - use_build_context_synchronously
   info - Don't invoke 'print' in production code - lib\ui\screen\user\my_post_screen.dart:148:9 - avoid_print
warning - The '!' will have no effect because the receiver can't be null - lib\ui\screen\user\my_post_screen.dart:318:66 - unnecessary_non_null_assertion
warning - The '!' will have no effect because the receiver can't be null - lib\ui\screen\user\my_post_screen.dart:318:84 - unnecessary_non_null_assertion
warning - Unused import: 'package:go_router/go_router.dart' - lib\ui\screen\user\notifications_screen.dart:3:8 - unused_import
warning - The declaration '_buildNotificationSection' isn't referenced - lib\ui\screen\user\notifications_screen.dart:57:10 - unused_element
warning - The declaration '_buildNotificationItem' isn't referenced - lib\ui\screen\user\notifications_screen.dart:78:10 - unused_element
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\ui\screen\user\notifications_screen.dart:88:50 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\ui\screen\user\notifications_screen.dart:97:32 - deprecated_member_use
warning - The value of the local variable 'carLocation' isn't used - lib\ui\screen\user\post_detail_screen.dart:39:11 - unused_local_variable
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\ui\screen\user\post_detail_screen.dart:104:51 - deprecated_member_use
warning - The receiver can't be 'null' because of short-circuiting, so the null-aware operator '?.' can't be used - lib\ui\screen\user\post_detail_screen.dart:165:84 - invalid_null_aware_operator
warning - The receiver can't be 'null' because of short-circuiting, so the null-aware operator '?.' can't be used - lib\ui\screen\user\post_detail_screen.dart:167:81 - invalid_null_aware_operator
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\ui\screen\user\post_detail_screen.dart:263:38 - deprecated_member_use
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\post_detail_screen.dart:382:28 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\post_detail_screen.dart:395:28 - use_build_context_synchronously
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\price_title_description_screen.dart:108:27 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\price_title_description_screen.dart:117:29 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\price_title_description_screen.dart:134:27 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\price_title_description_screen.dart:142:29 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\price_title_description_screen.dart:161:27 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\ui\screen\user\price_title_description_screen.dart:169:29 - prefer_const_constructors
   info - Invalid use of a private type in a public API - lib\ui\screen\user\profile_screen.dart:16:3 - library_private_types_in_public_api
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\profile_screen.dart:92:32 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps - lib\ui\screen\user\profile_screen.dart:113:44 - use_build_context_synchronously
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\ui\screen\user\sell_screen.dart:188:46 - deprecated_member_use
   info - 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre - lib\ui\widgets\user\auth_dropdown_field.dart:22:7 - deprecated_member_use
   info - Don't invoke 'print' in production code - lib\utils\validators\user_validator.dart:16:7 - avoid_print

flutter : 193 issues found. (ran in 7.7s)
At line:2 char:150
+ ... t.log -Tail 12; flutter analyze --no-pub *> final_analyze.log; Write- ...
+                     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (193 issues found. (ran in 7.7s):String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 

```

### build_web.log

```text
Compiling lib\main.dart for the Web...                          
flutter : Wasm dry run succeeded. Consider building and testing your application with the `--wasm` flag. See docs for more info: 
https://docs.flutter.dev/platform-integration/web/wasm
At line:2 char:1
+ flutter build web --no-pub *> build_web.log; Write-Output "web_build_ ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (Wasm dry run su...ration/web/wasm:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
Use --no-wasm-dry-run to disable these warnings.
Font asset "CupertinoIcons.ttf" was tree-shaken, reducing it from 257628 to 1472 bytes (99.4% reduction). Tree-shaking can be disabled by providing the --no-tree-shake-icons flag when building your app.
Font asset "MaterialIcons-Regular.otf" was tree-shaken, reducing it from 1645184 to 11964 bytes (99.3% reduction). Tree-shaking can be disabled by providing the --no-tree-shake-icons flag when building your app.
Compiling lib\main.dart for the Web...                             78.8s
√ Built build\web

```


## Bổ sung bộ chạy test tự động (2026-10-02)

Theo yêu cầu tiếp theo, đã đặt toàn bộ công cụ vào `frontend/tools/testing`, giữ backend tại đường dẫn người dùng cung cấp và không sửa backend ngoài workspace.

- `run_tests.py` / `run-tests.ps1`: chạy từ một lệnh, timeout mỗi bước, tiếp tục bước độc lập khi lỗi, lưu báo cáo Markdown/JSON, log từng bước, coverage riêng và LATEST.txt. Có tùy chọn build, API, load, Cloudinary và Firestore Emulator.
- `backend_tests.py`: 10 tests chạy view tìm kiếm thật, Django response thật, Firestore giả lập. Không import settings đang khởi tạo Firebase bằng service-account.
- `network_checks.py`: API GET kiểm tra JSON contract; Cloudinary GET kiểm tra image delivery; load smoke có giới hạn và p50/p95/p99/error rate. Mặc định không gọi mạng cloud; chỉ chạy khi chọn cờ tương ứng.
- `emulator_tests.py`, `firebase.json`, `firestore.test.rules`: 3 tests với Firestore local/demo project, anonymous credentials, dữ liệu seed và cleanup. Rules chỉ dành cho harness, không phải rules production.
- `test_harness.py`: 8 regression tests cho chính bộ chạy/logging và HTTP contract trên server loopback.
- `TESTING.md`: hướng dẫn chạy, cấu hình cá nhân, đọc kết quả, prerequisites và các giới hạn.
- `.gitignore` tại frontend: bỏ qua test-results và config.local.json. Không thêm credential.

Xác minh ban đầu: `python tools/testing/run_tests.py --backend-only` exit 0, 10/10 PASS. Test harness lần đầu trong sandbox: 5 PASS, 3 ERROR do quyền thư mục tạm Windows; chạy lại ngoài sandbox: 8/8 PASS. `py_compile` và `git diff --check` đạt. Những lỗi cố ý tạo trong harness sinh báo cáo FAIL/BLOCKED để kiểm tra tính trung thực của exit code; không phải lỗi nghiệp vụ backend.

Lần yêu cầu quyền trước bị người dùng ngắt; kiểm tra lại xác nhận lần full-run chưa bắt đầu. Sau yêu cầu tiếp tục, đã chạy lại full-run với `--web --firebase`. Kết quả cuối được ghi tiếp bên dưới.

### Kết quả xác minh bộ chạy tự động

- `python tools/testing/run_tests.py`: chạy thực tế với code cuối, run `20261002-200245-1d7bda`; Flutter 50/50 PASS, backend 10/10 PASS, analyzer FAIL do issues hiện có. Exit tổng 1 đúng thiết kế. Log, REPORT.md, results.json và lcov.info được tạo tự động.
- `python tools/testing/run_tests.py --web --firebase`: run `20261002-194609-dadd4b`; Flutter/backend PASS, build web PASS (exit 0, 126.91 giây cả command). Firebase CLI nhận HTTP 200 khi tải JAR 1.19.8 nhưng file tạm vẫn 0 byte sau nhiều phút; agent dừng phiên và xác nhận process node đã thoát. Ba test emulator chưa thực thi. Báo cáo phiên bị ngắt được đối chiếu và cập nhật từ RUNNING thành INTERRUPTED, không ghi PASS.
- Bổ sung heartbeat mỗi 15 giây, log khi timeout và emulator_timeout_seconds riêng (mặc định 600). Bộ harness 8/8 PASS sau thay đổi heartbeat. Default runner đã được chạy lại sau thay đổi timeout config.
- PowerShell wrapper `./tools/testing/run-tests.ps1 --backend-only`: exit 0, backend 10/10 PASS, run `20261002-200331-79af1d`.
- Python syntax compilation và git diff --check đạt. Các thay đổi của vòng kiểm thử trước được giữ nguyên.
- API/live load và Cloudinary chưa gọi vì chưa chỉ định API chạy trên test data hoặc URL ảnh test. Không cần gửi tài khoản/secret để chạy unit test. Hướng dẫn đầy đủ trong TESTING.md.

Các log chi tiết tự lưu ở test-results/<run-id>/. Đường dẫn mới nhất ở test-results/LATEST.txt; các lần chạy cũ giữ nguyên. Thư mục log bị gitignore nhưng báo cáo này lưu lại quá trình và kết quả chính trong source.

### Log backend thực tế (10 tests)
```text
test_empty_database_returns_empty_array (__main__.SearchContractTests.test_empty_database_returns_empty_array) ... ok
test_empty_query_returns_joined_contract (__main__.SearchContractTests.test_empty_query_returns_joined_contract) ... ok
test_missing_car_skips_orphan_post (__main__.SearchContractTests.test_missing_car_skips_orphan_post) ... ok
test_missing_model_and_brand_preserves_title_search (__main__.SearchContractTests.test_missing_model_and_brand_preserves_title_search) ... ok
test_missing_user_preserves_listing_with_null_seller (__main__.SearchContractTests.test_missing_user_preserves_listing_with_null_seller) ... ok
test_no_images_returns_empty_array (__main__.SearchContractTests.test_no_images_returns_empty_array) ... ok
test_non_matching_query_returns_empty_list (__main__.SearchContractTests.test_non_matching_query_returns_empty_list) ... ok
test_null_user_id_preserves_listing (__main__.SearchContractTests.test_null_user_id_preserves_listing) ... ok
test_search_fields_and_case_normalization (__main__.SearchContractTests.test_search_fields_and_case_normalization) ... ok
test_whitespace_query_returns_all (__main__.SearchContractTests.test_whitespace_query_returns_all) ... ok

----------------------------------------------------------------------
Ran 10 tests in 0.030s

OK
```

### Báo cáo JSON của lần chạy mặc định cuối

```json
{
  "run": "20261002-200245-1d7bda",
  "root": "C:\\OnlineCarAppFlutterGITHUB\\intelli-car-app\\frontend",
  "interrupted": false,
  "stages": [
    {
      "name": "analyze",
      "log": "analyze.log",
      "status": "FAIL",
      "exit_code": 1,
      "seconds": 7.57
    },
    {
      "name": "flutter-tests",
      "log": "flutter-tests.log",
      "status": "PASS",
      "exit_code": 0,
      "seconds": 10.48
    },
    {
      "name": "backend-tests",
      "log": "backend-tests.log",
      "status": "PASS",
      "exit_code": 0,
      "seconds": 0.84
    },
    {
      "name": "build-web",
      "status": "SKIP",
      "log": "build-web.log"
    },
    {
      "name": "build-apk",
      "status": "SKIP",
      "log": "build-apk.log"
    },
    {
      "name": "firebase-emulator",
      "status": "SKIP",
      "log": "firebase-emulator.log"
    },
    {
      "name": "api",
      "status": "SKIP",
      "log": "api.log"
    },
    {
      "name": "cloudinary",
      "status": "SKIP",
      "log": "cloudinary.log"
    },
    {
      "name": "load",
      "status": "SKIP",
      "log": "load.log"
    }
  ]
}
```

## Bổ sung đo homepage khi chạy chương trình (2026-10-02)

### Phạm vi và thiết kế

Người dùng yêu cầu gắn mã đo vào luồng chạy thật. Khảo sát xác nhận `/buy` là BuyScreen sau đăng nhập; landing `/` có prefetch riêng. Mốc bắt đầu đặt tại BuyScreen.initState, không gộp thời gian login/app startup.

- Thêm `lib/services/home_load_trace.dart`: Stopwatch đơn điệu, mốc shell/posts/brands/content/thumbnail; tổng hợp số lần gọi SDK, tổng/max thời gian và errors theo nhóm. Mỗi visit chốt một báo cáo với ready/partial_error/timeout/abandoned/interacted. Timeout 60 giây không hủy request nghiệp vụ. Callback muộn không sửa snapshot đã phát.
- Thêm `HomePerformanceStore`: JSON console `[HOME_PERF]`, SharedPreferences giữ 20 báo cáo cuối, serialize ghi để tránh ghi đè giữa các visit. Không ghi UID/email/URL ảnh; lỗi sink không làm hỏng app.
- PostProvider/PostRepository nhận trace tùy chọn, đo posts/cars/models/users/image metadata; BrandProvider đo lấy hãng xe. Không thay query, giới hạn, thứ tự await hoặc backend endpoint.
- BuyScreen tạo trace mỗi lần vào, chờ luồng dữ liệu/hãng xe, đánh dấu post-frame của nội dung. Thoát/tương tác trước khi hoàn tất không ghi ready.
- `HomeMeasuredImage` quan sát frame của ảnh đang hiển thị, không prefetch/request phụ. Chỉ đo thumbnail đầu có trong dataset; giữ nguyên error handling ảnh. Ảnh không ra frame được ghi pending/timeout.
- `HOME_PERF` mặc định bật trong debug/profile và tắt ở release; có thể đổi bằng dart-define.
- Thêm `tools/testing/profile_home.py`: chạy Flutter profile theo device ID, lưu flutter.log/homepage.jsonl/REPORT.md, hỗ trợ Ctrl+C và thời lượng capture. Parser hỗ trợ tiền tố Android log. Thêm HOME_PERFORMANCE.md và liên kết từ TESTING.md.

### Kiểm thử đã chạy

1. Format 3 file Dart mới; chạy `python tools/testing/run_tests.py --web`, run `20261002-202639-e77fd5`.
2. Flutter: **58/58 PASS**, gồm 8 tests mới: chốt đúng một lần sau content+ảnh; empty state; đo lỗi SDK và rethrow; timeout ảnh; bỏ qua late completion; sink lỗi không ảnh hưởng app; frame ảnh đồng bộ; lịch sử local giới hạn/đúng thứ tự.
3. Backend: **10/10 PASS**. Build web: **PASS**, biên dịch 84.9 giây (đây là build time, không phải homepage load time).
4. Analyzer lần đầu: không error, có một lint braces trong widget mới. Đã sửa lint đó và chạy analyze lại, kết quả ghi bên dưới.
5. Python harness: **10/10 PASS**, gồm 2 tests mới cho parser `[HOME_PERF]`; py_compile của capture script đạt; git diff --check đạt.

### Giới hạn của bằng chứng

Chưa chạy homepage với tài khoản/thiết bị/dataset của người dùng, nên chưa có số đo tốc độ homepage hoặc kết luận bottleneck runtime. SDK duration không đồng nghĩa network-only latency; post-frame callback không chứng minh GPU hoàn tất; thumbnail đầu không phải toàn bộ ảnh hoặc LCP. Dùng HOME_PERFORMANCE.md để tự capture các lần lạnh/ấm trên cùng thiết bị/build mode/mạng/dataset.

Analyze cuối: exit 1, 0 error / 89 warning / 103 info (192 issues); không có diagnostic ở home_load_trace.dart, home_measured_image.dart hoặc home_load_trace_test.dart. Log: test-results/homepage-final-analyze.log.


## Sửa thu log homepage trên web profile (2026-10-02)

Người dùng chạy Chrome profile nhưng không có HOME_PERF trong terminal. Đọc báo cáo `homepage-20261002-204214-a6b217`: outcome=user_stopped, reports=0. Không suy ra build lỗi hoặc script tự thoát: đây là nhánh KeyboardInterrupt. Kiểm tra source Flutter SDK resident_web_runner.dart: supportsServiceProtocol chỉ bật cho web debug không Wasm; subscription stdout/stderr nằm trong nhánh này. Script trước chỉ đọc stdout nên không đủ để capture web profile.

Đã sửa:
- profile_home.py mở HTTP collector loopback với port/token từng phiên, kiểm tra origin localhost, xử lý CORS/preflight và giới hạn payload; truyền HOME_PERF_ENDPOINT qua dart-define cho chrome/edge/web-server.
- HomePerformanceStore gửi JSON đã chốt về loopback bằng HTTP có timeout, vẫn giữ console và history; lỗi gửi không ảnh hưởng app. Không gửi dữ liệu đo lên cloud.
- Giữ stdin pipe mở cho process Flutter, thay DEVNULL; thêm thông báo rõ khi không thu được mẫu. Đây là cải thiện lifecycle, không kết luận DEVNULL gây ra lần user_stopped đã quan sát.
- Tài liệu cập nhật khác biệt console web profile/debug, yêu cầu giữ terminal mở rồi vào /buy.

Validation: 58/58 Flutter tests PASS, 10/10 backend tests PASS, build web PASS (76.4 giây compile), run `20261002-205502-994ce3`. Analyzer vẫn FAIL vì issues hiện có. Python harness lần đầu 11 PASS/1 ERROR: trả HTTP 403 trước khi đọc body khiến Windows reset kết nối. Đã sửa đọc body trong giới hạn trước khi trả 403; lần chạy lại **12/12 PASS**, bao gồm preflight + POST JSON thành công và chặn origin ngoài localhost. git diff --check đạt. Chưa chạy lại bằng tài khoản người dùng; không có benchmark mới trong đợt sửa này.

## Phân tích kết quả người dùng export (2026-10-02 21:08)

Đã đọc `test-results/homepage-20261002-210200-0af8bf/REPORT.md`, `homepage.jsonl`, `flutter.log` và đối chiếu getPostsWithCarAndImages trong source hiện tại. Có 1 mẫu Chrome/profile hợp lệ, 6 bài đăng, status ready, errors SDK=0. user_stopped là kết thúc capture sau khi có mẫu, không phải failure.

- Posts ready: 19.436 s; content frame: 19.6088 s; first thumbnail frame: 19.8335 s.
- 98% thời gian đến thumbnail frame trôi qua trước posts_ready.
- Nhánh posts có 25 calls tuần tự: posts=1, cars/models/users/images_metadata mỗi nhóm=6. SDK total=19355.804 ms so với fetch elapsed=19361.101 ms (chênh 5.297 ms). Brands=1 call/758.5 ms chạy song song, không cộng vào critical path.
- Bằng chứng ủng hộ bottleneck chờ SDK tuần tự/N+1. Chưa kết luận riêng Firestore server, mạng, cache hoặc khu vực database là nguyên nhân latency từng call. Không có bằng chứng ảnh/render là phần chính của lần này.
- Đề xuất thử query độc lập song song có giới hạn, deduplicate/cache ID, phân trang; chưa sửa/tối ưu production code trong lượt phân tích.
- Chỉ 1 mẫu, chưa có p95/p99 hoặc before/after. Không nhầm build 59.7 s với load homepage. Chi tiết lưu trong ANALYSIS.md cùng thư mục export.

## Tối ưu có kiểm soát A/B/C/D (2026-10-03)

Yêu cầu: sửa sequential fetching trước, dedup, pagination, giữ measurement và so sánh nhiều mẫu; không chuyển backend/schema, không tối ưu ảnh khi chưa có bằng chứng.

### Triển khai

- Thêm HomeFeedLoader + FirestoreHomeFeedSource; homepage đi qua PostRepository.getHomePage. A tuần tự/no dedup/unpaged; B bounded parallel/no dedup; C thêm dedup; D thêm cursor pagination (mặc định).
- Pool tối đa 4 SDK reads liên quan mỗi page request, tối đa 4 post workers; car→model giữ dependency; seller/images độc lập. Cache Future đang chạy theo car/model/user/images ID trong từng request, không giữ stale cache giữa lần tải. Giữ thứ tự output. Optional model/user failure trả null; required posts/car/images failure làm page fail, chờ các nhánh đang chạy xử lý xong để không có lỗi Future không được xử lý.
- Cursor dùng document-ID như thứ tự mặc định cũ; limit 21 để trả 20 và xác định hasMore, chỉ hydrate 20. Không thay schema hoặc index composite.
- Provider loadMore chống trùng thao tác, append unique IDs, giữ items/cursor khi lỗi để retry; generation bảo vệ refresh/search/dispose khỏi kết quả cũ. Search không trộn feed page.
- UI có scroll load-more và nút Xem thêm xe, trạng thái lỗi/loading/retry, thông báo sort trên tin đã tải. Bỏ prefetch ở landing vốn bị tải lại khi vào /buy. Điều này là thay đổi chung cho A/B/C/D, nên cần đo lại A thay vì coi sample cũ hoàn toàn tương đương.
- Trace thêm variant/concurrency/page_size/dedup_scope/cache label/experiment label. Capture CLI thêm --variant, --cache-state, --label. Cache-state là nhãn do người đo cung cấp, không tự xóa cache hoặc tự tạo 30 lượt.
- summarize_home.py tạo REPORT.md + summary.json: min/max/mean/median/p90/p95/p99/stddev, tách điều kiện, chỉ ready cho latency, đếm trạng thái lỗi riêng, không tính missing metrics=0 và không đếm lại run_id.
- Baseline cũ giữ nguyên trong tools/testing/baselines/homepage_sequential_20261002.jsonl; hướng dẫn đầy đủ trong HOMEPAGE_OPTIMIZATION.md.

### Kiểm thử và bằng chứng

1. Run 20261003-141920-e2c80f: **73/73 Flutter tests PASS**, **10/10 backend tests PASS**, build web **PASS** (116.6 giây compile, không phải thời gian tải homepage). Analyzer có 2 info mới (braces/import) và issues cũ; đã sửa 2 info mới.
2. Thêm 10 loader tests: A có 25 calls/6 fake posts và concurrency=1; B giữ 25 calls nhưng overlap trong cap, giữ output order; C fixture chung model/user giảm xuống 15 calls; D shared-car fixture còn 5 calls/page. Cache không tồn tại giữa loads. Kiểm tra optional/required failures, empty result và options lỗi. Đây là kiểm chứng orchestration trên fake data, không là benchmark production.
3. Thêm 5 provider tests: coalesce loadMore, dedup append/end-of-feed, retry giữ cursor, stale refresh, search overlap, dispose late-result (một test bao phủ nhiều điều kiện).
4. Python harness **14/14 PASS**, bao gồm tách cold/warm/variants, loại timeout khỏi latency, thống kê và collector tests.
5. Chạy summarize_home.py trên baseline thật: 1 unique visit, 0 malformed; đúng posts_ready 19436 ms/content 19608.8 ms/thumbnail 19833.5 ms. Các percentile bằng nhau vì chỉ có 1 mẫu, không phải bằng chứng phân phối latency ổn định.
6. Run cuối sau điều chỉnh scroll/retry và lint: **20261003-142522-5074b7**, **73/73 Flutter PASS**, **10/10 backend PASS**. Analyzer: 0 error / 88 warning / 103 info, exit tổng 1 do các issues hiện có. Không có diagnostic trong hai file loader/source mới. git diff --check đạt.

### Chưa được xác minh trên môi trường thật

Chưa chạy 10 cold + 20 warm bằng tài khoản/dataset Chrome của người dùng sau sửa; chưa có số giây After, không khẳng định <5 giây hoặc % improvement. Chưa kiểm chứng live Firestore pagination với >20 documents và dữ liệu thay đổi đồng thời. Sort phía client chỉ áp dụng trên các tin đã tải, đã ghi rõ ở UI. Giới hạn SDK áp dụng mỗi page request; request cũ không bị Firebase hủy khi generation thay đổi, nhưng kết quả cũ bị bỏ. Tổng SDK durations sau parallelization chồng lấp, không cộng để suy ra elapsed. Đã chuẩn bị các chế độ và thống kê để thu dữ liệu thực tế tiếp theo.


## Ph?n t?ch l?n ch?y m?i nh?t (2026-10-03)

# Đánh giá homepage — 2026-10-03 14:43

### Nguồn và điều kiện

Đọc REPORT.md, homepage.jsonl và flutter.log trong phiên homepage-20261003-144123-37f777. So sánh với baseline tools/testing/baselines/homepage_sequential_20261002.jsonl (phiên 2026-10-02).

Mẫu mới: run_id 1791013380594000, Chrome/profile/web, 6 bài đăng, status=ready; variant D, concurrency=4, page_size=20, dedup_scope=page_request, landing_prefetch=false. Cache_state=unknown. Có 1 mẫu mới và 1 mẫu baseline. Tất cả 20 SDK calls được ghi nhận đều completed, errors=0. Capture outcome=user_stopped chỉ là kết thúc thu log, không phải phép đo thất bại. Build web 57,6 giây không nằm trong thời gian tải homepage.

### Kết quả

| Mốc tính từ khởi tạo màn hình | Baseline (s) | Mới (s) |
| --- | ---: | ---: |
| Shell frame | 0,0745 | 0,0649 |
| Brands settled | 0,8358 | 1,4542 |
| Posts ready | 19,4360 | 4,5896 |
| Content frame | 19,6088 | 4,7518 |
| First thumbnail frame | 19,8335 | 4,9046 |

- Posts ready giảm 14,8464 giây, tương đương 76,4%.
- Thumbnail đầu giảm 14,9289 giây, tương đương 75,3%; baseline mất khoảng 4,04 lần thời gian mẫu mới.
- Riêng fetch: 4,5896 − 0,0652 = 4,5244 giây, so với baseline 19,3611 giây.
- Sau posts_ready đến content_frame: 162,2 ms; đến thumbnail đầu: 315,0 ms. Posts_ready vẫn chiếm 93,6% thời gian đến thumbnail đầu.
- Mẫu này đạt mục tiêu ban đầu data ready <5 giây. Chưa chứng minh mọi lần tải đều đạt mục tiêu.

### Thay đổi số lượt đọc

| SDK operation | Baseline calls | Mới calls | Tổng duration mới (ms) |
| --- | ---: | ---: | ---: |
| Posts | 1 | 1 | 1379,0 |
| Cars | 6 | 6 | 3787,4 |
| Models | 6 | 4 | 2498,2 |
| Users/sellers | 6 | 2 | 1277,6 |
| Image metadata | 6 | 6 | 3772,2 |
| Brands | 1 | 1 | 1386,2 |

Nhánh danh sách giảm 25 xuống 19 calls (24%); gồm brands là 26 xuống 20. Model và seller giảm phù hợp với deduplication. Số SDK calls không đồng nghĩa số HTTP requests hoặc số document reads tính phí.

Tổng duration của nhánh danh sách mới là 12714,4 ms, nhưng elapsed fetch chỉ 4524,4 ms vì các thao tác chồng lấp. Không được cộng duration song song rồi gọi đó là thời gian người dùng chờ. Log chỉ ghi cấu hình concurrency=4, không đo trực tiếp peak concurrency thực tế.

Posts query mới 1379 ms so với 755,6 ms trước, brands mới 1386,2 ms so với 758,5 ms trước. Dù hai thao tác đầu chậm hơn, tổng thời gian giảm rõ. Kết quả phù hợp với giả thuyết cải thiện orchestration và giảm đọc trùng; chưa tách được đóng góp riêng của parallelization, dedup, cache và mạng.

### Giới hạn và bước tiếp theo

1. Đây là so sánh quan sát giữa hai lần chạy khác ngày, mỗi bên n=1, cache chưa xác định. Baseline cũ có landing prefetch; bản mới bỏ prefetch cho mọi variant. Cùng 6 bài không chứng minh nội dung dataset và điều kiện mạng hoàn toàn giống nhau.
2. Với 6 bài và page_size=20, chưa chứng minh lợi ích hoặc tính đúng của phân trang trên dataset lớn. Không quy toàn bộ mức giảm latency cho pagination.
3. Thumbnail frame là mốc callback của instrumentation, không phải toàn bộ ảnh, LCP hoặc GPU hoàn tất. Khoảng 315 ms không phải phép đo riêng tốc độ Cloudinary.
4. Đo lại A và D trong cùng điều kiện, ghi rõ cold/warm theo cache thực tế; mục tiêu 10 cold và 20 warm mỗi variant. Có thể thêm B/C để tách tác động parallel và dedup. Nhãn --cache-state không tự xóa cache. Không suy ra p95/p99 ổn định từ mẫu hiện có; ngay cả 10–30 mẫu vẫn cho percentile đuôi rất thô.
5. Chưa có bằng chứng cần đổi backend hoặc tối ưu Cloudinary. Ưu tiên xác nhận độ lặp lại của kết quả trước khi sửa thêm.

Đã chạy summarize_home.py trên đúng hai JSONL: báo cáo thống kê nằm trong comparison/REPORT.md và comparison/summary.json; hai điều kiện được tách nhóm. Không chạy lại test ứng dụng hoặc thay đổi production code trong lượt đánh giá này.
