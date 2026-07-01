import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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
                        'Riwayat',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '7 Hari Terakhir',
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
                    _buildStatsRow(health),
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
            child: records.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada data',
                      style: TextStyle(color: AppColors.grey),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${rod.toY.toInt()}',
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
                              if (index < records.length) {
                                final date = records[index].date;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    DateFormat('EEE').format(date),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.grey,
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
                        records.length > 7 ? 7 : records.length,
                        (index) {
                          final record = records[index];
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: record.totalScore.toDouble(),
                                color: _getScoreColor(record.totalScore),
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

  Widget _buildStatsRow(HealthProvider health) {
    return Row(
      children: [
        _buildStatCard(
          'Rata-rata',
          health.averageScore.toStringAsFixed(0),
          AppColors.primaryBlue,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Terbaik',
          '${health.highestScore}',
          AppColors.success,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Streak',
          '${health.currentStreak}',
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

    if (records.isEmpty) {
      insights.add('Mulai input data harian untuk mendapat insight.');
    } else {
      final recent = records.take(7).toList();
      final sleepAvg = recent
              .map((r) => (r as HealthRecord).sleepHours)
              .fold(0.0, (a, b) => a + b) /
          recent.length;
      final activityDays = recent
          .where((r) => (r as HealthRecord).activityType != 'No Activity' && (r).activityDuration >= 30)
          .length;
      final waterAvg = recent
              .map((r) => (r as HealthRecord).waterIntake)
              .fold(0, (a, b) => a + b) /
          recent.length;
      final averageScore = recent
              .map((r) => (r as HealthRecord).totalScore)
              .fold(0, (a, b) => a + b) /
          recent.length;

      if (sleepAvg < 7) {
        insights.add('Rata-rata tidurmu ${sleepAvg.toStringAsFixed(1)} jam, masih di bawah target 7–9 jam.');
      } else if (sleepAvg <= 9) {
        insights.add('Rata-rata tidurmu ${sleepAvg.toStringAsFixed(1)} jam, sudah sesuai target 7–9 jam.');
      } else {
        insights.add('Rata-rata tidurmu ${sleepAvg.toStringAsFixed(1)} jam, sedikit di atas target 7–9 jam.');
      }

      if (activityDays >= 4) {
        insights.add('Aktivitas fisikmu cukup konsisten di $activityDays dari ${recent.length} hari terakhir.');
      } else {
        insights.add('Aktivitas fisikmu belum konsisten, baru $activityDays dari ${recent.length} hari terakhir.');
      }

      if (waterAvg >= 8) {
        insights.add('Konsumsi airmu rata-rata ${waterAvg.toStringAsFixed(1)} gelas, sangat baik.');
      } else if (waterAvg >= 6) {
        insights.add('Konsumsi airmu rata-rata ${waterAvg.toStringAsFixed(1)} gelas, masih bisa ditingkatkan.');
      } else {
        insights.add('Konsumsi airmu rata-rata ${waterAvg.toStringAsFixed(1)} gelas, perlu ditambah.');
      }

      if (averageScore >= 80) {
        insights.add('Skor rata-ratamu ${averageScore.toStringAsFixed(0)}, sangat sehat.');
      } else if (averageScore >= 60) {
        insights.add('Skor rata-ratamu ${averageScore.toStringAsFixed(0)}, cukup sehat.');
      } else if (averageScore >= 40) {
        insights.add('Skor rata-ratamu ${averageScore.toStringAsFixed(0)}, butuh perhatian lebih.');
      } else {
        insights.add('Skor rata-ratamu ${averageScore.toStringAsFixed(0)}, perlu perbaikan segera.');
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
