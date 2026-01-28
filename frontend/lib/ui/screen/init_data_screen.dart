// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import '../../../models/role_model.dart';
// import '../../../models/user_model.dart';
// import '../../../models/car_type_model.dart';
// import '../../../models/brand_model.dart';
// import '../../../models/model_model.dart';
// import '../../../models/car_model.dart';
// import '../../../models/image_model.dart';
// import '../../../models/favorite_model.dart';
// import '../../../models/message_model.dart';
// import '../../../models/post_model.dart';
// import '../../../repositories/role_repository.dart';
// import '../../../repositories/user_repository.dart';
// import '../../../repositories/car_type_repository.dart';
// import '../../../repositories/brand_repository.dart';
// import '../../../repositories/model_repository.dart';
// import '../../../repositories/car_repository.dart';
// import '../../../repositories/image_repository.dart';
// import '../../../repositories/favorite_repository.dart';
// import '../../../repositories/message_repository.dart';
// import '../../../repositories/post_repository.dart';
//
// class InitDataScreen extends StatelessWidget {
//   Future<void> initializeData() async {
//     final roleRepo = RoleRepository();
//     final userRepo = UserRepository();
//     final carTypeRepo = CarTypeRepository();
//     final brandRepo = BrandRepository();
//     final modelRepo = ModelRepository();
//     final carRepo = CarRepository();
//     final imageRepo = ImageRepository();
//     final favoriteRepo = FavoriteRepository();
//     final messageRepo = MessageRepository();
//     final postRepo = PostRepository();
//
//     // Thêm VaiTro
//     final roles = [
//       Role(id: 1, name: 'user'),
//       Role(id: 2, name: 'admin'),
//     ];
//     for (var role in roles) {
//       try {
//         await roleRepo.addRole(role);
//         print('Added role: ${role.name}');
//       } catch (e) {
//         print('Error adding role ${role.name}: $e');
//       }
//     }
//
//     // Thêm TaiKhoan
//     final users = [
//       User(
//         id: 1,
//         name: 'Hoang Phuc',
//         email: 'phucphuc2004444@gmail.com',
//         phone: '0944404698',
//         address: '123 Street, HCM',
//         avatarUrl: 'https://asset.cloudinary.com/doohwusyf/775f6c12d5784251acedb6d0684373c0',
//         roleId: 2,
//         status: 'Hoạt động',
//         creationDate: Timestamp.now(),
//         updateDate: Timestamp.now(),
//       ),
//       User(
//         id: 2,
//         name: 'Trần Thị B',
//         email: 'tranthib@gmail.com',
//         phone: '0987654321',
//         address: '456 Road, HN',
//         avatarUrl: 'https://asset.cloudinary.com/doohwusyf/4d40dfc854be3fd56703479219e55804',
//         roleId: 1,
//         status: 'Hoạt động',
//         creationDate: Timestamp.now(),
//         updateDate: Timestamp.now(),
//       ),
//       User(
//         id: 3,
//         name: 'Trần Thị c',
//         email: 'tranthic@gmail.com',
//         phone: '0987654341',
//         address: '456 Road, HN',
//         avatarUrl: 'https://asset.cloudinary.com/doohwusyf/4d40dfc854be3fd56703479219e55804',
//         roleId: 1,
//         status: 'Hoạt động',
//         creationDate: Timestamp.now(),
//         updateDate: Timestamp.now(),
//       ),
//       // Thêm các tài khoản khác
//     ];
//     for (var user in users) {
//       try {
//         await userRepo.addUser(user);
//         print('Added user: ${user.name}');
//       } catch (e) {
//         print('Error adding user ${user.name}: $e');
//       }
//     }
//
//
//     // Thêm LoaiXe
//     final carTypes = [
//       CarType(id: 1, name: 'Sedan'),
//       CarType(id: 2, name: 'SUV'),
//       CarType(id: 3, name: 'Hatchback'),
//       CarType(id: 4, name: 'Crossover'),
//       CarType(id: 5, name: 'MPV'),
//       CarType(id: 6, name: 'Coupe'),
//       CarType(id: 7, name: 'Convertible'),
//       CarType(id: 8, name: 'Pickup'),
//       CarType(id: 9, name: 'Limousine'),
//       CarType(id: 10, name: 'Van'),
//       CarType(id: 11, name: 'Minivan'),
//       CarType(id: 12, name: 'Microbus'),
//       CarType(id: 13, name: 'Bus'),
//       CarType(id: 14, name: 'Truck'),
//       CarType(id: 15, name: 'Other'),
//       // Thêm các loại xe khác
//     ];
//     for (var type in carTypes) {
//       try {
//         await carTypeRepo.addCarType(type);
//         print('Added car type: ${type.name}');
//       } catch (e) {
//         print('Error adding car type ${type.name}: $e');
//       }
//     }
//
//     // Thêm HangXe
//     final brands = [
//       Brand(id: 1, name: 'Toyota'),
//       Brand(id: 2, name: 'Honda'),
//       Brand(id: 3, name: 'Ford'),
//       Brand(id: 4, name: 'Mazda'),
//       Brand(id: 5, name: 'Mitsubishi'),
//       Brand(id: 6, name: 'Isuzu'),
//       Brand(id: 7, name: 'Suzuki'),
//       Brand(id: 8, name: 'Subaru'),
//       Brand(id: 9, name: 'Vinfast'),
//       Brand(id: 10, name: 'Hyundai'),
//       Brand(id: 11, name: 'Kia'),
//       Brand(id: 12, name: 'Lexus'),
//       Brand(id: 13, name: 'Mercedes-Benz'),
//       Brand(id: 14, name: 'BMW'),
//       Brand(id: 15, name: 'Audi'),
//       Brand(id: 16, name: 'Porsche'),
//       Brand(id: 17, name: 'Jaguar'),
//       Brand(id: 18, name: 'Volvo'),
//       Brand(id: 19, name: 'Tesla'),
//       Brand(id: 20, name: 'Chevrolet'),
//       Brand(id: 21, name: 'Nissan'),
//       Brand(id: 22, name: 'Volkswagen'),
//       Brand(id: 23, name: 'Peugeot'),
//       Brand(id: 24, name: 'Land Rover'),
//       // Thêm các hãng xe khác
//     ];
//     for (var brand in brands) {
//       try {
//         await brandRepo.addBrand(brand);
//         print('Added brand: ${brand.name}');
//       } catch (e) {
//         print('Error adding brand ${brand.name}: $e');
//       }
//     }
//
//     // Thêm DongXe
//     final models = [
//     // --- Toyota ---
//     CarModel(id: 1, brandId: 1, carTypeId: 1, name: 'Camry'), // Sedan
//     CarModel(id: 2, brandId: 1, carTypeId: 1, name: 'Corolla'), // Sedan
//     CarModel(id: 3, brandId: 1, carTypeId: 3, name: 'Corolla Hatchback'), // Hatchback
//     CarModel(id: 4, brandId: 1, carTypeId: 2, name: 'RAV4'), // SUV
//     CarModel(id: 5, brandId: 1, carTypeId: 16, name: 'Prius'), // Hybrid (assuming type 16)
//     CarModel(id: 6, brandId: 1, carTypeId: 2, name: 'Highlander'), // SUV
//     CarModel(id: 7, brandId: 1, carTypeId: 8, name: 'Tacoma'), // Pickup
//     CarModel(id: 8, brandId: 1, carTypeId: 2, name: '4Runner'), // SUV (Off-Road)
//     CarModel(id: 9, brandId: 1, carTypeId: 1, name: 'Avalon'), // Sedan (Large)
//     CarModel(id: 10, brandId: 1, carTypeId: 5, name: 'Sienna'), // MPV/Minivan
//     CarModel(id: 11, brandId: 1, carTypeId: 8, name: 'Tundra'), // Pickup (Full-Size)
//     CarModel(id: 12, brandId: 1, carTypeId: 7, name: 'GR86'), // Sports Car
//     CarModel(id: 13, brandId: 1, carTypeId: 7, name: 'Supra'), // Sports Car
//
//     // --- Honda ---
//     CarModel(id: 14, brandId: 2, carTypeId: 1, name: 'Civic'), // Sedan
//     CarModel(id: 15, brandId: 2, carTypeId: 3, name: 'Civic Hatchback'), // Hatchback
//     CarModel(id: 16, brandId: 2, carTypeId: 1, name: 'Accord'), // Sedan
//     CarModel(id: 17, brandId: 2, carTypeId: 2, name: 'CR-V'), // SUV
//     CarModel(id: 18, brandId: 2, carTypeId: 2, name: 'HR-V'), // SUV (Compact)
//     CarModel(id: 19, brandId: 2, carTypeId: 2, name: 'Pilot'), // SUV
//     CarModel(id: 20, brandId: 2, carTypeId: 2, name: 'Passport'), // SUV
//     CarModel(id: 21, brandId: 2, carTypeId: 8, name: 'Ridgeline'), // Pickup
//     CarModel(id: 22, brandId: 2, carTypeId: 5, name: 'Odyssey'), // MPV/Minivan
//     CarModel(id: 23, brandId: 2, carTypeId: 16, name: 'Accord Hybrid'), // Hybrid
//     CarModel(id: 24, brandId: 2, carTypeId: 16, name: 'CR-V Hybrid'), // Hybrid
//
//     // --- Ford ---
//     CarModel(id: 25, brandId: 3, carTypeId: 1, name: 'Fusion'), // Sedan (may be discontinued)
//     CarModel(id: 26, brandId: 3, carTypeId: 7, name: 'Mustang'), // Sports Car (Coupe/Convertible)
//     CarModel(id: 27, brandId: 3, carTypeId: 2, name: 'Escape'), // SUV
//     CarModel(id: 28, brandId: 3, carTypeId: 2, name: 'Explorer'), // SUV
//     CarModel(id: 29, brandId: 3, carTypeId: 2, name: 'Expedition'), // SUV (Full-Size)
//     CarModel(id: 30, brandId: 3, carTypeId: 8, name: 'F-150'), // Pickup
//     CarModel(id: 31, brandId: 3, carTypeId: 8, name: 'Super Duty'), // Pickup (Heavy Duty)
//     CarModel(id: 32, brandId: 3, carTypeId: 2, name: 'Bronco'), // SUV (Off-Road)
//     CarModel(id: 33, brandId: 3, carTypeId: 2, name: 'Bronco Sport'), // SUV (Compact Off-Road)
//     CarModel(id: 34, brandId: 3, carTypeId: 8, name: 'Maverick'), // Pickup (Compact)
//     CarModel(id: 35, brandId: 3, carTypeId: 10, name: 'Transit'), // Van
//     CarModel(id: 36, brandId: 3, carTypeId: 10, name: 'Transit Connect'), // Van (Compact)
//     CarModel(id: 37, brandId: 3, carTypeId: 17, name: 'Mustang Mach-E'), // EV (assuming type 17)
//
//     // --- Chevrolet ---
//     CarModel(id: 38, brandId: 20, carTypeId: 1, name: 'Malibu'), // Sedan
//     CarModel(id: 39, brandId: 20, carTypeId: 2, name: 'Equinox'), // SUV
//     CarModel(id: 40, brandId: 20, carTypeId: 2, name: 'Traverse'), // SUV
//     CarModel(id: 41, brandId: 20, carTypeId: 2, name: 'Tahoe'), // SUV (Full-Size)
//     CarModel(id: 42, brandId: 20, carTypeId: 2, name: 'Suburban'), // SUV (Extended)
//     CarModel(id: 43, brandId: 20, carTypeId: 8, name: 'Colorado'), // Pickup
//     CarModel(id: 44, brandId: 20, carTypeId: 8, name: 'Silverado'), // Pickup
//     CarModel(id: 45, brandId: 20, carTypeId: 7, name: 'Corvette'), // Sports Car
//     CarModel(id: 46, brandId: 20, carTypeId: 17, name: 'Bolt EV'), // EV
//     CarModel(id: 47, brandId: 20, carTypeId: 17, name: 'Bolt EUV'), // EV (Crossover)
//     CarModel(id: 48, brandId: 20, carTypeId: 1, name: 'Camaro'), // Muscle Car (Coupe/Convertible)
//
//     // --- BMW ---
//     CarModel(id: 49, brandId: 14, carTypeId: 1, name: '3 Series'), // Sedan
//     CarModel(id: 50, brandId: 14, carTypeId: 1, name: '5 Series'), // Sedan
//     CarModel(id: 51, brandId: 14, carTypeId: 1, name: '7 Series'), // Sedan (Luxury)
//     CarModel(id: 52, brandId: 14, carTypeId: 2, name: 'X1'), // SUV (Compact)
//     CarModel(id: 53, brandId: 14, carTypeId: 2, name: 'X3'), // SUV
//     CarModel(id: 54, brandId: 14, carTypeId: 2, name: 'X5'), // SUV
//     CarModel(id: 55, brandId: 14, carTypeId: 7, name: 'Z4'), // Sports Car (Roadster)
//     CarModel(id: 56, brandId: 14, carTypeId: 6, name: '4 Series'), // Coupe/Gran Coupe
//     CarModel(id: 57, brandId: 14, carTypeId: 6, name: '8 Series'), // Coupe/Gran Coupe (Luxury)
//     CarModel(id: 58, brandId: 14, carTypeId: 17, name: 'i4'), // EV (Gran Coupe)
//     CarModel(id: 59, brandId: 14, carTypeId: 17, name: 'iX'), // EV (SUV)
//
//     // --- Mercedes-Benz ---
//     CarModel(id: 60, brandId: 13, carTypeId: 1, name: 'C-Class'), // Sedan
//     CarModel(id: 61, brandId: 13, carTypeId: 1, name: 'E-Class'), // Sedan
//     CarModel(id: 62, brandId: 13, carTypeId: 1, name: 'S-Class'), // Sedan (Luxury)
//     CarModel(id: 63, brandId: 13, carTypeId: 2, name: 'GLC'), // SUV
//     CarModel(id: 64, brandId: 13, carTypeId: 2, name: 'GLE'), // SUV
//     CarModel(id: 65, brandId: 13, carTypeId: 2, name: 'GLS'), // SUV (Full-Size)
//     CarModel(id: 66, brandId: 13, carTypeId: 6, name: 'CLA'), // Coupe (4-Door)
//     CarModel(id: 67, brandId: 13, carTypeId: 6, name: 'CLS'), // Coupe (4-Door)
//     CarModel(id: 68, brandId: 13, carTypeId: 7, name: 'SL'), // Roadster
//     CarModel(id: 69, brandId: 13, carTypeId: 17, name: 'EQS'), // EV (Sedan)
//     CarModel(id: 70, brandId: 13, carTypeId: 17, name: 'EQE'), // EV (Sedan)
//     CarModel(id: 71, brandId: 13, carTypeId: 17, name: 'EQB'), // EV (SUV)
//     CarModel(id: 72, brandId: 13, carTypeId: 17, name: 'EQC'), // EV (SUV)
//
//     // --- Audi ---
//     CarModel(id: 73, brandId: 15, carTypeId: 1, name: 'A3'), // Sedan/Hatchback
//     CarModel(id: 74, brandId: 15, carTypeId: 1, name: 'A4'), // Sedan
//     CarModel(id: 75, brandId: 15, carTypeId: 1, name: 'A6'), // Sedan
//     CarModel(id: 76, brandId: 15, carTypeId: 1, name: 'A8'), // Sedan (Luxury)
//     CarModel(id: 77, brandId: 15, carTypeId: 2, name: 'Q3'), // SUV (Compact)
//     CarModel(id: 78, brandId: 15, carTypeId: 2, name: 'Q5'), // SUV
//     CarModel(id: 79, brandId: 15, carTypeId: 2, name: 'Q7'), // SUV
//     CarModel(id: 80, brandId: 15, carTypeId: 2, name: 'Q8'), // SUV (Coupe)
//     CarModel(id: 81, brandId: 15, carTypeId: 7, name: 'TT'), // Sports Car
//     CarModel(id: 82, brandId: 15, carTypeId: 6, name: 'A5'), // Coupe/Sportback
//     CarModel(id: 83, brandId: 15, carTypeId: 6, name: 'A7'), // Sportback
//     CarModel(id: 84, brandId: 15, carTypeId: 17, name: 'e-tron'), // EV (SUV)
//     CarModel(id: 85, brandId: 15, carTypeId: 17, name: 'e-tron GT'), // EV (Sportback)
//
//     // --- Tesla ---
//     CarModel(id: 86, brandId: 19, carTypeId: 17, name: 'Model 3'), // EV (Sedan)
//     CarModel(id: 87, brandId: 19, carTypeId: 17, name: 'Model S'), // EV (Sedan)
//     CarModel(id: 88, brandId: 19, carTypeId: 17, name: 'Model X'), // EV (SUV)
//     CarModel(id: 89, brandId: 19, carTypeId: 17, name: 'Model Y'), // EV (SUV)
//     CarModel(id: 90, brandId: 19, carTypeId: 17, name: 'Cybertruck'), // EV (Pickup)
//     CarModel(id: 91, brandId: 19, carTypeId: 7, name: 'Roadster'), // EV (Sports Car)
//
//     // --- Nissan ---
//     CarModel(id: 92, brandId: 21, carTypeId: 1, name: 'Altima'), // Sedan
//     CarModel(id: 93, brandId: 21, carTypeId: 1, name: 'Sentra'), // Sedan
//     CarModel(id: 94, brandId: 21, carTypeId: 1, name: 'Versa'), // Sedan
//     CarModel(id: 95, brandId: 21, carTypeId: 2, name: 'Rogue'), // SUV
//     CarModel(id: 96, brandId: 21, carTypeId: 2, name: 'Murano'), // SUV
//     CarModel(id: 97, brandId: 21, carTypeId: 2, name: 'Pathfinder'), // SUV
//     CarModel(id: 98, brandId: 21, carTypeId: 8, name: 'Titan'), // Pickup
//     CarModel(id: 99, brandId: 21, carTypeId: 7, name: 'Z'), // Sports Car
//     CarModel(id: 100, brandId: 21, carTypeId: 17, name: 'Leaf'), // EV
//
//     // --- Mazda ---
//     CarModel(id: 101, brandId: 4, carTypeId: 1, name: 'Mazda3'), // Sedan/Hatchback
//     CarModel(id: 102, brandId: 4, carTypeId: 1, name: 'Mazda6'), // Sedan
//     CarModel(id: 103, brandId: 4, carTypeId: 2, name: 'CX-5'), // SUV
//     CarModel(id: 104, brandId: 4, carTypeId: 2, name: 'CX-50'), // SUV
//     CarModel(id: 105, brandId: 4, carTypeId: 2, name: 'CX-9'), // SUV
//     CarModel(id: 106, brandId: 4, carTypeId: 7, name: 'MX-5 Miata'), // Sports Car (Roadster)
//
//     // --- Subaru ---
//     CarModel(id: 107, brandId: 8, carTypeId: 1, name: 'Impreza'), // Sedan/Hatchback
//     CarModel(id: 108, brandId: 8, carTypeId: 1, name: 'Legacy'), // Sedan
//     CarModel(id: 109, brandId: 8, carTypeId: 2, name: 'Crosstrek'), // SUV (Compact)
//     CarModel(id: 110, brandId: 8, carTypeId: 2, name: 'Forester'), // SUV
//     CarModel(id: 111, brandId: 8, carTypeId: 2, name: 'Outback'), // SUV/Wagon
//     CarModel(id: 112, brandId: 8, carTypeId: 8, name: 'Baja'), // Pickup (Discontinued, but for completeness)
//     CarModel(id: 113, brandId: 8, carTypeId: 7, name: 'BRZ'), // Sports Car
//
//     // --- Volkswagen ---
//     CarModel(id: 114, brandId: 22, carTypeId: 1, name: 'Jetta'), // Sedan
//     CarModel(id: 115, brandId: 22, carTypeId: 3, name: 'Golf'), // Hatchback
//     CarModel(id: 116, brandId: 22, carTypeId: 1, name: 'Passat'), // Sedan (may be discontinued in some markets)
//       CarModel(id: 117, brandId: 22, carTypeId: 2, name: 'Tiguan'), // SUV
//       CarModel(id: 118, brandId: 22, carTypeId: 2, name: 'Atlas'), // SUV
//       CarModel(id: 119, brandId: 22, carTypeId: 17, name: 'ID.4'), // EV (SUV)
//       CarModel(id: 120, brandId: 22, carTypeId: 17, name: 'ID. Buzz'), // EV (Van)
//
//       // --- Hyundai ---
//       CarModel(id: 121, brandId: 10, carTypeId: 1, name: 'Elantra'), // Sedan
//       CarModel(id: 122, brandId: 10, carTypeId: 1, name: 'Sonata'), // Sedan
//       CarModel(id: 123, brandId: 10, carTypeId: 2, name: 'Tucson'), // SUV
//       CarModel(id: 124, brandId: 10, carTypeId: 2, name: 'Santa Fe'), // SUV
//       CarModel(id: 125, brandId: 10, carTypeId: 2, name: 'Palisade'), // SUV
//       CarModel(id: 126, brandId: 10, carTypeId: 3, name: 'Veloster'), // Hatchback (Sporty)
//       CarModel(id: 127, brandId: 10, carTypeId: 8, name: 'Santa Cruz'), // Pickup (Compact)
//       CarModel(id: 128, brandId: 10, carTypeId: 17, name: 'Kona Electric'), // EV (SUV)
//       CarModel(id: 129, brandId: 10, carTypeId: 17, name: 'IONIQ 5'), // EV (Hatchback/Crossover)
//       CarModel(id: 130, brandId: 10, carTypeId: 17, name: 'IONIQ 6'), // EV (Sedan)
//
//       // --- Kia ---
//       CarModel(id: 131, brandId: 11, carTypeId: 1, name: 'Forte'), // Sedan
//       CarModel(id: 132, brandId: 11, carTypeId: 1, name: 'K5'), // Sedan
//       CarModel(id: 133, brandId: 11, carTypeId: 2, name: 'Sportage'), // SUV
//       CarModel(id: 134, brandId: 11, carTypeId: 2, name: 'Sorento'), // SUV
//       CarModel(id: 135, brandId: 11, carTypeId: 2, name: 'Telluride'), // SUV
//       CarModel(id: 136, brandId: 11, carTypeId: 5, name: 'Carnival'), // MPV/Minivan
//       CarModel(id: 137, brandId: 11, carTypeId: 17, name: 'Niro EV'), // EV (SUV)
//       CarModel(id: 138, brandId: 11, carTypeId: 17, name: 'EV6'), // EV (Crossover)
//
//       // --- Lexus ---
//       CarModel(id: 139, brandId: 12, carTypeId: 1, name: 'ES'), // Sedan
//       CarModel(id: 140, brandId: 12, carTypeId: 1, name: 'IS'), // Sedan
//       CarModel(id: 141, brandId: 12, carTypeId: 1, name: 'LS'), // Sedan (Luxury)
//       CarModel(id: 142, brandId: 12, carTypeId: 2, name: 'NX'), // SUV (Compact)
//       CarModel(id: 143, brandId: 12, carTypeId: 2, name: 'RX'), // SUV
//       CarModel(id: 144, brandId: 12, carTypeId: 2, name: 'GX'), // SUV (Off-Road)
//       CarModel(id: 145, brandId: 12, carTypeId: 2, name: 'LX'), // SUV (Luxury Full-Size)
//       CarModel(id: 146, brandId: 12, carTypeId: 6, name: 'RC'), // Coupe
//       CarModel(id: 147, brandId: 12, carTypeId: 17, name: 'RZ'), // EV (SUV)
//
//       // --- Acura --- (Honda's Luxury Brand - requires adding Brand)
//       // Add Brand(id: 25, name: 'Acura') to your brands list first.
//       CarModel(id: 148, brandId: 25, carTypeId: 1, name: 'TLX'), // Sedan
//       CarModel(id: 149, brandId: 25, carTypeId: 1, name: 'Integra'), // Sedan
//       CarModel(id: 150, brandId: 25, carTypeId: 2, name: 'MDX'), // SUV
//       CarModel(id: 151, brandId: 25, carTypeId: 2, name: 'RDX'), // SUV
//       CarModel(id: 152, brandId: 25, carTypeId: 7, name: 'NSX'), // Sports Car
//
//       // --- Cadillac --- (requires adding Brand)
//       // Add Brand(id: 26, name: 'Cadillac') to your brands list first.
//       CarModel(id: 153, brandId: 26, carTypeId: 1, name: 'CT4'), // Sedan
//       CarModel(id: 154, brandId: 26, carTypeId: 1, name: 'CT5'), // Sedan
//       CarModel(id: 155, brandId: 26, carTypeId: 1, name: 'CT6'), // Sedan (Luxury)
//       CarModel(id: 156, brandId: 26, carTypeId: 2, name: 'XT4'), // SUV (Compact)
//       CarModel(id: 157, brandId: 26, carTypeId: 2, name: 'XT5'), // SUV
//       CarModel(id: 158, brandId: 26, carTypeId: 2, name: 'XT6'), // SUV
//       CarModel(id: 159, brandId: 26, carTypeId: 2, name: 'Escalade'), // SUV (Full-Size)
//       CarModel(id: 160, brandId: 26, carTypeId: 17, name: 'Lyriq'), // EV (SUV)
//     ];
//     for (var model in models) {
//       try {
//         await modelRepo.addModel(model);
//         print('Added model: ${model.name}');
//       } catch (e) {
//         print('Error adding model ${model.name}: $e');
//       }
//     }
//
//     // Thêm Xe và ChiTietXe (kết hợp trong Car model)
//     final cars = [
//       Car(
//         id: 1,
//         userId: 2,
//         modelId: 1,
//         fuelType: 'Xăng',
//         transmission: 'Số sàn',
//         year: 2020,
//         mileage: 25000,
//         licensePlate: '29A12345',
//         location: 'Ha Noi',
//         price: 800000000,
//       ),
//       Car(
//         id: 2,
//         userId: 2,
//         modelId: 2,
//         fuelType: 'Xăng',
//         transmission: 'Số sàn',
//         year: 2020,
//         mileage: 35000,
//         licensePlate: '60A12345',
//         location: 'Bien Hoa',
//         price: 850000000,
//       ),
//       // Thêm các xe khác
//     ];
//     for (var car in cars) {
//       try {
//         await carRepo.addCar(car);
//         print('Added car ID: ${car.id}');
//       } catch (e) {
//         print('Error adding car ID ${car.id}: $e');
//       }
//     }
//
//
//
//     // Thêm HinhAnh (dùng URL giả định vì chưa upload ảnh)
//     final images = [
//       ImageModel(
//         id: 1,
//         carId: 1,
//         url: 'https://asset.cloudinary.com/doohwusyf/1ebe4b7ea8fe7b4fb07e370b5e34ba5b',
//         creationDate: Timestamp.now(),
//       ),
//       ImageModel(
//         id: 2,
//         carId: 2,
//         url: 'https://asset.cloudinary.com/doohwusyf/f307975530be012b45f4d7a5a2ede556',
//         creationDate: Timestamp.now(),
//       ),
//       // Thêm các ảnh khác
//     ];
//     for (var image in images) {
//       try {
//         await imageRepo.addImage(image);
//         print('Added image ID: ${image.id}');
//       } catch (e) {
//         print('Error adding image ID ${image.id}: $e');
//       }
//     }
//
//
//     // Thêm YeuThich
//     final favorites = [
//       Favorite(id: 1, userId: 2, carId: 1),
//       Favorite(id: 2, userId: 2, carId: 2),
//       // Thêm các yêu thích khác
//     ];
//     for (var fav in favorites) {
//       try {
//         await favoriteRepo.addFavorite(fav);
//         print('Added favorite ID: ${fav.id}');
//       } catch (e) {
//         print('Error adding favorite ID ${fav.id}: $e');
//       }
//     }
//
//     // Thêm TinNhan
//     final messages = [
//       Message(id: 1,
//           senderId: 1,
//           receiverId: 2,
//           content: 'Cảm ơn bạn đã quan tâm tới chiếc xe của tôi!',
//           sentAt: Timestamp.now()),
//       Message(id: 2,
//           senderId: 2,
//           receiverId: 3,
//           content: 'Tôi muốn biết thêm về tình trạng xe.',
//           sentAt: Timestamp.now()),
//       // Thêm các tin nhắn khác
//     ];
//     for (var msg in messages) {
//       try {
//         await messageRepo.addMessage(msg);
//         print('Added message ID: ${msg.id}');
//       } catch (e) {
//         print('Error adding message ID ${msg.id}: $e');
//       }
//     }
//
//     // Thêm TinDang
//     final posts = [
//       Post(
//         id: 1,
//         userId: 2,
//         carId: 1,
//         title: 'Bán xe Toyota Camry 2020, mới 95%',
//         description: 'Xe sử dụng rất tốt, chưa qua sửa chữa lớn, bảo dưỡng định kỳ đầy đủ.',
//         status: 'Chờ duyệt',
//         // Cập nhật trạng thái tin đăng
//         creationDate: Timestamp.now(),
//       ),
//
//       Post(
//         id: 2,
//         userId: 2,
//         carId: 1,
//         title: 'Bán xe Toyota Corrola 2020, mới 95%',
//         description: 'Xe sử dụng rất tốt, chưa qua sửa chữa lớn, bảo dưỡng định kỳ đầy đủ.',
//         status: 'Chờ duyệt',
//         // Cập nhật trạng thái tin đăng
//         creationDate: Timestamp.now(),
//       ),
//       // Thêm các tin đăng khác
//     ];
//     for (var post in posts) {
//       try {
//         await postRepo.addPost(post);
//         print('Added post ID: ${post.id}');
//       } catch (e) {
//         print('Error adding post ID ${post.id}: $e');
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () async {
//             // Hiển thị Loading Indicator
//             showDialog(
//               context: context,
//               builder: (context) => AlertDialog(
//                 content: Row(
//                   children: [CircularProgressIndicator(), Text("Đang tải dữ liệu...")],
//                 ),
//               ),
//             );
//             await initializeData();
//             Navigator.pop(context); // Đóng Loading Dialog
//             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data initialized')));
//           },
//           child: Text('Initialize Data'),
//         ),
//       ),
//     );
//   }
//
// }
