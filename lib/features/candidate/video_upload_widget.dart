import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'candidate_service.dart';

class VideoUploadWidget extends StatefulWidget {
  final int candidateProfileId;
  final VoidCallback onUploadComplete;

  const VideoUploadWidget({
    super.key,
    required this.candidateProfileId,
    required this.onUploadComplete,
  });

  @override
  State<VideoUploadWidget> createState() => _VideoUploadWidgetState();
}

class _VideoUploadWidgetState extends State<VideoUploadWidget> {
  final _picker = ImagePicker();
  final _candidateService = CandidateService();

  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _error;

  Future<void> _pickAndUpload(ImageSource source) async {
    final permission = source == ImageSource.camera
        ? Permission.camera
        : Permission.photos;

    final status = await permission.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              source == ImageSource.camera
                  ? 'Přístup ke kameře byl odepřen'
                  : 'Přístup k fotkám byl odepřen',
            ),
          ),
        );
      }
      return;
    }

    final video = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 10),
    );
    if (video == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _error = null;
    });

    try {
      await _candidateService.uploadVideoCV(
        candidateProfileId: widget.candidateProfileId,
        videoPath: video.path,
        onProgress: (sent, total) {
          if (total > 0 && mounted) {
            setState(() => _uploadProgress = sent / total);
          }
        },
      );
      if (mounted) {
        widget.onUploadComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Upload selhal. Zkuste to znovu.');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Nahrát z kamery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Vybrat z galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isUploading) {
      return Column(
        children: [
          const Text(
            'Nahrávám video...',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: _uploadProgress),
          const SizedBox(height: 8),
          Text('${(_uploadProgress * 100).toStringAsFixed(0)} %'),
        ],
      );
    }

    return Column(
      children: [
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
        ElevatedButton.icon(
          onPressed: _showSourcePicker,
          icon: const Icon(Icons.upload_file),
          label: const Text('Nahrát video CV'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
      ],
    );
  }
}
