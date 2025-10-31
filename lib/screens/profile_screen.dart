import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../config_service.dart';
import '../services/dashboard_service.dart';
import '../services/family_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'family_members_screen.dart';

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _svc = DashboardService();
  final _family = FamilyService();
  final ImagePicker _picker = ImagePicker();
  late Future<_ProfileResult> _future;
  String _language = 'en';
  bool _languageInitialized = false;
  bool _notifyEmail = true;
  bool _notifySms = false;
  bool _notificationsInitialized = false;
  bool _notificationsSaving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _addFamilyMember() async {
    final saved = await showFamilyMemberForm(context);
    if (saved && mounted) {
      setState(() {
        _future = _load();
      });
    }
  }

  Future<void> _editFamilyMember(Map<String, dynamic> member) async {
    final saved = await showFamilyMemberForm(context, initial: member);
    if (saved && mounted) {
      setState(() {
        _future = _load();
      });
    }
  }

  Future<void> _chooseEmergencyContact() async {
    final messenger = ScaffoldMessenger.of(context);
    final loggedIn = await AuthService.instance.isLoggedIn();
    if (!loggedIn) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (ok != true) return;
    }

    final userId = await AuthService.instance.getUserId();
    if (userId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please login to set emergency contact.')),
      );
      return;
    }

    List<Map<String, dynamic>> members;
    try {
      members = await _family.list(userId);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to load family: $e')),
      );
      return;
    }

    if (!mounted) return;
    final choice = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              const Text('Select emergency contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: members.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return ListTile(
                        leading: const Icon(Icons.clear),
                        title: const Text('Clear emergency contact'),
                        onTap: () => Navigator.of(ctx).pop(<String, dynamic>{'id': 0}),
                      );
                    }
                    final m = members[i - 1];
                    final name = (m['full_name'] ?? m['name'] ?? '').toString();
                    final relation = (m['relationship'] ?? '').toString();
                    final phone = (m['phone'] ?? m['mobile'] ?? '').toString();
                    return ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(name.isNotEmpty ? name : 'Unnamed'),
                      subtitle: Text([
                        if (relation.isNotEmpty) relation,
                        if (phone.isNotEmpty) phone,
                      ].join(' • ')),
                      onTap: () => Navigator.of(ctx).pop(m),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );

    if (choice == null) return;
    final id = int.tryParse((choice['id'] ?? '0').toString()) ?? 0;

    try {
      await _svc.updateProfile({
        'user_id': '$userId',
        'emergency_contact_id': '$id',
      });
      if (!mounted) return;
      setState(() {
        _future = _load();
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(id == 0 ? 'Emergency contact cleared.' : 'Emergency contact updated.'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    }
  }

  Future<void> _updateNotificationPref({bool? email, bool? sms}) async {
    if (_notificationsSaving) return;
    final messenger = ScaffoldMessenger.of(context);
    final loggedIn = await AuthService.instance.isLoggedIn();
    if (!loggedIn) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (ok != true) return;
    }

    final userId = await AuthService.instance.getUserId();
    if (userId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please login to update notifications.')),
      );
      return;
    }

    final prevEmail = _notifyEmail;
    final prevSms = _notifySms;
    final nextEmail = email ?? _notifyEmail;
    final nextSms = sms ?? _notifySms;

    setState(() {
      _notifyEmail = nextEmail;
      _notifySms = nextSms;
      _notificationsSaving = true;
    });

    try {
      await _svc.updateProfile({
        'user_id': '$userId',
        'notify_email': nextEmail ? '1' : '0',
        'notify_sms': nextSms ? '1' : '0',
      });
      if (!mounted) return;
      setState(() {
        _notificationsSaving = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Notification preferences updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notifyEmail = prevEmail;
        _notifySms = prevSms;
        _notificationsSaving = false;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update notifications: $e')),
      );
    }
  }

  Future<_ProfileResult> _load() async {
    final isLoggedIn = await AuthService.instance.isLoggedIn();
    if (!isLoggedIn) {
      return const _ProfileResult(loggedIn: false, payload: null);
    }
    final id = await AuthService.instance.getUserId();
    if (id == null) {
      return const _ProfileResult(loggedIn: false, payload: null);
    }
    final payload = await _svc.profileOverview(id);
    return _ProfileResult(
      loggedIn: true,
      payload: Map<String, dynamic>.from(payload),
    );
  }

  bool _readBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final trimmed = value.trim().toLowerCase();
      if (trimmed.isEmpty) return fallback;
      if (trimmed == '1' || trimmed == 'true' || trimmed == 'yes' || trimmed == 'y') {
        return true;
      }
      if (trimmed == '0' || trimmed == 'false' || trimmed == 'no' || trimmed == 'n') {
        return false;
      }
    }
    return fallback;
  }

  String? _photoFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final raw = map['photo'] ??
        map['photo_url'] ??
        map['avatar'] ??
        map['profile_image'] ??
        map['profile_photo'] ??
        map['image'] ?? map['url'];
    if (raw == null) return null;
    final url = raw.toString();
    return ConfigService.resolveAssetUrl(url) ?? url;
  }

  Future<void> _openEditProfile(Map<String, dynamic> user) async {
    final parentContext = context;
    final messenger = ScaffoldMessenger.of(parentContext);
    final dynamic userIdRaw = user['id'] ?? user['user_id'];
    if (userIdRaw == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Cannot edit profile: missing user id.')),
      );
      return;
    }
    final userIdString = userIdRaw.toString();
    final int? userIdInt = int.tryParse(userIdString);
    final nameC = TextEditingController(text: user['name']?.toString() ?? '');
    final usernameC =
        TextEditingController(text: user['username']?.toString() ?? '');
    final emailC = TextEditingController(text: user['email']?.toString() ?? '');
    final phoneC = TextEditingController(
      text: (user['phone'] ??
              user['mobile'] ??
              user['contact'] ??
              user['phone_number'] ??
              '')
          .toString(),
    );
    final existingPhotoUrl = _photoFromMap(user);
    File? selectedPhotoFile;
    String? previewPhotoUrl = existingPhotoUrl;
    final formKey = GlobalKey<FormState>();

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        bool saving = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickImage(ImageSource source) async {
              try {
                final picked = await _picker.pickImage(
                  source: source,
                  maxWidth: 1600,
                  maxHeight: 1600,
                  imageQuality: 85,
                );
                if (picked != null) {
                  setModalState(() {
                    selectedPhotoFile = File(picked.path);
                    previewPhotoUrl = null;
                  });
                }
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to pick image: $e')),
                );
              }
            }

            ImageProvider? displayImage;
            if (selectedPhotoFile != null) {
              displayImage = FileImage(selectedPhotoFile!);
            } else if (previewPhotoUrl != null) {
              displayImage = NetworkImage(previewPhotoUrl!);
            }
            final bool canRemovePhoto = selectedPhotoFile != null ||
                (previewPhotoUrl != null && previewPhotoUrl != existingPhotoUrl);

            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Edit Profile',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: saving
                                ? null
                                : () => Navigator.of(context).pop(false),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: const Color(0xFFE3E9F2),
                              backgroundImage: displayImage,
                              child: displayImage == null
                                  ? const Icon(Icons.person_outline, size: 42, color: Colors.black38)
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: saving ? null : () => pickImage(ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library_outlined),
                                  label: const Text('Choose Photo'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: saving ? null : () => pickImage(ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  label: const Text('Camera'),
                                ),
                                if (canRemovePhoto)
                                  TextButton(
                                    onPressed: saving
                                        ? null
                                        : () {
                                            setModalState(() {
                                              selectedPhotoFile = null;
                                              previewPhotoUrl = existingPhotoUrl;
                                            });
                                          },
                                    child: const Text('Remove'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameC,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: usernameC,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailC,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'Email is required';
                          if (!text.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneC,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => saving = true);
                                try {
                                  final payload = <String, dynamic>{
                                    'user_id': userIdString,
                                    'name': nameC.text.trim(),
                                    'username': usernameC.text.trim(),
                                    'email': emailC.text.trim(),
                                    'phone': phoneC.text.trim(),
                                  };
                                  payload.removeWhere(
                                    (key, value) =>
                                        key != 'user_id' &&
                                        (value == null ||
                                            (value is String &&
                                                value.trim().isEmpty)),
                                  );
                                  final response =
                                      await _svc.updateProfile(payload);
                                  Map<String, dynamic> storedUser = {};
                                  if (response is Map<String, dynamic>) {
                                    storedUser = Map<String, dynamic>.from(response);
                                    final userData = response['user'];
                                    if (userData is Map) {
                                      storedUser = Map<String, dynamic>.from(userData);
                                    }
                                  }
                                  final updatedName =
                                      storedUser['name']?.toString() ?? nameC.text.trim();
                                  final updatedUsername =
                                      storedUser['username']?.toString() ?? usernameC.text.trim();
                                  final updatedEmail =
                                      storedUser['email']?.toString() ?? emailC.text.trim();
                                  final updatedPhone = (storedUser['phone'] ??
                                          storedUser['mobile'] ??
                                          storedUser['contact'] ??
                                          storedUser['phone_number'])
                                      ?.toString() ??
                                      phoneC.text.trim();
                                  String? finalPhotoUrl =
                                      _photoFromMap(storedUser) ?? previewPhotoUrl ?? existingPhotoUrl;

                                  if (selectedPhotoFile != null) {
                                    if (userIdInt == null) {
                                      throw Exception('Invalid user id for uploading photo.');
                                    }
                                    final uploadData = await _svc.uploadProfilePhoto(
                                      userId: userIdInt,
                                      file: selectedPhotoFile!,
                                    );
                                    final uploadedPhoto = _photoFromMap(uploadData);
                                    if (uploadedPhoto != null) {
                                      finalPhotoUrl = uploadedPhoto;
                                    }
                                  }

                                  await AuthService.instance.updateStoredProfile(
                                    name: updatedName,
                                    username: updatedUsername,
                                    email: updatedEmail,
                                    phone: updatedPhone,
                                    photoUrl: finalPhotoUrl ?? '',
                                  );
                                  Navigator.of(sheetContext).pop(true);
                                } catch (e) {
                                  setModalState(() => saving = false);
                                  messenger
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to update profile: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameC.dispose();
    usernameC.dispose();
    emailC.dispose();
    phoneC.dispose();

    if (updated == true && mounted) {
      setState(() {
        _future = _load();
        _languageInitialized = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Profile settings',
          ),
        ],
      ),
      body: FutureBuilder(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final result = snap.data as _ProfileResult;
          if (!result.loggedIn || result.payload == null) {
            return _LoggedOutProfile(onLogin: () async {
              final loggedIn = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
              );
              if (loggedIn == true && mounted) {
                setState(() {
                  _future = _load();
                });
              }
            });
          }

          final m = result.payload!;
          final user =
              Map<String, dynamic>.from(m['user'] as Map? ?? const <String, dynamic>{});
          final counts =
              Map<String, dynamic>.from(m['counts'] as Map? ?? const <String, dynamic>{});
          final members = (m['family_members'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          final emergency =
              Map<String, dynamic>.from(m['emergency_contact'] as Map? ?? const {});

          final preferredLang = (user['language'] ??
                  user['preferred_language'] ??
                  user['lang'])
              ?.toString()
              .toLowerCase();
          if (!_languageInitialized && preferredLang != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _language = preferredLang.startsWith('b') ? 'ms' : 'en';
                _languageInitialized = true;
              });
            });
          }

          if (!_notificationsInitialized) {
            final emailPref = _readBool(
              user['notify_email'] ??
                  user['email_notifications'] ??
                  user['pref_email'] ??
                  user['notification_email'],
              fallback: true,
            );
            final smsPref = _readBool(
              user['notify_sms'] ??
                  user['sms_notifications'] ??
                  user['pref_sms'] ??
                  user['notification_sms'],
              fallback: false,
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _notifyEmail = emailPref;
                _notifySms = smsPref;
                _notificationsInitialized = true;
              });
            });
          }

          final photoUrl = _photoFromMap(user);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _ProfileHeader(
                user: user,
                photoUrl: photoUrl,
                onEdit: () => _openEditProfile(user),
              ),
              const SizedBox(height: 16),
              _StatsRow(
                completed: counts['completed']?.toString() ?? '0',
                upcoming: counts['upcoming']?.toString() ?? '0',
                familyMembers: counts['family_members']?.toString() ??
                    members.length.toString(),
              ),
              const SizedBox(height: 16),
              _SavedTravellersCard(
                travellerCount: members.length,
                travellers: members,
                onViewAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FamilyMembersScreen(),
                  ),
                ),
                onAdd: _addFamilyMember,
                onEdit: (member) => _editFamilyMember(Map<String, dynamic>.from(member)),
              ),
              const SizedBox(height: 12),
              _EmergencyContactCard(
                contact: emergency,
                onEdit: _chooseEmergencyContact,
              ),
              const SizedBox(height: 12),
              _NotificationsCard(
                emailEnabled: _notifyEmail,
                smsEnabled: _notifySms,
                loading: _notificationsSaving,
                onEmailChanged: (value) => _updateNotificationPref(email: value),
                onSmsChanged: (value) => _updateNotificationPref(sms: value),
              ),
              const SizedBox(height: 12),
              _LanguageCard(
                selected: _language,
                onChanged: (value) => setState(() {
                  _language = value;
                  _languageInitialized = true;
                }),
              ),
              const SizedBox(height: 12),
              const _SettingsCard(),
              const SizedBox(height: 18),
              _LogoutButton(
                onLogout: () async {
                  await AuthService.instance.logout();
                  if (!mounted) return;
                  setState(() {
                    _future = _load();
                    _languageInitialized = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out successfully.')),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Rotana Travel & Tours\nVersion 2.1.0',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.black54),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.photoUrl, required this.onEdit});
  final Map<String, dynamic> user;
  final String? photoUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final name = (user['name'] ?? user['username'] ?? '-').toString();
    final email = (user['email'] ?? '').toString();
    final phone = (user['phone'] ??
            user['mobile'] ??
            user['contact'] ??
            user['phone_number'] ??
            '')
        .toString();
    ImageProvider<Object>? avatarImage;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      avatarImage = NetworkImage(photoUrl!);
    }
    final initials = name.trim().isNotEmpty
        ? name
            .trim()
            .split(RegExp(r'\\s+'))
            .take(2)
            .map((e) => e.isNotEmpty ? e[0] : '')
            .join()
            .toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFEEF1F7),
            backgroundImage: avatarImage,
            child: avatarImage == null
                ? Text(
                    initials,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (email.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.mail_outline, size: 16, color: Colors.black54),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            email,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (phone.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 16, color: Colors.black54),
                        const SizedBox(width: 6),
                        Text(
                          phone,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit profile',
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.completed,
    required this.upcoming,
    required this.familyMembers,
  });

  final String completed;
  final String upcoming;
  final String familyMembers;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        children: [
          _ProfileStat(label: 'Trips Completed', value: completed),
          _divider(),
          _ProfileStat(label: 'Upcoming', value: upcoming),
          _divider(),
          _ProfileStat(label: 'Family Members', value: familyMembers),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: const Color(0xFFE3E5EB),
      );
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _SavedTravellersCard extends StatelessWidget {
  const _SavedTravellersCard({
    required this.travellerCount,
    required this.travellers,
    required this.onViewAll,
    required this.onAdd,
    this.onEdit,
  });

  final int travellerCount;
  final List<Map<String, dynamic>> travellers;
  final VoidCallback onViewAll;
  final VoidCallback onAdd;
  final void Function(Map<String, dynamic> member)? onEdit;

  @override
  Widget build(BuildContext context) {
    final preview = travellers.take(3).toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Saved Travellers',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                tooltip: 'Add traveller',
              ),
            ],
          ),
          if (preview.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('No travellers saved yet.'),
            )
          else
            ...preview.map(
              (m) {
                final name = (m['full_name'] ?? m['name'] ?? '').toString();
                final subtitle = _travellerSubtitle(m);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFECEFF4),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  title: Text(name.isEmpty ? 'Traveller' : name),
                  subtitle: subtitle.isEmpty ? null : Text(subtitle),
                  onTap: onEdit != null ? () => onEdit!(m) : onViewAll,
                  dense: true,
                );
              },
            ),
          if (travellerCount > 3)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onViewAll,
                child: Text('View all $travellerCount travellers'),
              ),
            ),
        ],
      ),
    );
  }

  String _travellerSubtitle(Map<String, dynamic> member) {
    final parts = <String>[];
    final relation = (member['relationship'] ?? member['type'] ?? '').toString();
    if (relation.isNotEmpty) parts.add(relation);
    final nationality = (member['nationality'] ?? '').toString();
    if (nationality.isNotEmpty) parts.add(nationality);
    final passport = (member['passport_no'] ?? '').toString();
    if (passport.isNotEmpty) parts.add('Passport: $passport');
    final dob = _parseDate(member['dob']);
    if (dob != null) {
      parts.add('DOB: ${DateFormat('dd/MM/yyyy').format(dob)}');
    }
    return parts.join(' ? ');
  }
}

class _EmergencyContactCard extends StatelessWidget {
  const _EmergencyContactCard({required this.contact, this.onEdit});
  final Map<String, dynamic> contact;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final name = (contact['name'] ?? contact['full_name'] ?? '').toString();
    final relation =
        (contact['relationship'] ?? contact['relation'] ?? '').toString();
    final phone = (contact['phone'] ??
            contact['mobile'] ??
            contact['contact'] ??
            contact['phone_number'] ??
            '')
        .toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Emergency Contact',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit emergency contact',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (name.isEmpty && phone.isEmpty)
            const Text('No emergency contact added.')
          else ...[
            Text(
              name.isEmpty ? 'Emergency Contact' : name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (relation.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  relation,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            if (phone.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  phone,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard({
    required this.emailEnabled,
    required this.smsEnabled,
    required this.loading,
    required this.onEmailChanged,
    required this.onSmsChanged,
  });

  final bool emailEnabled;
  final bool smsEnabled;
  final bool loading;
  final ValueChanged<bool> onEmailChanged;
  final ValueChanged<bool> onSmsChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Notifications',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            value: emailEnabled,
            onChanged: loading ? null : onEmailChanged,
            contentPadding: EdgeInsets.zero,
            title: const Text('Email updates'),
            subtitle: const Text('Receive booking reminders and payment receipts by email.'),
          ),
          const Divider(height: 1),
          SwitchListTile.adaptive(
            value: smsEnabled,
            onChanged: loading ? null : onSmsChanged,
            contentPadding: EdgeInsets.zero,
            title: const Text('SMS alerts'),
            subtitle: const Text('Get important travel alerts via SMS.'),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Language',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'en', label: Text('English')),
              ButtonSegment(value: 'ms', label: Text('Bahasa')),
            ],
            style: ButtonStyle(
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
            selected: <String>{selected},
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) {
                onChanged(selection.first);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        children: const [
          _SettingsTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
          ),
          Divider(height: 1),
          _SettingsTile(
            icon: Icons.credit_card_outlined,
            label: 'Payment Methods',
          ),
          Divider(height: 1),
          _SettingsTile(
            icon: Icons.lock_outline,
            label: 'Privacy & Security',
          ),
          Divider(height: 1),
          _SettingsTile(
            icon: Icons.support_agent_outlined,
            label: 'Help & Support',
          ),
          Divider(height: 1),
          _SettingsTile(
            icon: Icons.info_outline,
            label: 'About Rotana',
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onLogout,
        child: const Text('Logout'),
      ),
    );
  }
}

class _LoggedOutProfile extends StatelessWidget {
  const _LoggedOutProfile({required this.onLogin});
  final Future<void> Function() onLogin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          CircleAvatar(
            radius: 44,
            backgroundColor: const Color(0xFFE8ECF4),
            child: Icon(
              Icons.person_outline,
              color: Colors.blueGrey.shade600,
              size: 44,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Rotana Travel',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Create an account or log in to manage your trips, family members, and profile details.',
            style: const TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () { onLogin(); },
              child: const Text('Log In or Sign Up'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileResult {
  final bool loggedIn;
  final Map<String, dynamic>? payload;
  const _ProfileResult({required this.loggedIn, required this.payload});
}
