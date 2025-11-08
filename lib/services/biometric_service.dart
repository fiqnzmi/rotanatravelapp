import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricSnapshot {
  const BiometricSnapshot({
    required this.userId,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.photo,
    required this.savedAt,
  });

  final int userId;
  final String? name;
  final String? username;
  final String? email;
  final String? phone;
  final String? photo;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
        'id': userId,
        'name': name,
        'username': username,
        'email': email,
        'phone': phone,
        'photo': photo,
        'saved_at': savedAt.toIso8601String(),
      };

  factory BiometricSnapshot.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return BiometricSnapshot(
      userId: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?)?.trim(),
      username: (json['username'] as String?)?.trim(),
      email: (json['email'] as String?)?.trim(),
      phone: (json['phone'] as String?)?.trim(),
      photo: (json['photo'] as String?)?.trim(),
      savedAt: parseDate(json['saved_at']),
    );
  }

  bool get isValid => userId > 0;
}

class BiometricAuthService {
  BiometricAuthService._();
  static final BiometricAuthService instance = BiometricAuthService._();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.unlocked),
  );

  static const _storageKey = 'rotana_biometric_snapshot';

  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<bool> hasBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> canUseBiometrics() async {
    final supported = await isDeviceSupported();
    if (!supported) return false;
    return await hasBiometrics();
  }

  Future<bool> authenticate(String reason) async {
    try {
      final available = await canUseBiometrics();
      if (!available) return false;
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  Future<void> saveSnapshot(BiometricSnapshot snapshot) async {
    if (!snapshot.isValid) return;
    await _storage.write(key: _storageKey, value: jsonEncode(snapshot.toJson()));
  }

  Future<BiometricSnapshot?> readSnapshot() async {
    final value = await _storage.read(key: _storageKey);
    if (value == null || value.isEmpty) return null;
    try {
      final data = jsonDecode(value) as Map<String, dynamic>;
      final snapshot = BiometricSnapshot.fromJson(data);
      return snapshot.isValid ? snapshot : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasSnapshot() async => await readSnapshot() != null;

  Future<void> clearSnapshot() => _storage.delete(key: _storageKey);
}
