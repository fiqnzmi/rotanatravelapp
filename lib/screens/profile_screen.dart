import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'family_members_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _svc = DashboardService();
  late Future<_ProfileResult> _future;
  String _language = 'en';
  bool _languageInitialized = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
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

  Future<void> _openEditProfile(Map<String, dynamic> user) async {
    final parentContext = context;
    final messenger = ScaffoldMessenger.of(parentContext);
    final userId = user['id'] ?? user['user_id'];
    if (userId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Cannot edit profile: missing user id.')),
      );
      return;
    }
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
    final formKey = GlobalKey<FormState>();

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        bool saving = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                                    'user_id': '$userId',
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
                                  Map<String, dynamic> storedUser =
                                      Map<String, dynamic>.from(response);
                                  final userData = response['user'];
                                  if (userData is Map) {
                                    storedUser =
                                        Map<String, dynamic>.from(userData);
                                  }
                                  await AuthService.instance
                                      .updateStoredProfile(
                                    name: storedUser['name']?.toString() ??
                                        nameC.text.trim(),
                                    username: storedUser['username']
                                            ?.toString() ??
                                        usernameC.text.trim(),
                                    email: storedUser['email']?.toString() ??
                                        emailC.text.trim(),
                                    phone: (storedUser['phone'] ??
                                                storedUser['mobile'] ??
                                                storedUser['contact'] ??
                                                storedUser['phone_number'])
                                            ?.toString() ??
                                        phoneC.text.trim(),
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

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _ProfileHeader(
                user: user,
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
              ),
              const SizedBox(height: 12),
              _EmergencyContactCard(contact: emergency),
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
  const _ProfileHeader({required this.user, required this.onEdit});
  final Map<String, dynamic> user;
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
            child: Text(
              initials,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
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
  });

  final int travellerCount;
  final List<Map<String, dynamic>> travellers;
  final VoidCallback onViewAll;

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
                onPressed: onViewAll,
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
                final relation = (m['relationship'] ?? m['type'] ?? '').toString();
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
                  subtitle: relation.isEmpty ? null : Text(relation),
                  onTap: onViewAll,
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
}

class _EmergencyContactCard extends StatelessWidget {
  const _EmergencyContactCard({required this.contact});
  final Map<String, dynamic> contact;

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
                onPressed: () {},
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
