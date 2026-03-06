import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/storage_service.dart';
import '../features/auth/login_screen.dart';
import '../features/candidate/video_cv_screen.dart';

final _storageService = StorageService();

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final isLoggedIn = await _storageService.getToken() != null;
      final goingToLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !goingToLogin) return '/login';
      if (isLoggedIn && goingToLogin) return '/video-cv';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/video-cv',
        builder: (context, state) => const VideoCVScreen(),
      ),
    ],
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RobJob',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      routerConfig: buildRouter(),
    );
  }
}
