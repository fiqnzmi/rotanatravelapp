import '../models/package_review.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';
import 'auth_service.dart';

class PackageReviewService {
  final _api = ApiClient();
  final _auth = AuthService.instance;

  Future<PackageReviewsPage> listReviews(int packageId, {int limit = 20, int offset = 0}) async {
    final userId = await _auth.getUserId();
    final query = <String, String>{
      'package_id': '$packageId',
      'limit': '$limit',
    };
    if (offset > 0) {
      query['offset'] = '$offset';
    }
    if (userId != null) {
      query['user_id'] = '$userId';
    }
    final data = await _api.get('package_reviews.php', query: query);
    return PackageReviewsPage.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<SubmitReviewResult> submitReview({
    required int packageId,
    required int rating,
    String? comment,
  }) async {
    final userId = await _auth.getUserId();
    if (userId == null) {
      throw Exception('Please sign in before leaving a review.');
    }
    final payload = <String, dynamic>{
      'package_id': packageId,
      'user_id': userId,
      'rating': rating,
    };
    if (comment != null) {
      payload['comment'] = comment.trim();
    }
    final data = await _api.post('submit_package_review.php', payload);
    final map = Map<String, dynamic>.from(data as Map);
    final reviewData = map['review'];
    final summary = map['summary'];
    final eligibility = ReviewEligibility.fromJson(map['eligibility']);
    return SubmitReviewResult(
      review: reviewData is Map<String, dynamic> ? PackageReview.fromJson(Map<String, dynamic>.from(reviewData)) : null,
      ratingAvg: readDoubleOrNull(summary is Map<String, dynamic> ? summary['rating_avg'] : (summary is Map ? summary['rating_avg'] : null)),
      ratingCount: readInt(summary is Map<String, dynamic> ? summary['rating_count'] : (summary is Map ? summary['rating_count'] : null)),
      eligibility: eligibility,
    );
  }
}
