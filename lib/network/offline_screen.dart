import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../drawer/app_theme.dart';

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});

  @override
  _OfflineScreenState createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  Timer? _timer;
  String _dots = '';

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    _startDotsAnimation();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _startDotsAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return;
      setState(() {
        _dots = (_dots.length < 3) ? '$_dots.' : '';
      });
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    if (!mounted) {
      return;
    }
    if (result != ConnectivityResult.none) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.gradientStart, theme.gradientEnd],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Checking Connection',
                  style: TextStyle(fontSize: 18, color: theme.bodyTextColor),
                ),
                SizedBox(
                  width: 25,
                  child: Text(
                    _dots,
                    style: TextStyle(fontSize: 18, color: theme.bodyTextColor),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
