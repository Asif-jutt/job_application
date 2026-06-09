import 'package:equatable/equatable.dart';

class CompanyProfile extends Equatable {
  const CompanyProfile({
    required this.uid,
    required this.companyName,
    required this.email,
    this.logoUrl,
    this.industry,
    this.website,
    this.description,
    this.activeJobs = 0,
  });

  final String uid;
  final String companyName;
  final String email;
  final String? logoUrl;
  final String? industry;
  final String? website;
  final String? description;
  final int activeJobs;

  factory CompanyProfile.fromMap(String uid, Map<String, dynamic> data) {
    return CompanyProfile(
      uid: uid,
      companyName: data['displayName'] as String? ?? 'Company',
      email: data['email'] as String? ?? '',
      logoUrl: data['photoUrl'] as String?,
      industry: data['industry'] as String?,
      website: data['website'] as String?,
      description: data['description'] as String?,
    );
  }

  @override
  List<Object?> get props => [uid, companyName, email, logoUrl];
}
