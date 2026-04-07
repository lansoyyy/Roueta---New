import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';

class ManageAssignedRoutesScreen extends StatefulWidget {
  const ManageAssignedRoutesScreen({super.key});

  @override
  State<ManageAssignedRoutesScreen> createState() =>
      _ManageAssignedRoutesScreenState();
}

class _ManageAssignedRoutesScreenState
    extends State<ManageAssignedRoutesScreen> {
  late final Set<String> _selectedRoutes;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedRoutes = context.read<AuthProvider>().assignedRoutes.toSet();
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final app = context.read<AppProvider>();

    if (_selectedRoutes.isEmpty) {
      setState(() {
        _errorMessage = 'Select at least one assigned route.';
      });
      return;
    }

    final changed =
        _selectedRoutes.length != auth.assignedRoutes.length ||
        !_selectedRoutes.containsAll(auth.assignedRoutes);

    if (app.activeDriverRoute != null && changed) {
      setState(() {
        _errorMessage =
            'Stop the active route before changing assigned route access.';
      });
      return;
    }

    setState(() => _errorMessage = null);

    final error = await auth.updateStaffAccount(
      fullName: auth.driverName ?? '',
      role: auth.driverRole ?? 'driver',
      badge: auth.driverBadge ?? '',
      assignedRoutes: _selectedRoutes.toList(growable: false),
    );

    if (!mounted) return;

    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Assigned routes updated.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final routes = context.watch<AppProvider>().routes;
    final auth = context.watch<AuthProvider>();
    final isOnDuty = context.watch<AppProvider>().activeDriverRoute != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Manage Routes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isOnDuty)
              _InlineBanner(
                message:
                    'Assigned routes affect which trips this account can start. Stop the active route before changing assignments.',
                backgroundColor: AppColors.accentLight,
                textColor: AppColors.gray800,
                icon: Icons.info_outline,
              ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
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
                    'Assigned Route Access',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selected routes appear in My Routes and determine which trips can be started for ${auth.driverBadge ?? 'this badge'}.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
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
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              _InlineBanner(
                message: _errorMessage!,
                backgroundColor: Colors.red.shade50,
                textColor: Colors.red.shade700,
                icon: Icons.error_outline,
              ),
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
                        'SAVE ROUTES',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineBanner extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  const _InlineBanner({
    required this.message,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
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
