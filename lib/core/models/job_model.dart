import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum JobSource { firestore, external }

class JobModel extends Equatable {
  const JobModel({
    required this.id,
    required this.title,
    required this.company,
    required this.description,
    required this.location,
    required this.source,
    this.salary,
    this.isPremium = false,
    this.postedAt,
    this.companyId,
    this.tags = const [],
  });

  final String id;
  final String title;
  final String company;
  final String description;
  final String location;
  final String? salary;
  final bool isPremium;
  final JobSource source;
  final DateTime? postedAt;
  final String? companyId;
  final List<String> tags;

  factory JobModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return JobModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      company: data['companyName'] as String? ?? '',
      description: data['description'] as String? ?? '',
      location: data['location'] as String? ?? '',
      salary: data['salary'] as String?,
      isPremium: data['isPremium'] as bool? ?? true,
      source: JobSource.firestore,
      postedAt: (data['postedAt'] as Timestamp?)?.toDate(),
      companyId: data['companyId'] as String?,
      tags: List<String>.from(data['tags'] as List? ?? []),
    );
  }

  factory JobModel.fromExternalApi(Map<String, dynamic> json) {
    return JobModel(
      id: 'ext_${json['id']}',
      title: json['title'] as String? ?? 'Untitled Position',
      company: 'External Partner',
      description: json['body'] as String? ?? '',
      location: 'Remote',
      source: JobSource.external,
      isPremium: false,
      postedAt: DateTime.now(),
      tags: const ['External', 'Public'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'companyName': company,
        'description': description,
        'location': location,
        'salary': salary,
        'isPremium': isPremium,
        'postedAt': postedAt != null ? Timestamp.fromDate(postedAt!) : null,
        'companyId': companyId,
        'tags': tags,
      };

  @override
  List<Object?> get props =>
      [id, title, company, description, location, salary, source];
}
