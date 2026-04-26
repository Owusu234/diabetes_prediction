import 'package:flutter/material.dart';
import '../const/colors.dart';
import 'database_helper.dart';
import '../const/diabetes_doodle_painter.dart';

class HealthLogScreen extends StatefulWidget {
  const HealthLogScreen({super.key});

  @override
  State<HealthLogScreen> createState() => _HealthLogScreenState();
}

class _HealthLogScreenState extends State<HealthLogScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, List<Map<String, dynamic>>> _exerciseLogs = {};
  Map<String, List<Map<String, dynamic>>> _predictionLogs = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshLogs() async {
    setState(() => _isLoading = true);
    final exerciseData = await DatabaseHelper().queryAllLogs();
    final predictionData = await DatabaseHelper().queryAllPredictions();
    _exerciseLogs = _groupLogsByDate(exerciseData);
    _predictionLogs = _groupLogsByDate(predictionData);
    setState(() => _isLoading = false);
  }

  Map<String, List<Map<String, dynamic>>> _groupLogsByDate(List<Map<String, dynamic>> logs) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var item in logs) {
      final date = (item['date'] as String).split(' ')[0];
      if (grouped[date] == null) grouped[date] = [];
      grouped[date]!.add(item);
    }
    grouped.forEach((date, items) {
      items.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    });
    return grouped;
  }

  Future<void> _deleteItem(Map<String, dynamic> item, bool isExercise) async {
    if (isExercise) {
      await DatabaseHelper().deleteLog(item['id']);
    } else {
      await DatabaseHelper().deletePrediction(item['id']);
    }
    _refreshLogs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Entry deleted'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: DiabetesDoodlePainter(
                iconColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
              ),
            ),
          ),
          Column(
            children: [
              _buildTopBar(),
              _buildTabBar(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildLogList(_exerciseLogs, true),
                          _buildLogList(_predictionLogs, false),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            const Text('Health Records', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
              onPressed: _showClearAllDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        tabs: const [Tab(text: 'Activities'), Tab(text: 'Predictions')],
      ),
    );
  }

  Widget _buildLogList(Map<String, List<Map<String, dynamic>>> groupedLogs, bool isExercise) {
    if (groupedLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isExercise ? Icons.fitness_center_rounded : Icons.analytics_rounded, size: 64, color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text('No records found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final sortedDates = groupedLogs.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIndex) {
        final date = sortedDates[dateIndex];
        final dayItems = groupedLogs[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
              child: Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
            ),
            ...dayItems.map((item) => _buildLogCard(item, isExercise)),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildLogCard(Map<String, dynamic> item, bool isExercise) {
    final color = isExercise ? AppColors.secondary : AppColors.primary;
    return Dismissible(
      key: Key('${isExercise ? "ex" : "pr"}_${item['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _deleteItem(item, isExercise),
      child: InkWell(
        onTap: () => _showAnalysisDialog(item, isExercise),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(isExercise ? Icons.directions_run_rounded : Icons.psychology_rounded, color: color, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isExercise ? (item['type'] ?? 'Workout') : 'Health Risk Analysis', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(item['date'].split(' ')[1], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                ],
              ),
              if (isExercise) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniStat('${item['distance'].toStringAsFixed(2)}', 'KM'),
                    _buildMiniStat('${item['steps']}', 'STEPS'),
                    _buildMiniStat('${item['calories'].toStringAsFixed(0)}', 'KCAL'),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Result:', style: TextStyle(fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: (item['outcome'] == "Diabetic" ? AppColors.error : AppColors.success).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item['outcome'],
                        style: TextStyle(color: item['outcome'] == "Diabetic" ? AppColors.error : AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
      ],
    );
  }

  void _showAnalysisDialog(Map<String, dynamic> item, bool isExercise) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isExercise ? AppColors.secondary : AppColors.primary).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isExercise ? Icons.fitness_center_rounded : Icons.analytics_rounded,
                  color: isExercise ? AppColors.secondary : AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isExercise ? 'Workout Analysis' : 'Prediction Details',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(item['date'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 24),
              if (isExercise) ...[
                _buildAnalysisRow('Activity', item['type'] ?? 'Exercise'),
                _buildAnalysisRow('Distance', '${item['distance'].toStringAsFixed(2)} km'),
                _buildAnalysisRow('Total Steps', '${item['steps']}'),
                _buildAnalysisRow('Calories Burned', '${item['calories'].toStringAsFixed(0)} kcal'),
              ] else ...[
                _buildAnalysisRow('Assessment', item['outcome'], color: item['outcome'] == "Diabetic" ? AppColors.error : AppColors.success),
                _buildAnalysisRow('Risk Level', item['risk_level'] ?? 'N/A'),
                _buildAnalysisRow('Confidence', item['confidence'] ?? 'N/A'),
                _buildAnalysisRow('Probability', item['probability'] ?? 'N/A'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'This analysis was generated by our AI model based on your clinical parameters. Please consult a doctor for a medical diagnosis.',
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Clear All Records?'),
        content: const Text('This action will permanently delete all your health logs and predictions.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await DatabaseHelper().deleteAllLogs();
              final db = await DatabaseHelper().database;
              await db.delete('predictions');
              Navigator.pop(context);
              _refreshLogs();
            },
            child: const Text('Clear All', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
