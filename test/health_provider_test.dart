import 'package:flutter_test/flutter_test.dart';
import 'package:medisync/models/health_record_model.dart';
import 'package:medisync/providers/health_provider.dart';
import 'package:medisync/services/firestore_service.dart';

void main() {
  test('builds a stable daily record document id for a user and date', () {
    final docId = FirestoreService.buildDailyRecordDocId('user-1', DateTime(2025, 6, 23));
    expect(docId, 'user-1_2025-06-23');
  });

  test('locks records from previous days automatically', () {
    expect(FirestoreService.isRecordLocked(DateTime(2025, 6, 22)), isTrue);
    expect(FirestoreService.isRecordLocked(DateTime.now()), isFalse);
  });

  group('HealthProvider recommendations', () {
    test('uses the submitted record when generating recommendations', () {
      final record = HealthRecord(
        id: '1',
        userId: 'user-1',
        date: DateTime.now(),
        sleepStartTime: '22:00',
        sleepEndTime: '06:00',
        sleepHours: 7.5,
        activityType: 'Walking',
        activityDuration: 30,
        waterIntake: 2,
        totalScore: 70,
        healthLabel: 'Healthy',
        sleepScore: 40,
        activityScore: 10,
        waterScore: 0,
      );

      final recommendations = HealthProvider.buildRecommendations(
        age: 25,
        height: 170,
        weight: 65,
        record: record,
      );

      expect(recommendations, isNotEmpty);
      expect(recommendations.any((item) => item['title'] == 'Hidrasi'), isTrue);
      expect(recommendations.any((item) => item['title'] == 'Tidur'), isFalse);
    });

    test('uses the updated rules for sleep, activity, water, and BMI', () {
      final record = HealthRecord(
        id: '2',
        userId: 'user-2',
        date: DateTime.now(),
        sleepStartTime: '23:00',
        sleepEndTime: '06:30',
        sleepHours: 6.5,
        activityType: 'Light Exercise',
        activityDuration: 60,
        waterIntake: 1,
        totalScore: 40,
        healthLabel: 'Needs Attention',
        sleepScore: 25,
        activityScore: 20,
        waterScore: 0,
      );

      final recommendations = HealthProvider.buildRecommendations(
        age: 25,
        height: 170,
        weight: 65,
        record: record,
      );

      expect(recommendations.any((item) => item['title'] == 'Aktivitas'), isFalse);
      expect(recommendations.any((item) => item['title'] == 'BMI'), isFalse);
      expect(
        recommendations.any(
          (item) => item['title'] == 'Hidrasi' && (item['message'] ?? '').contains('8 gelas'),
        ),
        isTrue,
      );
      expect(
        recommendations.any(
          (item) => item['title'] == 'Tidur' && (item['message'] ?? '').contains('7 jam'),
        ),
        isTrue,
      );
    });

    test('does not recommend activity for 45-minute light exercise and keeps 8 glasses as sufficient', () {
      final record = HealthRecord(
        id: '3',
        userId: 'user-3',
        date: DateTime.now(),
        sleepStartTime: '22:30',
        sleepEndTime: '06:30',
        sleepHours: 8,
        activityType: 'Light Exercise',
        activityDuration: 45,
        waterIntake: 8,
        totalScore: 100,
        healthLabel: 'Very Healthy',
        sleepScore: 40,
        activityScore: 30,
        waterScore: 30,
      );

      final recommendations = HealthProvider.buildRecommendations(
        age: 25,
        height: 170,
        weight: 65,
        record: record,
      );

      expect(recommendations.any((item) => item['title'] == 'Aktivitas'), isFalse);
      expect(recommendations.any((item) => item['title'] == 'Hidrasi'), isFalse);
    });

    test('treats 5 glasses of water as sufficient and does not recommend hydration', () {
      final record = HealthRecord(
        id: '4',
        userId: 'user-4',
        date: DateTime.now(),
        sleepStartTime: '22:30',
        sleepEndTime: '06:30',
        sleepHours: 8,
        activityType: 'Light Exercise',
        activityDuration: 45,
        waterIntake: 8,
        totalScore: 100,
        healthLabel: 'Sangat Sehat',
        sleepScore: 40,
        activityScore: 30,
        waterScore: HealthRecord.calculateWaterScore(8),
      );

      expect(HealthRecord.calculateWaterScore(8), 30);

      final recommendations = HealthProvider.buildRecommendations(
        age: 25,
        height: 170,
        weight: 65,
        record: record,
      );

      expect(recommendations.any((item) => item['title'] == 'Hidrasi'), isFalse);
    });

    test('serializes recommendations into the health record payload', () {
      final record = HealthRecord(
        id: '5',
        userId: 'user-3',
        date: DateTime.now(),
        sleepStartTime: '23:00',
        sleepEndTime: '06:30',
        sleepHours: 7.5,
        activityType: 'Light Exercise',
        activityDuration: 45,
        waterIntake: 6,
        totalScore: 80,
        healthLabel: 'Healthy',
        sleepScore: 40,
        activityScore: 20,
        waterScore: 20,
        recommendations: [
          {'title': 'Hidrasi', 'message': 'Minum air lebih banyak besok.'},
        ],
      );

      final payload = record.toMap();

      expect(payload['accountId'], 'user-3');
      expect(payload['ownerUid'], 'user-3');
      expect(payload['ownerEmail'], isEmpty);
      expect(payload['recommendations'], isA<List>());
      expect(
        payload['recommendations'].any(
          (item) => item['title'] == 'Hidrasi' && item['message'] == 'Minum air lebih banyak besok.',
        ),
        isTrue,
      );
    });
  });
}
