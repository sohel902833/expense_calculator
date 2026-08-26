import 'package:expense_calculator/common/repository/utils/utils.dart';
import 'package:expense_calculator/constants/color.dart';
import 'package:expense_calculator/features/auth/controller/auth_controller.dart';
import 'package:expense_calculator/features/auth/controller/local_auth_controller.dart';
import 'package:expense_calculator/features/auth/screens/login_screen.dart';
import 'package:expense_calculator/features/auth/widgets/auth_widgets.dart';
import 'package:expense_calculator/features/dashboard/screens/dashboard_screen.dart';
import 'package:expense_calculator/features/offline_mode/controller/offline_mode_controller.dart';
import 'package:expense_calculator/features/offline_mode/repository/offline_mode_repository.dart';
import 'package:expense_calculator/features/session_lock/controller/session_lock_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupScreen extends ConsumerStatefulWidget {
  static const routeName = '/signup-screen';
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  bool _continueOffline = false;

  @override
  void initState() {
    super.initState();
    ref.read(offlineModeRepositoryProvider).isOfflineModePreferred().then((
      preferred,
    ) {
      if (mounted) setState(() => _continueOffline = preferred);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onSuccess() {
    setState(() => _isLoading = false);
    ref.read(sessionLockControllerProvider).markActiveNow();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Signup successful!")));
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
      (route) => false,
    );
  }

  void _onError(String? error) {
    var message = error ?? "Something went wrong";
    showSnackBar(context: context, content: message);
    setState(() => _isLoading = false);
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    if (_continueOffline) {
      ref
          .read(localAuthControllerProvider)
          .signupWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
            name: _nameController.text,
            onError: _onError,
            onSuccess: _onSuccess,
          );
      return;
    }

    ref
        .read(authControllerProvider)
        .signupWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
          name: _nameController.text,
          phoneNumber: "",
          onError: _onError,
          onSuccess: () {
            ref.read(offlineModeControllerProvider).setOfflineMode(false);
            _onSuccess();
          },
        );
  }

  void _onSignInTap() {
    Navigator.pushNamed(context, LoginScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeader(
                icon: Icons.person_add_alt_1_rounded,
                title: "Create Account",
                subtitle: "Sign up to start managing your expenses",
                showBackButton: true,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthTextField(
                        controller: _nameController,
                        labelText: "Name",
                        hintText: "John Doe",
                        prefixIcon: Icons.person_outline_rounded,
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your name";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 4),
                      ContinueOfflineCheckbox(
                        value: _continueOffline,
                        onChanged: (value) =>
                            setState(() => _continueOffline = value),
                      ),
                      const SizedBox(height: 12),
                      AuthPrimaryButton(
                        label: "Sign Up",
                        isLoading: _isLoading,
                        onPressed: _submitForm,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account? ",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          GestureDetector(
                            onTap: _onSignInTap,
                            child: const Text(
                              "Sign in",
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
    );
  }
}
