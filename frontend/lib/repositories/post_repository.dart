import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:online_car_marketplace_app/models/post_model.dart';
import 'package:online_car_marketplace_app/models/car_model.dart';
import 'package:online_car_marketplace_app/models/model_model.dart';
import 'package:online_car_marketplace_app/models/post_with_car_and_images.dart';
import '../models/brand_model.dart';

class PostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _djangoApiBaseUrl = 'http://10.0.2.2:8000/onlinecar';

  Future<void> addPost(Post post) async {
    await _firestore.doc('posts/${post.id}').set(post.toMap());
  }

  Future<void> addPostAutoIncrement(Post post) async {
    final snapshot = await _firestore
        .collection('posts')
        .orderBy('id', descending: true)
        .limit(1)
        .get();

    int nextId = 1;
    if (snapshot.docs.isNotEmpty) {
      final lastPost = Post.fromMap(snapshot.docs.first.data());
      nextId = lastPost.id + 1;
    }

    final newPost = Post(
      id: nextId,
      userId: post.userId,
      carId: post.carId,
      title: post.title,
      description: post.description,
      creationDate: post.creationDate,
    );

    await _firestore
        .collection('posts')
        .doc(newPost.id.toString())
        .set(newPost.toMap());
  }

  Future<List<Post>> getPosts() async {
    final snapshot = await _firestore.collection('posts').get();
    return snapshot.docs.map((doc) => Post.fromMap(doc.data())).toList();
  }

  Future<List<Map<String, dynamic>>> getPostsWithCarAndImages() async {
    final postsSnapshot = await _firestore.collection('posts').get();
    List<Map<String, dynamic>> results = [];

    for (var doc in postsSnapshot.docs) {
      final post = Post.fromMap(doc.data());
      Car? car;
      String? sellerName;
      String? sellerPhone;
      String? sellerAddress;
      String? carLocation;
      String? carModelName;
      List<String> imageUrls = [];

      // Lấy thông tin xe
      final carDoc = await _firestore.collection('cars').doc(post.carId.toString()).get();
      if (carDoc.exists) {
        final carData = carDoc.data() as Map<String, dynamic>;
        car = Car.fromMap(carData);
        carLocation = carData['location'] as String?;

        // Lấy tên model từ collection 'models' dựa vào car.modelId
        if (car?.modelId != null) {
          try {
            final modelDoc = await _firestore.collection('models').doc(car!.modelId.toString()).get();
            if (modelDoc.exists) {
              final modelData = modelDoc.data() as Map<String, dynamic>;
              carModelName = CarModel.fromMap(modelData).name; // <-- Lấy name từ CarModel
            }
          } catch (e) {
            print('Error fetching car model name for modelId ${car!.modelId}: $e');
            carModelName = null;
          }
        }
      }


      // Lấy thông tin người dùng
      if (post.userId != null) {
        final String userId = post.userId!;
        try {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            sellerName = userData['name'] as String?;
            sellerPhone = userData['phone'] as String?;
            sellerAddress = userData['address'] as String?;
          } else {
            sellerName = null;
            sellerPhone = null;
            sellerAddress = null;
          }
        } catch (e) {
          sellerName = null;
          sellerPhone = null;
          sellerAddress = null;
        }
      } else {
        sellerName = null;
        sellerPhone = null;
        sellerAddress = null;
      }

      // Lấy ảnh
      final imagesSnapshot = await _firestore
          .collection('images')
          .where('carId', isEqualTo: post.carId)
          .get();
      imageUrls = imagesSnapshot.docs.map((e) => e['url'] as String).toList();

      results.add({
        'post': post,
        'car': car,
        'sellerName': sellerName,
        'sellerPhone': sellerPhone,
        'sellerAddress': sellerAddress,
        'carLocation': carLocation,
        'images': imageUrls,
        'carModelName': carModelName,
      });
    }

    return results;
  }

  // Future<DocumentSnapshot<Map<String, dynamic>>> getPostDetails(String postId) async {
  //   return await _firestore.collection('posts').doc(postId).get();
  // }

  Future<Map<String, dynamic>> getPostDetails(String postId) async {
    final postDoc = await _firestore.collection('posts').doc(postId).get();

    if (!postDoc.exists) {
      // Trả về một Map rỗng hoặc null nếu bài đăng không tồn tại
      return {};
    }

    final post = Post.fromMap(postDoc.data()!);
    Car? car;
    String? sellerName;
    String? sellerPhone;
    String? sellerAddress;
    String? carLocation;
    String? carModelName; // Thêm biến này
    List<String> imageUrls = [];

    // Lấy thông tin xe (Tương tự như getPostsWithCarAndImages)
    final carDoc = await _firestore.collection('cars').doc(post.carId.toString()).get();
    if (carDoc.exists) {
      final carData = carDoc.data() as Map<String, dynamic>;
      car = Car.fromMap(carData);
      carLocation = carData['location'] as String?;

      // Lấy tên model từ collection 'models' dựa vào car.modelId
      if (car?.modelId != null) {
        try {
          final modelDoc = await _firestore.collection('models').doc(car!.modelId.toString()).get();
          if (modelDoc.exists) {
            final modelData = modelDoc.data() as Map<String, dynamic>;
            carModelName = CarModel.fromMap(modelData).name; // Lấy name từ CarModel
          }
        } catch (e) {
          print('Error fetching car model name for modelId ${car!.modelId}: $e');
          carModelName = null;
        }
      }
    }

    // Lấy thông tin người dùng (Tương tự như getPostsWithCarAndImages)
    if (post.userId != null) {
      final String userId = post.userId!;
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          sellerName = userData['name'] as String?;
          sellerPhone = userData['phone'] as String?;
          sellerAddress = userData['address'] as String?;
        }
      } catch (e) {
        print('Error fetching user data for userId $userId: $e');
      }
    }

    // Lấy ảnh (Tương tự như getPostsWithCarAndImages)
    final imagesSnapshot = await _firestore
        .collection('images')
        .where('carId', isEqualTo: post.carId)
        .get();
    imageUrls = imagesSnapshot.docs.map((e) => e['url'] as String).toList();

    return {
      'post': post,
      'car': car,
      'sellerName': sellerName,
      'sellerPhone': sellerPhone,
      'sellerAddress': sellerAddress,
      'carLocation': carLocation,
      'images': imageUrls,
      'carModelName': carModelName, // Thêm carModelName vào kết quả
    };
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getCarDetails(String carId) async {
    return await _firestore.collection('cars').doc(carId).get();
  }

  Future<PostWithCarAndImages?> getPostWithCarAndImagesById(String postId) async {
    final postDoc = await _firestore.collection('posts').doc(postId).get();
    if (postDoc.exists && postDoc.data() != null) {
      final postData = postDoc.data() as Map<String, dynamic>;
      final post = Post.fromMap(postData);
      return await _fetchPostDetails(post);
    }
    return null;
  }

  Future<PostWithCarAndImages> _fetchPostDetails(Post post) async {
    Car? car;
    String? sellerName;
    String? sellerPhone;
    String? sellerAddress;
    String? carLocation;
    String? carModelName;
    List<String> imageUrls = [];

    // Lấy thông tin xe
    try {
      final carDoc = await _firestore.collection('cars').doc(post.carId.toString()).get();
      if (carDoc.exists) {
        final carData = carDoc.data() as Map<String, dynamic>;
        car = Car.fromMap(carData);
        carLocation = carData['location'] as String?;

        // Lấy tên model từ collection 'models' dựa vào car.modelId
        if (car?.modelId != null) {
          try {
            final modelDoc = await _firestore.collection('models').doc(car!.modelId.toString()).get();
            if (modelDoc.exists) {
              final modelData = modelDoc.data() as Map<String, dynamic>;
              carModelName = CarModel.fromMap(modelData).name; // <-- Lấy name từ CarModel
            }
          } catch (e) {
            print('Error fetching car model name for modelId ${car!.modelId}: $e');
            carModelName = null;
          }
        }
      }
    } catch (e) {
      print('Error fetching car details for post ${post.id}: $e');
    }

    // Lấy thông tin người dùng
    if (post.userId != null) {
      final String userId = post.userId!;
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          sellerName = userData['name'] as String?;
          sellerPhone = userData['phone'] as String?;
          sellerAddress = userData['address'] as String?;
        } else {
          sellerName = null;
          sellerPhone = null;
          sellerAddress = null;
        }
      } catch (e) {
        print('Error fetching user details for post ${post.id}: $e');
        sellerName = null;
        sellerPhone = null;
        sellerAddress = null;
      }
    } else {
      sellerName = null;
      sellerPhone = null;
      sellerAddress = null;
    }

    // Lấy ảnh
    try {
      final imagesSnapshot = await _firestore
          .collection('images')
          .where('carId', isEqualTo: post.carId)
          .get();
      imageUrls = imagesSnapshot.docs.map((e) => e['url'] as String).toList();
    } catch (e) {
      print('Error fetching images for car ${post.carId}: $e');
    }

    return PostWithCarAndImages(
      post: post,
      car: car,
      sellerName: sellerName,
      sellerPhone: sellerPhone,
      sellerAddress: sellerAddress,
      carLocation: carLocation,
      imageUrls: imageUrls,
      carModelName: carModelName,
    );
  }

  // Phương thức hiện có để lấy tất cả bài đăng
  Stream<List<PostWithCarAndImages>> getAllPosts() {
    return _firestore.collection('posts').snapshots().asyncMap((postSnapshot) async {
      final posts = postSnapshot.docs.map((doc) => Post.fromMap(doc.data())).toList();

      final List<PostWithCarAndImages> postWithDetails = [];
      for (var post in posts) {
        // Lấy thông tin Car
        final carDoc = await _firestore.collection('cars').doc(post.carId.toString()).get();
        final car = carDoc.exists ? Car.fromMap(carDoc.data()!) : null;

        if (car != null) {
          // Lấy thông tin CarModel
          final modelDoc = await _firestore.collection('models').doc(car.modelId.toString()).get();
          final carModel = modelDoc.exists ? CarModel.fromMap(modelDoc.data()!) : null;

          // Lấy thông tin Brand
          Brand? brand;
          if (carModel != null) {
            final brandDoc = await _firestore.collection('brands').doc(carModel.brandId.toString()).get();
            brand = brandDoc.exists ? Brand.fromMap(brandDoc.data()!) : null;
          }

          // Lấy ảnh
          final imagesSnapshot = await _firestore.collection('images')
              .where('carId', isEqualTo: car.id)
              .get();
          final imageUrls = imagesSnapshot.docs
              .map((doc) => doc.data()['url'] as String)
              .toList();

          // Lấy thông tin người bán
          final userDoc = await _firestore.collection('users').doc(post.userId).get();
          final sellerName = userDoc.exists ? userDoc.data()!['name'] : null; // Thay đổi 'Unknown' thành null
          final sellerPhone = userDoc.exists ? userDoc.data()!['phone'] : null;
          final sellerAddress = userDoc.exists ? userDoc.data()!['address'] : null;
          final carLocation = car.location; // Lấy vị trí xe từ đối tượng car

          postWithDetails.add(PostWithCarAndImages(
            post: post,
            car: car,
            carModelName: carModel?.name,
            brand: brand,
            imageUrls: imageUrls,
            sellerName: sellerName,
            sellerPhone: sellerPhone,
            sellerAddress: sellerAddress,
            carLocation: carLocation, // Thêm vào đây
          ));
        }
      }
      return postWithDetails;
    });
  }

  // Phương thức mới để tìm kiếm bằng cách gọi API Django
  Stream<List<PostWithCarAndImages>> searchPosts(String query) async* {
    if (query.isEmpty) {
      yield* getAllPosts(); // Nếu query rỗng, trả về tất cả bài đăng
      return;
    }

    try {
      final response = await http.get(Uri.parse('$_djangoApiBaseUrl/search-posts/?query=$query')); // Đảm bảo '/api' trong đường dẫn

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        // print('Django Search API Response: ${jsonResponse.toString()}'); // Giữ lại dòng này để debug

        final List<PostWithCarAndImages> searchResults = jsonResponse.map((item) {
          final post = Post.fromMap(item['post']);
          final car = Car.fromMap(item['car']);
          final carModel = item['carModel'] != null ? CarModel.fromMap(item['carModel']) : null;
          final brand = item['brand'] != null ? Brand.fromMap(item['brand']) : null;
          final imageUrls = List<String>.from(item['imageUrls'] ?? []);

          // Lấy các trường mới từ response JSON
          final sellerName = item['sellerName'] as String?;
          final sellerPhone = item['sellerPhone'] as String?;
          final sellerAddress = item['sellerAddress'] as String?;
          final carLocation = item['carLocation'] as String?;

          return PostWithCarAndImages(
            post: post,
            car: car,
            carModelName: carModel?.name,
            brand: brand,
            imageUrls: imageUrls,
            sellerName: sellerName,
            sellerPhone: sellerPhone,
            sellerAddress: sellerAddress,
            carLocation: carLocation,
          );
        }).toList();
        yield searchResults;
      } else {
        print('Failed to load search results from Django: ${response.statusCode}');
        yield [];
      }
    } catch (e) {
      print('Error calling Django search API: $e');
      yield [];
    }
  }

  //Phương thức để lấy các bài đăng của một người dùng cụ thể
  Future<List<Post>> getPostsByUserId(String userId) async {
    final snapshot = await _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.map((doc) => Post.fromMap(doc.data())).toList();
  }

  //Phương thức để cập nhật một bài đăng
  Future<void> updatePost(Post post) async {
    await _firestore.collection('posts').doc(post.id.toString()).update(post.toMap());
  }

  //Phương thức để xóa một bài đăng
  Future<void> deletePost(int postId) async {
    await _firestore.collection('posts').doc(postId.toString()).delete();
  }
}