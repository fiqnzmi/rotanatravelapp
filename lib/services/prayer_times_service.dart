import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'api_client.dart';

class PrayerTimesData {
  PrayerTimesData({
    required this.city,
    required this.country,
    required this.timings,
  });

  final String city;
  final String country;
  final Map<String, String> timings;
}

class PrayerTimesService {
  PrayerTimesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _defaultCity = 'Kangar';
  static const _defaultCountry = 'Malaysia';
  static const _defaultMethod = '4'; // Umm Al-Qura University, Makkah

  Future<PrayerTimesData> fetchToday({String? city, String? country}) async {
    final now = DateTime.now();
    final selectedCity = city ?? _defaultCity;
    final selectedCountry = country ?? _defaultCountry;
    final response = await _request({
      'city': selectedCity,
      'country': selectedCountry,
      'method': _defaultMethod,
      'date': DateFormat('dd-MM-yyyy').format(now),
    });
    return _buildData(
      response,
      city: selectedCity,
      country: selectedCountry,
    );
  }

  Future<PrayerTimesData> fetchByCoordinates({
    required double latitude,
    required double longitude,
    String? city,
    String? country,
  }) async {
    final now = DateTime.now();
    final response = await _request({
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'method': _defaultMethod,
      'date': DateFormat('dd-MM-yyyy').format(now),
    });
    return _buildData(
      response,
      city: city ?? _defaultCity,
      country: country ?? _defaultCountry,
    );
  }

  Future<Map<String, dynamic>> _request(Map<String, String> params) async {
    final uri = Uri.https('api.aladhan.com', '/v1/timings', params);
    try {
      final res = await _client.get(uri);
      if (res.statusCode != 200) {
        throw Exception('Prayer times error (HTTP ${res.statusCode})');
      }
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      if (decoded['code'] != 200) {
        throw Exception(decoded['status'] ?? 'Failed to load prayer times');
      }
      return decoded;
    } on SocketException catch (_) {
      throw const NoConnectionException();
    } on http.ClientException catch (_) {
      throw const NoConnectionException();
    }
  }

  PrayerTimesData _buildData(
    Map<String, dynamic> decoded, {
    required String city,
    required String country,
  }) {
    final data = decoded['data'] as Map<String, dynamic>;
    final timings = Map<String, dynamic>.from(data['timings'] as Map);
    const relevantKeys = {
      'Fajr',
      'Sunrise',
      'Dhuhr',
      'Asr',
      'Maghrib',
      'Isha',
    };

    final result = <String, String>{};
    for (final entry in timings.entries) {
      if (relevantKeys.contains(entry.key)) {
        result[entry.key] = entry.value.toString();
      }
    }

    return PrayerTimesData(
      city: city,
      country: country,
      timings: result,
    );
  }
}
