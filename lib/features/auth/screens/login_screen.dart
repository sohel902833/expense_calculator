import 'package:expense_calculator/common/repository/utils/utils.dart';
import 'package:expense_calculator/constants/app_mode.dart';
import 'package:expense_calculator/constants/color.dart';
import 'package:expense_calculator/features/auth/controller/auth_controller.dart';
import 'package:expense_calculator/features/auth/screens/signup_screen.dart';
import 'package:expense_calculator/features/auth/widgets/auth_widgets.dart';
import 'package:expense_calculator/features/dashboard/screens/dashboard_screen.dart';
import 'package:expense_calculator/features/session_lock/controller/session_lock_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const routeName = '/login-screen';
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authController = ref.read(authControllerProvider);
      authController.loginWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
        onError: (String? error) {
          var message = error ?? "Something went wrong";
          showSnackBar(context: context, content: message);
          setState(() => _isLoading = false);
        },
        onSuccess: () {
          setState(() => _isLoading = false);
          // Otherwise a user logging in after being logged out for longer
          // than the session timeout would be immediately re-challenged by
          // their own fresh login.
          ref.read(sessionLockControllerProvider).markActiveNow();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Login successful!")));
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          );
        },
      );
    }
  }

  void _onSignupTap() {
    Navigator.pushNamed(context, SignupScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeader(
                    icon: Icons.account_balance_wallet_rounded,
                    title: "Welcome Back",
                    subtitle: "Sign in to keep track of your expenses",
                  ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthTextField(
                        controller: _emailController,
                        labelText: "Email",
                        hintText: "you@example.com",
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your email";
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$',
                          ).hasMatch(value)) {
                            return "Enter a valid email address";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        controller: _passwordController,
                        labelText: "Password",
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscureText,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your password";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      AuthPrimaryButton(
                        label: "Login",
                        isLoading: _isLoading,
                        onPressed: _submitForm,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          GestureDetector(
                            onTap: _onSignupTap,
                            child: const Text(
                              "Sign up",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: tabColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
                ],
              ),
            ),
          ),
          if (!AppMode.isProd)
            Positioned(
              top: 12,
              right: 12,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${AppMode.current} MODE",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
