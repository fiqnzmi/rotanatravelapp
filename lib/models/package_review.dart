import '../config_service.dart';
import '../utils/json_utils.dart';

class PackageReview {
  final int id;
  final int packageId;
  final int userId;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String reviewerName;
  final String reviewerInitials;
  final String? reviewerPhoto;
  final bool isMine;

  PackageReview({
    required this.id,
    required this.packageId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    required this.reviewerName,
    required this.reviewerInitials,
    required this.reviewerPhoto,
    required this.isMine,
  });

  factory PackageReview.fromJson(Map<String, dynamic> json) {
    final commentText = (json['comment'] as String?)?.trim();
    final photo = ConfigService.resolveAssetUrl(json['reviewer_photo']?.toString());
    return PackageReview(
      id: readInt(json['id']),
      packageId: readInt(json['package_id']),
      userId: readInt(json['user_id']),
      rating: readInt(json['rating'], defaultValue: 0),
      comment: commentText?.isEmpty == true ? null : commentText,
      createdAt: readDateTimeOrNull(json['created_at']),
      updatedAt: readDateTimeOrNull(json['updated_at']),
      reviewerName: json['reviewer_name']?.toString() ?? 'Traveler',
      reviewerInitials: json['reviewer_initials']?.toString() ?? 'T',
      reviewerPhoto: photo,
      isMine: json['is_mine'] == true,
    );
  }
}

class ReviewEligibility {
  final bool isLoggedIn;
  final bool hasBooking;

  const ReviewEligibility({required this.isLoggedIn, required this.hasBooking});

  factory ReviewEligibility.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return ReviewEligibility(
        isLoggedIn: json['is_logged_in'] == true,
        hasBooking: json['has_booking'] == true,
      );
    }
    return const ReviewEligibility(isLoggedIn: false, hasBooking: false);
  }
}

class PackageReviewsPage {
  final List<PackageReview> items;
  final int total;
  final bool hasMore;
  final double? ratingAvg;
  final int ratingCount;
  final PackageReview? myReview;
  final ReviewEligibility eligibility;

  PackageReviewsPage({
    required this.items,
    required this.total,
    required this.hasMore,
    required this.ratingAvg,
    required this.ratingCount,
    required this.myReview,
    required this.eligibility,
  });

  factory PackageReviewsPage.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => PackageReview.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final myReviewRaw = json['my_review'];
    Map<String, dynamic>? summary;
    final rawSummary = json['summary'];
    if (rawSummary is Map<String, dynamic>) {
      summary = rawSummary;
    } else if (rawSummary is Map) {
      summary = Map<String, dynamic>.from(rawSummary);
    }
    return PackageReviewsPage(
      items: items,
      total: readInt(json['total']),
      hasMore: json['has_more'] == true,
      ratingAvg: readDoubleOrNull(summary?['rating_avg']) ?? readDoubleOrNull(json['rating_avg']),
      ratingCount: readInt(summary?['rating_count'], defaultValue: readInt(json['rating_count'], defaultValue: 0)),
      myReview: myReviewRaw is Map<String, dynamic> ? PackageReview.fromJson(Map<String, dynamic>.from(myReviewRaw)) : null,
      eligibility: ReviewEligibility.fromJson(json['eligibility']),
    );
  }
}

class SubmitReviewResult {
  final PackageReview? review;
  final double? ratingAvg;
  final int ratingCount;
  final ReviewEligibility eligibility;

  SubmitReviewResult({
    required this.review,
    required this.ratingAvg,
    required this.ratingCount,
    required this.eligibility,
  });
}
