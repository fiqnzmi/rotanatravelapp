import '../config_service.dart';
import '../utils/json_utils.dart';

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
  final List<PackageDepartureSummary> departures;

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
    this.departures = const [],
  });

  factory TravelPackage.fromJson(Map<String, dynamic> j) => TravelPackage(
        id: readInt(j['id']),
        title: j['title']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        price: readDouble(j['price']),
        images: _resolveImages(j['images']),
        durationDays: readIntOrNull(j['duration_days']),
        cities: j['cities']?.toString(),
        hotelStars: readIntOrNull(j['hotel_stars']),
        ratingAvg: readDoubleOrNull(j['rating_avg']),
        coverImage: _resolveCover(j['cover_image'], j['images']),
        departures: (j['departures'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((m) => PackageDepartureSummary.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );
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

class PackageDepartureSummary {
  final String date; // ISO-8601 string
  final String? note;
  final List<PackageTierSummary> tiers;

  PackageDepartureSummary({
    required this.date,
    this.note,
    required this.tiers,
  });

  factory PackageDepartureSummary.fromJson(Map<String, dynamic> j) => PackageDepartureSummary(
        date: j['date']?.toString() ?? '',
        note: j['note']?.toString(),
        tiers: (j['tiers'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((m) => PackageTierSummary.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );
}

class PackageTierSummary {
  final String name;
  final double price;
  final int? roomsLeft;

  PackageTierSummary({
    required this.name,
    required this.price,
    this.roomsLeft,
  });

  factory PackageTierSummary.fromJson(Map<String, dynamic> j) => PackageTierSummary(
        name: j['name']?.toString() ?? '',
        price: readDouble(j['price']),
        roomsLeft: readIntOrNull(j['rooms_left']),
      );
}
