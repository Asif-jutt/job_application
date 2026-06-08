import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.phone,
    this.salary,
    this.cvUrl,
    this.skills = const [],
  });

  final String uid;
  final String displayName;
  final String email;
  final String? phone;
  final String? salary;
  final String? cvUrl;
  final List<String> skills;

  @override
  List<Object?> get props => [uid, displayName, email, phone, salary];
}
