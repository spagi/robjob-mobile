import 'package:dio/dio.dart';
import '../../core/api_client.dart';

class CandidateProfile {
  final int id;
  final VideoCV? videoCV;

  const CandidateProfile({required this.id, this.videoCV});
}

class VideoCV {
  final String? url;
  final String? bunnyStatus;
  final int? encodingProgress;

  const VideoCV({this.url, this.bunnyStatus, this.encodingProgress});

  bool get isCompleted => bunnyStatus == 'completed';
  bool get isProcessing => bunnyStatus == 'processing';
  bool get isFailed => bunnyStatus == 'failed';
}

class CandidateService {
  final Dio _dio;

  CandidateService({Dio? dio, void Function()? onUnauthorized})
      : _dio = dio ?? createApiClient(onUnauthorized: onUnauthorized);

  Future<int> fetchCandidateProfileId() async {
    final response = await _dio.get('v1/me/show');
    final relationships = response.data['data']?['relationships'];
    final profiles = relationships?['candidateProfiles'];

    if (profiles == null || (profiles is List && profiles.isEmpty)) {
      throw Exception('No candidate profile found');
    }

    final firstProfile = profiles is List ? profiles.first : profiles;
    final id = firstProfile['id'] ?? firstProfile['data']?['id'];
    if (id == null) throw Exception('Candidate profile ID missing');

    return int.parse(id.toString());
  }

  Future<CandidateProfile> fetchCandidateProfile(int profileId) async {
    final response = await _dio.get(
      'v1/candidate_profiles/show',
      queryParameters: {'id': profileId},
    );

    final data = response.data['data'];
    final relationships = data?['relationships'];
    final videoCVData = relationships?['video_cv'];

    VideoCV? videoCV;
    if (videoCVData != null) {
      final attrs = videoCVData['attributes'] ?? videoCVData['data']?['attributes'];
      videoCV = VideoCV(
        url: attrs?['url']?.toString(),
        bunnyStatus: attrs?['bunny_status']?.toString(),
        encodingProgress: attrs?['encoding_progress'] != null
            ? int.tryParse(attrs!['encoding_progress'].toString())
            : null,
      );
    }

    return CandidateProfile(id: profileId, videoCV: videoCV);
  }

  Future<void> uploadVideoCV({
    required int candidateProfileId,
    required String videoPath,
    void Function(int sent, int total)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'id': candidateProfileId,
      'video_cv[0][file]': await MultipartFile.fromFile(
        videoPath,
        contentType: DioMediaType('video', 'mp4'),
      ),
    });

    await _dio.post(
      'v1/candidate_profiles/update',
      data: formData,
      onSendProgress: onProgress,
    );
  }
}
