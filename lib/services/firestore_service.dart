import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/health_record_model.dart';
import '../config/app_config.dart';
import 'local_storage_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _local = LocalStorageService();

  static String buildDailyRecordDocId(String userId, DateTime date) {
    final formattedDate =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${userId}_$formattedDate';
  }

  static bool isRecordLocked(DateTime date) {
    final today = DateTime.now();
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedToday = DateTime(today.year, today.month, today.day);
    return normalizedDate.isBefore(normalizedToday);
  }

  FirestoreService() {
    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (_) {}
  }

  // ===================== USER CRUD =====================

  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(user.uid)
          .set(user.toMap());
      await _local.markUserSynced(user.uid);
    } catch (_) {
      await _local.saveUser(user);
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(uid)
          .get();
      if (doc.exists) return UserModel.fromFirestore(doc);
    } catch (_) {}
    return await _local.getUser(uid);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(uid)
          .update(data);
    } catch (_) {
      await _local.updateUser(uid, data);
    }
  }

  Future<void> saveOnboardingData(
      String uid, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(uid)
          .update({...data, 'onboardingCompleted': true});
    } catch (_) {
      await _local.saveOnboarding(uid, data);
    }
  }

  // ===================== HEALTH RECORDS =====================

  Future<void> saveHealthRecord(HealthRecord record) async {
    final docId = record.id.isNotEmpty
        ? record.id
        : buildDailyRecordDocId(record.userId, record.date);

    try {
      await _firestore
          .collection(FirebaseConfig.healthRecordsCollection)
          .doc(docId)
          .set(record.toMap(), SetOptions(merge: true));
    } catch (_) {
      await _local.saveHealthRecord(record);
    }
  }

  Future<List<HealthRecord>> getHealthRecords(String uid,
      {int limit = 7}) async {
    try {
      final query = await _firestore
          .collection(FirebaseConfig.healthRecordsCollection)
          .where('userId', isEqualTo: uid)
          .orderBy('date', descending: true)
          .get();
      final records = query.docs
          .map((doc) => HealthRecord.fromFirestore(doc))
          .toList();
      return records.take(limit).toList();
    } catch (_) {}
    return await _local.getHealthRecords(uid, limit: limit);
  }

  Future<HealthRecord?> getTodayRecord(String uid) async {
    try {
      final today = DateTime.now();
      final docId = buildDailyRecordDocId(uid, today);
      final doc = await _firestore
          .collection(FirebaseConfig.healthRecordsCollection)
          .doc(docId)
          .get();

      if (doc.exists) {
        return HealthRecord.fromFirestore(doc);
      }
    } catch (_) {}
    return await _local.getTodayRecord(uid);
  }

  // ===================== HEALTH HISTORY CLEANUP =====================

  Future<void> cleanupOldRecords(String uid) async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      final oldDocs = await _firestore
          .collection(FirebaseConfig.healthRecordsCollection)
          .where('userId', isEqualTo: uid)
          .where('date', isLessThan: Timestamp.fromDate(cutoff))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {}
  }

  // ===================== NOTIFICATION SETTINGS =====================

  Future<void> saveNotificationSetting(String uid, bool enabled) async {
    try {
      await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(uid)
          .update({'notificationEnabled': enabled});
    } catch (_) {}
  }

  // ===================== SYNC =====================

  Future<void> syncLocalToFirestore() async {
    try {
      final unsyncedUserIds = await _local.getUnsyncedUserIds();
      for (final uid in unsyncedUserIds) {
        final user = await _local.getUser(uid);
        if (user != null) {
          try {
            await _firestore
                .collection(FirebaseConfig.usersCollection)
                .doc(uid)
                .set(user.toMap());
            await _local.markUserSynced(uid);
          } catch (_) {}
        }
      }

      final unsyncedRecords = await _local.getUnsyncedRecords();
      for (final record in unsyncedRecords) {
        try {
          final healthRecord = HealthRecord(
            id: '',
            userId: record['userId'] ?? '',
            date: DateTime.parse(record['date']),
            sleepStartTime: record['sleepStartTime'] ?? '',
            sleepEndTime: record['sleepEndTime'] ?? '',
            sleepHours: (record['sleepHours'] as num?)?.toDouble() ?? 0,
            activityType: record['activityType'] ?? 'None',
            activityDuration: record['activityDuration'] ?? 0,
            waterIntake: record['waterIntake'] ?? 0,
            totalScore: record['totalScore'] ?? 0,
            healthLabel: record['healthLabel'] ?? '',
            sleepScore: record['sleepScore'] ?? 0,
            activityScore: record['activityScore'] ?? 0,
            waterScore: record['waterScore'] ?? 0,
            recommendations: (record['recommendations'] as List<dynamic>?)
                    ?.map((item) => Map<String, String>.from(item as Map))
                    .toList() ??
                const [],
            createdAt: record['createdAt'] != null
                ? DateTime.parse(record['createdAt'])
                : DateTime.now(),
          );
          await _firestore
              .collection(FirebaseConfig.healthRecordsCollection)
              .add(healthRecord.toMap());
          await _local.markRecordSynced(record['id']);
        } catch (_) {}
      }
    } catch (_) {}
  }
}
