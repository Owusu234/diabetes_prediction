import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../const/colors.dart';
import 'theme_provider.dart';
import '../const/diabetes_doodle_painter.dart';
import '../network/network_checker.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _resetProfile(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Reset Profile?'),
        content: const Text('This will delete your personalized profile data and return you to the welcome screen. Your health logs will remain intact.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await prefs.remove('username');
      await prefs.remove('profile_image');
      await prefs.remove('has_seen_welcome'); 
      
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const NetworkChecker()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

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
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader('Appearance'),
                    const SizedBox(height: 16),
                    _buildThemeCard(context, themeProvider),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Data Management'),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      context,
                      'Reset Profile',
                      'Return to setup and clear profile info',
                      Icons.person_remove_rounded,
                      AppColors.error,
                      () => _resetProfile(context),
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      context,
                      'Clear App Cache',
                      'Free up local storage space',
                      Icons.cleaning_services_rounded,
                      Colors.grey,
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cache cleared successfully'), behavior: SnackBarBehavior.floating),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader('About App'),
                    const SizedBox(height: 16),
                    _buildInfoCard(context),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        background: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5));
  }

  Widget _buildThemeCard(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _buildThemeOption(context, 'Light', Icons.wb_sunny_rounded, ThemeMode.light, themeProvider),
          const Divider(height: 1, indent: 56),
          _buildThemeOption(context, 'Dark', Icons.nightlight_round_rounded, ThemeMode.dark, themeProvider),
          const Divider(height: 1, indent: 56),
          _buildThemeOption(context, 'System', Icons.settings_brightness_rounded, ThemeMode.system, themeProvider),
        ],
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, String title, IconData icon, ThemeMode mode, ThemeProvider provider) {
    final isSelected = provider.themeMode == mode;
    return ListTile(
      onTap: () => provider.setThemeMode(mode),
      leading: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Diabetes Predict', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Version 2.0.1', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Developed with medical insights and AI to empower your health journey.',
            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }
}
