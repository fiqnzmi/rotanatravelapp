import '../models/package.dart';
import 'api_client.dart';

class PackageService {
  final _api = ApiClient();

  Future<List<TravelPackage>> listPackages() async {
    final list = await _api.get('list_packages.php');
    final arr = (list as List).cast<Map<String, dynamic>>();
    return arr.map((m) => TravelPackage.fromJson(m)).toList();
  }
}
