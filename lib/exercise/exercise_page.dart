import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../const/colors.dart';
import '../health_log/database_helper.dart';
import '../const/diabetes_doodle_painter.dart';

enum WorkoutState { notStarted, running, paused }

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  _ExercisePageState createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _workoutTypes = ['Running', 'Cycling', 'Walking'];
  final FlutterTts _flutterTts = FlutterTts();

  // Workout state
  int? _countdown;
  Timer? _countdownTimer;
  String? _workoutMessage;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<StepCount>? _stepSubscription;

  // Per-workout data
  final Map<String, WorkoutState> _workoutStates = {};
  final Map<String, double> _distances = {};
  final Map<String, int> _milestones = {};
  final Map<String, Position?> _lastPositions = {};
  final Map<String, int> _sessionSteps = {};
  int? _initialSteps;

  @override
  void initState() {
    super.initState();
    for (var type in _workoutTypes) {
      _workoutStates[type] = WorkoutState.notStarted;
      _distances[type] = 0.0;
      _sessionSteps[type] = 0;
      _milestones[type] = 0;
    }

    _tabController = TabController(length: _workoutTypes.length, vsync: this);
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _countdownTimer?.cancel();
    _positionStream?.cancel();
    _stepSubscription?.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  void _startCountdown(String workoutType) {
    if (_countdown != null) return;
    setState(() => _countdown = 3);
    _speak("3");
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        if (_countdown! > 1) { 
          _countdown = _countdown! - 1; 
          _speak(_countdown!.toString());
        }
        else { 
          timer.cancel(); 
          _countdown = null; 
          _startWorkout(workoutType); 
        }
      });
    });
  }

  void _startWorkout(String workoutType) async {
    setState(() => _workoutMessage = "GO!");
    _speak("Go!");
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _workoutMessage = null;
      _workoutStates[workoutType] = WorkoutState.running;
    });
    _startTracking(workoutType);
  }

  void _startTracking(String workoutType) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    if (await Permission.activityRecognition.request().isGranted) {
      _stepSubscription = Pedometer.stepCountStream.listen((event) {
        _initialSteps ??= event.steps;
        if (mounted && _workoutStates[workoutType] == WorkoutState.running) {
          setState(() => _sessionSteps[workoutType] = event.steps - _initialSteps!);
        }
      });
    }

    const LocationSettings locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (mounted && _workoutStates[workoutType] == WorkoutState.running) {
        final lastPos = _lastPositions[workoutType];
        setState(() {
          if (lastPos != null) {
            double newDistance = (_distances[workoutType] ?? 0.0) + (Geolocator.distanceBetween(lastPos.latitude, lastPos.longitude, position.latitude, position.longitude) / 1000);
            _distances[workoutType] = newDistance;
            
            // Check for 1km milestones
            int currentMilestone = newDistance.floor();
            if (currentMilestone > _milestones[workoutType]!) {
              _milestones[workoutType] = currentMilestone;
              _speak("You have covered $currentMilestone kilometers.");
            }
          }
          _lastPositions[workoutType] = position;
        });
      }
    });
  }

  void _pauseWorkout(String workoutType) {
    _positionStream?.pause();
    _speak("Workout paused");
    setState(() => _workoutStates[workoutType] = WorkoutState.paused);
  }

  void _resumeWorkout(String workoutType) {
    _positionStream?.resume();
    _speak("Workout resumed");
    setState(() => _workoutStates[workoutType] = WorkoutState.running);
  }

  void _stopWorkout(String workoutType) async {
    _positionStream?.cancel();
    _positionStream = null;
    _stepSubscription?.cancel();
    _stepSubscription = null;

    final distance = _distances[workoutType]!;
    final steps = _sessionSteps[workoutType]!;
    final calories = _calculateCalories(workoutType, distance);

    _speak("Workout stopped. You covered ${distance.toStringAsFixed(1)} kilometers.");

    await DatabaseHelper().insertLog({
      'date': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      'type': 'Outdoor $workoutType',
      'distance': distance,
      'steps': steps,
      'calories': calories,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Workout saved successfully!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.success,
        )
      );
      setState(() {
        _workoutStates[workoutType] = WorkoutState.notStarted;
        _distances[workoutType] = 0.0;
        _lastPositions[workoutType] = null;
        _sessionSteps[workoutType] = 0;
        _initialSteps = null;
        _milestones[workoutType] = 0;
      });
    }
  }

  double _calculateCalories(String type, double distanceKm) {
    if (type == 'Running') return distanceKm * 60;
    if (type == 'Cycling') return distanceKm * 30;
    return distanceKm * 50;
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
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildWorkoutTab('Running', Icons.directions_run_rounded, AppColors.primary),
                    _buildWorkoutTab('Cycling', Icons.directions_bike_rounded, AppColors.secondary),
                    _buildWorkoutTab('Walking', Icons.directions_walk_rounded, AppColors.warning),
                  ],
                ),
              ),
            ],
          ),
          if (_countdown != null || _workoutMessage != null)
            _buildCountdownOverlay(),
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
            const Text(
              'Activity Tracker',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        tabs: _workoutTypes.map((type) => Tab(text: type)).toList(),
      ),
    );
  }

  Widget _buildWorkoutTab(String workoutType, IconData icon, Color accentColor) {
    final distance = _distances[workoutType]!;
    final state = _workoutStates[workoutType]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildMainStats(distance, workoutType, accentColor),
          const SizedBox(height: 32),
          _buildSecondaryStats(workoutType),
          const SizedBox(height: 48),
          _buildActionControls(workoutType, icon, accentColor),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMainStats(double distance, String type, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
      ),
      child: Column(
        children: [
          Text(
            distance.toStringAsFixed(2),
            style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: color, letterSpacing: -2),
          ),
          Text(
            'KILOMETERS',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color.withOpacity(0.6), letterSpacing: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryStats(String type) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Steps',
            _sessionSteps[type].toString(),
            Icons.directions_walk_rounded,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Calories',
            _calculateCalories(type, _distances[type]!).toStringAsFixed(0),
            Icons.local_fire_department_rounded,
            AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildActionControls(String workoutType, IconData icon, Color color) {
    final state = _workoutStates[workoutType]!;

    if (state == WorkoutState.notStarted) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _startCountdown(workoutType),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              const Text('START WORKOUT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () => _stopWorkout(workoutType),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error.withOpacity(0.1),
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: const Text('STOP', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: ElevatedButton(
            onPressed: () => state == WorkoutState.running ? _pauseWorkout(workoutType) : _resumeWorkout(workoutType),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(state == WorkoutState.running ? Icons.pause_rounded : Icons.play_arrow_rounded),
                const SizedBox(width: 8),
                Text(state == WorkoutState.running ? 'PAUSE' : 'RESUME', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Text(
          _countdown?.toString() ?? _workoutMessage ?? '',
          style: const TextStyle(fontSize: 100, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
