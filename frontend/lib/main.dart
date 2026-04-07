import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
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
import 'utils/colors.dart';
import 'screens/create_tutorial_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'ArtLearn',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: NotificationService.messengerKey,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: GoogleFonts.inter().fontFamily,
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => Consumer<AuthProvider>(
            builder: (_, auth, __) => auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
          ),
          '/home': (context) => const HomeScreen(),
          '/tutorials': (context) => const TutorialsScreen(),
          '/tutorial_detail': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as String;
            return TutorialDetailScreen(tutorialId: args);
          },
          '/art_draw': (context) => const ArtDrawScreen(),
          '/explore': (context) => const ExploreScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/edit_profile': (context) => const EditProfileScreen(),
          '/liked': (context) => const LikedScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/create_tutorial': (context) => const CreateTutorialScreen(),
          '/artwork_detail': (context) {
            final id = ModalRoute.of(context)!.settings.arguments as String;
            return ArtworkDetailScreen(artworkId: id);
          },
        },
      ),
    );
  }
}