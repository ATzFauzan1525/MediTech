import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/health_provider.dart';
import '../theme/app_theme.dart';
import '../config/app_config.dart';

class DailyInputScreen extends StatefulWidget {
  const DailyInputScreen({super.key});

  @override
  State<DailyInputScreen> createState() => _DailyInputScreenState();
}

class _DailyInputScreenState extends State<DailyInputScreen> {
  TimeOfDay _sleepStart = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _sleepEnd = const TimeOfDay(hour: 7, minute: 0);
  String _activityType = 'No Activity';
  int _activityDuration = 30;
  int _waterIntake = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncValuesFromProvider();
      final auth = context.read<AuthProvider>();
      final uid = auth.user?.uid;
      if (uid != null) {
        context.read<HealthProvider>().loadRecords(uid);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncValuesFromProvider();
  }

  static const List<Map<String, dynamic>> _activities = [
    {'type': 'Walking', 'icon': Icons.directions_walk, 'label': 'Jalan Kaki'},
    {'type': 'Light Exercise', 'icon': Icons.fitness_center, 'label': 'Ringan'},
    {'type': 'Heavy Exercise', 'icon': Icons.sports_martial_arts, 'label': 'Berat'},
    {'type': 'No Activity', 'icon': Icons.hourglass_empty, 'label': 'Tidak Ada'},
  ];

  double _calculateSleepHours() {
    final startMinutes = _sleepStart.hour * 60 + _sleepStart.minute;
    final endMinutes = _sleepEnd.hour * 60 + _sleepEnd.minute;
    int totalMinutes;
    if (endMinutes > startMinutes) {
      totalMinutes = endMinutes - startMinutes;
    } else {
      totalMinutes = (24 * 60 - startMinutes) + endMinutes;
    }
    return totalMinutes / 60.0;
  }

  void _syncValuesFromProvider() {
    final healthProvider = context.read<HealthProvider>();
    final todayRecord = healthProvider.todayRecord;
    if (todayRecord == null) return;

    final today = DateTime.now();
    final sameDay =
        todayRecord.date.year == today.year &&
        todayRecord.date.month == today.month &&
        todayRecord.date.day == today.day;
    if (!sameDay) return;

    final sleepStart = _parseTimeOfDay(todayRecord.sleepStartTime);
    final sleepEnd = _parseTimeOfDay(todayRecord.sleepEndTime);

    if (mounted) {
      setState(() {
        _sleepStart = sleepStart ?? _sleepStart;
        _sleepEnd = sleepEnd ?? _sleepEnd;
        _activityType = todayRecord.activityType;
        _activityDuration = todayRecord.activityDuration;
        _waterIntake = todayRecord.waterIntake;
      });
    }
  }

  TimeOfDay? _parseTimeOfDay(String value) {
    try {
      final parts = value.split(':');
      if (parts.length != 2) return null;
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _selectTime(bool isSleepStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isSleepStart ? _sleepStart : _sleepEnd,
    );
    if (picked != null) {
      setState(() {
        if (isSleepStart) {
          _sleepStart = picked;
        } else {
          _sleepEnd = picked;
        }
      });
    }
  }

  Future<void> _saveRecord() async {
    final authProvider = context.read<AuthProvider>();
    final healthProvider = context.read<HealthProvider>();
    final user = authProvider.user;

    if (user == null) return;

    if (healthProvider.isTodayRecordLocked(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data untuk hari sebelumnya tidak bisa diubah lagi.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    final record = healthProvider.calculateRecord(
      userId: user.uid,
      date: DateTime.now(),
      sleepStart: _sleepStart.format(context),
      sleepEnd: _sleepEnd.format(context),
      sleepHours: _calculateSleepHours(),
      activityType: _activityType,
      activityDuration: _activityDuration,
      waterIntake: _waterIntake,
    );

    final success = await healthProvider.saveHealthRecord(record);

    if (success && mounted) {
      await healthProvider.loadRecords(user.uid);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Jam Tidur', Icons.bedtime_outlined),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeCard(
                          'Mulai Tidur',
                          _sleepStart.format(context),
                          () => _selectTime(true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimeCard(
                          'Bangun',
                          _sleepEnd.format(context),
                          () => _selectTime(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time,
                            color: AppColors.primaryBlue, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Durasi: ${_calculateSleepHours().toStringAsFixed(1)} jam',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Target: 7-9 jam',
                          style: TextStyle(color: AppColors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Aktivitas Fisik', Icons.fitness_center),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _activities.map((activity) {
                      final isSelected = _activityType == activity['type'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _activityType = activity['type'];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : AppColors.softBlue,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : AppColors.lightGrey,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                activity['icon'],
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                activity['label'],
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  if (_activityType != 'No Activity') ...[
                    Row(
                      children: [
                        const Text(
                          'Durasi: ',
                          style: TextStyle(fontSize: 14, color: AppColors.grey),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (_activityDuration > 0) {
                                _activityDuration -= 1;
                              }
                            });
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppColors.primaryBlue,
                        ),
                        Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.softBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDuration(_activityDuration),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _activityDuration += 1;
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          color: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickDuration(15, '15m'),
                        _buildQuickDuration(30, '30m'),
                        _buildQuickDuration(45, '45m'),
                        _buildQuickDuration(60, '1j'),
                        _buildQuickDuration(90, '1.5j'),
                        _buildQuickDuration(120, '2j'),
                      ],
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.softBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Pilih aktivitas jalan kaki, ringan, atau berat jika kamu sudah beraktivitas hari ini.',
                        style: TextStyle(fontSize: 13, color: AppColors.grey),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Konsumsi Air', Icons.water_drop_outlined),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.lightGrey),
                    ),
                    child: Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final iconSize = constraints.maxWidth < 360 ? 22.0 : 28.0;
                            final spacing = constraints.maxWidth < 360 ? 2.0 : 3.0;

                            return Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      if (_waterIntake > 0 && _waterIntake <= 3) {
                                        _waterIntake = 0;
                                      } else if (_waterIntake > 3) {
                                        _waterIntake = 3;
                                      }
                                    });
                                  },
                                  icon: Icon(
                                    Icons.remove_circle_outline,
                                    size: iconSize + 2,
                                  ),
                                  color: AppColors.primaryBlue,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    runSpacing: 4,
                                    children: List.generate(8, (index) {
                                      final isFilled = index < _waterIntake;
                                      return Padding(
                                        padding: EdgeInsets.symmetric(horizontal: spacing),
                                        child: Icon(
                                          Icons.local_drink,
                                          size: iconSize,
                                          color: isFilled
                                              ? AppColors.primaryBlue
                                              : AppColors.lightGrey,
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      if (_waterIntake < 8) _waterIntake++;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    size: iconSize + 2,
                                  ),
                                  color: AppColors.primaryBlue,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_waterIntake / 8 gelas',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<HealthProvider>(
      builder: (context, health, _) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
                  ),
                  if (health.todayRecord != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Terakhir diperbarui ${_formatUpdatedAt(health.todayRecord?.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Input Harian',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<HealthProvider>(
      builder: (context, health, _) {
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: health.isLoading
                ? null
                : (health.canSubmitInput() ? _saveRecord : null),
            child: health.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Text('Hitung Skor'),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }

  String _formatUpdatedAt(DateTime? updatedAt) {
    if (updatedAt == null) return 'baru saja';
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    if (difference.inMinutes < 1) return 'baru saja';
    if (difference.inHours < 1) return '${difference.inMinutes} menit lalu';
    if (difference.inHours < 24) return '${difference.inHours} jam lalu';
    return '${difference.inDays} hari lalu';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes mnt';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '$hours jam';
    }
    return '$hours j $mins mnt';
  }

  Widget _buildQuickDuration(int minutes, String label) {
    final isSelected = _activityDuration == minutes;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activityDuration = minutes;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.softBlue,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.lightGrey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.white : AppColors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCard(String label, String time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightGrey),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              label.contains('Mulai') ? Icons.nightlight_round : Icons.wb_sunny,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
