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

  CollectionReference<Map<String, dynamic>> get applications =>
      _firestore.collection(AppConstants.applicationsCollection);

  CollectionReference<Map<String, dynamic>> messages(String chatId) =>
      chats.doc(chatId).collection(AppConstants.messagesSubcollection);

  DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      users.doc(uid);

  Future<void> setUser(String uid, Map<String, dynamic> data) =>
      userDoc(uid).set(data, SetOptions(merge: true));

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) =>
      userDoc(uid).get();

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUser(String uid) =>
      userDoc(uid).snapshots();
}
