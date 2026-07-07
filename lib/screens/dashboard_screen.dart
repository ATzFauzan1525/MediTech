import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/health_provider.dart';
import '../models/health_record_model.dart';
import '../theme/app_theme.dart';
import '../widgets/suggestion_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _loadedUid;
  final ScreenshotController _screenshotController = ScreenshotController();

  void _loadHealthDataIfNeeded() {
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    if (uid == null) {
      _loadedUid = null;
      return;
    }
    if (uid == _loadedUid) return;

    _loadedUid = uid;
    context.read<HealthProvider>().loadRecords(uid);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHealthDataIfNeeded();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadHealthDataIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<AuthProvider, HealthProvider>(
        builder: (context, auth, health, _) {
          final user = auth.userModel;
          final now = DateTime.now();
          final todayRecord = health.todayRecord;
          final latestIsToday = health.latestRecord != null &&
              health.latestRecord!.date.year == now.year &&
              health.latestRecord!.date.month == now.month &&
              health.latestRecord!.date.day == now.day;
          final record = todayRecord ?? (latestIsToday ? health.latestRecord : null);
          final score = record?.totalScore ?? 0;
          final label = record?.healthLabel ?? 'No Data';

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
                _buildHeader(context, score, label, record),
                Padding(
                  padding: const EdgeInsets.all(24),
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
                      _buildScoreBar('Tidur', record?.sleepScore ?? 0, 40, Icons.nightlight_round),
                      const SizedBox(height: 12),
                      _buildScoreBar('Aktivitas', record?.activityScore ?? 0, 30, Icons.fitness_center),
                      const SizedBox(height: 12),
                      _buildScoreBar('Air', record?.waterScore ?? 0, 30, Icons.water_drop_outlined),
                      const SizedBox(height: 24),
                      const Text(
                        'Saran Untukmu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (recommendations.isEmpty)
                        const SuggestionCard(
                          title: 'Belum Ada Data',
                          message: 'Isi data harian untuk mendapat rekomendasi.',
                          icon: Icons.info_outline,
                          color: AppColors.primaryBlue,
                        )
                      else
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
                      const SizedBox(height: 80),
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

  Widget _buildHeader(BuildContext context, int score, String label, dynamic record) {
    final now = DateTime.now();
    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    final dateStr = '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 24,
        right: 24,
        bottom: 30,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hasil Hari Ini',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              if (record != null)
                IconButton(
                  onPressed: () => _shareHealthScore(score, label, record),
                  icon: const Icon(Icons.share, color: AppColors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.white.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Score circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 4),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white.withValues(alpha: 0.8),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.bar_chart,
                            color: AppColors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$score / 100',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      record != null
                          ? HealthRecord.getHealthMessage(record.totalScore)
                          : 'Belum ada data untuk hari ini.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _shareHealthScore(int score, String label, dynamic record) async {
    final auth = context.read<AuthProvider>();
    final userName = auth.userModel?.name ?? 'User';
    final sleepHours = record?.sleepHours.toStringAsFixed(1) ?? '0';
    final activityType = record?.activityType ?? 'Tidak Ada';
    final activityDuration = record?.activityDuration ?? 0;
    final waterIntake = record?.waterIntake ?? 0;
    final sleepScore = record?.sleepScore ?? 0;
    final activityScore = record?.activityScore ?? 0;
    final waterScore = record?.waterScore ?? 0;

    final image = await _screenshotController.captureFromLongWidget(
      _buildPosterWidget(userName, score, label, sleepHours, activityType, activityDuration, waterIntake, sleepScore, activityScore, waterScore),
      context: context,
      pixelRatio: 3.0,
    );

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/medisync_share.png');
    await file.writeAsBytes(image);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Skor Kesehatanku Hari Ini: $score/100 ($label)',
    );
  }

  Widget _buildPosterWidget(String userName, int score, String label, String sleepHours, String activityType, int activityDuration, int waterIntake, int sleepScore, int activityScore, int waterScore) {
    final now = DateTime.now();
    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final dateStr = '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';

    return Container(
      width: 225,
      height: 400,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E5EFF), Color(0xFF0A1F44)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite, color: Colors.white, size: 10),
                      SizedBox(width: 4),
                      Text(
                        'MediSync',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white54,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$score',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          label.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                _buildPosterMetric(Icons.nightlight_round, 'Tidur', '$sleepHours jam', sleepScore, 40),
                const SizedBox(height: 6),
                _buildPosterMetric(Icons.fitness_center, 'Aktivitas', activityType, activityScore, 30),
                const SizedBox(height: 6),
                _buildPosterMetric(Icons.water_drop, 'Air', '$waterIntake/8 gelas', waterScore, 30),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '#MediSync #HealthyLifestyle',
                    style: TextStyle(
                      fontSize: 7,
                      color: Colors.white38,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterMetric(IconData icon, String label, String value, int score, int max) {
    final percentage = max > 0 ? score / max : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 12),
          const SizedBox(width: 6),
          SizedBox(
            width: 45,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 4,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 30,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 8,
                color: Colors.white60,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, int score, int max, IconData icon) {
    final percentage = max > 0 ? score / max : 0.0;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                  Text(
                    '$score / $max',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 8,
                  backgroundColor: AppColors.lightGrey,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage >= 0.7 ? AppColors.success : AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
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
