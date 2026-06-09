import 'package:equatable/equatable.dart';

class EducationEntry extends Equatable {
  const EducationEntry({
    required this.institution,
    required this.degree,
    required this.year,
  });

  final String institution;
  final String degree;
  final String year;

  factory EducationEntry.fromMap(Map<String, dynamic> map) => EducationEntry(
        institution: map['institution'] as String? ?? '',
        degree: map['degree'] as String? ?? '',
        year: map['year'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'institution': institution,
        'degree': degree,
        'year': year,
      };

  @override
  List<Object?> get props => [institution, degree, year];
}

class WorkExperience extends Equatable {
  const WorkExperience({
    required this.company,
    required this.role,
    required this.duration,
  });

  final String company;
  final String role;
  final String duration;

  factory WorkExperience.fromMap(Map<String, dynamic> map) => WorkExperience(
        company: map['company'] as String? ?? '',
        role: map['role'] as String? ?? '',
        duration: map['duration'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'company': company,
        'role': role,
        'duration': duration,
      };

  @override
  List<Object?> get props => [company, role, duration];
}

class UserProfile extends Equatable {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.phone,
    this.salary,
    this.cvUrl,
    this.skills = const [],
    this.education = const [],
    this.experience = const [],
    this.headline,
    this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? phone;
  final String? salary;
  final String? cvUrl;
  final List<String> skills;
  final List<EducationEntry> education;
  final List<WorkExperience> experience;
  final String? headline;
  final String? photoUrl;

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      salary: data['salary'] as String?,
      cvUrl: data['cvUrl'] as String?,
      skills: List<String>.from(data['skills'] as List? ?? []),
      education: (data['education'] as List? ?? [])
          .map((e) => EducationEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
      experience: (data['experience'] as List? ?? [])
          .map((e) => WorkExperience.fromMap(e as Map<String, dynamic>))
          .toList(),
      headline: data['headline'] as String?,
      photoUrl: data['photoUrl'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [uid, displayName, email, phone, salary, skills, headline];
}
