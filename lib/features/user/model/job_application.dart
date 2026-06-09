import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ApplicationStatus {
  applied('Applied'),
  underReview('Under Review'),
  interviewScheduled('Interview Scheduled'),
  offered('Offered'),
  rejected('Rejected');

  const ApplicationStatus(this.label);
  final String label;

  static ApplicationStatus fromString(String? value) {
    return ApplicationStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => ApplicationStatus.applied,
    );
  }
}

class JobApplication extends Equatable {
  const JobApplication({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    this.companyId,
    required this.applicantId,
    required this.applicantName,
    required this.experience,
    required this.status,
    this.resumeUrl,
    this.appliedAt,
  });

  final String id;
  final String jobId;
  final String jobTitle;
  final String companyName;
  final String? companyId;
  final String applicantId;
  final String applicantName;
  final String experience;
  final ApplicationStatus status;
  final String? resumeUrl;
  final DateTime? appliedAt;

  factory JobApplication.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return JobApplication(
      id: doc.id,
      jobId: data['jobId'] as String? ?? '',
      jobTitle: data['jobTitle'] as String? ?? '',
      companyName: data['companyName'] as String? ?? '',
      companyId: data['companyId'] as String?,
      applicantId: data['applicantId'] as String? ?? '',
      applicantName: data['applicantName'] as String? ?? '',
      experience: data['experience'] as String? ?? '',
      status: ApplicationStatus.fromString(data['status'] as String?),
      resumeUrl: data['resumeUrl'] as String?,
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'jobId': jobId,
        'jobTitle': jobTitle,
        'companyName': companyName,
        if (companyId != null) 'companyId': companyId,
        'applicantId': applicantId,
        'applicantName': applicantName,
        'experience': experience,
        'status': status.name,
        'resumeUrl': resumeUrl,
        'appliedAt': appliedAt != null
            ? Timestamp.fromDate(appliedAt!)
            : FieldValue.serverTimestamp(),
      };

  @override
  List<Object?> get props => [id, jobId, applicantId, status];
}
