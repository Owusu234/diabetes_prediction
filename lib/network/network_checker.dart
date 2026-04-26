import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../welcome_screen.dart';

class NetworkChecker extends StatefulWidget {
  const NetworkChecker({super.key});

  @override
  _NetworkCheckerState createState() => _NetworkCheckerState();
}

class _NetworkCheckerState extends State<NetworkChecker> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _isOffline = true;
      });
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const WelcomeScreen())
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isOffline
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.signal_wifi_off, size: 64),
                  const SizedBox(height: 16),
                  const Text('You are currently offline.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _checkConnectivity,
                    child: const Text('Retry'),
                  ),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
