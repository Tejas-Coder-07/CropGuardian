import 'package:crop_guardian/Screens/diagnosis_screen/viewmodels/diagnosis_viewmodel.dart';
import 'package:crop_guardian/Screens/diagnosis_screen/widgets/image_picker_card.dart';
import 'package:crop_guardian/Screens/diagnosis_screen/widgets/language_selector.dart';
import 'package:crop_guardian/responsive_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/diagnosis_model.dart';


class DiagnosisScreen extends StatelessWidget {
  const DiagnosisScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DiagnosisViewModel(),
      child: ResponsivePage(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.green[900],
           iconTheme: IconThemeData(color: Colors.white),
            centerTitle: true,
            title: Padding(
              padding: const EdgeInsets.only(top: 25.0),
              child: Column(
                children: [
                  const Text(
                    "AI Crop Diagnose",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Text("एआई-फसल निदान", style: TextStyle(color: Colors.white70, fontSize: 18)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // backgroundColor: Color(0xFF388E3C),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 25),
              child: Column(
                children: [
                  Consumer<DiagnosisViewModel>(
                    builder: (context, viewModel, child) {
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image Picker Card
                            ImagePickerCard(
                              selectedImage: viewModel.selectedImage,
                              onImageSelected: (image) => viewModel.setImage(image),
                            ),
            
                            // Description Input
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: viewModel.descriptionController,
                                        decoration: const InputDecoration(
                                          hintText: 'Describe crop issue (optional)',
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.all(16),
                                        ),
                                        maxLines: 3,
                                        onChanged: (value) => viewModel.setDescription(value),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        viewModel.isListening ? Icons.mic : Icons.mic_none,
                                        color: viewModel.isListening ? Colors.red : const Color(0xFF047857),
                                        size: 26,
                                      ),
                                      tooltip: 'Speak instead of typing',
                                      onPressed: () => viewModel.toggleListening(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
            
                            // Language Selector
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: LanguageSelector(
                                selectedLanguage: viewModel.selectedLanguage,
                                onLanguageChanged: (lang) => viewModel.setLanguage(lang),
                              ),
                            ),
            
                            const SizedBox(height: 16),
            
                            // Diagnose Button
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: ElevatedButton(
                                onPressed: viewModel.isLoading ? null : () => viewModel.performDiagnosis(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[900],
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: viewModel.isLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Text(
                                  'Diagnose Crop',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
            
                            // Error Message
                            if (viewModel.errorMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.red.shade700),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          viewModel.errorMessage,
                                          style: TextStyle(color: Colors.red.shade700),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
            
                            // Diagnosis Result
                            if (viewModel.hasResult && viewModel.diagnosis == null)
                              _buildOfflineResult(context, viewModel),


                            if (viewModel.diagnosis != null)
                              _buildDiagnosisResult(context, viewModel.diagnosis!, viewModel),
            
                            const SizedBox(height: 24),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineResult(BuildContext context, DiagnosisViewModel vm) {
    final conf = (vm.resultConfidence * 100).toStringAsFixed(0);
    final lowConfidence = vm.resultConfidence < 0.70;
    final healthy = vm.offlineResult?.isHealthy ?? false;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: lowConfidence ? Colors.orange : const Color(0xFF34D399),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF022C22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_android, size: 13, color: Color(0xFF34D399)),
                    SizedBox(width: 5),
                    Text('ON-DEVICE',
                        style: TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Spacer(),
              Text('$conf% confident',
                  style: TextStyle(
                      color: lowConfidence
                          ? Colors.orange.shade800
                          : Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          Text(vm.resultCrop,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(healthy ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: healthy ? Colors.green : Colors.orange, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(vm.resultTitle,
                    style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF022C22))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            healthy
                ? 'No disease detected. Keep monitoring your crop regularly.'
                : 'Detected offline in under a second, with no internet connection.',
            style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
          ),
          if (lowConfidence) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'I am not fully sure about this one. Connect to the internet and ask the expert model for a detailed answer.',
                style: TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: vm.isLoading ? null : () => vm.askExpertModel(),
              icon: vm.isEscalating
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_outlined, size: 18),
              label: Text(
                  vm.isEscalating ? 'Asking expert model...' : 'Ask expert model'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF047857),
                side: const BorderSide(color: Color(0xFF34D399)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          const Divider(height: 28),
          if (vm.feedbackGiven)
            const Row(
              children: [
                Icon(Icons.check_circle, size: 17, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Thank you. This helps improve the model for every farmer.',
                      style: TextStyle(fontSize: 12.5, color: Colors.black54)),
                ),
              ],
            )
          else ...[
            const Text('Was this correct?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => vm.submitFeedback(),
                    icon: const Icon(Icons.thumb_up_outlined, size: 16),
                    label: const Text('Correct'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      side: BorderSide(color: Colors.green.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _askCorrection(context, vm),
                    icon: const Icon(Icons.thumb_down_outlined, size: 16),
                    label: const Text('Wrong'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _askCorrection(BuildContext context, DiagnosisViewModel vm) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('What is it actually?'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g. Late blight',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              vm.submitFeedback(correctedLabel: controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisResult(
      BuildContext context,
      DiagnosisModel diagnosis,
      DiagnosisViewModel viewModel,
      ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with TTS control
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Diagnosis Result',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      viewModel.isSpeaking ? Icons.stop_circle : Icons.volume_up,
                      color: Colors.green,
                    ),
                    onPressed: () => viewModel.toggleSpeech(),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Crop Type
                  _buildInfoRow(Icons.agriculture, 'Crop Type', diagnosis.cropType),
                  const Divider(),

                  // Detected Issue
                  _buildInfoRow(Icons.warning_amber, 'Issue', diagnosis.detectedIssue),
                  const Divider(),

                  // Severity
                  _buildSeverityRow(diagnosis.severity),
                  const Divider(),

                  // confidenceScore
                  _buildConfidenceRow(diagnosis.confidenceScore),
                  const Divider(),

                  // Description
                  const SizedBox(height: 12),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    diagnosis.description,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),

                  // Symptoms
                  if (diagnosis.symptoms.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Symptoms',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...diagnosis.symptoms.map(
                          (symptom) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 16)),
                            Expanded(child: Text(symptom)),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Solutions
                  if (diagnosis.solutions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Solutions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...diagnosis.solutions.asMap().entries.map(
                          (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(entry.value)),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Preventive Measures
                  if (diagnosis.preventiveMeasures.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Preventive Measures',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...diagnosis.preventiveMeasures.map(
                          (measure) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(child: Text(measure)),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Pesticide Measures
                  if (diagnosis.recommendedPesticides.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Pesticide',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...diagnosis.recommendedPesticides.map(
                          (measure) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle,
                                size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(child: Text(measure)),
                          ],

                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeverityRow(String severity) {
    Color severityColor;
    switch (severity.toLowerCase()) {
      case 'low':
        severityColor = Colors.green;
        break;
      case 'medium':
        severityColor = Colors.orange;
        break;
      case 'high':
      case 'critical':
        severityColor = Colors.red;
        break;
      default:
        severityColor = Colors.grey;
    }

    return Row(
      children: [
        Icon(Icons.priority_high, color: severityColor, size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Severity',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                severity,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: severityColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Widget _buildConfidenceRow(double confidence) {
  // Convert 0.95 to 95%
  int percentage = (confidence * 100).toInt();

  // Color logic: Green for high confidence, Orange for medium
  Color scoreColor = percentage >= 80 ? Colors.blue.shade700 : Colors.orange.shade700;

  return Row(
    children: [
      Icon(Icons.verified_user_rounded, color: scoreColor, size: 24),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Confidence',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scoreColor.withOpacity(0.3)),
            ),
            child: Text(
              "$percentage%",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
