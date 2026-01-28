import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_car_marketplace_app/utils/validators/user_validator.dart';

class User {
  final int id;
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? avatarUrl;
  final int roleId;
  final String status;
  final Timestamp creationDate;
  final Timestamp updateDate;

  User({
    required this.id,
    required this.uid,
    required String name,
    required this.email,
    required this.phone,
    required this.address,
    this.avatarUrl,
    required this.roleId,
    required String status,
    required this.creationDate,
    required this.updateDate,
    bool isHashed = false,
  })  : name = UserValidator.validateName(name),
        status = UserValidator.validateStatus(status);

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      uid: map['uid'] ?? '',
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
      avatarUrl: map['avatarUrl'],
      roleId: map['roleId'],
      status: map['status'],
      creationDate: map['creationDate'],
      updateDate: map['updateDate'],
      isHashed: true,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'uid': uid,
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    'avatarUrl': avatarUrl,
    'roleId': roleId,
    'status': status,
    'creationDate': creationDate,
    'updateDate': updateDate,
  };

  User copyWith({
    int? id,
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? avatarUrl,
    int? roleId,
    String? status,
    Timestamp? creationDate,
    Timestamp? updateDate,
  }) {
    return User(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      roleId: roleId ?? this.roleId,
      status: status ?? this.status,
      creationDate: creationDate ?? this.creationDate,
      updateDate: updateDate ?? this.updateDate,
    );
  }
}
