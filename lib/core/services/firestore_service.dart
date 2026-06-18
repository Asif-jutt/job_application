import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get users =>
      _firestore.collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get jobs =>
      _firestore.collection(AppConstants.jobsCollection);

  CollectionReference<Map<String, dynamic>> get chats =>
      _firestore.collection(AppConstants.chatsCollection);

  /// Query chats where [uid] is a participant (required by Firestore security rules).
  Query<Map<String, dynamic>> chatsForUser(String uid) => chats.where(
        'participants',
        arrayContains: uid,
      );

  CollectionReference<Map<String, dynamic>> get applications =>
      _firestore.collection(AppConstants.applicationsCollection);

  CollectionReference<Map<String, dynamic>> messages(String chatId) =>
      chats.doc(chatId).collection(AppConstants.messagesSubcollection);

  CollectionReference<Map<String, dynamic>> jobComments(String jobId) =>
      jobs.doc(jobId).collection(AppConstants.commentsSubcollection);

  CollectionReference<Map<String, dynamic>> applicationStatus(
    String applicationId,
  ) =>
      applications
          .doc(applicationId)
          .collection(AppConstants.statusSubcollection);

  DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      users.doc(uid);

  Future<void> setUser(String uid, Map<String, dynamic> data) =>
      userDoc(uid).set(data, SetOptions(merge: true));

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) =>
      userDoc(uid).get();

  DocumentReference<Map<String, dynamic>> phoneIndexDoc(String phoneKey) =>
      _firestore
          .collection(AppConstants.phoneIndexCollection)
          .doc(phoneKey);

  Future<DocumentSnapshot<Map<String, dynamic>>> getPhoneIndex(
    String phoneKey,
  ) =>
      phoneIndexDoc(phoneKey).get();

  Future<void> setPhoneIndex(String phoneKey, Map<String, dynamic> data) =>
      phoneIndexDoc(phoneKey).set(data);

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUser(String uid) =>
      userDoc(uid).snapshots();

  Future<DocumentReference<Map<String, dynamic>>> addJob(
    Map<String, dynamic> data,
  ) =>
      jobs.add(data);

  Future<void> updateJob(String jobId, Map<String, dynamic> data) =>
      jobs.doc(jobId).update(data);

  Future<DocumentReference<Map<String, dynamic>>> addApplication(
    Map<String, dynamic> data,
  ) =>
      applications.add(data);

  Future<void> updateApplication(
    String applicationId,
    Map<String, dynamic> data,
  ) =>
      applications.doc(applicationId).update(data);
}
