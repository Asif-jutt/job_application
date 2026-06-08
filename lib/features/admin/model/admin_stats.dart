import 'package:equatable/equatable.dart';

class AdminStats extends Equatable {
  const AdminStats({
    required this.totalUsers,
    required this.totalCompanies,
    required this.totalJobs,
    required this.totalApplications,
  });

  final int totalUsers;
  final int totalCompanies;
  final int totalJobs;
  final int totalApplications;

  @override
  List<Object?> get props =>
      [totalUsers, totalCompanies, totalJobs, totalApplications];
}
