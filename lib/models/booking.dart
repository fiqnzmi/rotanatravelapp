import '../utils/json_utils.dart';

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
        id: readInt(j['id']),
        packageId: readInt(j['package_id']),
        title: j['title']?.toString() ?? '',
        price: readDouble(j['price']),
        adults: readInt(j['adults'], defaultValue: 1),
        children: readInt(j['children']),
        status: j['status']?.toString() ?? 'CONFIRMED',
        createdAt: readDateTimeOrNull(j['created_at']) ?? DateTime.now(),
      );
}
