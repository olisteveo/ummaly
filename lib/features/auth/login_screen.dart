import 'package:flutter/material.dart';
import 'package:ummaly/features/home/home_screen.dart';
import 'package:ummaly/features/auth/register_screen.dart';
import 'package:ummaly/features/auth/auth_service.dart';
import 'package:ummaly/theme/styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  final AuthService _authService = AuthService();

  String _error = '';
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _passwordFocus.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await _authService.loginUser(
        _email.text.trim(),
        _password.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extra bottom padding when keyboard is open so nothing is hidden
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error.isNotEmpty) ...[
                  Text(_error, style: AppTextStyles.error),
                  const SizedBox(height: 12),
                ],

                // Email
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username, AutofillHints.email],
                  onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Email is required';
                    // lightweight email check
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Password
                TextFormField(
                  controller: _password,
                  focusNode: _passwordFocus,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _signIn(),
                  validator: (v) {
                    final value = v ?? '';
                    if (value.isEmpty) return 'Password is required';
                    if (value.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                    child: const Text('Forgot Password?'),
                  ),
                ),

                const SizedBox(height: 12),

                // Login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: AppButtons.primaryButton,
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text('Login'),
                  ),
                ),

                const SizedBox(height: 20),

                // Register link
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text("Don't have an account? Register here"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
