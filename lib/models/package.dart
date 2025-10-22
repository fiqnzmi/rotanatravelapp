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
        id: j['id'],
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        price: (j['price'] as num).toDouble(),
        images: List<String>.from(j['images'] ?? const []),
        durationDays: j['duration_days'],
        cities: j['cities'],
        hotelStars: j['hotel_stars'],
        ratingAvg: (j['rating_avg'] as num?)?.toDouble(),
        coverImage: j['cover_image'],
      );
}
