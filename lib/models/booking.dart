class Booking {
  final int id;
  final int packageId;
  final String title;
  final double price;
  final int adults;
  final int children;
  final String status;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.packageId,
    required this.title,
    required this.price,
    required this.adults,
    required this.children,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'],
        packageId: j['package_id'],
        title: j['title'] ?? '',
        price: (j['price'] as num).toDouble(),
        adults: j['adults'] ?? 1,
        children: j['children'] ?? 0,
        status: j['status'] ?? 'CONFIRMED',
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );
}
