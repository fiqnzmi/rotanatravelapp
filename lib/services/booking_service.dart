import '../models/booking.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';
import 'auth_service.dart';

class BookingService {
  final _api = ApiClient();

  Future<Map<String, dynamic>> fetchPackageDetail(int id) async {
    return await _api.get('package_detail.php', query: {'id': '$id'});
  }

  Future<List<Booking>> myBookings() async {
    final userId = await AuthService.instance.getUserId();
    final query = userId != null ? {'user_id': '$userId'} : null;
    final list = await _api.get('my_bookings.php', query: query);
    final arr = (list as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    return arr.map((m) => Booking.fromJson(m)).toList();
  }

  Future<int> createBooking(Map<String, dynamic> payload) async {
    final userId = await AuthService.instance.getUserId();
    if (userId == null) {
      throw Exception('Please log in before making a booking.');
    }
    final body = Map<String, dynamic>.from(payload)..['user_id'] = userId;
    final data = await _api.post('create_booking.php', body);
    return readInt(data['id']);
  }

  Future<void> cancelBooking(int bookingId) async {
    await _api.post('cancel_booking.php', {'booking_id': bookingId});
  }
}
