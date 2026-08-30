import 'package:flutter/material.dart';
import '../../services/ai_service.dart';

class AITestScreen extends StatefulWidget {
  const AITestScreen({super.key});

  @override
  State<AITestScreen> createState() => _AITestScreenState();
}

class _AITestScreenState extends State<AITestScreen> {
  String result = 'Press the button to test Gemini.';
  bool loading = false;

  Future<void> testGemini() async {
    setState(() {
      loading = true;
      result = 'AI is analyzing...';
    });

    try {
      final response = await AIService().testAI();

      if (!mounted) return;

      setState(() {
        result = response;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        result = 'AI ERROR:\n$e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Connection Test'),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.psychology,
                size: 80,
                color: Colors.blue,
              ),

              const SizedBox(height: 25),

              Text(
                result,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton.icon(
                  onPressed: loading ? null : testGemini,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(
                    loading
                        ? 'Testing AI...'
                        : 'Test Real Gemini AI',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}