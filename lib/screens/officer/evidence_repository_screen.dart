import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'flood_image_screen.dart';
import 'rescue_video_screen.dart';
import 'incident_report_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';

class EvidenceRepositoryScreen extends StatefulWidget {
  const EvidenceRepositoryScreen({super.key});

  @override
  State<EvidenceRepositoryScreen> createState() =>
      _EvidenceRepositoryScreenState();
}

class _EvidenceRepositoryScreenState
    extends State<EvidenceRepositoryScreen> {

  bool isUploading = false;
  final TextEditingController searchController =
    TextEditingController();

String selectedFileType = 'All';

  Future<void> uploadEvidence() async {
  if (isUploading) return;

  setState(() {
    isUploading = true;
  });

  try {
    final result = await FilePicker.pickFiles(
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) {
      return;
    }

    final pickedFile = result.files.single;
    final fileBytes = pickedFile.bytes!;

    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      throw Exception('Please log in again.');
    }

    final firebaseToken = await firebaseUser.getIdToken();

    if (firebaseToken == null || firebaseToken.isEmpty) {
      throw Exception('Unable to verify your login session.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        'https://cdkwzxjneqxsroswkqtc.supabase.co/functions/v1/upload-evidence',
      ),
    );

    request.headers['Authorization'] = 'Bearer $firebaseToken';

    String contentType = 'application/octet-stream';

    switch (pickedFile.extension?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        contentType = 'image/jpeg';
        break;

      case 'png':
        contentType = 'image/png';
        break;

      case 'webp':
        contentType = 'image/webp';
        break;

      case 'mp4':
        contentType = 'video/mp4';
        break;

      case 'mov':
        contentType = 'video/quicktime';
        break;

      case 'pdf':
        contentType = 'application/pdf';
        break;
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: pickedFile.name,
        contentType: MediaType.parse(contentType),
      ),
    );

    final streamedResponse = await request.send();

    final responseBody =
        await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode != 200) {
      throw Exception(
        'HTTP ${streamedResponse.statusCode}: $responseBody',
      );
    }

    final responseData = jsonDecode(responseBody);

    final storagePath =
        responseData['storagePath']?.toString();

    final downloadUrl =
        responseData['downloadUrl']?.toString();

    if (storagePath == null ||
        storagePath.isEmpty ||
        downloadUrl == null ||
        downloadUrl.isEmpty) {
      throw Exception('Invalid response from upload server.');
    }

    await FirebaseFirestore.instance
        .collection('evidence_repository')
        .add({
      'name': pickedFile.name,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'fileType': pickedFile.extension ?? 'unknown',
      'uploadedBy': firebaseUser.uid,
      'uploadedAt': Timestamp.now(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Evidence uploaded successfully'),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      'Upload failed: ${e.toString()}',
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
    ),
  ),
);
  } finally {
    if (mounted) {
      setState(() {
        isUploading = false;
      });
    }
  }
}
Future<void> deleteEvidence(
  String documentId,
  String storagePath,
) async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please log in again.');
    }

    final token = await user.getIdToken();

    final response = await http.post(
      Uri.parse(
        'https://cdkwzxjneqxsroswkqtc.supabase.co/functions/v1/delete-evidence',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'storagePath': storagePath,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Supabase delete failed: ${response.body}',
      );
    }

    await FirebaseFirestore.instance
        .collection('evidence_repository')
        .doc(documentId)
        .delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Evidence deleted successfully'),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Delete failed: $e'),
      ),
    );
  }
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF5F7FA),
    appBar: AppBar(
      title: const Text("Evidence Repository"),
      backgroundColor: const Color(0xFF0B3D91),
      foregroundColor: Colors.white,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
  controller: searchController,
  decoration: InputDecoration(
    hintText: 'Search evidence...',
    prefixIcon: const Icon(Icons.search),
    suffixIcon: IconButton(
      icon: Icon(Icons.clear),
      onPressed: () {
        searchController.clear();
        setState(() {});
      },
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  onChanged: (_) {
    setState(() {});
  },
),

const SizedBox(height: 10),

DropdownButtonFormField<String>(
  value: selectedFileType,
  decoration: InputDecoration(
    labelText: 'Filter by file type',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  items: const [
    DropdownMenuItem(
      value: 'All',
      child: Text('All files'),
    ),
    DropdownMenuItem(
      value: 'Image',
      child: Text('Images'),
    ),
    DropdownMenuItem(
      value: 'Video',
      child: Text('Videos'),
    ),
    DropdownMenuItem(
      value: 'PDF',
      child: Text('PDF files'),
    ),
  ],
  onChanged: (value) {
    setState(() {
      selectedFileType = value ?? 'All';
    });
  },
),

const SizedBox(height: 15),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('evidence_repository')
                  .orderBy('uploadedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading evidence: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

final allEvidenceDocs = snapshot.data?.docs ?? [];

final searchText = searchController.text.toLowerCase();

final evidenceDocs = allEvidenceDocs.where((doc) {
  final data = doc.data() as Map<String, dynamic>;

  final name = data['name']?.toString().toLowerCase() ?? '';
  final fileType = data['fileType']?.toString().toLowerCase() ?? '';

  final matchesSearch =
      name.contains(searchText);

  final matchesType =
      selectedFileType == 'All' ||
      (selectedFileType == 'Image' &&
          ['jpg', 'jpeg', 'png', 'gif', 'webp']
              .contains(fileType)) ||
      (selectedFileType == 'Video' &&
          ['mp4', 'mov', 'avi', 'mkv']
              .contains(fileType)) ||
      (selectedFileType == 'PDF' &&
          fileType == 'pdf');

  return matchesSearch && matchesType;
}).toList();

               if (evidenceDocs.isEmpty) {
  return Center(
    child: Text(
      searchText.isNotEmpty || selectedFileType != 'All'
          ? 'No matching evidence found'
          : 'No evidence uploaded yet',
      style: const TextStyle(fontSize: 16),
    ),
  );
}

                return ListView.builder(
                  itemCount: evidenceDocs.length,
                  itemBuilder: (context, index) {
                    final doc = evidenceDocs[index];
                    final data =
                        doc.data() as Map<String, dynamic>;

                    final fileName =
                        data['name']?.toString() ?? 'Unknown file';

                    final fileType =
                        data['fileType']?.toString() ?? 'unknown';

                    IconData fileIcon =
                        Icons.insert_drive_file;
                    Color iconColor = Colors.grey;

                    if ([
                      'jpg',
                      'jpeg',
                      'png',
                      'gif',
                      'webp',
                    ].contains(fileType.toLowerCase())) {
                      fileIcon = Icons.image;
                      iconColor = Colors.red;
                    } else if ([
                      'mp4',
                      'mov',
                      'avi',
                      'mkv',
                    ].contains(fileType.toLowerCase())) {
                      fileIcon = Icons.videocam;
                      iconColor = Colors.blue;
                    } else if ([
                      'pdf',
                      'doc',
                      'docx',
                      'txt',
                    ].contains(fileType.toLowerCase())) {
                      fileIcon = Icons.description;
                      iconColor = Colors.green;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: iconColor,
                          child: Icon(
                            fileIcon,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Type: ${fileType.toUpperCase()}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.visibility,
                                color: Colors.blue,
                              ),
                              tooltip: 'Preview evidence',
                              onPressed: () {
                                final url =
                                    data['downloadUrl']?.toString();

                                if (url == null || url.isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Evidence URL not available',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      final lowerType =
                                          fileType.toLowerCase();

                                      if (lowerType == 'mp4' ||
                                          lowerType == 'mov') {
                                        return VideoPreviewScreen(
                                          url: url,
                                          fileName: fileName,
                                        );
                                      }

                                      return Scaffold(
                                        appBar: AppBar(
                                          title: Text(fileName),
                                          backgroundColor:
                                              const Color(0xFF0B3D91),
                                          foregroundColor:
                                              Colors.white,
                                        ),
                                        body: Center(
                                          child: lowerType == 'pdf'
                                              ? SfPdfViewer.network(url)
                                              : Image.network(
                                                  url,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return const Text(
                                                      'Unable to display this evidence',
                                                    );
                                                  },
                                                  loadingBuilder: (
                                                    context,
                                                    child,
                                                    loadingProgress,
                                                  ) {
                                                    if (loadingProgress ==
                                                        null) {
                                                      return child;
                                                    }

                                                    return const CircularProgressIndicator();
                                                  },
                                                ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              tooltip: 'Delete evidence',
                              onPressed: () async {
  final storagePath =
      data['storagePath']?.toString();

  if (storagePath == null || storagePath.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Storage path not available'),
      ),
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete evidence?'),
        content: Text(
          'Are you sure you want to delete "$fileName"?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;

  await deleteEvidence(
    doc.id,
    storagePath,
  );
},
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
                    const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: FilledButton.icon(
              onPressed: isUploading ? null : uploadEvidence,
              icon: isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(
                isUploading
                    ? "Uploading..."
                    : "Upload Evidence",
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  
} // closes build()
@override
void dispose() {
  searchController.dispose();
  super.dispose();
}
} // closes _EvidenceRepositoryScreenState

class VideoPreviewScreen extends StatefulWidget {
  final String url;
  final String fileName;

  const VideoPreviewScreen({
    super.key,
    required this.url,
    required this.fileName,
  });

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
    )..initialize().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: _controller.value.isInitialized
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}