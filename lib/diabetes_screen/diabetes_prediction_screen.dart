import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import '../const/colors.dart';
import '../const/diabetes_doodle_painter.dart';
import '../drawer/app_theme.dart';
import '../health_log/database_helper.dart';

class DiabetesPredictionScreen extends StatefulWidget {
  const DiabetesPredictionScreen({super.key});

  @override
  _DiabetesPredictionScreenState createState() => _DiabetesPredictionScreenState();
}

class _DiabetesPredictionScreenState extends State<DiabetesPredictionScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPredicting = false;

  final TextEditingController _pregnanciesController = TextEditingController();
  final TextEditingController _glucoseController = TextEditingController();
  final TextEditingController _bloodPressureController = TextEditingController();
  final TextEditingController _skinThicknessController = TextEditingController();
  final TextEditingController _insulinController = TextEditingController();
  final TextEditingController _bmiController = TextEditingController();
  final TextEditingController _pedigreeController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  @override
  void dispose() {
    _pregnanciesController.dispose();
    _glucoseController.dispose();
    _bloodPressureController.dispose();
    _skinThicknessController.dispose();
    _insulinController.dispose();
    _bmiController.dispose();
    _pedigreeController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _clearInputs() {
    _pregnanciesController.clear();
    _glucoseController.clear();
    _bloodPressureController.clear();
    _skinThicknessController.clear();
    _insulinController.clear();
    _bmiController.clear();
    _pedigreeController.clear();
    _ageController.clear();
  }

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPredicting = true);

    String apiUrl = dotenv.env['API_URL'] ?? '';
    final String apiKey = dotenv.env['API_KEY'] ?? ''; 
    
    apiUrl = apiUrl.trim();
    if (apiUrl.isNotEmpty && !apiUrl.endsWith('/predict')) {
      apiUrl = apiUrl.endsWith('/') ? '${apiUrl}predict' : '$apiUrl/predict';
    }

    final Map<String, dynamic> data = {
      "Pregnancies": int.tryParse(_pregnanciesController.text) ?? 0,
      "Glucose": int.tryParse(_glucoseController.text) ?? 0,
      "BloodPressure": int.tryParse(_bloodPressureController.text) ?? 0,
      "SkinThickness": int.tryParse(_skinThicknessController.text) ?? 0,
      "Insulin": int.tryParse(_insulinController.text) ?? 0,
      "BMI": double.tryParse(_bmiController.text) ?? 0.0,
      "DiabetesPedigreeFunction": double.tryParse(_pedigreeController.text) ?? 0.0,
      "Age": int.tryParse(_ageController.text) ?? 0,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          if (apiKey.isNotEmpty) "X-API-Key": apiKey,
          if (apiKey.isNotEmpty) "Authorization": "Bearer $apiKey",
        }, 
        body: json.encode(data),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        String predictionValue = result['prediction']?.toString() ?? result['result']?.toString() ?? 'Unknown';
        bool isDiabetic = predictionValue == "1";
        String outcome = isDiabetic ? "Diabetic" : "Non-Diabetic";
        
        String probability = result['probability']?.toString() ?? 'N/A';
        String confidence = result['confidence']?.toString() ?? 'N/A';
        String diagnosis = result['diagnosis']?.toString() ?? 'N/A';
        String riskLevel = result['risk_level']?.toString() ?? 'N/A';

        _showResultDialog(
          outcome: outcome,
          probability: probability,
          confidence: confidence,
          isDiabetic: isDiabetic,
          diagnosis: diagnosis,
          riskLevel: riskLevel,
        ); 
        _clearInputs();
      } else {
        _showErrorDialog("Unable to connect to the prediction service. Please try again later.");
      }
    } on SocketException catch (_) {
      _showErrorDialog("No internet connection or server is unreachable. Please check your network.");
    } on http.ClientException catch (_) {
      _showErrorDialog("A network error occurred while connecting to the server. Please try again.");
    } on TimeoutException catch (_) {
       _showErrorDialog("The prediction service is taking too long to respond. Please try again.");
    } catch (e) {
      _showErrorDialog("Something went wrong. Please check your inputs and try again.");
    } finally {
      if (mounted) setState(() => _isPredicting = false);
    }
  }

  Future<void> _savePrediction(String outcome, String probability, String confidence, String diagnosis, String riskLevel) async {
    await DatabaseHelper().insertPrediction({
      'date': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      'outcome': outcome,
      'probability': probability,
      'confidence': confidence,
      'diagnosis': diagnosis,
      'risk_level': riskLevel,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prediction saved to Health Log.')));
    }
  }

  void _showResultDialog({
    required String outcome,
    required String probability,
    required String confidence,
    required bool isDiabetic,
    required String diagnosis,
    required String riskLevel,
  }) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: theme.tileBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.tileBorderColor, width: 1.5),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDiabetic ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                  color: isDiabetic ? Colors.redAccent : Colors.greenAccent,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Prediction Result',
                  style: TextStyle(color: theme.bodyTextColor.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  outcome,
                  style: TextStyle(color: isDiabetic ? Colors.redAccent : Colors.greenAccent, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildMetricRow('Probability', probability, theme),
                const SizedBox(height: 10),
                _buildMetricRow('Confidence', confidence, theme),
                const SizedBox(height: 10),
                _buildMetricRow('Risk Level', riskLevel, theme),
                const SizedBox(height: 20),
                
                // Explanation Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDiabetic ? Colors.red : Colors.green).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (isDiabetic ? Colors.red : Colors.green).withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What this means',
                        style: TextStyle(
                          color: isDiabetic ? Colors.redAccent : Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Based on the clinical parameters provided, the diagnostic assessment suggests a status of $outcome with a risk level classified as $riskLevel. '
                        'The high confidence level of this assessment underscores its relevance.'
                        'Please consult with a qualified healthcare professional for a formal medical evaluation.',
                        style: TextStyle(
                          color: theme.bodyTextColor.withOpacity(0.8),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                const Divider(color: Colors.white24),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Caution: This is a risk assessment and not a medical diagnosis.',
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.orange.shade300, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Exit', style: TextStyle(color: theme.bodyTextColor.withOpacity(0.6))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _savePrediction(outcome, probability, confidence, diagnosis, riskLevel);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Result'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, AppThemeExtension theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.bodyTextColor.withOpacity(0.6), fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value, 
            style: TextStyle(color: theme.bodyTextColor, fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prediction Status'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: theme.tileBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.tileBorderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Field Information',
                    style: TextStyle(
                      color: theme.bodyTextColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildInfoItem(Icons.pregnant_woman_rounded, 'Pregnancies', 'Number of times pregnant.', theme),
                      _buildInfoItem(Icons.bloodtype_rounded, 'Glucose', 'Plasma glucose concentration.', theme),
                      _buildInfoItem(Icons.monitor_heart_rounded, 'Blood Pressure', 'Diastolic blood pressure (mm Hg).', theme),
                      _buildInfoItem(Icons.layers_rounded, 'Skin Thickness', 'Triceps skin fold thickness (mm).', theme),
                      _buildInfoItem(Icons.vaccines_rounded, 'Insulin', '2-Hour serum insulin (mu U/ml).', theme),
                      _buildInfoItem(Icons.fitness_center_rounded, 'BMI', 'Body Mass Index.', theme),
                      _buildInfoItem(Icons.family_restroom_rounded, 'Pedigree Function', 'Scores likelihood based on family history.', theme),
                      _buildInfoItem(Icons.calendar_month_rounded, 'Age', 'Age in years.', theme),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Got it', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description, AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary.withOpacity(0.7), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.bodyTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: theme.bodyTextColor.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diabetes Predict'),
        backgroundColor: theme.gradientStart,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.bodyTextColor),
        titleTextStyle: TextStyle(color: theme.bodyTextColor, fontSize: 20, fontWeight: FontWeight.bold),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'Field Information',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.gradientStart, theme.gradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: DiabetesDoodlePainter(iconColor: theme.bodyTextColor.withOpacity(0.05)),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildTextField(label: 'Pregnancies', hint: 'e.g., 6', controller: _pregnanciesController),
                    _buildTextField(label: 'Glucose', hint: 'e.g., 148', controller: _glucoseController),
                    _buildTextField(label: 'Blood Pressure', hint: 'e.g., 72', controller: _bloodPressureController),
                    _buildTextField(label: 'Skin Thickness', hint: 'e.g., 35', controller: _skinThicknessController),
                    _buildTextField(label: 'Insulin', hint: 'e.g., 0', controller: _insulinController),
                    _buildTextField(label: 'BMI', hint: 'e.g., 33.6', controller: _bmiController),
                    _buildTextField(label: 'Diabetes Pedigree Function', hint: 'e.g., 0.627', controller: _pedigreeController),
                    _buildTextField(label: 'Age', hint: 'e.g., 50', controller: _ageController),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isPredicting ? null : _predict,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Predict Risk Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            if (_isPredicting)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 20),
                      const Text(
                        'Processing prediction...',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                        child: Text(
                          'Your health parameters are being analyzed. This may take a moment.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required String hint, required TextEditingController controller}) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: theme.bodyTextColor),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: theme.tileBackground.withOpacity(0.5),
          labelStyle: TextStyle(color: theme.bodyTextColor.withOpacity(0.7)),
          hintStyle: TextStyle(color: theme.bodyTextColor.withOpacity(0.3)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.tileBorderColor.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter a value';
          if (double.tryParse(value) == null) return 'Please enter a valid number';
          return null;
        },
      ),
    );
  }
}
