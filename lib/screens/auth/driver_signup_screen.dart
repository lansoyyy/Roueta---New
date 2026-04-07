import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../main_map_screen.dart';
import 'driver_login_screen.dart';

class DriverSignupScreen extends StatefulWidget {
  const DriverSignupScreen({super.key});

  @override
  State<DriverSignupScreen> createState() => _DriverSignupScreenState();
}

class _DriverSignupScreenState extends State<DriverSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _badgeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final Set<String> _selectedRoutes = <String>{};
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'driver';
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _badgeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoutes.isEmpty) {
      setState(() {
        _errorMessage = 'Select at least one route for this staff account.';
      });
      return;
    }

    setState(() => _errorMessage = null);

    final auth = context.read<AuthProvider>();
    final error = await auth.signUp(
      fullName: _fullNameCtrl.text,
      username: _usernameCtrl.text,
      password: _passwordCtrl.text,
      role: _selectedRole,
      badge: _badgeCtrl.text,
      assignedRoutes: _selectedRoutes.toList(growable: false),
    );

    if (!mounted) return;

    if (error == null) {
      context.read<AppProvider>().setUserMode(UserMode.driver);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainMapScreen()),
        (route) => false,
      );
      return;
    }

    setState(() => _errorMessage = error);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final routes = context.watch<AppProvider>().routes;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const _AuthHeader(
            title: 'Create staff account',
            subtitle:
                'Set up driver or konduktor access with live route tracking',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Staff details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'The saved badge and assigned routes are used for live bus publishing and occupancy updates.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const _FieldLabel('Full name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fullNameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        hint: 'e.g. Maria Garcia',
                        prefixIcon: Icons.badge_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Enter the staff member\'s full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel('Role'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: _inputDecoration(
                        hint: 'Select a role',
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
                        setState(() => _selectedRole = value);
                      },
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel('Username'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _usernameCtrl,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: _inputDecoration(
                        hint: 'e.g. konduktor03',
                        prefixIcon: Icons.person_outline,
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Username is required';
                        if (text.length < 4) {
                          return 'Use at least 4 characters';
                        }
                        final valid = RegExp(
                          r'^[a-zA-Z0-9._-]+$',
                        ).hasMatch(text);
                        if (!valid) {
                          return 'Only letters, numbers, dots, underscores, and dashes are allowed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel('Bus badge'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _badgeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: _inputDecoration(
                        hint: 'e.g. BUS-005',
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
                    const SizedBox(height: 20),
                    const _FieldLabel('Password'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        hint: 'Create a password',
                        prefixIcon: Icons.lock_outline,
                        suffix: GestureDetector(
                          onTap: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final text = value ?? '';
                        if (text.isEmpty) return 'Password is required';
                        if (text.length < 8) {
                          return 'Use at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel('Confirm password'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordCtrl,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleSignup(),
                      decoration: _inputDecoration(
                        hint: 'Re-enter your password',
                        prefixIcon: Icons.lock_reset_outlined,
                        suffix: GestureDetector(
                          onTap: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                          child: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').isEmpty) {
                          return 'Please confirm the password';
                        }
                        if (value != _passwordCtrl.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const _FieldLabel('Assigned routes'),
                    const SizedBox(height: 8),
                    Text(
                      'These routes appear in My Routes and are used when starting a live trip.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              _errorMessage != null && _selectedRoutes.isEmpty
                              ? Colors.red.shade200
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: routes
                            .map(
                              (route) => FilterChip(
                                label: Text('${route.code} · ${route.name}'),
                                selected: _selectedRoutes.contains(route.id),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedRoutes.add(route.id);
                                    } else {
                                      _selectedRoutes.remove(route.id);
                                    }
                                  });
                                },
                                selectedColor: AppColors.primaryVeryLight,
                                checkmarkColor: AppColors.primary,
                                side: BorderSide(color: Colors.grey.shade300),
                                labelStyle: TextStyle(
                                  color: _selectedRoutes.contains(route.id)
                                      ? AppColors.primaryDark
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primary
                              .withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
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
                                'CREATE ACCOUNT',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 1.1,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _FooterCard(
                      prompt: 'Already have a staff account?',
                      actionLabel: 'Back to login',
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const DriverLoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: Colors.grey[400], size: 20),
      suffixIcon: suffix != null
          ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
          : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: Colors.grey[50],
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
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
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

class _AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AuthHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4DD0E1), Color(0xFF00ACC1), Color(0xFF00838F)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.drive_eta_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

class _FooterCard extends StatelessWidget {
  final String prompt;
  final String actionLabel;
  final VoidCallback onTap;

  const _FooterCard({
    required this.prompt,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              prompt,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
