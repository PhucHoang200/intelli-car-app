# Tự chạy kiểm thử và lưu log

Đo homepage khi chạy ứng dụng: xem [HOME_PERFORMANCE.md](HOME_PERFORMANCE.md).

Chạy từ thư mục `frontend`. Không cần sửa backend hoặc đưa service-account, mật khẩu Cloudinary/API secret vào bộ test.

## Lệnh thường dùng

```powershell
# Analyze + 50 Flutter tests + 10 backend tests dùng Firestore giả lập
python tools/testing/run_tests.py

# Tương đương với wrapper PowerShell
.\tools\testing\run-tests.ps1

# Thêm thông tin SDK/thiết bị và build web
python tools/testing/run_tests.py --inventory --web

# Chỉ backend (nhanh, không yêu cầu Flutter)
python tools/testing/run_tests.py --backend-only

# Firestore local thật + 3 integration tests; tự bật/tắt emulator
python tools/testing/run_tests.py --firebase

# Build APK debug khi Android SDK/licenses đã sẵn sàng
python tools/testing/run_tests.py --apk
```

Mặc định dùng backend `C:/BackEnd_API_Online_Car_App_Flutter/onlinecarmarketplaceapp`. Test đọc trực tiếp `onlinecar/views.py`, dùng Django thật và dữ liệu Firestore giả lập. Không import settings production (settings hiện đọc service-account). Đây là kiểm thử view/contract, không phải kiểm thử toàn bộ middleware, routing hoặc quyền production.

## Kết quả ở đâu?

Mỗi lần chạy tạo `test-results/YYYYMMDD-HHMMSS-id/`:

- `REPORT.md`: trạng thái từng bước và liên kết log.
- `results.json`: kết quả máy đọc được, exit code, thời gian từng bước.
- `analyze.log`, `flutter-tests.log`, `backend-tests.log`, cùng log của bước tùy chọn.
- `lcov.info`: coverage của lần chạy này.
- `test-results/LATEST.txt`: đường dẫn đến thư mục kết quả mới nhất.

Runner tiếp tục các bước độc lập sau một failure. Exit code tổng: **0** khi mọi bước yêu cầu PASS; **1** khi FAIL/BLOCKED/TIMEOUT; **130** khi Ctrl+C. Lần chạy bị ngắt giữ báo cáo một phần và dừng cây process của bước đang chạy. Bước không chọn được ghi SKIP. Đóng cưỡng bức máy/terminal có thể để trạng thái RUNNING trong báo cáo.

Project hiện còn cảnh báo analyzer, vì vậy lệnh tổng có thể exit 1 dù Flutter/backend tests đều PASS. Không bỏ qua warning để tạo kết quả xanh giả. Các thư mục kết quả và cấu hình cá nhân đã được gitignore.

## Chuẩn bị môi trường

- Python 3.10+ và Django tương thích backend (máy hiện tại có Django 5.2).
- Flutter/Dart trong PATH; chạy `flutter pub get` nếu máy mới/chưa có dependencies. Runner dùng `--no-pub` để không tự đổi dependency.
- Nếu dùng Python riêng: cấu hình `python` là đường dẫn executable của virtualenv. Không cần cài firebase-admin cho 10 backend test giả lập.
- `--firebase` cần Firebase CLI, Java tương thích CLI/Firestore emulator và `firebase-admin` trong Python của PATH. Lần đầu Firebase CLI có thể tải emulator. Không tự cài dependency hay chấp nhận Android licenses.
- Đợt xác minh hiện tại chưa chạy được 3 test emulator: tải JAR nhận HTTP 200 nhưng không truyền dữ liệu, đã dừng sau khi không có tiến triển. Khi mạng tải được, chạy lại `--firebase`; timeout riêng mặc định 600 giây, chỉnh `emulator_timeout_seconds` nếu cần. Bộ unit test mặc định không phụ thuộc tải này.
- Android APK cần toolchain đầy đủ; bản debug không phải bản phát hành.

## Cấu hình cá nhân

Tạo `tools/testing/config.local.json` chứa các giá trị muốn ghi đè từ `config.json`, ví dụ:

```json
{
  "backend_path": "C:/BackEnd_API_Online_Car_App_Flutter/onlinecarmarketplaceapp",
  "api_url": "http://127.0.0.1:8000/onlinecar/search-posts/",
  "api_query": "Toyota",
  "cloudinary_image_url": "https://res.cloudinary.com/YOUR_CLOUD/image/upload/YOUR_TEST_IMAGE.jpg"
}
```

Cũng có thể chỉ định `--config path/to/config.json`. URL ảnh dùng asset test công khai, không dùng URL ký chứa thông tin nhạy cảm. Cấu hình URL không phải nơi lưu credential.

## API đang chạy và tải nhỏ

```powershell
python tools/testing/run_tests.py --api
python tools/testing/run_tests.py --api --load
python tools/testing/run_tests.py --cloudinary
```

Bạn cần tự khởi động API trong môi trường test trước. Runner **không** chạy `manage.py runserver` với settings hiện tại vì settings đó kết nối Firebase theo service-account. `127.0.0.1` chỉ có nghĩa API chạy local; nó vẫn có thể đọc cloud thật nếu bạn cấu hình backend như vậy. Chọn backend trỏ Firebase test cho API/load.

Mặc định load smoke là **20 requests, 2 workers**, ngưỡng **p95 ≤ 2000 ms** và **0 lỗi**. Có thể chỉnh trong config; giới hạn công cụ này là 200 requests/10 workers. Metric bao gồm latency của cả lượt thành công và thất bại; mẫu nhỏ không đại diện benchmark production. Công cụ dùng Python chuẩn, không cần k6. HTTP timeout và timeout tổng được áp dụng. Redirect không được theo tự động.

Địa chỉ API ngoài loopback cần chọn rõ `--allow-remote-api`. Cloudinary smoke chỉ GET tối đa 1 KB đầu ảnh và kiểm tra status/content type, không upload/delete; chưa kiểm tra quyền tài khoản hoặc vòng đời asset.

## Firebase SDK và emulator

`--firebase` khởi chạy Firestore ở `127.0.0.1:8088` với project giả `demo-intelli-car-tests`. Script chỉ chấp nhận host/project này, seed dữ liệu test, gọi **view backend thật với Admin SDK thật** rồi dọn các document đã seed. Không cần service-account. CLI tự quản lý vòng đời emulator; dùng port trống và không chạy nhiều phiên emulator đồng thời.

`tools/testing/firestore.test.rules` cố ý từ chối mọi client request. Admin SDK bypass rules nên vẫn seed và query được. Một test xác nhận client chưa đăng nhập bị từ chối. Đây chỉ là kiểm tra hạ tầng emulator và rules mẫu của test; **không phải bộ security rules của ứng dụng và không được deploy file này lên Firebase thật**.

Bộ chạy không đổi cấu hình Firebase của ứng dụng Flutter, không dùng tài khoản Cloudinary đang nhúng trong StorageService. Flutter E2E đăng nhập/đăng tin với emulator, rules phân quyền theo vai trò, upload/delete Cloudinary, camera/GPS và profiling homepage vẫn cần kịch bản/tài khoản test riêng. `--firebase` hiện không khởi tạo Firebase Auth/Storage emulator.

## Kiểm tra chính bộ chạy

```powershell
python -m unittest discover -s tools/testing -p "test_harness.py" -v
```

Các test này kiểm tra lưu báo cáo khi cấu hình/backend lỗi, exit code và HTTP contract bằng server local, không gọi dịch vụ cloud.
