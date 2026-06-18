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
    this.authProvider = 'email',
    this.phoneVerified = true,
    this.needsRoleSelection = false,
  });

  final String uid;
  final String email;
  final UserRole role;
  final String? displayName;
  final String? phone;
  final String? photoUrl;
  final DateTime? createdAt;
  final String authProvider;
  final bool phoneVerified;
  final bool needsRoleSelection;

  bool get needsPhoneVerification => false;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final authProvider = data['authProvider'] as String? ??
        data['authenticationProvider'] as String? ??
        'email';
    final phone = data['phone'] as String? ?? data['mobileNumber'] as String?;
    return AppUser(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?),
      displayName: data['displayName'] as String?,
      phone: phone,
      photoUrl: data['photoUrl'] as String? ?? data['profileImage'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      authProvider: authProvider,
      phoneVerified: data['phoneVerified'] as bool? ?? authProvider != 'google',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'role': role.value,
        'displayName': displayName,
        'phone': phone,
        'mobileNumber': phone,
        'photoUrl': photoUrl,
        'profileImage': photoUrl,
        'authProvider': authProvider,
        'authenticationProvider': authProvider,
        'phoneVerified': phoneVerified,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  AppUser copyWith({
    String? phone,
    bool? phoneVerified,
    String? photoUrl,
    String? displayName,
  }) =>
      AppUser(
        uid: uid,
        email: email,
        role: role,
        displayName: displayName ?? this.displayName,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        createdAt: createdAt,
        authProvider: authProvider,
        phoneVerified: phoneVerified ?? this.phoneVerified,
      );

  @override
  List<Object?> get props =>
      [uid, email, role, displayName, authProvider, phoneVerified];
}
