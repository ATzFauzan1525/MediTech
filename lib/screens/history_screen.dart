import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/health_record_model.dart';
import '../providers/health_provider.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<HealthProvider>(
        builder: (context, health, _) {
          final records = health.records;
          final now = DateTime.now();
          final weekday = now.weekday;
          final startOfWeek = DateTime(now.year, now.month, now.day - (weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));

          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
          final dateRange = '${startOfWeek.day} ${months[startOfWeek.month - 1]} - ${endOfWeek.day} ${months[endOfWeek.month - 1]} ${endOfWeek.year}';

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 20,
                    left: 24,
                    right: 24,
                    bottom: 24,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.darkBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Riwayat Minggu Ini',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateRange,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildChartCard(records),
                    const SizedBox(height: 20),
                    _buildStatsRow(records),
                    const SizedBox(height: 24),
                    const Text(
                      'Insight Minggu Ini',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInsightCard(records),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.primaryBlue;
    if (score >= 40) return AppColors.warning;
    return AppColors.danger;
  }

  Widget _buildChartCard(List records) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = now.weekday;
    final startOfWeek = today.subtract(Duration(days: weekday - 1));

    final weekDays = List.generate(7, (i) {
      final date = startOfWeek.add(Duration(days: i));
      final dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      return {
        'date': date,
        'label': dayNames[i],
      };
    });

    final weekRecords = weekDays.map((day) {
      final date = day['date'] as DateTime;
      HealthRecord? record;
      for (final r in records) {
        if (r.date.year == date.year &&
            r.date.month == date.month &&
            r.date.day == date.day) {
          record = r;
          break;
        }
      }
      return {
        'label': day['label'],
        'score': record?.totalScore ?? 0,
        'hasData': record != null,
      };
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tren Skor',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dayData = weekRecords[group.x.toInt()];
                      return BarTooltipItem(
                        '${dayData['score']}',
                        const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < weekRecords.length) {
                          final isToday = index == weekday - 1;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              weekRecords[index]['label'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: isToday ? AppColors.primaryBlue : AppColors.grey,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: List.generate(
                  7,
                  (index) {
                    final score = weekRecords[index]['score'] as int;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: score.toDouble(),
                          color: score > 0
                              ? _getScoreColor(score)
                              : AppColors.lightGrey,
                          width: 18,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List records) {
    final now = DateTime.now();
    final weekday = now.weekday;
    final startOfWeek = DateTime(now.year, now.month, now.day - (weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final weekRecords = records.where((r) {
      final date = r.date;
      return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          date.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();

    int totalScore = 0;
    for (final HealthRecord r in weekRecords) {
      totalScore += r.totalScore;
    }
    final avgScore = weekRecords.isNotEmpty ? totalScore / weekRecords.length : 0.0;

    final highestScore = weekRecords.isNotEmpty
        ? weekRecords.map((r) => r.totalScore).reduce((a, b) => a > b ? a : b)
        : 0;

    int streak = 0;
    final today = DateTime(now.year, now.month, now.day);
    for (int i = 0; i < 7; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final hasRecord = weekRecords.any((r) =>
          r.date.year == checkDate.year &&
          r.date.month == checkDate.month &&
          r.date.day == checkDate.day);
      if (hasRecord) {
        streak++;
      } else {
        break;
      }
    }

    return Row(
      children: [
        _buildStatCard(
          'Rata-rata',
          avgScore.toStringAsFixed(0),
          AppColors.primaryBlue,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Terbaik',
          '$highestScore',
          AppColors.success,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Streak',
          '$streak',
          AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(List records) {
    final insights = <String>[];
    final now = DateTime.now();
    final weekday = now.weekday;
    final startOfWeek = DateTime(now.year, now.month, now.day - (weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final weekRecords = records.where((r) {
      final date = r.date;
      return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          date.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();

    if (weekRecords.isEmpty) {
      insights.add('Belum ada data minggu ini. Mulai input data harian.');
    } else {
      final sleepAvg = weekRecords
              .map((r) => (r as HealthRecord).sleepHours)
              .fold(0.0, (a, b) => a + b) /
          weekRecords.length;
      final activityDays = weekRecords
          .where((r) => (r as HealthRecord).activityType != 'No Activity' && (r).activityDuration >= 30)
          .length;
      final waterAvg = weekRecords
              .map((r) => (r as HealthRecord).waterIntake)
              .fold(0, (a, b) => a + b) /
          weekRecords.length;
      final averageScore = weekRecords
              .map((r) => (r as HealthRecord).totalScore)
              .fold(0, (a, b) => a + b) /
          weekRecords.length;

      if (sleepAvg < 7) {
        insights.add('Rata-rata tidurmu ${sleepAvg.toStringAsFixed(1)} jam, masih di bawah target 7–9 jam.');
      } else if (sleepAvg <= 9) {
        insights.add('Rata-rata tidurmu ${sleepAvg.toStringAsFixed(1)} jam, sudah sesuai target 7–9 jam.');
      } else {
        insights.add('Rata-rata tidurmu ${sleepAvg.toStringAsFixed(1)} jam, sedikit di atas target 7–9 jam.');
      }

      if (activityDays >= 4) {
        insights.add('Aktivitas fisikmu cukup konsisten di $activityDays dari ${weekRecords.length} hari minggu ini.');
      } else {
        insights.add('Aktivitas fisikmu belum konsisten, baru $activityDays dari ${weekRecords.length} hari minggu ini.');
      }

      if (waterAvg >= 8) {
        insights.add('Konsumsi airmu rata-rata ${waterAvg.toStringAsFixed(1)} gelas, sangat baik.');
      } else if (waterAvg >= 6) {
        insights.add('Konsumsi airmu rata-rata ${waterAvg.toStringAsFixed(1)} gelas, masih bisa ditingkatkan.');
      } else {
        insights.add('Konsumsi airmu rata-rata ${waterAvg.toStringAsFixed(1)} gelas, perlu ditambah.');
      }

      if (averageScore >= 80) {
        insights.add('Skor rata-ratamu ${averageScore.toStringAsFixed(0)}, sangat sehat minggu ini.');
      } else if (averageScore >= 60) {
        insights.add('Skor rata-ratamu ${averageScore.toStringAsFixed(0)}, cukup sehat minggu ini.');
      } else if (averageScore >= 40) {
        insights.add('Skor rata-ratamu ${averageScore.toStringAsFixed(0)}, butuh perhatian lebih minggu ini.');
      } else {
        insights.add('Skor rata-ratamu ${averageScore.toStringAsFixed(0)}, perlu perbaikan segera minggu ini.');
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: insights.map((insight) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
