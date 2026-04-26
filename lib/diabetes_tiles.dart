import 'package:flutter/material.dart';
import 'drawer/app_theme.dart';

class DiabetesTile extends StatelessWidget {
  const DiabetesTile({
    super.key,
    required this.icon,
    required this.text,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;

    return InkWell(
      onTap: onTap,
      child: Card(
        color: theme.tileBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.tileBorderColor, width: 1.5),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 50.0, color: theme.tileTextColor),
              const SizedBox(height: 10.0),
              Text(text, style: TextStyle(color: theme.tileTextColor)),
            ],
          ),
        ),
      ),
    );
  }
}
