import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/app_colors.dart';
import '../../viewmodels/auth_view_model.dart';
import '../dashboard/dashboard_page.dart';
import '../dashboard/employee_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _loginController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authViewModel = context.read<AuthViewModel>();

    final success = await authViewModel.login(
      login: _loginController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    // Login haikufanikiwa
    if (!success) {
      return;
    }

    // Chukua user aliyerudishwa na API
    final user = authViewModel.user;

    // Chukua roles
    final roles = user?['roles'];

    bool isSuperAdmin = false;

    if (roles is List) {
      isSuperAdmin = roles.any(
            (role) =>
        role is Map &&
            role['name']?.toString().toLowerCase() ==
                'super_admin',
      );
    }

    // Super Admin
    if (isSuperAdmin) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const DashboardPage(),
        ),
            (route) => false,
      );

      return;
    }

    // HR, ICT, Developer, Accountant,
    // Secretary, Unit Head, Staff, etc.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const EmployeeDashboardPage(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final bool isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 40 : 24,
              vertical: 30,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 500 : 450,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(
                      isTablet: isTablet,
                    ),

                    const SizedBox(height: 35),

                    _buildLoginCard(
                      isTablet: isTablet,
                    ),

                    const SizedBox(height: 25),

                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required bool isTablet,
  }) {
    return Column(
      children: [
        Container(
          width: isTablet ? 105 : 90,
          height: isTablet ? 105 : 90,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.20,
                ),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.co_present_rounded,
            color: Colors.white,
            size: isTablet ? 52 : 45,
          ),
        ),

        const SizedBox(height: 22),

        Text(
          'Staff Attendance',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 30 : 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Management System',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 20 : 17,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          'Sign in to continue to your account',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 15 : 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard({
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.all(
        isTablet ? 32 : 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.06,
            ),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome Back',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Enter your credentials to sign in.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'Email or Employee Number',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _loginController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [
              AutofillHints.username,
            ],
            decoration: InputDecoration(
              hintText:
              'Enter email or employee number',
              prefixIcon: const Icon(
                Icons.person_outline_rounded,
              ),
              prefixIconColor: AppColors.primary,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.danger,
                ),
              ),
              focusedErrorBorder:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.danger,
                  width: 1.5,
                ),
              ),
              contentPadding:
              const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Please enter your email or employee number';
              }

              return null;
            },
          ),

          const SizedBox(height: 20),

          const Text(
            'Password',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [
              AutofillHints.password,
            ],
            onFieldSubmitted: (_) {
              final viewModel =
              context.read<AuthViewModel>();

              if (!viewModel.isLoading) {
                _login();
              }
            },
            decoration: InputDecoration(
              hintText: 'Enter your password',
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
              ),
              prefixIconColor: AppColors.primary,
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? 'Show password'
                    : 'Hide password',
                onPressed: () {
                  setState(() {
                    _obscurePassword =
                    !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              suffixIconColor:
              AppColors.textSecondary,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.danger,
                ),
              ),
              focusedErrorBorder:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.danger,
                  width: 1.5,
                ),
              ),
              contentPadding:
              const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (value == null ||
                  value.isEmpty) {
                return 'Please enter your password';
              }

              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }

              return null;
            },
          ),

          const SizedBox(height: 25),

          Consumer<AuthViewModel>(
            builder: (
                context,
                viewModel,
                child,
                ) {
              if (viewModel.errorMessage != null) {
                return Container(
                  margin:
                  const EdgeInsets.only(
                    bottom: 18,
                  ),
                  padding:
                  const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger
                        .withValues(alpha: 0.08),
                    borderRadius:
                    BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.danger
                          .withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.danger,
                        size: 21,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          viewModel.errorMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            color:
                            AppColors.danger,
                            fontWeight:
                            FontWeight.w500,
                          ),
                        ),
                      ),

                      InkWell(
                        onTap:
                        viewModel.clearError,
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color:
                          AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),

          Consumer<AuthViewModel>(
            builder: (
                context,
                viewModel,
                child,
                ) {
              return SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed:
                  viewModel.isLoading
                      ? null
                      : _login,
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    AppColors.primary,
                    foregroundColor:
                    Colors.white,
                    disabledBackgroundColor:
                    AppColors.primary
                        .withValues(
                      alpha: 0.55,
                    ),
                    elevation: 0,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                  child: viewModel.isLoading
                      ? const SizedBox(
                    width: 23,
                    height: 23,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                        Colors.white,
                      ),
                    ),
                  )
                      : const Row(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                    children: [
                      Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons
                            .arrow_forward_rounded,
                        size: 21,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security_rounded,
              size: 17,
              color: AppColors.primary
                  .withValues(alpha: 0.8),
            ),
            const SizedBox(width: 6),
            const Text(
              'Secure Staff Attendance System',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        const Text(
          'Ministry of Health Zanzibar',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Version 1.0.0',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}