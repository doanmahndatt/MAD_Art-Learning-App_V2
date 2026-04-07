import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/app_provider.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/tutorials_screen.dart';
import 'screens/tutorial_detail_screen.dart';
import 'screens/art_draw_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/liked_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/artwork_detail_screen.dart';
import 'screens/create_tutorial_screen.dart';
import 'utils/colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _lightTheme() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      background: AppColors.background,
      surface: AppColors.surface,
      onPrimary: Colors.white,
      onBackground: AppColors.text,
      onSurface: AppColors.text,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.surface, elevation: 0, foregroundColor: AppColors.text),
    cardColor: AppColors.surface,
    dividerColor: AppColors.border,
  );

  ThemeData _darkTheme() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      background: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      onPrimary: Colors.white,
      onBackground: AppColors.darkText,
      onSurface: AppColors.darkText,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.darkSurface, elevation: 0, foregroundColor: AppColors.darkText),
    cardColor: AppColors.darkSurface,
    dividerColor: AppColors.darkBorder,
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (_, app, __) => MaterialApp(
          title: 'ArtLearn',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: NotificationService.messengerKey,
          theme: _lightTheme(),
          darkTheme: _darkTheme(),
          themeMode: app.themeMode,
          home: const _StartupRouter(),
          routes: {
            '/home':      (_) => const HomeScreen(),
            '/tutorials': (_) => const TutorialsScreen(),
            '/tutorial_detail': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as String;
              return TutorialDetailScreen(tutorialId: args);
            },
            '/art_draw':     (_) => const ArtDrawScreen(),
            '/explore':      (_) => const ExploreScreen(),
            '/profile':      (_) => const ProfileScreen(),
            '/edit_profile': (_) => const EditProfileScreen(),
            '/liked':        (_) => const LikedScreen(),
            '/settings':     (_) => const SettingsScreen(),
            '/create_tutorial': (_) => const CreateTutorialScreen(),
            '/artwork_detail': (context) {
              final id = ModalRoute.of(context)!.settings.arguments as String;
              return ArtworkDetailScreen(artworkId: id);
            },
          },
        ),
      ),
    );
  }
}

/// Handles app startup: restore session from saved token before deciding which screen to show
class _StartupRouter extends StatefulWidget {
  const _StartupRouter();
  @override State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    await Provider.of<AuthProvider>(context, listen: false).loadUserFromToken();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)),
      );
    }
    final auth = context.watch<AuthProvider>();
    return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}