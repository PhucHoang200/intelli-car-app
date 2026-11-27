from pathlib import Path
from collections import Counter
from xml.sax.saxutils import escape
import re
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.pagesizes import A4

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'output/pdf/bao_cao_kiem_thu_va_toi_uu_homepage.pdf'
OUT.parent.mkdir(parents=True, exist_ok=True)
report = (ROOT / 'TEST_REPORT.md').read_text(encoding='utf-8')
baseline = report.split('### baseline_analyze.log', 1)[1].split('```', 2)[1]
issues = [line.strip() for line in baseline.splitlines() if re.match(r'\s*(warning|info|error) - ', line)]
assert len(issues) == 195, len(issues)
pdfmetrics.registerFont(TTFont('ArialVN', 'C:/Windows/Fonts/arial.ttf'))
pdfmetrics.registerFont(TTFont('ArialVNB', 'C:/Windows/Fonts/arialbd.ttf'))
pdfmetrics.registerFontFamily('ArialVN', normal='ArialVN', bold='ArialVNB', italic='ArialVN', boldItalic='ArialVNB')
styles = getSampleStyleSheet()
for name in ['Normal', 'BodyText', 'Title', 'Heading1', 'Heading2']:
    styles[name].fontName = 'ArialVN' if name in ['Normal', 'BodyText'] else 'ArialVNB'
styles['BodyText'].fontSize = 10
styles['BodyText'].leading = 15
styles['BodyText'].spaceAfter = 8
styles['Title'].fontSize = 27
styles['Title'].leading = 35
styles['Title'].textColor = colors.HexColor('#14364B')
styles['Heading1'].fontSize = 19
styles['Heading1'].leading = 25
styles['Heading1'].spaceAfter = 16
styles['Heading2'].fontSize = 12
styles['Heading2'].leading = 17
styles.add(ParagraphStyle(name='SmallVN', fontName='ArialVN', fontSize=8, leading=11, spaceAfter=5))
story = []
def p(text, style='BodyText'):
    return Paragraph(text, styles[style])
def add(text, style='BodyText'):
    story.append(p(text, style))
def title(text):
    if story: story.append(PageBreak())
    add(text, 'Heading1')
def table(rows, widths=None, compact=False):
    data = [[p(str(x), 'SmallVN') for x in row] for row in rows]
    t = Table(data, colWidths=widths, repeatRows=1, hAlign='LEFT')
    t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#E4EEF4')),('VALIGN',(0,0),(-1,-1),'TOP'),('LINEBELOW',(0,0),(-1,0),1,colors.HexColor('#267D91')),('BOTTOMPADDING',(0,0),(-1,-1),7),('TOPPADDING',(0,0),(-1,-1),7),('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,colors.HexColor('#F5F8FA')])]))
    if compact:
        t.setStyle(TableStyle([('TOPPADDING',(0,0),(-1,-1),2),('BOTTOMPADDING',(0,0),(-1,-1),2)]))
    story.append(t)
    story.append(Spacer(1, 10))
def flow(text):
    t = Table([[p(text)]], colWidths=[491])
    t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,-1),colors.HexColor('#EAF4F2')),('BOX',(0,0),(-1,-1),0.7,colors.HexColor('#42978C')),('LEFTPADDING',(0,0),(-1,-1),14),('RIGHTPADDING',(0,0),(-1,-1),14),('TOPPADDING',(0,0),(-1,-1),12),('BOTTOMPADDING',(0,0),(-1,-1),12)]))
    story.append(t)
    story.append(Spacer(1,12))

add('INTELLI CAR APP', 'Heading2')
story.append(Spacer(1,20))
add('Báo cáo kiểm thử<br/>và tối ưu homepage', 'Title')
add('Flutter Web · Firebase/Firestore · Django · Cloudinary', 'Heading2')
story.append(Spacer(1,24))
flow('<b>19,436 giây → 4,590 giây</b><br/>Thời gian dữ liệu sẵn sàng giảm 76,4% trong hai mẫu quan sát trước/sau, mỗi mẫu có 6 bài đăng.')
add('Báo cáo tổng hợp lỗi ban đầu, kiến trúc và luồng xử lý trước/sau sửa, bằng chứng kiểm thử và giới hạn của mức cải thiện.')
add('<b>Ngày lập:</b> 26/11/2026<br/><b>Kỳ bằng chứng:</b> 02-03/10/2026<br/><b>Phạm vi:</b> frontend và bộ kiểm thử backend cô lập; đo homepage /buy trên Chrome/profile.')
add('Ngày lập báo cáo không phải ngày chạy lại test. Tài liệu tổng hợp các log hiện có, không xác nhận trạng thái triển khai hoặc hiệu năng tại ngày 26/11/2026.')
add('Nội dung: 1. Lỗi xác nhận · 2. Rủi ro và môi trường · 3. Kiến trúc cũ · 4. Kiến trúc mới · 5. Mức cải thiện · 6. Kiểm chứng và nguồn · Phụ lục đầy đủ analyzer.', 'SmallVN')

title('1. Lỗi và vấn đề đã xác nhận')
table([
['Mã / loại','Bằng chứng ban đầu','Sửa và kết quả'],
['F01 · Test sai fixture','Counter test dựng MaterialApp trống nhưng mong text 0 và nút cộng. Baseline: 0 pass, 1 fail.','Thay bằng 3 test widget thật: email, ẩn/hiện mật khẩu, dropdown. Không thay kỳ vọng để che lỗi ứng dụng.'],
['F02 · Validator','Input được lower-case nhưng whitelist nhiên liệu/hộp số còn chữ hoa. 12 trường hợp hợp lệ fail; đợt test bổ sung có 35 pass, 12 fail.','Chuẩn hóa hai whitelist trong CarValidator thành chữ thường. Suite sau sửa: 50/50 pass. Chưa chứng minh helper này được gọi trong UI hiện tại.'],
['F03 · Hiệu năng homepage','25 SDK calls cho 6 bài, thực thi tuần tự. Data ready 19,436 s; thumbnail đầu 19,834 s.','Loader song song có giới hạn + dedup theo ID. Mẫu mới: 19 calls, data ready 4,590 s.'],
['F04 · Thu log web profile','Phiên 20261002-204214-a6b217 có 0 báo cáo. Chỉ đọc stdout không đủ thu sự kiện web/profile.','Thêm HTTP collector loopback và gửi JSON từ app. Các phiên sau thu được mẫu ready. user_stopped không tự đồng nghĩa lỗi.'],
['F05 · Collector trên Windows','Trong kiểm thử harness: 11 pass, 1 error; HTTP 403 trả trước khi đọc body làm reset kết nối.','Đọc body trong giới hạn rồi trả 403; chạy lại 12/12 pass, gồm kiểm tra origin và CORS.'],
['F06 · Phân tích tĩnh','195 diagnostics: 0 error, 91 warning, 104 info. Analyzer exit 1.','Cuối kỳ: 191 diagnostics, 0 error / 88 warning / 103 info. Vẫn FAIL; không coi toàn bộ chất lượng mã đã sạch.']
], [97,194,200])
add('12 failure của F02 là các test case thất bại của cùng lỗi chuẩn hóa whitelist, không phải 12 lỗi nghiệp vụ độc lập. F04/F05 thuộc công cụ đo, không phải lỗi dữ liệu bán xe.', 'SmallVN')

title('2. Tồn đọng, môi trường và phạm vi')
add('Rủi ro từ đọc mã - chưa được chứng minh bằng test runtime', 'Heading2')
table([
['Phát hiện','Trạng thái / tác động'],
['AuthValidator','Thông báo yêu cầu ký tự đặc biệt nhưng regex không bắt buộc. Chưa đổi chính sách mật khẩu; cần chốt yêu cầu nghiệp vụ.'],
['Post.fromMap','Ngày thiếu/sai kiểu có thể được thay bằng DateTime.now(), che dữ liệu lỗi. Chưa sửa; cần quyết định cách xử lý dữ liệu không hợp lệ.'],
['ID bài đăng tự tăng','Đọc max ID rồi ghi, không transaction: nguy cơ ghi đè khi tạo đồng thời. Chưa chạy concurrency test và chưa xác nhận lỗi thực tế.'],
['Đọc toàn bộ posts; prefetch trùng','Đã thêm phân trang và bỏ prefetch landing. Với 6 posts, chưa đánh giá hiệu quả phân trang hoặc tải trang tiếp trên dữ liệu thật >20 posts.']
], [135,356])
add('Các trở ngại thực thi - không tính là bug nghiệp vụ', 'Heading2')
add('• Flutter cần ghi cache ngoài workspace: chạy sandbox không có output; thực thi với quyền phù hợp mới chạy được.<br/>• Python harness lần đầu: 5 pass, 3 error do quyền thư mục tạm; chạy ngoài sandbox đạt 8/8.<br/>• Firebase Emulator: tải JAR trả HTTP 200 nhưng file tạm 0 byte; đã dừng và ghi INTERRUPTED. Ba test emulator chưa chạy.<br/>• Android thiếu cmdline-tools, license chưa xác định và không có thiết bị kết nối; iOS chưa chạy trên Windows.')
add('Không ghi nhận là failure thực: Wasm dry run thành công bị PowerShell bọc NativeCommandError; log vẫn xác nhận build web thành công. Các FAIL/BLOCKED được cố ý tạo trong harness nhằm kiểm tra exit code cũng không phải lỗi ứng dụng.')
add('API live, load test, Cloudinary delivery, security rules thật, E2E thiết bị và CI chưa được xác minh trong kỳ này. Backend test dùng Firestore giả, không chứng minh tích hợp production.', 'SmallVN')

title('3. Kiến trúc và workflow ban đầu')
flow('<b>Flutter UI → Provider → Repository</b><br/>Repository → Firebase SDK → Firestore: posts, cars, models, users, images, brands.<br/>URL ảnh trong metadata → widget ảnh → Cloudinary.<br/>Tìm kiếm qua HTTP → Django API (nhánh riêng với tải danh sách homepage).')
add('Các thực thể lưu tách collection; Flutter thực hiện ghép dữ liệu thành view model. Homepage không đi qua một API aggregation Django cho lượt tải danh sách đang đo.')
add('Workflow tải /buy', 'Heading2')
add('1. Landing khởi tạo prefetch posts/brands; vào /buy lại yêu cầu dữ liệu.<br/>2. BuyScreen khởi tạo; Provider gọi getPostsWithCarAndImages().<br/>3. Đọc toàn bộ posts, chưa có cursor/limit.<br/>4. Với từng post: await Car → await Model → await Seller → await Image metadata; hoàn tất bài hiện tại rồi mới sang bài kế tiếp.<br/>5. Ghép toàn bộ kết quả, cập nhật Provider; UI dựng danh sách và widget ảnh.<br/>6. Brands được lấy ở nhánh riêng; ảnh bắt đầu có frame theo luồng hiển thị.')
flow('<b>Posts → [Post 1: Car → Model → Seller → Images]</b><br/>→ [Post 2: Car → Model → Seller → Images] → … → Post 6<br/>→ Danh sách đầy đủ → Content frame → Thumbnail đầu')
add('Với 6 bài: 1 + 4 × 6 = 25 lượt SDK cho danh sách; thêm 1 lượt brands là 26. Model hoặc seller trùng ID vẫn đọc lại. Đây là kiểu truy xuất N+1 ở lớp ứng dụng, kèm chuỗi await tuần tự.')
add('Bằng chứng định lượng', 'Heading2')
add('Tổng SDK duration trên nhánh danh sách: 19.355,804 ms, gần bằng fetch elapsed 19.361,101 ms (chênh 5,297 ms). Brands chạy song song nên không cộng vào đường chờ này. Dữ liệu sẵn sàng chiếm khoảng 98% thời gian đến thumbnail đầu: nút thắt chính của mẫu cũ nằm trước render danh sách.')
add('Không suy từ số này rằng Firestore server hoặc Cloudinary tự thân chậm; SDK duration còn chịu ảnh hưởng mạng, cache và vị trí database.')

title('4. Kiến trúc và workflow sau sửa')
flow('<b>BuyScreen → PostProvider → PostRepository.getHomePage()</b><br/>→ HomeFeedLoader (điều phối, pool, dedup)<br/>→ FirestoreHomeFeedSource (SDK queries, cursor)<br/>→ Firestore → View model → Provider → UI / ảnh Cloudinary')
add('1. /buy tải trang đầu; không prefetch posts/brands ở landing.<br/>2. Query posts theo document ID; đọc tối đa 21 để trả 20 và xác định hasMore.<br/>3. Tối đa 4 post workers; pool giới hạn 4 lượt đọc SDK của mỗi page request. Brands nằm ngoài pool này.<br/>4. Trong mỗi post: Car → Model giữ phụ thuộc thật; Seller và Images chạy độc lập với nhánh đó.<br/>5. Cache Future theo ID cho car/model/user/images trong một page request, dùng chung cả truy vấn đang chạy.<br/>6. Giữ thứ tự kết quả, cập nhật UI; cuộn gần cuối hoặc bấm Xem thêm xe để tải trang tiếp.')
flow('<b>Mỗi post:</b> [Car → Model] ∥ [Seller] ∥ [Image metadata]<br/><b>Nhiều post:</b> worker chạy song song qua pool có giới hạn<br/><b>ID trùng:</b> dùng chung Future → giảm SDK calls<br/><b>Trang kế:</b> cursor → tải thêm → nối danh sách, bỏ ID trùng')
table([
['File trong lib/','Vai trò sau sửa'],
['repositories/home_feed_loader.dart','Điều phối song song, dependency, dedup; cấu hình A/B/C/D.'],
['repositories/firestore_home_feed_source.dart','Truy vấn Firestore, limit và cursor theo document ID.'],
['repositories/post_repository.dart','Thêm getHomePage(), nối repository vào loader mới.'],
['providers/post_provider.dart','Fetch/loadMore, giữ cursor khi lỗi; bỏ kết quả cũ sau refresh/search/dispose.'],
['ui/screen/user/buy_screen.dart','Load-more khi cuộn/bấm nút, trạng thái lỗi/retry/loading.'],
['ui/screen/user/introduction.dart','Bỏ prefetch landing bị tải lại khi vào homepage.']
], [235,256])
add('Không đổi backend, schema hay xử lý Cloudinary. Cache không tồn tại xuyên các lần tải; request cũ chưa được hủy ở Firebase nhưng kết quả cũ bị bỏ. Sort phía client chỉ áp dụng trên tin đã tải.', 'SmallVN')

title('5. Mức cải thiện đã quan sát')
add('Hai lượt Chrome/profile/web, cùng số lượng 6 bài: baseline ngày 02/10 và variant D ngày 03/10. Mỗi bên n=1; mẫu mới cache_state=unknown, status=ready, không lỗi SDK.')
table([
['Chỉ số','Trước','Sau','Thay đổi'],
['Posts ready','19,4360 s','4,5896 s','Giảm 76,4%'],
['Fetch elapsed','19,3611 s','4,5244 s','Giảm 76,6%'],
['Content frame','19,6088 s','4,7518 s','Giảm 75,8%'],
['Thumbnail đầu','19,8335 s','4,9046 s','Giảm 75,3%'],
['SDK calls danh sách','25','19','Giảm 24,0%'],
['SDK calls gồm brands','26','20','Giảm 23,1%']
], [175,95,95,126])
table([
['Operation','Calls trước → sau','Duration tổng trước → sau (ms)'],
['Posts','1 → 1','755,6 → 1.379,0'],
['Cars','6 → 6','4.384,5 → 3.787,4'],
['Models','6 → 4','4.647,401 → 2.498,2'],
['Sellers','6 → 2','5.031,502 → 1.277,6'],
['Image metadata','6 → 6','4.536,801 → 3.772,2'],
['Brands','1 → 1','758,5 → 1.386,2']
], [120,130,241])
add('<b>Diễn giải:</b> data ready giảm 14,8464 giây; thumbnail đầu giảm 14,9289 giây. Mẫu mới đạt data ready &lt;5 giây. Posts query và brands riêng lẻ chậm hơn, nhưng tổng thời gian vẫn giảm mạnh, phù hợp với lợi ích điều phối song song và dedup.')
add('Sau sửa, tổng SDK duration danh sách 12.714,4 ms chồng lấp trong fetch elapsed 4.524,4 ms. Không cộng duration song song để suy ra thời gian chờ người dùng. Số SDK calls cũng không phải số HTTP request hoặc số document reads tính phí.', 'SmallVN')
add('Giới hạn: khác ngày/mạng/cache chưa kiểm soát; baseline có prefetch, bản mới bỏ prefetch. Không tách được đóng góp riêng của từng thay đổi. Chỉ 6 bài nên chưa chứng minh lợi ích pagination. Thumbnail frame không phải LCP, toàn bộ ảnh hoặc GPU hoàn tất; 315 ms sau posts_ready không phải latency Cloudinary thuần.', 'SmallVN')

title('6. Kiểm chứng, đo lường và bước tiếp')
table([
['Hạng mục','Bằng chứng cuối kỳ'],
['Flutter tests','73/73 PASS; gồm 39 validator + 8 model + 3 widget + 8 trace + 10 loader + 5 provider.'],
['Backend cô lập','10/10 PASS: view Django thật, Firestore giả; không gọi service account production.'],
['Python harness','14/14 PASS: runner/logging, collector, nhóm thống kê và dữ liệu lỗi.'],
['Build web','PASS ở run 20261003-141920-e2c80f; compile 116,6 s. Build time không phải homepage latency.'],
['Analyzer','Run 20261003-142522-5074b7: 191 issues; exit 1. Chưa sạch lint.'],
['Homepage thật','Mẫu mới ready, 6 posts, 20/20 SDK calls completed, 0 errors. Không thay thế E2E toàn hệ thống.']
], [120,371])
add('Luồng kiểm thử và lưu bằng chứng', 'Heading2')
flow('Khảo sát source → chạy baseline → thêm test tái hiện → sửa nhỏ nhất<br/>→ chạy regression/build/analyze → ghi log và REPORT.md<br/>→ đo runtime /buy → so sánh JSONL trước/sau → ghi giới hạn')
add('home_load_trace.dart dùng Stopwatch từ BuyScreen.initState, ghi mốc SDK/data/content/thumbnail. HomeMeasuredImage quan sát ảnh đang hiển thị. profile_home.py chạy Flutter và collector loopback, lưu flutter.log + homepage.jsonl + REPORT.md; summarize_home.py phân nhóm điều kiện và tổng hợp. Không gộp thời gian login hoặc compile vào phép đo homepage.')
add('Bước xác minh tiếp theo', 'Heading2')
add('Đo A (tuần tự), B (song song), C (thêm dedup), D (thêm phân trang) trong cùng điều kiện. Ưu tiên A/D với 10 cold + 20 warm mỗi variant; nhãn cache không tự xóa cache. Với 10-30 mẫu, percentile đuôi vẫn thô, không coi là SLO ổn định. Kiểm tra live pagination >20 bài, retry và dữ liệu đổi đồng thời; sau đó giải quyết rủi ro ID/policy/rules và lint tồn đọng.')
add('Chưa có bằng chứng buộc chuyển ASP.NET Core hoặc đổi Cloudinary. Quyết định kiến trúc tiếp theo cần dựa trên phép đo lặp lại và workload lớn hơn.')

title('7. Nguồn và khả năng truy vết')
add('Tất cả đường dẫn dưới đây tương đối với thư mục frontend. Báo cáo dùng bằng chứng cục bộ, không suy diễn từ tài liệu quảng bá hoặc benchmark bên ngoài.')
for item in [
'TEST_REPORT.md: nhật ký đầy đủ, baseline analyzer/test và các vòng sửa.',
'tools/testing/baselines/homepage_sequential_20261002.jsonl: bản lưu baseline runtime.',
'test-results/homepage-20261002-210200-0af8bf/homepage.jsonl: mẫu trước tối ưu.',
'test-results/homepage-20261003-144123-37f777/homepage.jsonl và ANALYSIS.md: mẫu sau tối ưu.',
'test-results/20261003-142522-5074b7/: kết quả regression cuối kỳ.',
'test-results/20261003-141920-e2c80f/: kiểm thử và build web.',
'HOMEPAGE_OPTIMIZATION.md; HOME_PERFORMANCE.md; TESTING.md: hướng dẫn chạy, mode và giới hạn.',
'test/validators_test.dart; test/models_test.dart; test/widget_test.dart; test/home_load_trace_test.dart; test/home_feed_loader_test.dart; test/home_feed_provider_test.dart: mã kiểm thử.',
'tools/testing/backend_tests.py; test_harness.py; profile_home.py; summarize_home.py: bộ chạy và đo lường.'
]: add(escape(item), 'SmallVN')
add('Phụ lục: toàn bộ chẩn đoán tĩnh ban đầu', 'Heading2')
counts = Counter(line.rsplit(' - ', 1)[-1] for line in issues)
table([['Loại diagnostic','Số lượng']] + [[escape(k),str(v)] for k,v in counts.most_common()], [370,121], compact=True)
add('Danh sách tiếp theo giữ nguyên nội dung 195 diagnostics từ baseline; không khẳng định từng mục còn tồn tại ở mã hiện tại. Tổng cuối kỳ là 191 trên tập mã đã thay đổi. Warning/info không tương đương lỗi runtime.', 'SmallVN')
title('Phụ lục A. 195 diagnostics ban đầu')
for i, line in enumerate(issues,1):
    add(f'<b>{i:03d}.</b> '+escape(line), 'SmallVN')

def footer(canvas, doc):
    canvas.setStrokeColor(colors.HexColor('#D4DFE5'))
    canvas.line(52,42,543,42)
    canvas.setFont('ArialVN',8)
    canvas.setFillColor(colors.HexColor('#557080'))
    canvas.drawString(52,28,'INTELLI CAR | Bằng chứng 02-03/10/2026 | Báo cáo 26/11/2026')
    canvas.drawRightString(543,28,str(doc.page))
doc = SimpleDocTemplate(str(OUT), pagesize=A4, rightMargin=52,leftMargin=52,topMargin=45,bottomMargin=56,title='Báo cáo kiểm thử và tối ưu homepage - Intelli Car',author='Intelli Car - Engineering report')
doc.build(story,onFirstPage=footer,onLaterPages=footer)
print(OUT)
