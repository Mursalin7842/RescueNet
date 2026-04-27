import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/db_service.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DbService().init();
  runApp(const RescueNetApp());
}

/// Premium color palette
class C {
  static const Color bg = Color(0xFFF5F0EB);
  static const Color card = Colors.white;
  static const Color red = Color(0xFFDC3545);
  static const Color redDark = Color(0xFFB02A37);
  static const Color orange = Color(0xFFE8890C);
  static const Color green = Color(0xFF28A745);
  static const Color blue = Color(0xFF0D6EFD);
  static const Color charcoal = Color(0xFF2B2D42);
  static const Color mist = Color(0xFF8D99AE);
  static const Color amber = Color(0xFFD4A373);
  static final shadow = [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 16, offset: const Offset(0, 4))];
  static final radius = BorderRadius.circular(18);
  static final gradient = LinearGradient(colors: [red, orange], begin: Alignment.topLeft, end: Alignment.bottomRight);
}

class RescueNetApp extends StatelessWidget {
  const RescueNetApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RescueNet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: C.bg,
        colorScheme: ColorScheme.fromSeed(seedColor: C.red, brightness: Brightness.light),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: C.bg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: C.charcoal,
          titleTextStyle: TextStyle(color: C.charcoal, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: C.red, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        cardTheme: CardThemeData(
          color: Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() { super.initState(); _check(); }

  Future<void> _check() async {
    final u = await DbService().getUser();
    if (mounted) setState(() { _loggedIn = u != null; _checking = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) return const Scaffold(body: Center(child: CircularProgressIndicator(color: C.red)));
    return _loggedIn
        ? const ShellScreen()
        : LoginScreen(onLogin: () => setState(() => _loggedIn = true));
  }
}
