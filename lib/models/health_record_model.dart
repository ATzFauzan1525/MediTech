import 'package:cloud_firestore/cloud_firestore.dart';

class HealthRecord {
  final String id;
  final String userId;
  final String accountId;
  final String ownerUid;
  final String ownerEmail;
  final DateTime date;
  final String sleepStartTime;
  final String sleepEndTime;
  final double sleepHours;
  final String activityType;
  final int activityDuration;
  final int waterIntake;
  final int totalScore;
  final String healthLabel;
  final int sleepScore;
  final int activityScore;
  final int waterScore;
  final List<Map<String, String>> recommendations;
  final DateTime createdAt;

  HealthRecord({
    required this.id,
    required this.userId,
    String? accountId,
    String? ownerUid,
    String? ownerEmail,
    required this.date,
    required this.sleepStartTime,
    required this.sleepEndTime,
    required this.sleepHours,
    required this.activityType,
    required this.activityDuration,
    required this.waterIntake,
    required this.totalScore,
    required this.healthLabel,
    required this.sleepScore,
    required this.activityScore,
    required this.waterScore,
    List<Map<String, String>>? recommendations,
    DateTime? createdAt,
  })  : accountId = accountId ?? userId,
        ownerUid = ownerUid ?? userId,
        ownerEmail = ownerEmail ?? '',
        recommendations = recommendations ?? const [],
        createdAt = createdAt ?? DateTime.now();

  factory HealthRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HealthRecord(
      id: doc.id,
      userId: data['userId'] ?? '',
      accountId: data['accountId'] ?? data['userId'] ?? '',
      ownerUid: data['ownerUid'] ?? data['userId'] ?? '',
      ownerEmail: data['ownerEmail'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sleepStartTime: data['sleepStartTime'] ?? '',
      sleepEndTime: data['sleepEndTime'] ?? '',
      sleepHours: (data['sleepHours'] as num?)?.toDouble() ?? 0,
      activityType: data['activityType'] ?? 'None',
      activityDuration: data['activityDuration'] ?? 0,
      waterIntake: data['waterIntake'] ?? 0,
      totalScore: data['totalScore'] ?? 0,
      healthLabel: data['healthLabel'] ?? '',
      sleepScore: data['sleepScore'] ?? 0,
      activityScore: data['activityScore'] ?? 0,
      waterScore: data['waterScore'] ?? 0,
      recommendations: (data['recommendations'] as List<dynamic>?)
              ?.map((item) => Map<String, String>.from(item as Map))
              .toList() ??
          const [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'accountId': accountId,
      'ownerUid': ownerUid,
      'ownerEmail': ownerEmail,
      'date': Timestamp.fromDate(date),
      'sleepStartTime': sleepStartTime,
      'sleepEndTime': sleepEndTime,
      'sleepHours': sleepHours,
      'activityType': activityType,
      'activityDuration': activityDuration,
      'waterIntake': waterIntake,
      'totalScore': totalScore,
      'healthLabel': healthLabel,
      'sleepScore': sleepScore,
      'activityScore': activityScore,
      'waterScore': waterScore,
      'recommendations': recommendations
          .map((item) => {'title': item['title'], 'message': item['message']})
          .toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static int calculateSleepScore(double hours) {
    if (hours >= 7 && hours <= 9) return 40;
    if (hours >= 6 && hours < 7) return 25;
    if (hours >= 5 && hours < 6) return 10;
    return 0;
  }

  static int calculateActivityScore(String type, int duration) {
    switch (type) {
      case 'Heavy Exercise':
        return duration >= 30 ? 30 : 20;
      case 'Light Exercise':
        return duration >= 30 ? 25 : 15;
      case 'Walking':
        return duration >= 30 ? 20 : 10;
      default:
        return 0;
    }
  }

  static int calculateWaterScore(int glasses) {
    if (glasses >= 8) return 30;
    if (glasses == 7) return 26;
    if (glasses == 6) return 22;
    if (glasses == 5) return 18;
    if (glasses == 4) return 14;
    if (glasses == 3) return 10;
    if (glasses == 2) return 6;
    if (glasses == 1) return 3;
    return 0;
  }

  static String getHealthLabel(int score) {
    if (score >= 80) return 'Sangat Sehat';
    if (score >= 60) return 'Cukup Sehat';
    if (score >= 40) return 'Perlu Perhatian';
    return 'Tidak Sehat';
  }

  static String getHealthMessage(int score) {
    if (score >= 80) {
      return 'Luar biasa! Pertahankan gaya hidupmu hari ini.';
    }
    if (score >= 60) {
      return 'Bagus! Ada satu area yang bisa kamu tingkatkan.';
    }
    if (score >= 40) {
      return 'Yuk mulai perhatikan pola hidupmu lebih serius.';
    }
    return 'Tubuhmu butuh perhatian ekstra. Mari mulai berubah hari ini!';
  }
}
