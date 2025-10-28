import '../models/package.dart';
import 'api_client.dart';

class PackageService {
  final _api = ApiClient();

  Future<List<TravelPackage>> listPackages() async {
    final list = await _api.get('list_packages.php');
    final arr = (list as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    return arr.map((m) => TravelPackage.fromJson(m)).toList();
  }
}
