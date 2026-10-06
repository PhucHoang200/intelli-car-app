# Thí nghiệm tối ưu homepage

## Thay đổi đã triển khai

Mặc định dùng **D**: tối đa 4 lời gọi SDK liên quan đang chạy trên mỗi lần tải trang, deduplicate theo ID trong lần tải đó, và trang 20 bài. Nhánh hãng xe riêng chạy song song như trước, nên có thể có thêm 1 lời gọi brands ngoài giới hạn 4 của feed.

Dependency thực sự vẫn là `post → car → model`; seller và metadata ảnh chạy độc lập. Pool giới hạn lời gọi SDK, không giữ slot trong lúc đợi model sau car. Kết quả được trả theo thứ tự posts ban đầu dù các request hoàn tất khác thứ tự.

Cache lưu **Future đang chạy** theo car/model/user/car-images ID để các bài trùng ID dùng chung request. Cache chỉ tồn tại trong một page request; không có cache tồn tại lâu giữa các lần tải, tránh ẩn thay đổi dữ liệu. Không thay Cloudinary, schema Firestore hay backend Django.

Pagination dùng document-ID cursor (cùng thứ tự mặc định cũ), query `limit(pageSize + 1)` để xác định còn trang. Chỉ hydrate pageSize bài, không hydrate document look-ahead. Không cần field creationDate trên mọi document cũ. Thêm scroll load-more và nút Xem thêm xe; lỗi trang sau giữ trang trước và cho retry. Provider chặn double-tap load-more, loại bài trùng khi append và bỏ kết quả cũ sau refresh/search/dispose.

Sort giá/năm/ngày vẫn là sort phía client, **áp dụng trên các tin đã tải**, UI ghi rõ phạm vi. Search Django là luồng riêng, không ghép trang feed vào kết quả search. Bộ lọc địa điểm trước đây chưa thực thi trong LocationFilterScreen, không được sửa thành tính năng mới ở đợt này.

Đã bỏ prefetch posts/brands ở landing `/` vì `/buy` tải lại. Điều này tránh request chồng nhau và cache warming không chủ ý. Vì thế sample lịch sử 19.834 giây là mốc tham chiếu, chưa phải đối chứng hoàn toàn tương đương: hãy đo lại **A** trên code hiện tại. Cả A/B/C/D mới đều không prefetch ở landing.

## Chọn thí nghiệm

| Chế độ | Tải liên quan | Dedup trong request | Pagination |
| --- | --- | --- | --- |
| A | Tuần tự | Không | Không |
| B | Song song, giới hạn 4 | Không | Không |
| C | Song song, giới hạn 4 | Có | Không |
| D (mặc định) | Song song, giới hạn 4 | Có | 20 bài/trang |

Các chế độ dùng chung parser/shape kết quả, khác scheduler/cache/page policy; A giữ chuỗi tuần tự để làm đối chứng. API legacy `getPostsWithCarAndImages` vẫn còn cho tương thích; homepage hiện đi qua `getHomePage` → HomeFeedLoader → FirestoreHomeFeedSource.

```powershell
python tools/testing/profile_home.py --device chrome --variant A --cache-state cold --label six-posts-same-network
python tools/testing/profile_home.py --device chrome --variant B --cache-state cold --label six-posts-same-network
python tools/testing/profile_home.py --device chrome --variant C --cache-state cold --label six-posts-same-network
python tools/testing/profile_home.py --device chrome --variant D --cache-state cold --label six-posts-same-network
```

Chạy từng lệnh riêng, đăng nhập và vào `/buy`, đợi HOME_PERF rồi Ctrl+C. Đừng chạy nhiều phiên song song. Với 6 bài, D vẫn trả 6 bài: pagination không tự giải quyết latency của dataset nhỏ; cải thiện chính cần đo ở B/C.

Khi chạy Flutter trực tiếp, tùy chọn build tương đương là `--dart-define=HOME_VARIANT=D`, `--dart-define=HOME_CONCURRENCY=4`, `--dart-define=HOME_PAGE_SIZE=20`. Code kiểm tra concurrency 1..16 và pageSize 1..100. Tạm chỉnh page size nhỏ để kiểm tra scroll/retry khi chỉ có 6 bài; không trộn phép đo đó với pageSize 20.

## Cold/warm và 10–30 lần đo

`--cache-state` chỉ là **nhãn do người đo khai báo**, không tự xóa cache, không tự đăng nhập và không tự tạo 30 lượt.

- Cold: đo lần đầu vào `/buy` trong một phiên Chrome mới, sau khi chuẩn bị cache nhất quán. Bộ preload landing đã tắt. Điều này vẫn không chứng minh cache CDN/server đều trống.
- Warm: chạy với `--cache-state warm`, mở `/buy` một lần làm nóng. Giữ phiên Chrome, rời `/buy` rồi quay lại để đo các lần tiếp theo. Bỏ mẫu làm nóng đầu khỏi input thống kê; không gộp nó vào warm cohort.
- Ưu tiên 10 cold + 20 warm cho A và D; B/C giúp phân biệt tác động của scheduling và dedup. Giữ cùng account, dataset 6 bài, thiết bị, mạng và build profile; ghi label tương ứng. Không bật/tắt cache hoặc đổi mạng giữa một cohort.
- Nếu browser/Firestore dùng cache bền vững, phải kiểm soát riêng; chỉ bật “Disable cache” trong DevTools không chứng minh đã xóa mọi cache SDK. Không xóa dữ liệu Firebase thật.

Chưa có 10–30 mẫu runtime sau sửa trong repository. Unit test dùng nguồn giả để chứng minh dependency/concurrency/call counts, không dùng timing đó làm số đo production hoặc khẳng định đạt <5 giây.

## Tổng hợp kết quả đã export

```powershell
python tools/testing/summarize_home.py "test-results/homepage-*/homepage.jsonl"
```

Tự tạo `test-results/comparison-<thời-gian>/REPORT.md` và `summary.json` với min/max/mean/median (p50)/p90/p95/p99/population stddev cho posts_ready/content_frame/first_thumbnail_frame.

Công cụ tách nhóm theo variant, cache label, mode, platform, post_count, concurrency, page_size và experiment label; deduplicate run_id. Chỉ status ready được đưa vào latency, nhưng tất cả status đều được đếm. Thiếu mốc không được biến thành 0. p90/p95/p99 là nearest rank; với 10–30 mẫu, p99 thường là max nên chưa đủ để khẳng định SLO ổn định. Dataset/device/network phải được người đo giữ đúng, không thể suy ra chỉ từ label.

Sample trước sửa được lưu tại `tools/testing/baselines/homepage_sequential_20261002.jsonl` (variant legacy/unknown cache). Có thể đưa vào lệnh tổng hợp như một input riêng; không gộp legacy với nhóm A mới.

## Đọc phép đo sau parallelization

`total_ms` của các nhóm SDK lúc này **chồng lấp**. Không cộng chúng để suy ra elapsed hay tỉ lệ bottleneck như với chuỗi tuần tự cũ. `measure()` bắt đầu sau khi được pool cấp slot: tổng SDK duration không bao gồm queue wait, còn posts_ready có bao gồm.

Mục tiêu <5 giây là giả thuyết cần kiểm chứng, không phải cam kết. Chỉ tính improvement giữa cohorts tương đương; với một sample baseline cũ không suy ra p95 trước/sau.
