import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/health_provider.dart';
import '../models/health_record_model.dart';
import '../theme/app_theme.dart';
import '../config/app_config.dart';
import '../widgets/score_card.dart';
import '../widgets/suggestion_card.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<AuthProvider, HealthProvider>(
        builder: (context, auth, health, _) {
          final record = health.latestRecord;
          final user = auth.userModel;

          if (record == null) {
            return const Scaffold(
              body: Center(child: Text('No data available')),
            );
          }

          final recommendations = health.getRecommendations(
            age: user?.age,
            height: user?.height,
            weight: user?.weight,
            record: record,
          );

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
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
                        'Hasil Hari Ini',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMMM yyyy').format(DateTime.now()),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xCCFFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: ScoreCard(
                          score: record.totalScore,
                          label: record.healthLabel,
                          size: 180,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.softBlue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          HealthRecord.getHealthMessage(record.totalScore),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.cardShadow,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rincian Skor',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildScoreRow(
                                'Tidur', record.sleepScore, 40, AppColors.primaryBlue),
                            const SizedBox(height: 12),
                            _buildScoreRow(
                                'Aktivitas', record.activityScore, 30, AppColors.success),
                            const SizedBox(height: 12),
                            _buildScoreRow(
                                'Air', record.waterScore, 30, AppColors.lightBlue),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Rekomendasi Untukmu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...recommendations.map((r) {
                        final icon = _getIcon(r['icon'] ?? 'lightbulb');
                        final color = _getColor(r['color'] ?? 'warning');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SuggestionCard(
                            title: r['title'] ?? '',
                            message: r['message'] ?? '',
                            icon: icon,
                            color: color,
                          ),
                        );
                      }),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.dashboard,
                              (route) => false,
                            );
                          },
                          child: const Text('Kembali ke Dashboard'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreRow(
      String label, int score, int maxScore, Color color) {
    return Row(
      children: [
        Icon(
          label == 'Tidur'
              ? Icons.bedtime_outlined
              : label == 'Aktivitas'
                  ? Icons.fitness_center
                  : Icons.water_drop_outlined,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 14, color: AppColors.grey)),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: score / maxScore,
                backgroundColor: AppColors.lightGrey,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$score / $maxScore',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'bedtime':
        return Icons.bedtime_outlined;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'water_drop':
        return Icons.water_drop_outlined;
      case 'monitor_weight':
        return Icons.monitor_weight_outlined;
      case 'check_circle':
        return Icons.check_circle_outline;
      default:
        return Icons.lightbulb_outline;
    }
  }

  Color _getColor(String name) {
    switch (name) {
      case 'success':
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      case 'info':
        return AppColors.primaryBlue;
      case 'danger':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }
}
