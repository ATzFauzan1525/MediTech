import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/health_record_model.dart';

class LocalStorageService {
  static const String _usersKey = 'local_users';
  static const String _recordsKey = 'local_health_records';
  static const String _syncedUsersKey = 'synced_users';
  static const String _syncedRecordsKey = 'synced_records';

  // ===================== USER =====================

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _getUsers();
    users[user.uid] = user.toMap();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  Future<UserModel?> getUser(String uid) async {
    final users = await _getUsers();
    if (users.containsKey(uid)) {
      return UserModel.fromMap(users[uid]!, uid);
    }
    return null;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _getUsers();
    if (users.containsKey(uid)) {
      users[uid]!.addAll(data);
      await prefs.setString(_usersKey, jsonEncode(users));
    }
  }

  Future<Map<String, dynamic>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_usersKey);
    if (data != null) {
      return Map<String, dynamic>.from(jsonDecode(data));
    }
    return {};
  }

  // ===================== ONBOARDING =====================

  Future<void> saveOnboarding(String uid, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _getUsers();
    if (users.containsKey(uid)) {
      users[uid]!.addAll({...data, 'onboardingCompleted': true});
    } else {
      users[uid] = {...data, 'onboardingCompleted': true, 'uid': uid};
    }
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  // ===================== HEALTH RECORDS =====================

  Future<void> saveHealthRecord(HealthRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await _getRecords();
    final docId = record.id.isNotEmpty
        ? record.id
        : '${record.userId}_${record.date.year.toString().padLeft(4, '0')}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';

    records.removeWhere((r) {
      final sameDocId = (r['id'] as String?) == docId;
      final sameUserAndDate =
          (r['userId'] as String?) == record.userId &&
              (r['date'] as String?) == record.date.toIso8601String();
      return sameDocId || sameUserAndDate;
    });

    records.add({
      'id': docId,
      'userId': record.userId,
      'accountId': record.accountId,
      'ownerUid': record.ownerUid,
      'ownerEmail': record.ownerEmail,
      'date': record.date.toIso8601String(),
      'sleepStartTime': record.sleepStartTime,
      'sleepEndTime': record.sleepEndTime,
      'sleepHours': record.sleepHours,
      'activityType': record.activityType,
      'activityDuration': record.activityDuration,
      'waterIntake': record.waterIntake,
      'totalScore': record.totalScore,
      'healthLabel': record.healthLabel,
      'sleepScore': record.sleepScore,
      'activityScore': record.activityScore,
      'waterScore': record.waterScore,
      'recommendations': record.recommendations
          .map((item) => {'title': item['title'], 'message': item['message']})
          .toList(),
      'createdAt': record.createdAt.toIso8601String(),
    });
    await prefs.setString(_recordsKey, jsonEncode(records));
  }

  Future<List<HealthRecord>> getHealthRecords(String uid, {int limit = 7}) async {
    final records = await _getRecords();
    final userRecords = records
        .where((r) => r['userId'] == uid)
        .toList()
      ..sort((a, b) =>
          DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

    return userRecords.take(limit).map((r) {
      return HealthRecord(
        id: r['id'] ?? '',
        userId: r['userId'] ?? '',
        accountId: r['accountId'] ?? r['userId'] ?? '',
        ownerUid: r['ownerUid'] ?? r['userId'] ?? '',
        ownerEmail: r['ownerEmail'] ?? '',
        date: DateTime.parse(r['date']),
        sleepStartTime: r['sleepStartTime'] ?? '',
        sleepEndTime: r['sleepEndTime'] ?? '',
        sleepHours: (r['sleepHours'] as num?)?.toDouble() ?? 0,
        activityType: r['activityType'] ?? 'None',
        activityDuration: r['activityDuration'] ?? 0,
        waterIntake: r['waterIntake'] ?? 0,
        totalScore: r['totalScore'] ?? 0,
        healthLabel: r['healthLabel'] ?? '',
        sleepScore: r['sleepScore'] ?? 0,
        activityScore: r['activityScore'] ?? 0,
        waterScore: r['waterScore'] ?? 0,
        recommendations: (r['recommendations'] as List<dynamic>?)
                ?.map((item) => Map<String, String>.from(item as Map))
                .toList() ??
            const [],
        createdAt: r['createdAt'] != null
            ? DateTime.parse(r['createdAt'])
            : DateTime.now(),
      );
    }).toList();
  }

  Future<HealthRecord?> getTodayRecord(String uid) async {
    final records = await _getRecords();
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    for (final r in records) {
      if (r['userId'] == uid) {
        final recordDate = DateTime.parse(r['date']);
        final recordDateStr =
            '${recordDate.year}-${recordDate.month.toString().padLeft(2, '0')}-${recordDate.day.toString().padLeft(2, '0')}';
        if (recordDateStr == todayStr) {
          return HealthRecord(
            id: r['id'] ?? '',
            userId: r['userId'] ?? '',
            accountId: r['accountId'] ?? r['userId'] ?? '',
            ownerUid: r['ownerUid'] ?? r['userId'] ?? '',
            ownerEmail: r['ownerEmail'] ?? '',
            date: recordDate,
            sleepStartTime: r['sleepStartTime'] ?? '',
            sleepEndTime: r['sleepEndTime'] ?? '',
            sleepHours: (r['sleepHours'] as num?)?.toDouble() ?? 0,
            activityType: r['activityType'] ?? 'None',
            activityDuration: r['activityDuration'] ?? 0,
            waterIntake: r['waterIntake'] ?? 0,
            totalScore: r['totalScore'] ?? 0,
            healthLabel: r['healthLabel'] ?? '',
            sleepScore: r['sleepScore'] ?? 0,
            activityScore: r['activityScore'] ?? 0,
            waterScore: r['waterScore'] ?? 0,
            recommendations: (r['recommendations'] as List<dynamic>?)
                    ?.map((item) => Map<String, String>.from(item as Map))
                    .toList() ??
                const [],
            createdAt: r['createdAt'] != null
                ? DateTime.parse(r['createdAt'])
                : DateTime.now(),
          );
        }
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _getRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_recordsKey);
    if (data != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    }
    return [];
  }

  // ===================== SYNC TRACKING =====================

  Future<Set<String>> _getSyncedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_syncedUsersKey);
    if (data != null) {
      return Set<String>.from(jsonDecode(data));
    }
    return {};
  }

  Future<void> markUserSynced(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final synced = await _getSyncedUsers();
    synced.add(uid);
    await prefs.setString(_syncedUsersKey, jsonEncode(synced.toList()));
  }

  Future<List<String>> getUnsyncedUserIds() async {
    final users = await _getUsers();
    final synced = await _getSyncedUsers();
    return users.keys.where((uid) => !synced.contains(uid)).toList();
  }

  Future<Set<String>> _getSyncedRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_syncedRecordsKey);
    if (data != null) {
      return Set<String>.from(jsonDecode(data));
    }
    return {};
  }

  Future<void> markRecordSynced(String localId) async {
    final prefs = await SharedPreferences.getInstance();
    final synced = await _getSyncedRecords();
    synced.add(localId);
    await prefs.setString(_syncedRecordsKey, jsonEncode(synced.toList()));
  }

  Future<List<Map<String, dynamic>>> getUnsyncedRecords() async {
    final records = await _getRecords();
    final synced = await _getSyncedRecords();
    return records.where((r) => !synced.contains(r['id'])).toList();
  }

}
