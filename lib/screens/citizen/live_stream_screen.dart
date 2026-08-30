import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({super.key});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  final _picker = ImagePicker();
  File? _video;
  bool _starting = false;

  Future<void> _pickVideo(ImageSource source) async {
    final file = await _picker.pickVideo(source: source, maxDuration: const Duration(minutes: 2));
    if (file == null || !mounted) return;
    setState(() => _video = File(file.path));
  }

  Future<void> _startLiveStream() async {
    if (_video == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record or choose a video first.')),
      );
      return;
    }
    setState(() => _starting = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _starting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Streaming service will be connected in the backend phase.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Live Stream'),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('Share live incident evidence', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Only record when it is safe. Do not put yourself at risk.'),
          const SizedBox(height: 20),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: _video == null
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam_off_outlined, color: Colors.white70, size: 55),
                        SizedBox(height: 10),
                        Text('No video selected', style: TextStyle(color: Colors.white70)),
                      ],
                    )
                  : const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.video_file_outlined, color: Colors.white, size: 55),
                        SizedBox(height: 10),
                        Text('Video ready to send', style: TextStyle(color: Colors.white)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickVideo(ImageSource.camera),
                  icon: const Icon(Icons.videocam_outlined),
                  label: const Text('Record'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickVideo(ImageSource.gallery),
                  icon: const Icon(Icons.video_library_outlined),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: Colors.red,
            ),
            onPressed: _starting ? null : _startLiveStream,
            icon: _starting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.live_tv_outlined),
            label: Text(_starting ? 'CONNECTING…' : 'START LIVE STREAM'),
          ),
        ],
      ),
    );
  }
}
