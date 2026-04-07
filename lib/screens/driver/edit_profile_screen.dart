import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _badgeCtrl;
  late String _role;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl = TextEditingController(text: auth.driverName ?? '');
    _badgeCtrl = TextEditingController(text: auth.driverBadge ?? '');
    _role = auth.driverRole ?? 'driver';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _badgeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final app = context.read<AppProvider>();
    final auth = context.read<AuthProvider>();
    final badgeChanged =
        _badgeCtrl.text.trim().toUpperCase() !=
        (auth.driverBadge ?? '').trim().toUpperCase();

    if (app.activeDriverRoute != null && badgeChanged) {
      setState(() {
        _errorMessage =
            'Stop your active route before changing the assigned bus badge.';
      });
      return;
    }

    setState(() => _errorMessage = null);
    final error = await auth.updateStaffAccount(
      fullName: _nameCtrl.text,
      role: _role,
      badge: _badgeCtrl.text,
      assignedRoutes: auth.assignedRoutes,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Staff profile updated.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isOnDuty = context.watch<AppProvider>().activeDriverRoute != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isOnDuty)
                _InfoBanner(
                  message:
                      'You are currently on duty. Name and role can still be updated, but changing the bus badge is blocked until the active route is stopped.',
                  color: AppColors.accentLight,
                  textColor: AppColors.gray800,
                  icon: Icons.info_outline,
                ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Account Identity',
                subtitle:
                    'These details are shown in the driver profile and used when publishing live bus identity.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('Username'),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: auth.driverUsername ?? 'Unknown',
                      enabled: false,
                      decoration: _inputDecoration(
                        hint: 'Username',
                        prefixIcon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _FieldLabel('Full name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        hint: 'Enter full name',
                        prefixIcon: Icons.badge_outlined,
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Full name is required';
                        if (text.length < 3) {
                          return 'Enter the staff member\'s full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    const _FieldLabel('Role'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _role,
                      decoration: _inputDecoration(
                        hint: 'Select role',
                        prefixIcon: Icons.assignment_ind_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'driver',
                          child: Text('Driver'),
                        ),
                        DropdownMenuItem(
                          value: 'konduktor',
                          child: Text('Konduktor'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _role = value);
                      },
                    ),
                    const SizedBox(height: 18),
                    const _FieldLabel('Bus badge'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _badgeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _inputDecoration(
                        hint: 'BUS-001',
                        prefixIcon: Icons.directions_bus_outlined,
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Bus badge is required';
                        if (text.length < 4) {
                          return 'Enter a valid badge identifier';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                _ErrorBanner(message: _errorMessage!),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'SAVE PROFILE',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      prefixIcon: Icon(prefixIcon, color: Colors.grey[400], size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String message;
  final Color color;
  final Color textColor;
  final IconData icon;

  const _InfoBanner({
    required this.message,
    required this.color,
    required this.textColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
