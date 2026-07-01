import 'package:flutter/material.dart';
import '../models/health_record_model.dart';
import '../services/firestore_service.dart';

class HealthProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<HealthRecord> _records = [];
  HealthRecord? _todayRecord;
  HealthRecord? _latestRecord;
  bool _isLoading = false;
  String? _error;

  List<HealthRecord> get records => _records;
  HealthRecord? get todayRecord => _todayRecord;
  HealthRecord? get latestRecord => _latestRecord;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get todayScore => _todayRecord?.totalScore ?? 0;
  String get todayLabel => _todayRecord?.healthLabel ?? 'No Data';

  double get averageScore {
    if (_records.isEmpty) return 0;
    final total = _records.fold<int>(0, (sum, r) => sum + r.totalScore);
    return total / _records.length;
  }

  int get highestScore {
    if (_records.isEmpty) return 0;
    return _records.map((r) => r.totalScore).reduce((a, b) => a > b ? a : b);
  }

  int get currentStreak {
    if (_records.isEmpty) return 0;
    int streak = 0;
    DateTime today = DateTime.now();
    for (int i = 0; i < _records.length; i++) {
      final recordDate = DateTime(
        _records[i].date.year,
        _records[i].date.month,
        _records[i].date.day,
      );
      final expectedDate = DateTime(today.year, today.month, today.day - i);
      if (recordDate == expectedDate) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ===================== INPUT RULES =====================

  bool canSubmitInput() => true;

  int get inputCooldown => 0;

  bool isTodayRecordLocked(DateTime date) {
    return FirestoreService.isRecordLocked(date);
  }

  // ===================== LOAD DATA =====================

  Future<void> loadRecords(String uid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final records = await _firestoreService.getHealthRecords(uid);
      final todayRecord = await _firestoreService.getTodayRecord(uid);

      _records = records;
      _todayRecord = todayRecord;
      _latestRecord = records.isNotEmpty ? records.first : todayRecord;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===================== SAVE RECORD =====================

  Future<bool> saveHealthRecord(HealthRecord record) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final recommendations = getRecommendations(
        age: null,
        height: null,
        weight: null,
        record: record,
      );
      final recordWithRecommendations = HealthRecord(
        id: record.id,
        userId: record.userId,
        date: record.date,
        sleepStartTime: record.sleepStartTime,
        sleepEndTime: record.sleepEndTime,
        sleepHours: record.sleepHours,
        activityType: record.activityType,
        activityDuration: record.activityDuration,
        waterIntake: record.waterIntake,
        totalScore: record.totalScore,
        healthLabel: record.healthLabel,
        sleepScore: record.sleepScore,
        activityScore: record.activityScore,
        waterScore: record.waterScore,
        recommendations: recommendations,
        createdAt: record.createdAt,
      );

      final recordToSave = HealthRecord(
        id: FirestoreService.buildDailyRecordDocId(record.userId, record.date),
        userId: recordWithRecommendations.userId,
        date: recordWithRecommendations.date,
        sleepStartTime: recordWithRecommendations.sleepStartTime,
        sleepEndTime: recordWithRecommendations.sleepEndTime,
        sleepHours: recordWithRecommendations.sleepHours,
        activityType: recordWithRecommendations.activityType,
        activityDuration: recordWithRecommendations.activityDuration,
        waterIntake: recordWithRecommendations.waterIntake,
        totalScore: recordWithRecommendations.totalScore,
        healthLabel: recordWithRecommendations.healthLabel,
        sleepScore: recordWithRecommendations.sleepScore,
        activityScore: recordWithRecommendations.activityScore,
        waterScore: recordWithRecommendations.waterScore,
        recommendations: recordWithRecommendations.recommendations,
        createdAt: recordWithRecommendations.createdAt,
      );

      await _firestoreService.saveHealthRecord(recordToSave);
      _todayRecord = recordToSave;
      _latestRecord = recordToSave;
      _records.removeWhere((existing) {
        final sameDay =
            existing.userId == recordToSave.userId &&
            existing.date.year == recordToSave.date.year &&
            existing.date.month == recordToSave.date.month &&
            existing.date.day == recordToSave.date.day;
        return sameDay;
      });
      _records.insert(0, recordToSave);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ===================== CALCULATE RECORD =====================

  HealthRecord calculateRecord({
    required String userId,
    required DateTime date,
    required String sleepStart,
    required String sleepEnd,
    required double sleepHours,
    required String activityType,
    required int activityDuration,
    required int waterIntake,
  }) {
    final sleepScore = HealthRecord.calculateSleepScore(sleepHours);
    final activityScore =
        HealthRecord.calculateActivityScore(activityType, activityDuration);
    final waterScore = HealthRecord.calculateWaterScore(waterIntake);
    final totalScore = sleepScore + activityScore + waterScore;
    final healthLabel = HealthRecord.getHealthLabel(totalScore);

    return HealthRecord(
      id: '',
      userId: userId,
      date: date,
      sleepStartTime: sleepStart,
      sleepEndTime: sleepEnd,
      sleepHours: sleepHours,
      activityType: activityType,
      activityDuration: activityDuration,
      waterIntake: waterIntake,
      totalScore: totalScore,
      healthLabel: healthLabel,
      sleepScore: sleepScore,
      activityScore: activityScore,
      waterScore: waterScore,
    );
  }

  // ===================== RECOMMENDATIONS =====================

  List<Map<String, String>> getRecommendations({
    required int? age,
    required double? height,
    required double? weight,
    HealthRecord? record,
  }) {
    final effectiveRecord = record ?? _todayRecord ?? _latestRecord;
    if (effectiveRecord == null) return [];

    return HealthProvider.buildRecommendations(
      age: age,
      height: height,
      weight: weight,
      record: effectiveRecord,
    );
  }

  static List<Map<String, String>> buildRecommendations({
    required int? age,
    required double? height,
    required double? weight,
    required HealthRecord record,
  }) {
    final recommendations = <Map<String, String>>[];

    // Sleep recommendation
    if (record.sleepScore < 40) {
      String msg = 'Pola tidurmu kurang. ';
      if (record.sleepHours < 7) {
        msg += 'Tidurmu kurang dari 7 jam. Pola tidur kurang.';
      } else {
        msg += 'Target tidur minimal 7 jam setiap hari.';
      }
      recommendations.add({
        'title': 'Tidur',
        'message': msg,
        'icon': 'bedtime',
        'color': 'warning',
      });
    }

    // Activity recommendation
    final hasSufficientActivity = switch (record.activityType) {
      'Heavy Exercise' => record.activityDuration >= 30,
      'Light Exercise' => record.activityDuration >= 30,
      'Walking' => record.activityDuration >= 30,
      _ => false,
    };

    if (!hasSufficientActivity && record.activityScore < 30) {
      String msg = 'Aktivitas fisikmu kurang. ';
      msg += 'Minimal 30 menit aktivitas fisik (jalan kaki, ringan, atau berat) setiap hari.';
      recommendations.add({
        'title': 'Aktivitas',
        'message': msg,
        'icon': 'fitness_center',
        'color': 'warning',
      });
    }

    // Water recommendation
    if (record.waterIntake < 8) {
      String msg = 'Kurang minum air. ';
      msg += 'Target minum air 8 gelas setiap hari.';
      recommendations.add({
        'title': 'Hidrasi',
        'message': msg,
        'icon': 'water_drop',
        'color': 'warning',
      });
    }

    // All good
    if (recommendations.isEmpty) {
      recommendations.add({
        'title': 'Luar Biasa!',
        'message': 'Semua skor kesehatanmu sudah optimal. Pertahankan!',
        'icon': 'check_circle',
        'color': 'success',
      });
    }

    return recommendations;
  }
}
