import 'api_client.dart';

class DashboardService {
  final _api = ApiClient();

  Future<Map<String, dynamic>> bookingSummary(int bookingId, int userId) async {
    return await _api.get('dashboard_booking_summary.php',
        query: {'booking_id': '$bookingId', 'user_id': '$userId'});
  }

  Future<List<Map<String, dynamic>>> listDocuments(int bookingId, int userId) async {
    final data = await _api.get('list_documents.php',
        query: {'booking_id': '$bookingId', 'user_id': '$userId'});
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> listNotifications(int userId) async {
    final data = await _api.get('list_notifications.php', query: {'user_id': '$userId'});
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> profileOverview(int userId) async {
    return await _api.get('profile_overview.php', query: {'user_id': '$userId'});
  }
}
