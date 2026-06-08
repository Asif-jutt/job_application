import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/user_role.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.displayName,
    this.phone,
    this.photoUrl,
    this.createdAt,
  });

  final String uid;
  final String email;
  final UserRole role;
  final String? displayName;
  final String? phone;
  final String? photoUrl;
  final DateTime? createdAt;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppUser(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?),
      displayName: data['displayName'] as String?,
      phone: data['phone'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'role': role.value,
        'displayName': displayName,
        'phone': phone,
        'photoUrl': photoUrl,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  @override
  List<Object?> get props => [uid, email, role, displayName];
}
