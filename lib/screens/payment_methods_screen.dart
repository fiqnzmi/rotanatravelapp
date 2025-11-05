import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<_PaymentMethod> _methods = [
    const _PaymentMethod(
      label: 'Visa',
      last4: '1234',
      expiry: '08/26',
      primary: true,
      brandIcon: Icons.credit_card,
    ),
    const _PaymentMethod(
      label: 'Mastercard',
      last4: '9876',
      expiry: '11/27',
      brandIcon: Icons.credit_card_outlined,
    ),
  ];

  Future<void> _addMethod() async {
    final added = await showModalBottomSheet<_PaymentMethod>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return const _AddPaymentMethodSheet();
      },
    );
    if (added == null) return;
    setState(() {
      final makePrimary = added.primary || _methods.isEmpty;
      final updated = makePrimary ? added.copyWith(primary: true) : added;
      if (makePrimary) {
        for (var i = 0; i < _methods.length; i++) {
          _methods[i] = _methods[i].copyWith(primary: false);
        }
      }
      _methods.add(updated);
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment method added.')),
    );
  }

  void _setPrimary(int index) {
    setState(() {
      for (var i = 0; i < _methods.length; i++) {
        _methods[i] = _methods[i].copyWith(primary: i == index);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_methods[index].label} set as primary.')),
    );
  }

  void _removeMethod(int index) {
    final removed = _methods[index];
    setState(() {
      _methods.removeAt(index);
      if (_methods.isNotEmpty && !_methods.any((m) => m.primary)) {
        _methods[0] = _methods[0].copyWith(primary: true);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${removed.label} removed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMethod,
        icon: const Icon(Icons.add),
        label: const Text('Add Payment Method'),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: _methods.length,
          itemBuilder: (context, index) {
            final method = _methods[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFFE3F2FD),
                          child: Icon(method.brandIcon, color: const Color(0xFF0D47A1)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method.label,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('•••• ${method.last4} • Exp ${method.expiry}'),
                              if (method.primary)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Primary',
                                    style: TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'primary') {
                              _setPrimary(index);
                            } else if (value == 'remove') {
                              _removeMethod(index);
                            }
                          },
                          itemBuilder: (context) => [
                            if (!method.primary)
                              const PopupMenuItem(
                                value: 'primary',
                                child: Text('Set as primary'),
                              ),
                            const PopupMenuItem(
                              value: 'remove',
                              child: Text('Remove'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PaymentMethod {
  final String label;
  final String last4;
  final String expiry;
  final bool primary;
  final IconData brandIcon;

  const _PaymentMethod({
    required this.label,
    required this.last4,
    required this.expiry,
    this.primary = false,
    this.brandIcon = Icons.credit_card,
  });

  _PaymentMethod copyWith({
    String? label,
    String? last4,
    String? expiry,
    bool? primary,
    IconData? brandIcon,
  }) {
    return _PaymentMethod(
      label: label ?? this.label,
      last4: last4 ?? this.last4,
      expiry: expiry ?? this.expiry,
      primary: primary ?? this.primary,
      brandIcon: brandIcon ?? this.brandIcon,
    );
  }
}

class _AddPaymentMethodSheet extends StatefulWidget {
  const _AddPaymentMethodSheet();

  @override
  State<_AddPaymentMethodSheet> createState() => _AddPaymentMethodSheetState();
}

class _AddPaymentMethodSheetState extends State<_AddPaymentMethodSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _numberC = TextEditingController();
  final _expiryC = TextEditingController();
  bool _primary = false;

  @override
  void dispose() {
    _nameC.dispose();
    _numberC.dispose();
    _expiryC.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final number = _numberC.text.trim();
    final last4 = number.length >= 4 ? number.substring(number.length - 4) : number;
    final method = _PaymentMethod(
      label: _nameC.text.trim(),
      last4: last4,
      expiry: _expiryC.text.trim(),
      primary: _primary,
    );
    Navigator.of(context).pop(method);
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Add Payment Method',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameC,
                  decoration: const InputDecoration(
                    labelText: 'Cardholder Name',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _numberC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Card Number',
                  ),
                  validator: (value) {
                    final text = value?.replaceAll(RegExp(r'\\s+'), '') ?? '';
                    if (text.length < 12) return 'Enter a valid card number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _expiryC,
                  decoration: const InputDecoration(
                    labelText: 'Expiry (MM/YY)',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (!RegExp(r'^(0[1-9]|1[0-2])\\/\\d{2}\$').hasMatch(text)) {
                      return 'Invalid expiry';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _primary,
                  onChanged: (value) => setState(() => _primary = value),
                  title: const Text('Set as primary'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
