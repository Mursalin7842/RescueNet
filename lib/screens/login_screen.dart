import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../main.dart';
import '../services/db_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  const LoginScreen({super.key, required this.onLogin});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  bool _isSignup = false, _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (_email.text.isEmpty || _pass.text.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      if (_isSignup) {
        await DbService().signup(_email.text.trim(), _pass.text, _name.text.trim());
      } else {
        await DbService().login(_email.text.trim(), _pass.text);
      }
      widget.onLogin();
    } catch (e) {
      setState(() => _error = e.toString().length > 100 ? '${e.toString().substring(0, 100)}...' : e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(children: [
            // Logo
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: C.gradient,
                  boxShadow: [BoxShadow(color: C.red.withAlpha(60), blurRadius: 20, offset: const Offset(0, 8))]),
              child: const Icon(Icons.emergency_rounded, size: 40, color: Colors.white),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text('RescueNet', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: C.charcoal)),
            const SizedBox(height: 4),
            Text('Disaster Response System', style: TextStyle(color: C.mist, fontSize: 14)),
            const SizedBox(height: 40),
            // Form
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: C.radius, boxShadow: C.shadow),
              child: Column(children: [
                if (_isSignup) ...[
                  TextField(controller: _name, decoration: InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_rounded, color: C.mist), fillColor: C.bg)),
                  const SizedBox(height: 12),
                ],
                TextField(controller: _email, decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_rounded, color: C.mist), fillColor: C.bg), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                TextField(controller: _pass, decoration: InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_rounded, color: C.mist), fillColor: C.bg), obscureText: true),
                if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: C.red, fontSize: 12), textAlign: TextAlign.center)),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_isSignup ? 'Create Account' : 'Login', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                )),
              ]),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => setState(() { _isSignup = !_isSignup; _error = null; }),
              child: Text(_isSignup ? 'Already have an account? Login' : "Don't have an account? Sign Up", style: TextStyle(color: C.red)),
            ),
          ]),
        )),
      ),
    );
  }
}
