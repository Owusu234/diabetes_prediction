import 'package:flutter/material.dart';
import '../const/colors.dart';
import '../const/diabetes_doodle_painter.dart';

class DietPlanScreen extends StatelessWidget {
  const DietPlanScreen({super.key});

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
                    _buildIntroSection(),
                    const SizedBox(height: 32),
                    _buildPlateMethodSection(context),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Meal Recommendations'),
                    const SizedBox(height: 16),
                    _buildMealCategory(
                      context,
                      'Breakfast',
                      'Start your day with stable energy.',
                      Icons.wb_sunny_rounded,
                      Colors.orange,
                      [
                        _MealOption('Fiber-Rich Cereals', 'Roasted maize, millet, and soy bean blend.', ['1/2 cup blend', '1.5 cups water', 'Minimal soy milk', 'No added sugar']),
                        _MealOption('Green Plantain Mash', 'Boiled unripe plantain with proteins.', ['2 slices plantain', '1 boiled egg', 'Steamed Kontomire']),
                      ],
                    ),
                    _buildMealCategory(
                      context,
                      'Lunch',
                      'Balanced fuel for your afternoon.',
                      Icons.lunch_dining_rounded,
                      Colors.blue,
                      [
                        _MealOption('Lean Protein Stew', 'Root tuber with micronutrient density.', ['1-2 slices boiled yam', '1 cup fiber-rich stew', 'Grilled fish']),
                        _MealOption('Whole Grain Medley', 'Sustained energy release.', ['3/4 cup brown rice', 'Veggie-based stew', 'Lean skinless poultry']),
                      ],
                    ),
                    _buildMealCategory(
                      context,
                      'Dinner',
                      'Light and nourishing.',
                      Icons.nightlight_round,
                      Colors.indigo,
                      [
                        _MealOption('Light Broth & Staple', 'Tennis ball sized mash with aromatic soup.', ['1 portion cassava-plantain mash', '2 cups clear veggie broth', 'Steamed tilapia']),
                        _MealOption('Banku & Groundnut', 'Nutrient-dense legume infusion.', ['Small banku portion', '1.5 cups natural peanut soup', 'Grilled lean fish']),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildHydrationCard(context),
                    const SizedBox(height: 32),
                    _buildDisclaimer(),
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
        title: const Text('Nutritional Guide', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        background: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildIntroSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Balanced Nutrition', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(
                  'Focus on high-fiber and low-glycemic index foods for better glucose control.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlateMethodSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('The Healthy Plate Method'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              _buildPlateRow('1/2 Plate', 'Fiber-Rich Vegetables', Icons.eco_rounded, Colors.green),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
              _buildPlateRow('1/4 Plate', 'Lean Proteins', Icons.egg_alt_rounded, Colors.orange),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
              _buildPlateRow('1/4 Plate', 'Complex Carbohydrates', Icons.grain_rounded, Colors.blue),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlateRow(String portion, String label, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text(portion, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Icon(icon, color: color.withOpacity(0.5)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildMealCategory(BuildContext context, String title, String subtitle, IconData icon, Color color, List<_MealOption> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        ...options.map((opt) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
            collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
            leading: Icon(Icons.circle, color: color.withOpacity(0.2), size: 12),
            title: Text(opt.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(opt.desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              const Divider(),
              const SizedBox(height: 12),
              const Text('Suggested Ingredients:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              ...opt.ingredients.map((ing) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 14, color: color),
                    const SizedBox(width: 8),
                    Text(ing, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              )).toList(),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildHydrationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.water_drop_rounded, color: Colors.blue),
              SizedBox(width: 12),
              Text('Smart Hydration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Prioritize plain water. Hibiscus tea (without sugar) or citrus-infused water are great alternatives to processed drinks.',
            style: TextStyle(color: Colors.blue.shade900.withOpacity(0.7), fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: Colors.grey),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Requirements vary by individual. Starchy staples should be consumed in moderation. Consult a health professional for a personalized plan.',
              style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealOption {
  final String name;
  final String desc;
  final List<String> ingredients;
  _MealOption(this.name, this.desc, this.ingredients);
}
