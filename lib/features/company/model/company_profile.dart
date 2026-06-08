import 'package:equatable/equatable.dart';

class CompanyProfile extends Equatable {
  const CompanyProfile({
    required this.uid,
    required this.companyName,
    required this.email,
    this.logoUrl,
    this.industry,
    this.description,
    this.activeJobs = 0,
  });

  final String uid;
  final String companyName;
  final String email;
  final String? logoUrl;
  final String? industry;
  final String? description;
  final int activeJobs;

  @override
  List<Object?> get props => [uid, companyName, email, logoUrl];
}
