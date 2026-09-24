// English Comment: Main entry point for the Flutter application initializing Supabase services.
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // English Comment: Initialize Supabase client with project configuration.
  await Supabase.initialize(
    url: 'https://vnnnhwalzqgwitlrqyxc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubm5od2FsenFnd2l0bHJxeXhjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAyMjQzMjgsImV4cCI6MjEwNTgwMDMyOH0.LU5DJHCwNEWdao7O-RPd9xCjyyyQ7aAkBvscFrk53nY',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSE IT Job Prep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SubjectListScreen(),
    );
  }
}

// English Comment: Screen for displaying unique subjects retrieved from the database.
class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<String> _subjects = [];

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  // English Comment: Fetch unique subject list from the lecture_materials table.
  Future<void> _fetchSubjects() async {
    try {
      final response = await _supabase
          .from('lecture_materials')
          .select('subject');

      final List<dynamic> data = response as List<dynamic>;
      final Set<String> uniqueSubjects = data
          .map((item) => item['subject'] as String)
          .toSet();

      setState(() {
        _subjects = uniqueSubjects.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subjects: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CSE/IT Subjects'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? const Center(child: Text('No subjects found.'))
              : ListView.builder(
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final subject = _subjects[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.book, color: Colors.deepPurple),
                        title: Text(
                          subject,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LectureListScreen(subjectName: subject),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

// English Comment: Screen for displaying lecture topics for a specific subject.
class LectureListScreen extends StatefulWidget {
  final String subjectName;
  const LectureListScreen({super.key, required this.subjectName});

  @override
  State<LectureListScreen> createState() => _LectureListScreenState();
}

class _LectureListScreenState extends State<LectureListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _lectures = [];

  @override
  void initState() {
    super.initState();
    _fetchLectures();
  }

  // English Comment: Retrieve all lecture items matching the selected subject.
  Future<void> _fetchLectures() async {
    try {
      final response = await _supabase
          .from('lecture_materials')
          .select()
          .eq('subject', widget.subjectName);

      setState(() {
        _lectures = List<Map<String, dynamic>>.from(response as List);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading lectures: $e')),
        );
      }
    }
  }

  // English Comment: Directly launch PDF URL in external browser or system viewer
  Future<void> _openPdfDirectly(String pdfUrl) async {
    final Uri url = Uri.parse(pdfUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open PDF URL')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lectures.isEmpty
              ? const Center(child: Text('No lectures available for this subject.'))
              : ListView.builder(
                  itemCount: _lectures.length,
                  itemBuilder: (context, index) {
                    final lecture = _lectures[index];
                    final String? youtubeVideoId = lecture['youtube_video_id'];
                    final String? pdfUrl = lecture['pdf_url'];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(
                          lecture['title'] ?? 'Untitled Lecture',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Row(
                          children: [
                            if (youtubeVideoId != null && youtubeVideoId.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VideoPlayerScreen(
                                          title: lecture['title'] ?? 'Lecture Video',
                                          youtubeVideoId: youtubeVideoId,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.play_circle_fill, size: 18),
                                  label: const Text('Watch Video'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: ElevatedButton.icon(
                          onPressed: () {
                            if (pdfUrl != null && pdfUrl.isNotEmpty) {
                              if (kIsWeb) {
                                _openPdfDirectly(pdfUrl);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PdfViewerScreen(
                                      title: lecture['title'] ?? 'PDF Document',
                                      pdfUrl: pdfUrl,
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: const Text('PDF'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// English Comment: Screen for playing YouTube videos in-app with controlled height for large screens.
class VideoPlayerScreen extends StatefulWidget {
  final String title;
  final String youtubeVideoId;

  const VideoPlayerScreen({
    super.key,
    required this.title,
    required this.youtubeVideoId,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    // English Comment: Initialize YoutubePlayerController with iframe support
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.youtubeVideoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );
  }

  // English Comment: Redirect to external YouTube app or web link
  Future<void> _openInYouTubeApp() async {
    final Uri url = Uri.parse('https://www.youtube.com/watch?v=${widget.youtubeVideoId}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('YouTube could not be opened')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // English Comment: Top action button for direct access on large screens.
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _openInYouTubeApp,
            tooltip: 'Open / Save in YouTube',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          child: Column(
            children: [
              // English Comment: Constrain player height on large desktop views.
              Container(
                constraints: BoxConstraints(
                  maxHeight: screenHeight * 0.7,
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: YoutubePlayer(
                    controller: _controller,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _openInYouTubeApp,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open / Save in YouTube'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// English Comment: PDF Viewer Screen supporting local downloading and offline reading on Mobile devices.
class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String pdfUrl;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.pdfUrl,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localFilePath;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _checkExistingPdf();
    }
  }

  // English Comment: Check if PDF file is already stored in local directory.
  Future<void> _checkExistingPdf() async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = widget.pdfUrl.split('/').last;
    final file = File('${dir.path}/$fileName');

    if (await file.exists()) {
      setState(() {
        _localFilePath = file.path;
      });
    }
  }

  // English Comment: Download PDF file to local device storage.
  Future<void> _downloadPdf() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = widget.pdfUrl.split('/').last;
      final filePath = '${dir.path}/$fileName';

      Dio dio = Dio();
      await dio.download(
        widget.pdfUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      setState(() {
        _localFilePath = filePath;
        _isDownloading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF downloaded successfully for offline view!')),
        );
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_localFilePath == null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _isDownloading ? null : _downloadPdf,
              tooltip: 'Download PDF for Offline',
            )
          else
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(Icons.check_circle, color: Colors.green),
            ),
        ],
      ),
      body: _isDownloading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(value: _downloadProgress),
                  const SizedBox(height: 16),
                  Text('Downloading PDF: ${(_downloadProgress * 100).toStringAsFixed(0)}%'),
                ],
              ),
            )
          : _localFilePath != null
              ? PDFView(filePath: _localFilePath!)
              : const Center(
                  child: Text('Click the download button top right to save and view offline.'),
                ),
    );
  }
}