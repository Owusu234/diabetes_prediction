import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'homepage.dart';
import 'drawer/app_theme.dart';

class NetworkChecker extends StatefulWidget {
  const NetworkChecker({super.key});

  @override
  _NetworkCheckerState createState() => _NetworkCheckerState();
}

class _NetworkCheckerState extends State<NetworkChecker> {
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isOffline = false;
  Timer? _timer;
  String _dots = '';

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
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

  Future<void> _checkInitialConnectivity() async {
    ConnectivityResult result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    if (!mounted) {
      return;
    }

    if (result == ConnectivityResult.none) {
      if (!_isOffline) {
        setState(() {
          _isOffline = true;
        });
      }
    } else {
      if (ModalRoute.of(context)?.isCurrent == true) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.gradientStart, theme.gradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: _isOffline
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Checking internet connection',
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
                )
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
