import '../config_service.dart';
import '../utils/json_utils.dart';

class DepartureTier {
  final String name;
  final double price;
  final int? roomsLeft;
  DepartureTier({required this.name, required this.price, this.roomsLeft});

  factory DepartureTier.fromJson(Map<String, dynamic> j) => DepartureTier(
        name: j['name'] ?? '',
        price: readDouble(j['price']),
        roomsLeft: readIntOrNull(j['rooms_left']),
      );
}

List<String> _resolveImages(dynamic value) {
  if (value is List) {
    return value
        .map((e) => ConfigService.resolveAssetUrl(e?.toString()) ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }
  final single = ConfigService.resolveAssetUrl(value?.toString());
  return single == null || single.isEmpty ? const [] : [single];
}

class Departure {
  final String date; // YYYY-MM-DD
  final String? note;
  final List<DepartureTier> tiers;
  Departure({required this.date, this.note, required this.tiers});

  factory Departure.fromJson(Map<String, dynamic> j) => Departure(
        date: j['date'] ?? '',
        note: j['note'],
        tiers: (j['tiers'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((e) => DepartureTier.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class PackageDetail {
  final int id;
  final String title;
  final String description;
  final double price;
  final List<String> images;
  final int? durationDays;
  final String? cities;
  final int? hotelStars;
  final double? ratingAvg;
  final int? ratingCount;
  final List<Departure> departures;
  final List<String> inclusions;
  final List<Map<String, dynamic>> itinerary;
  final List<Map<String, dynamic>> faqs;

  PackageDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.images,
    this.durationDays,
    this.cities,
    this.hotelStars,
    this.ratingAvg,
    this.ratingCount,
    required this.departures,
    required this.inclusions,
    required this.itinerary,
    required this.faqs,
  });

  factory PackageDetail.fromJson(Map<String, dynamic> j) => PackageDetail(
        id: readInt(j['id']),
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        price: readDouble(j['price']),
        images: _resolveImages(j['images']),
        durationDays: readIntOrNull(j['duration_days']),
        cities: j['cities'],
        hotelStars: readIntOrNull(j['hotel_stars']),
        ratingAvg: readDoubleOrNull(j['rating_avg']),
        ratingCount: readIntOrNull(j['rating_count']),
        departures: (j['departures'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((e) => Departure.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        inclusions: (j['inclusions'] as List? ?? []).map((e) => e.toString()).toList(),
        itinerary: (j['itinerary'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        faqs: (j['faqs'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
      );
}
