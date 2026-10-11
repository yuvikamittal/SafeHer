import 'package:flutter/material.dart';

import '../Screens/safety_assistant_screen.dart';
import '../Screens/alerts_noti_screen.dart';
import '../Screens/dashboard_screen.dart';
import '../Screens/emergency_contacts_screen.dart';
import '../Screens/live_location_screen.dart';
import '../Screens/login_screen.dart';
import '../Screens/nearby_help_screen.dart';
import '../Screens/profile_screen.dart';
import '../Screens/request_access_screen.dart';
import '../Screens/safe_route_screen.dart';
import '../Screens/settings_screen.dart';
import '../Screens/sos_screen.dart';
import '../Screens/splash_screen.dart';
import 'app_routes.dart';

/// Centralised navigation. A single [onGenerateRoute] resolves every named
/// route, passes typed arguments, and falls back to a safe screen for any
/// unknown route — so no navigation can ever lead nowhere.
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _fade(const SplashScreen());
      case AppRoutes.login:
        return _fade(const LoginScreen());
      case AppRoutes.requestAccess:
        return _page(const RequestAccessScreen());
      case AppRoutes.dashboard:
        return _page(DashboardScreen(email: _email(settings)));
      case AppRoutes.profile:
        return _page(ProfileScreen(email: _email(settings)));
      case AppRoutes.sos:
        return _page(const SOSScreen());
      case AppRoutes.liveLocation:
        return _page(const LiveLocationScreen());
      case AppRoutes.safeRoute:
        return _page(const SafeRouteScreen());
      case AppRoutes.emergencyContacts:
        return _page(const EmergencyContactsScreen());
      case AppRoutes.nearbyHelp:
        return _page(const NearbyHelpScreen());
      case AppRoutes.alerts:
        return _page(const AlertsNotiScreen());
      case AppRoutes.assistant:
        return _page(const SafetyAssistantScreen());
      case AppRoutes.settings:
        return _page(const SettingsScreen());
      default:
        return _page(_NotFoundScreen(routeName: settings.name));
    }
  }

  /// Reads a String email argument, defaulting to empty when absent.
  static String _email(RouteSettings settings) =>
      settings.arguments is String ? settings.arguments as String : '';

  static PageRoute<dynamic> _page(Widget child) =>
      MaterialPageRoute<dynamic>(builder: (_) => child);

  static PageRoute<dynamic> _fade(Widget child) => PageRouteBuilder<dynamic>(
    transitionDuration: const Duration(milliseconds: 600),
    pageBuilder: (_, _, _) => child,
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

/// Safe fallback shown if an unknown route is requested.
class _NotFoundScreen extends StatelessWidget {
  final String? routeName;
  const _NotFoundScreen({this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white70,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.explore_off_rounded,
                color: Colors.white38,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Screen "${routeName ?? 'unknown'}" is not available yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
