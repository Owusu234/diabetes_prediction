import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

import 'drawer/app_theme.dart';

class StepCounter extends StatefulWidget {
  const StepCounter({super.key});

  @override
  _StepCounterState createState() => _StepCounterState();
}

class _StepCounterState extends State<StepCounter> {
  late Stream<StepCount> _stepCountStream;
  String _steps = '0';
  int? _initialSteps;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  void onStepCount(StepCount event) {
    if (!mounted) return;

    _initialSteps ??= event.steps;

    int sessionSteps = event.steps - _initialSteps!;

    setState(() {
      _steps = sessionSteps.toString();
    });
  }

  void onStepCountError(error) {
    print('onStepCountError: $error');
    setState(() {
      _steps = 'N/A';
    });
  }

  void initPlatformState() async {
    if (await Permission.activityRecognition.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream.listen(onStepCount).onError(onStepCountError);
    } else {
      setState(() {
        _steps = "Perm. denied";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.tileBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.tileBorderColor, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.directions_walk, color: theme.tileTextColor),
          const SizedBox(height: 8.0),
          Text('Steps', style: TextStyle(color: theme.tileTextColor, fontSize: 16.0)),
          Text(_steps, style: TextStyle(color: theme.tileTextColor, fontSize: 24.0, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
