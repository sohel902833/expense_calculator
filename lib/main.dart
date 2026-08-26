import 'package:expense_calculator/common/providers/theme_provider.dart';
import 'package:expense_calculator/constants/color.dart';
import 'package:expense_calculator/features/auth/controller/auth_controller.dart';
import 'package:expense_calculator/features/auth/screens/login_screen.dart';
import 'package:expense_calculator/features/common/error_screen.dart';
import 'package:expense_calculator/features/common/loading_screen.dart';
import 'package:expense_calculator/features/dashboard/screens/dashboard_screen.dart';
import 'package:expense_calculator/router/router.dart';
import 'package:flutter/material.dart';
//import flutter staff
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider); // 👈 listen to theme mode

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Expense Calculator",
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.blue),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black26),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black26),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(backgroundColor: appBarColor),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white38),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
      ),
      themeMode: themeMode,
      onGenerateRoute: (settings) => generateRoute(settings),
      home: ref
          .watch(userDataAuthProvider)
          .when(
            data: (user) {
              if (user == null) {
                return const LoginScreen();
              }
              return const DashboardScreen();
            },
            error: (err, trace) {
              print("Error ===>$err");
              return ErrorScreen(error: err.toString());
            },
            loading: () => LoadingScreen(),
          ),
    );
  }
}
