# 🚗 ỨNG DỤNG MUA BÁN XE Ô TÔ TRỰC TUYẾN  
**Online Car Marketplace Mobile Application**

---

## 📌 Giới thiệu chung
Trong những năm gần đây, nhu cầu mua bán xe ô tô (đặc biệt là xe đã qua sử dụng) ngày càng tăng mạnh, nhất là tại các đô thị lớn. Tuy nhiên, thị trường hiện nay vẫn còn phân mảnh, chủ yếu thông qua các hội nhóm mạng xã hội hoặc các nền tảng không chính thống, gây khó khăn trong việc tìm kiếm, lọc thông tin và xác thực người bán.

Dự án **Ứng dụng mua bán xe ô tô trực tuyến** được xây dựng nhằm tạo ra một **nền tảng di động tiện lợi**, giúp người dùng dễ dàng **đăng tin bán xe, tìm kiếm xe, xem chi tiết thông tin và quản lý tin đăng** mọi lúc, mọi nơi thông qua điện thoại di động.

Ứng dụng được phát triển bằng **Flutter**, kết hợp các dịch vụ cloud hiện đại như **Firebase**, **Cloudinary** và **Django REST API**, đảm bảo hiệu năng, bảo mật và khả năng mở rộng trong tương lai.

---

## 🎯 Mục tiêu dự án

### 🎯 Mục tiêu chung
Phát triển một ứng dụng di động đa nền tảng (Android/iOS) phục vụ nhu cầu mua bán xe ô tô, thân thiện với người dùng và có tính ứng dụng thực tiễn cao.

### 🎯 Mục tiêu cụ thể
- Cho phép người dùng đăng ký và đăng nhập tài khoản an toàn.
- Hiển thị danh sách xe đang được rao bán kèm hình ảnh và thông tin chi tiết.
- Hỗ trợ tìm kiếm xe theo từ khóa gần đúng.
- Cho phép người dùng đăng tin bán xe, chỉnh sửa và xoá tin đăng.
- Quản lý hồ sơ cá nhân và lưu danh sách xe yêu thích.
- Tạo nền tảng có thể mở rộng thêm các chức năng nâng cao trong tương lai.

---

## 👥 Đối tượng áp dụng
- Người dùng có nhu cầu **mua hoặc bán xe ô tô** thông qua thiết bị di động.
- Sinh viên, giảng viên sử dụng cho mục đích **học tập, nghiên cứu và đánh giá đồ án**.
- Có thể mở rộng cho **garage nhỏ, showroom địa phương hoặc cá nhân kinh doanh xe**.

---

## 🧱 Kiến trúc hệ thống
Hệ thống được xây dựng theo mô hình:

- **Mobile App (Flutter)**: giao diện người dùng, xử lý logic phía client.
- **Firebase Authentication**: xác thực người dùng.
- **Firebase Firestore**: lưu trữ dữ liệu người dùng và tin đăng.
- **Cloudinary**: lưu trữ và tối ưu hình ảnh xe và ảnh đại diện.
- **Django REST Framework**: cung cấp REST API cho chức năng tìm kiếm xe theo từ khóa.

> Ứng dụng không sử dụng backend phức tạp hoặc cơ sở dữ liệu quan hệ, phù hợp với quy mô đồ án và mục tiêu học tập.

---

## ⚙️ Công nghệ & công cụ sử dụng

### 📱 Frontend (Mobile)
- Flutter (Dart)
- Provider (State Management)
- GoRouter (Navigation)
- Firebase SDK
- Google Maps Flutter
- Image Picker
- Dio / HTTP
- Shared Preferences

### ☁️ Backend & Cloud
- Firebase Authentication
- Firebase Firestore
- Firebase Storage
- Cloudinary
- Django REST Framework (Search API)

### 🛠 Công cụ phát triển
- Visual Studio Code
- Android Studio

---

## ✨ Chức năng chính

### 👤 Người dùng
- Đăng ký / Đăng nhập tài khoản
- Xem danh sách xe đang được bán
- Xem chi tiết xe (hình ảnh, mô tả, giá, thông tin liên hệ)
- Tìm kiếm xe theo từ khóa
- Đăng tin bán xe (tải ảnh, nhập thông tin)
- Chỉnh sửa / xoá tin đăng
- Lưu xe yêu thích
- Cập nhật hồ sơ cá nhân

### 🛡 Quản trị viên (định hướng mở rộng)
- Quản lý người dùng
- Duyệt hoặc từ chối tin đăng vi phạm

---

## 📁 Cấu trúc thư mục dự án

```text
project-root/
├─ fronted/
│  ├─ android/
│  ├─ assets/
│  ├─ ios/
│  ├─ lib/
│  │  ├─ models/
│  │  ├─ navigation/
│  │  ├─ providers/
│  │  ├─ repositories/
│  │  ├─ services/
│  │  ├─ ui/
│  │  ├─ utils/
│  │  │  └─ validators/
│  │  ├─ main.dart
│  │  └─ main_admin.dart
│  ├─ test/
│  ├─ web/
│  ├─ firebase.json
│  └─ pubspec.yaml
├─ .gitignore
├─ LICENSE
└─ README.md
````

---

## 🚀 Hướng dẫn cài đặt & chạy dự án

### 1️⃣ Yêu cầu môi trường

* Flutter SDK >= 3.0.0
* Android Studio hoặc thiết bị Android/iOS thật
* Firebase Project đã được cấu hình

### 2️⃣ Cài đặt thư viện

```bash
flutter pub get
```

### 3️⃣ Chạy ứng dụng

```bash
flutter run
```

---

## 🔐 Cấu hình môi trường

* Kết nối Firebase thông qua `firebase.json`
* Cấu hình Cloudinary trong service upload ảnh
* REST API Django dùng riêng cho chức năng tìm kiếm xe

> Dữ liệu sử dụng trong dự án mang tính **giả lập / thử nghiệm**, không kết nối với các sàn xe thực tế.

---

## 📊 Yêu cầu phi chức năng

* Thời gian phản hồi < 2 giây
* Hiệu năng tốt khi tải nhiều dữ liệu hình ảnh
* Bảo mật thông tin người dùng
* Giao diện đơn giản, dễ sử dụng
* Có khả năng mở rộng trong tương lai

---

## 🔄 CI/CD & DevOps

Dự án sử dụng **GitHub Actions** để tự động kiểm tra và build ứng dụng Flutter.

- **CI**: chạy analyze & test khi tạo Pull Request
- **CD**: build APK release và deploy lên **Firebase App Distribution** khi tạo tag

📄 Tài liệu chi tiết:  
➡️ [CI/CD Pipeline Documentation](docs/CI-CD.md)

---

## 🚧 Phạm vi & giới hạn

* Ứng dụng chỉ chạy trên **thiết bị di động**
* Không bao gồm:

  * Thanh toán online
  * Chat trực tiếp
  * Định giá xe tự động
* Chức năng tìm kiếm ở mức cơ bản, không sử dụng AI

---

## 🔮 Hướng phát triển tương lai

* Phân quyền quản trị viên nâng cao
* Chat trực tiếp giữa người mua và người bán
* Thanh toán online
* Định giá xe tự động
* Phát triển phiên bản Web Application

---

## 📄 License

This project is licensed under the **MIT License**.

---

## 📬 Ghi chú

Dự án được thực hiện phục vụ mục đích **học tập và nghiên cứu**, có thể tiếp tục mở rộng và triển khai thực tế trong tương lai.

⭐ Nếu bạn thấy dự án hữu ích, đừng quên **star repository** để ủng hộ nhé!
