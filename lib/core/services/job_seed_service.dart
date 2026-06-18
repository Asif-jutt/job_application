import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/job_model.dart';
import '../utils/app_logger.dart';
import 'firestore_service.dart';

/// Seeds demo CS/Software jobs into Firestore (runs once per install).
class JobSeedService {
  JobSeedService(this._firestore);

  final FirestoreService _firestore;
  static const _seedKey = 'rozgar_cs_jobs_seeded_v3';

  static const String seedCompanyId = 'rozgar_cs_seed_company';
  static const String seedCompanyName = 'Rozgar Tech Partners';

  Future<void> seedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final existing = await _firestore.jobs
          .where('companyId', isEqualTo: seedCompanyId)
          .get();

      if (existing.docs.length >= _csJobs.length) {
        await prefs.setBool(_seedKey, true);
        return;
      }

      for (final job in _csJobs) {
        final data = job.toFirestore();
        data['postedAt'] = FieldValue.serverTimestamp();
        data['companyId'] = seedCompanyId;
        data['isPremium'] = true;
        await _firestore.jobs.add(data);
      }

      await prefs.setBool(_seedKey, true);
      AppLogger.info('Seeded ${_csJobs.length} CS jobs');
    } catch (e, st) {
      AppLogger.warning('Job seed skipped', e);
      AppLogger.error('Job seed error', st);
    }
  }

  /// Links demo seed jobs and their chats to the first logged-in company account.
  Future<void> linkSeedJobsToCompany(String companyUid) async {
    final prefs = await SharedPreferences.getInstance();
    final linkedKey = 'rozgar_linked_company_$companyUid';
    if (prefs.getBool(linkedKey) == true) return;

    try {
      final jobs = await _firestore.jobs
          .where('companyId', isEqualTo: seedCompanyId)
          .get();
      for (final doc in jobs.docs) {
        await doc.reference.update({'companyId': companyUid});
      }

      final chats = await _firestore.chats
          .where('participants', arrayContains: seedCompanyId)
          .get();
      for (final doc in chats.docs) {
        final participants = List<String>.from(
          doc.data()['participants'] as List? ?? [],
        );
        final updated = participants
            .map((p) => p == seedCompanyId ? companyUid : p)
            .toList();
        await doc.reference.update({'participants': updated});
      }

      await prefs.setBool(linkedKey, true);
      AppLogger.info('Linked seed jobs/chats to company $companyUid');
    } catch (e, st) {
      AppLogger.warning('Link seed jobs skipped', e);
      AppLogger.error('Link seed jobs error', st);
    }
  }

  Future<String?> findCompanyRecruiterId() async {
    try {
      final snapshot = await _firestore.users
          .where('role', isEqualTo: 'company')
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.id;
    } catch (_) {
      return null;
    }
  }

  static final List<JobModel> _csJobs = [
    JobModel(
      id: 'seed_1',
      title: 'Flutter Mobile Developer',
      company: seedCompanyName,
      description:
          'Build cross-platform mobile apps with Flutter & Dart. Work on our Rozgar job portal and client projects. Strong UI skills and Firebase experience required.',
      location: 'Lahore, Pakistan (Hybrid)',
      salary: 'PKR 120,000 – 180,000 / month',
      isPremium: true,
      source: JobSource.firestore,
      postedAt: DateTime.now(),
      companyId: seedCompanyId,
      tags: ['Flutter', 'Dart', 'Firebase', 'Mobile'],
      bannerUrl:
          'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=800&q=80',
    ),
    JobModel(
      id: 'seed_2',
      title: 'Full Stack Software Engineer',
      company: seedCompanyName,
      description:
          'Develop REST APIs and React/Flutter frontends. Computer Science degree required. Experience with Node.js, PostgreSQL, and cloud deployment.',
      location: 'Islamabad, Pakistan',
      salary: 'PKR 150,000 – 220,000 / month',
      isPremium: true,
      source: JobSource.firestore,
      postedAt: DateTime.now().subtract(const Duration(days: 1)),
      companyId: seedCompanyId,
      tags: ['Full Stack', 'Node.js', 'React', 'CS'],
      bannerUrl:
          'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=800&q=80',
    ),
    JobModel(
      id: 'seed_3',
      title: 'Android Developer (Kotlin)',
      company: seedCompanyName,
      description:
          'Native Android development for fintech products. MVVM, Jetpack Compose, and Play Store releases. BS Computer Science or equivalent.',
      location: 'Karachi, Pakistan',
      salary: 'PKR 100,000 – 160,000 / month',
      isPremium: true,
      source: JobSource.firestore,
      postedAt: DateTime.now().subtract(const Duration(days: 2)),
      companyId: seedCompanyId,
      tags: ['Android', 'Kotlin', 'Jetpack Compose'],
      bannerUrl:
          'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800&q=80',
    ),
    JobModel(
      id: 'seed_4',
      title: 'Backend Developer – Cloud APIs',
      company: seedCompanyName,
      description:
          'Design scalable microservices on Firebase & GCP. Strong data structures, algorithms, and API security. CS/SE graduates welcome.',
      location: 'Remote – Pakistan',
      salary: 'PKR 130,000 – 200,000 / month',
      isPremium: true,
      source: JobSource.firestore,
      postedAt: DateTime.now().subtract(const Duration(days: 3)),
      companyId: seedCompanyId,
      tags: ['Backend', 'Firebase', 'Cloud', 'API'],
      bannerUrl:
          'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800&q=80',
    ),
    JobModel(
      id: 'seed_5',
      title: 'UI/UX Engineer (Mobile)',
      company: seedCompanyName,
      description:
          'Create pixel-perfect interfaces in Figma and implement in Flutter. Portfolio required. Understanding of Material Design 3.',
      location: 'Lahore, Pakistan',
      salary: 'PKR 90,000 – 140,000 / month',
      isPremium: true,
      source: JobSource.firestore,
      postedAt: DateTime.now().subtract(const Duration(days: 4)),
      companyId: seedCompanyId,
      tags: ['UI/UX', 'Figma', 'Flutter', 'Design'],
      bannerUrl:
          'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=800&q=80',
    ),
    JobModel(
      id: 'seed_6',
      title: 'DevOps Engineer',
      company: seedCompanyName,
      description:
          'CI/CD pipelines, Docker, GitHub Actions, and Firebase App Distribution. Automate builds for Flutter Android/iOS apps.',
      location: 'Islamabad, Pakistan (On-site)',
      salary: 'PKR 140,000 – 210,000 / month',
      isPremium: true,
      source: JobSource.firestore,
      postedAt: DateTime.now().subtract(const Duration(days: 5)),
      companyId: seedCompanyId,
      tags: ['DevOps', 'Docker', 'CI/CD', 'Flutter'],
      bannerUrl:
          'https://images.unsplash.com/photo-1667372393119-3d4c48d07fc9?w=800&q=80',
    ),
    JobModel(
      id: 'seed_7',
      title: 'Machine Learning Engineer',
      company: seedCompanyName,
      description:
          'Build recommendation systems for job matching. Python, TensorFlow, and NLP basics. MS CS preferred but BS with projects accepted.',
      location: 'Remote',
      salary: 'PKR 160,000 – 250,000 / month',
      isPremium: true,
      source: JobSource.firestore,
      postedAt: DateTime.now().subtract(const Duration(days: 6)),
      companyId: seedCompanyId,
      tags: ['ML', 'Python', 'AI', 'Data Science'],
      bannerUrl:
          'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800&q=80',
    ),
    JobModel(
      id: 'seed_8',
      title: 'React Native Developer',
      company: seedCompanyName,
      description:
          'Cross-platform apps for startups. JavaScript/TypeScript, Redux, and REST integration. Computer Science background required.',
      location: 'Karachi, Pakistan',
      salary: 'PKR 110,000 – 170,000 / month',
      isPremium: true,
      source: JobSource.firestore,
      postedAt: DateTime.now().subtract(const Duration(days: 7)),
      companyId: seedCompanyId,
      tags: ['React Native', 'JavaScript', 'Mobile'],
      bannerUrl:
          'https://images.unsplash.com/photo-1633356122544-f134324a6cee?w=800&q=80',
    ),
    JobModel(
      id: 'seed_9',
      title: 'Software Engineering Intern',
      company: seedCompanyName,
      description:
          '6-month paid internship for CS students (Semester 6+). Learn Flutter, Firebase, and agile workflows on a real job portal product.',
      location: 'Lahore, Pakistan',
      salary: 'PKR 40,000 – 60,000 / month',
      isPremium: true,
      source: JobSource.firestore,
      postedAt: DateTime.now().subtract(const Duration(days: 8)),
      companyId: seedCompanyId,
      tags: ['Internship', 'CS', 'Flutter', 'Student'],
      bannerUrl:
          'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=800&q=80',
    ),
    JobModel(
      id: 'seed_10',
      title: 'Senior Software Architect',
      company: seedCompanyName,
      description:
          'Lead system design for multi-role platforms. 5+ years experience. Flutter, Firestore, security, and mentoring junior developers.',
      location: 'Islamabad, Pakistan (Hybrid)',
      salary: 'PKR 250,000 – 350,000 / month',
      isPremium: true,
      source: JobSource.firestore,
      postedAt: DateTime.now().subtract(const Duration(days: 9)),
      companyId: seedCompanyId,
      tags: ['Architecture', 'Leadership', 'Flutter', 'Senior'],
      bannerUrl:
          'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800&q=80',
    ),
  ];
}
