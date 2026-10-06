# Đo tốc độ tải homepage khi chạy app

Tối ưu và cách chạy thí nghiệm A/B/C/D: [HOMEPAGE_OPTIMIZATION.md](HOMEPAGE_OPTIMIZATION.md). Mặc định hiện tại là D (bounded concurrency + dedup + pagination).

Phạm vi: màn hình **`/buy` sau đăng nhập**, từ `BuyScreen.initState`. Không bao gồm thời gian mở ứng dụng, Firebase.initializeApp hoặc đăng nhập. Trang landing `/` không nằm trong phép đo này.

## Chạy và tự lưu log trên máy

Từ `frontend`, xem ID thiết bị bằng `flutter devices`, rồi:

```powershell
# Thay ID bằng ID thiết bị Android của bạn
python tools/testing/profile_home.py --device emulator-5554

# Hoặc Chrome
python tools/testing/profile_home.py --device chrome

# Đo debug nếu cần điều tra lỗi; không so tốc độ debug với profile
python tools/testing/profile_home.py --device chrome --mode debug
```

Mặc định dùng `flutter run --profile --dart-define=HOME_PERF=true`. Nếu SDK/thiết bị không hỗ trợ profile thì lệnh sẽ báo lỗi; có thể chọn `--mode debug` để kiểm tra hoạt động, hoặc dùng thiết bị thật để đánh giá hiệu năng. Lệnh này chạy app với cấu hình Firebase/Cloudinary hiện tại của bạn.

Đăng nhập, mở homepage và **đợi trước khi tìm kiếm, lọc, sắp xếp hoặc chuyển màn hình**. Khi báo cáo `[HOME_PERF]` xuất hiện, có thể rời trang rồi quay lại để đo một lượt mới. Ctrl+C kết thúc phiên; có thể dùng `--duration 180` để dừng sau 180 giây (bao gồm thời gian build/khởi động).

Mỗi phiên tự tạo `test-results/homepage-<thời-gian>-<id>/` gồm:

- `flutter.log`: output từ Flutter trong phiên.
- `homepage.jsonl`: một JSON cho mỗi lần vào homepage đã thu được.
- `REPORT.md`: bảng so sánh các lần vào, kèm trạng thái phiên capture.
- `launch-error.log`: lỗi khởi chạy nếu có.

Không có báo cáo nghĩa là **chưa thu được phép đo**, không phải 0 ms/PASS. Script trả exit 1 nếu Flutter lỗi hoặc không thu được báo cáo. Có báo cáo không đồng nghĩa đạt một ngưỡng hiệu năng; phải xem status và các mốc cụ thể.

## Chạy app như thường lệ

### Lưu ý riêng cho web profile

Flutter SDK hiện tại không chuyển stdout của web profile về terminal như web debug. Vì vậy `profile_home.py` mở bộ thu HTTP chỉ trên `127.0.0.1`, truyền địa chỉ tạm vào app bằng `HOME_PERF_ENDPOINT`; app gửi JSON sau khi chốt phép đo. Bộ thu kiểm tra origin localhost và token riêng của phiên. Không gửi số đo lên cloud. Có thể thấy dòng **Web timing collector ready** khi chạy bản script mới.

Giữ PowerShell mở sau khi thấy `Built build/web`; đây mới là hoàn tất build, chưa phải đo homepage. Khi vào `/buy`, JSON nhận qua bộ thu sẽ được in thành `[HOME_PERF]` và ghi file. Nếu báo cáo ghi `user_stopped` với 0 reports, script đã nhận tín hiệu ngắt trước khi thu được số đo.

Bộ đo bật mặc định trong debug/profile; bản release mặc định tắt. Có thể điều khiển rõ bằng:

```powershell
flutter run --profile --dart-define=HOME_PERF=true
flutter run --dart-define=HOME_PERF=false
```

Khi chạy từ IDE ở debug, xem console với từ khóa `[HOME_PERF]`. Với web profile chạy trực tiếp không qua script, xem console của Chrome; log không nhất thiết xuất hiện trong PowerShell. App tự lưu tối đa 20 báo cáo cuối bằng SharedPreferences (trên thiết bị/browser, không phải file root của repo). Muốn đọc lịch sử từ mã Dart/debugger:

```dart
final jsonReports = await HomePerformanceStore.readReports();
```

Muốn có file trên máy tính, dùng `profile_home.py` ở trên. Log đo chỉ lưu timing/count/platform/status, không lưu UID, email, URL ảnh hoặc dữ liệu bài đăng. File Flutter raw log vẫn chứa output thông thường của ứng dụng.

## Ý nghĩa các trường

Mọi giá trị `milestones_ms` tính từ lúc tạo màn hình, dùng Stopwatch đơn điệu.

| Trường | Ý nghĩa |
| --- | --- |
| `shell_frame` | Post-frame callback đầu tiên của màn hình, trước khi bắt đầu fetch |
| `posts_fetch_start` | Bắt đầu tải dữ liệu bài đăng |
| `posts_ready` | Hoàn tất truy vấn và chuyển dữ liệu thành model dùng bởi Provider |
| `posts_failed` | Fetch/parse bài đăng thất bại; không coi là tải thành công |
| `brands_settled` | Hàm fetch hãng xe đã kết thúc; xem errors của `brands_sdk` để biết lỗi |
| `content_frame` | Frame Flutter đầu sau khi hai luồng bài đăng/hãng xe kết thúc |
| `first_thumbnail_widget_built` | Widget ảnh đầu tiên trong danh sách bài đăng có ảnh được dựng |
| `first_thumbnail_frame` | Post-frame callback sau khi ảnh đó có frame để hiển thị |
| `elapsed_ms` | Thời gian đến lúc báo cáo được chốt, phụ thuộc status; không dùng timeout/abandoned làm “load time” |

Ảnh theo dõi là thumbnail đầu tiên có trong tập bài đăng ban đầu, không nhất thiết là ảnh lớn nhất hay tất cả ảnh trong viewport. Callback phản ánh Flutter frame, **không chứng minh GPU/raster đã hoàn tất, không phải web LCP**. Mốc ảnh bao gồm ảnh hưởng cache/tải/giải mã/lập lịch; không tách chính xác thời gian download và decode. `synchronous_image_frame=true` cho biết frame đã sẵn đồng bộ, thường do cache; không phải chứng minh cache mạng.

`operations` tổng hợp `posts_sdk`, `cars_sdk`, `models_sdk`, `users_sdk`, `images_metadata_sdk`, `brands_sdk`. Mỗi nhóm gồm `started`, `completed`, `errors`, `total_ms`, `max_ms`. Đây là số lần gọi SDK được gắn đo và thời gian chờ SDK (có thể từ cache), **không phải số HTTP request hoặc số document bị tính phí**. `images_metadata_sdk` đo truy vấn URL ảnh trong Firestore, không đo tải byte ảnh Cloudinary. Các tác vụ có thể chạy song song, không cộng tất cả `total_ms` để suy ra thời gian tải trang.

## Trạng thái

- `ready`: đã có content frame và thumbnail đầu (hoặc không có thumbnail cần chờ).
- `partial_error`: đã đạt các mốc kết thúc nhưng có lỗi SDK/dữ liệu được ghi nhận.
- `timeout`: sau 60 giây chưa đủ mốc; báo cáo giữ các mốc đã có. Không hủy request nghiệp vụ.
- `abandoned`: rời/hủy màn hình trước khi hoàn tất.
- `interacted`: tìm kiếm/lọc/sắp xếp/mở chi tiết trước khi hoàn tất, tránh gộp phép đo ban đầu với luồng mới.

Ảnh lỗi vẫn dùng error handling mặc định của Flutter; nếu ảnh đầu không có frame, trace kết thúc bằng timeout/pending thay vì báo ready sai. Empty state không cần đợi ảnh. Lỗi ghi lịch sử local không làm hỏng app; vẫn có JSON console để script thu lại.

## So sánh kết quả

Giữ cùng thiết bị, build mode, mạng, dataset và cách vào trang. Tách lần lạnh và lần đã có cache. Đo nhiều lần rồi so `posts_ready`, `content_frame`, `first_thumbnail_frame` giữa các lần có status phù hợp. Hiện chưa có số đo thực tế từ tài khoản/thiết bị của bạn; các test tự động chỉ xác minh bộ đo hoạt động đúng, không phải benchmark homepage.
