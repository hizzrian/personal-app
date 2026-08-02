import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'qr/qr_camera_screen.dart';
import 'settings/settings_screen.dart';
import '../utils/app_spacing.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<QrCameraScreenState> _cameraKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const DashboardScreen(),
          QrCameraScreen(key: _cameraKey),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, -4))
          ],
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.panel)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, 'Home', colors),
                _navItem(1, Icons.camera_alt_rounded, 'Camera', colors),
                _navItem(2, Icons.settings_rounded, 'Settings', colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
    // Control camera lifecycle
    if (index == 1) {
      _cameraKey.currentState?.setVisible(true);
    } else {
      _cameraKey.currentState?.setVisible(false);
    }
  }

  Widget _navItem(int index, IconData icon, String label, ColorScheme colors) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            EdgeInsets.symmetric(horizontal: isActive ? 20 : 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 22,
                color: isActive ? AppTheme.onPrimary : colors.onSurfaceVariant),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(label,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: AppTheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      )),
            ],
          ],
        ),
      ),
    );
  }
}
