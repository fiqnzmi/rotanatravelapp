class DepartureTier {
  final String name;
  final double price;
  final int? roomsLeft;
  DepartureTier({required this.name, required this.price, this.roomsLeft});

  factory DepartureTier.fromJson(Map<String, dynamic> j) => DepartureTier(
        name: j['name'] ?? '',
        price: (j['price'] as num).toDouble(),
        roomsLeft: j['rooms_left'],
      );
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
        id: j['id'],
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        price: (j['price'] as num).toDouble(),
        images: List<String>.from(j['images'] ?? const []),
        durationDays: j['duration_days'],
        cities: j['cities'],
        hotelStars: j['hotel_stars'],
        ratingAvg: (j['rating_avg'] as num?)?.toDouble(),
        ratingCount: j['rating_count'],
        departures: (j['departures'] as List? ?? [])
            .map((e) => Departure.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        inclusions: (j['inclusions'] as List? ?? []).map((e) => e.toString()).toList(),
        itinerary: (j['itinerary'] as List? ?? []).cast<Map<String, dynamic>>(),
        faqs: (j['faqs'] as List? ?? []).cast<Map<String, dynamic>>(),
      );
}
