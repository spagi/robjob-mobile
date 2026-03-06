import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_service.dart';
import 'candidate_service.dart';
import 'video_cv_player.dart';
import 'video_upload_widget.dart';

class VideoCVScreen extends StatefulWidget {
  const VideoCVScreen({super.key});

  @override
  State<VideoCVScreen> createState() => _VideoCVScreenState();
}

class _VideoCVScreenState extends State<VideoCVScreen> {
  final _authService = AuthService();
  late final CandidateService _candidateService;

  CandidateProfile? _profile;
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _candidateService = CandidateService(
      onUnauthorized: () {
        if (mounted) context.go('/login');
      },
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profileId = await _candidateService.fetchCandidateProfileId();
      final profile = await _candidateService.fetchCandidateProfile(profileId);

      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });

        // Start polling if video is processing
        if (profile.videoCV?.isProcessing == true) {
          _startPolling(profileId);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Nepodařilo se načíst profil. Zkuste to znovu.';
          _isLoading = false;
        });
      }
    }
  }

  void _startPolling(int profileId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final profile =
            await _candidateService.fetchCandidateProfile(profileId);
        if (!mounted) return;

        setState(() => _profile = profile);

        if (profile.videoCV?.isCompleted == true ||
            profile.videoCV?.isFailed == true) {
          _pollingTimer?.cancel();
        }
      } catch (_) {
        // Keep polling silently on transient errors
      }
    });
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) context.go('/login');
  }

  void _onUploadComplete() {
    // Reload to start processing status
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video CV'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Odhlásit se',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Zkusit znovu'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profile!;
    final videoCV = profile.videoCV;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Moje Video CV',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (videoCV == null) ...[
            _buildNoVideoCard(profile),
          ] else if (videoCV.isCompleted && videoCV.url != null) ...[
            _buildPlayerCard(videoCV.url!),
            const SizedBox(height: 24),
            _buildUploadSection(profile),
          ] else if (videoCV.isProcessing) ...[
            _buildProcessingCard(videoCV),
          ] else if (videoCV.isFailed) ...[
            _buildFailedCard(profile),
          ] else ...[
            _buildNoVideoCard(profile),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerCard(String url) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VideoCVPlayer(hlsUrl: url),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Vaše Video CV',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingCard(VideoCV videoCV) {
    final progress = (videoCV.encodingProgress ?? 0) / 100.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.hourglass_top, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Video se zpracovává...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress > 0 ? progress : null),
            const SizedBox(height: 8),
            if (videoCV.encodingProgress != null)
              Text('${videoCV.encodingProgress} %'),
            const SizedBox(height: 8),
            const Text(
              'Stránka se automaticky obnoví.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedCard(CandidateProfile profile) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                const Text(
                  'Zpracování videa selhalo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Nahrajte prosím video znovu.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildUploadSection(profile),
      ],
    );
  }

  Widget _buildNoVideoCard(CandidateProfile profile) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.video_call, size: 64, color: Colors.blueGrey),
                const SizedBox(height: 12),
                const Text(
                  'Zatím nemáte žádné Video CV',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Nahrajte video a představte se zaměstnavatelům.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildUploadSection(profile),
      ],
    );
  }

  Widget _buildUploadSection(CandidateProfile profile) {
    return VideoUploadWidget(
      candidateProfileId: profile.id,
      onUploadComplete: _onUploadComplete,
    );
  }
}
