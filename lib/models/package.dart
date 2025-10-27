import '../config_service.dart';

class TravelPackage {
  final int id;
  final String title;
  final String description;
  final double price;
  final List<String> images;

  final int? durationDays;
  final String? cities;
  final int? hotelStars;
  final double? ratingAvg;
  final String? coverImage;

  TravelPackage({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.images,
    this.durationDays,
    this.cities,
    this.hotelStars,
    this.ratingAvg,
    this.coverImage,
  });

  factory TravelPackage.fromJson(Map<String, dynamic> j) => TravelPackage(
        id: _readInt(j['id']),
        title: j['title']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        price: _readDouble(j['price']),
        images: _resolveImages(j['images']),
        durationDays: _readIntOrNull(j['duration_days']),
        cities: j['cities']?.toString(),
        hotelStars: _readIntOrNull(j['hotel_stars']),
        ratingAvg: _readDoubleOrNull(j['rating_avg']),
        coverImage: _resolveCover(j['cover_image'], j['images']),
      );
}

int _readInt(dynamic value, {int defaultValue = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

int? _readIntOrNull(dynamic value) {
  if (value == null) return null;
  return _readInt(value);
}

double _readDouble(dynamic value, {double defaultValue = 0}) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

double? _readDoubleOrNull(dynamic value) {
  if (value == null) return null;
  return _readDouble(value);
}

List<String> _readStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
  }
  return const [];
}

List<String> _resolveImages(dynamic value) {
  final list = _readStringList(value);
  final resolved = <String>[];
  for (final item in list) {
    final url = ConfigService.resolveAssetUrl(item);
    if (url != null && url.isNotEmpty) {
      resolved.add(url);
    }
  }
  return resolved;
}

String? _resolveCover(dynamic cover, dynamic images) {
  final direct = ConfigService.resolveAssetUrl(cover?.toString());
  if (direct != null && direct.isNotEmpty) return direct;
  final resolvedImages = _resolveImages(images);
  if (resolvedImages.isNotEmpty) return resolvedImages.first;
  return null;
}
