import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pedometer/pedometer.dart';
import 'const/tips.dart';
import 'const/colors.dart';
import 'const/diabetes_doodle_painter.dart';
import 'diabetes_screen/diabetes_prediction_screen.dart';
import 'drawer/about_diabetes.dart';
import 'drawer/app_theme.dart';
import 'drawer/settings.dart';
import 'exercise/exercise_page.dart';
import 'health_log/health_log_screen.dart';
import 'map/map_screen.dart';
import 'network/offline_screen.dart';
import 'profile_screen.dart';
import 'diet/diet_plan_screen.dart';
import 'health_tips_screen.dart';
import 'chat/chat_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _username = "User";
  File? _image;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isOffline = false;
  late String _currentTip;
  int _currentIndex = 0;

  late Stream<StepCount> _stepCountStream;
  String _steps = '0';
  int? _initialSteps;
  double _stepProgress = 0.0;
  final int _stepGoal = 6000;

  @override
  void initState() {
    super.initState();
    _currentTip = diabetesTips[Random().nextInt(diabetesTips.length)];
    _loadSavedData();
    _checkInitialConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    _initPedometer();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? "User";
      final imagePath = prefs.getString('profile_image');
      if (imagePath != null && File(imagePath).existsSync()) {
        _image = File(imagePath);
      } else {
        _image = null;
      }
    });
  }

  void _initPedometer() async {
    if (await Permission.activityRecognition.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream.listen(_onStepCount).onError(_onStepCountError);
    }
  }

  void _onStepCount(StepCount event) {
    if (!mounted) return;
    setState(() {
      _initialSteps ??= event.steps;
      int sessionSteps = event.steps - _initialSteps!;
      _steps = sessionSteps.toString();
      _stepProgress = (sessionSteps / _stepGoal).clamp(0.0, 1.0);
    });
  }

  void _onStepCountError(error) => debugPrint('Pedometer Error: $error');

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    ConnectivityResult result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    if (!mounted) return;
    final bool isOffline = result == ConnectivityResult.none;
    if (isOffline != _isOffline) {
      setState(() => _isOffline = isOffline);
      if (isOffline) _showOfflineScreen();
    }
  }

  void _showOfflineScreen() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const OfflineScreen(), fullscreenDialog: true));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _showExitConfirmationDialog();
      },
      child: Scaffold(
        drawer: _currentIndex == 0 ? _buildDrawer() : null,
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: DiabetesDoodlePainter(
                  iconColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
                ),
              ),
            ),
            IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomeBody(),
                const ChatScreen(),
                ProfileScreen(
                  username: _username, 
                  image: _image, 
                  showAppBar: true,
                  onProfileUpdate: _loadSavedData,
                  stepProgress: _stepProgress,
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildHomeBody() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 100.0,
          floating: false,
          pinned: true,
          stretch: true,
          centerTitle: false,
          automaticallyImplyLeading: true,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(horizontal: 56, vertical: 12),
            title: Text(
              'Hello, $_username',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            background: Container(color: Colors.transparent),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildStepCard(),
              const SizedBox(height: 24),
              _buildSectionTitle('Health Services'),
              const SizedBox(height: 16),
              _buildFeatureGrid(),
              const SizedBox(height: 24),
              _buildDailyTipCard(),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStepCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: _stepProgress,
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_walk_rounded, color: Colors.white, size: 30),
                  Text(
                    '${(_stepProgress * 100).toInt()}%',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Steps',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  _steps,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Goal: $_stepGoal',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildFeatureTile(
          'Prediction', 
          'Risk Analysis',
          Icons.analytics_rounded, 
          AppColors.primary,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DiabetesPredictionScreen())),
        ),
        _buildFeatureTile(
          'Management', 
          'Health Plans',
          Icons.health_and_safety_rounded, 
          AppColors.secondary,
          _showManagementPlansDialog,
        ),
        _buildFeatureTile(
          'Facilities', 
          'Nearby Map',
          Icons.map_rounded, 
          AppColors.warning,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MapScreen())),
        ),
        _buildFeatureTile(
          'Health Log', 
          'Tracking',
          Icons.assignment_rounded, 
          AppColors.accent,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HealthLogScreen())),
        ),
      ],
    );
  }

  Widget _buildFeatureTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyTipCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: AppColors.warning),
              const SizedBox(width: 12),
              Text(
                'Health Tip',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currentTip,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              fontSize: 14,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_rounded, 'Home', 0),
          _buildNavItem(Icons.forum_rounded, 'Assistant', 1),
          _buildNavItem(Icons.person_rounded, 'Profile', 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    final color = isActive ? AppColors.primary : Colors.grey;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  void _showManagementPlansDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            const Text('Management Plans', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildPlanOption('Exercise Program', 'Track activity \u0026 routine', Icons.fitness_center_rounded, AppColors.secondary, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ExercisePage()));
            }),
            const SizedBox(height: 12),
            _buildPlanOption('Diet Plan', 'Nutrition \u0026 meal guides', Icons.restaurant_rounded, AppColors.warning, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DietPlanScreen()));
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanOption(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: _image != null ? FileImage(_image!) : null,
              child: _image == null ? Text(_username.isNotEmpty ? _username[0] : 'U', style: const TextStyle(fontSize: 32, color: AppColors.primary, fontWeight: FontWeight.bold)) : null,
            ),
            accountName: Text(_username, style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: const Text('Active Member'),
          ),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline_rounded),
            title: const Text('Health Tips'),
            onTap: () { 
              Navigator.pop(context); 
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HealthTipsScreen())); 
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())); },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Diabetes'),
            onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutDiabetesPage())); },
          ),
        ],
      ),
    );
  }

  Future<void> _showExitConfirmationDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); SystemNavigator.pop(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
