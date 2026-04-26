import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../const/colors.dart';
import '../const/diabetes_doodle_painter.dart';

class AboutDiabetesPage extends StatelessWidget {
  const AboutDiabetesPage({super.key});

  final String _url = 'https://www.who.int/news-room/fact-sheets/detail/diabetes';

  Future<void> _launchURL() async {
    final Uri url = Uri.parse(_url);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $_url';
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
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeroCard(),
                    const SizedBox(height: 32),
                    _buildSectionHeader('What is Type 2 Diabetes?'),
                    const SizedBox(height: 16),
                    _buildDescriptionCard('A chronic condition affecting how your body processes blood sugar. Without proper insulin management, sugar levels can rise, potentially causing long-term health complications.'),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Common Symptoms'),
                    const SizedBox(height: 16),
                    _buildSymptomsGrid(),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Risk Factors'),
                    const SizedBox(height: 16),
                    _buildRiskCard(context),
                    const SizedBox(height: 40),
                    _buildLearnMoreButton(),
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
        title: const Text('Diabetes Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        background: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.health_and_safety_rounded, size: 64, color: Colors.white),
          SizedBox(height: 20),
          Text(
            'Stay Informed, Stay Healthy',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Knowledge is your best tool for prevention and management.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildDescriptionCard(String text) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.grey),
      ),
    );
  }

  Widget _buildSymptomsGrid() {
    final symptoms = [
      {'icon': Icons.water_drop_rounded, 'label': 'Thirst', 'color': Colors.blue},
      {'icon': Icons.restore_from_trash_rounded, 'label': 'Urination', 'color': Colors.indigo},
      {'icon': Icons.visibility_off_rounded, 'label': 'Blurred Vision', 'color': Colors.amber},
      {'icon': Icons.bolt_rounded, 'label': 'Fatigue', 'color': Colors.orange},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: symptoms.length,
      itemBuilder: (context, index) {
        final item = symptoms[index];
        final color = item['color'] as Color;
        return Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item['icon'] as IconData, color: color, size: 28),
              const SizedBox(height: 8),
              Text(item['label'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiskCard(BuildContext context) {
    final risks = ['Overweight or Obesity', 'Lack of regular exercise', 'Family history', 'High blood pressure'];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        children: risks.map((risk) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warning),
              const SizedBox(width: 16),
              Text(risk, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildLearnMoreButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _launchURL,
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text('WHO FACT SHEET'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}
