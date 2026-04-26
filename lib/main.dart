import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'network/network_checker.dart';
import 'drawer/app_theme.dart';
import 'drawer/theme_provider.dart';
import 'profile_manager.dart';
import 'const/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  final profileManager = ProfileManager();
  await profileManager.loadProfiles();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: profileManager),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Diabetes Predict',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
              surface: AppColors.surfaceLight,
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              onSurface: AppColors.textPrimaryLight,
            ),
            scaffoldBackgroundColor: AppColors.backgroundLight,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.surfaceLight,
              foregroundColor: AppColors.textPrimaryLight,
              elevation: 0,
              centerTitle: true,
            ),
            cardTheme: CardThemeData(
              color: AppColors.surfaceLight,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            extensions: const <ThemeExtension<dynamic>>[
              AppThemeExtension(
                gradientStart: Color(0xFFE3F2FD),
                gradientEnd: Color(0xFFFFFFFF),
                tileBackground: AppColors.surfaceLight,
                bodyTextColor: AppColors.textPrimaryLight,
                tileTextColor: AppColors.textPrimaryLight,
                tileBorderColor: Color(0xFFE2E8F0),
              ),
            ],
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.dark,
              surface: AppColors.surfaceDark,
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              onSurface: AppColors.textPrimaryDark,
            ),
            scaffoldBackgroundColor: AppColors.backgroundDark,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.surfaceDark,
              foregroundColor: AppColors.textPrimaryDark,
              elevation: 0,
              centerTitle: true,
            ),
            cardTheme: CardThemeData(
              color: AppColors.surfaceDark,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFF334155)),
              ),
            ),
            extensions: const <ThemeExtension<dynamic>>[
              AppThemeExtension(
                gradientStart: Color(0xFF1E293B),
                gradientEnd: Color(0xFF0F172A),
                tileBackground: AppColors.surfaceDark,
                bodyTextColor: AppColors.textPrimaryDark,
                tileTextColor: AppColors.textPrimaryDark,
                tileBorderColor: Color(0xFF334155),
              ),
            ],
          ),
          themeMode: themeProvider.themeMode,
          home: const NetworkChecker(),
        );
      },
    );
  }
}
