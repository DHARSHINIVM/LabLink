import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_dashboard_screen.dart';
import '../app_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final TextEditingController
      _emailController =
      TextEditingController();

  final TextEditingController
      _passwordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // LOGIN
  // ==========================================================================

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final email =
        _emailController.text.trim();

    final password =
        _passwordController.text;

    if (email.isEmpty) {
      setState(() {
        _errorMessage =
            'Please enter your email.';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage =
            'Please enter your password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint(
        'LOGIN: Sending request...',
      );

      final response =
          await ApiService.login(
        email: email,
        password: password,
      );

      debugPrint(
        'LOGIN: API response received',
      );

      final user =
          ApiService.parseUser(
        response,
      );

      debugPrint(
        'LOGIN SUCCESS: '
        '${user.email} | ROLE: ${user.role}',
      );

      if (!mounted) return;

      // Stop loading before navigation.
      setState(() {
        _isLoading = false;
      });

      // ======================================================================
      // ADMIN
      // ======================================================================

      if (user.isAdmin) {
        debugPrint(
          'OPENING ADMIN DASHBOARD',
        );

        Navigator.of(context)
            .pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                AdminDashboardScreen(
              admin: user,
            ),
          ),
        );

        return;
      }

      // ======================================================================
      // STUDENT
      // ======================================================================

      debugPrint(
        'OPENING STUDENT APP',
      );

      Navigator.of(context)
          .pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              const AppShell(),
        ),
      );
    } catch (error) {
      debugPrint(
        'LOGIN ERROR: $error',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _errorMessage = error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ==========================================================================
  // UI
  // ==========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 28,
            ),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 430,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  // ==========================================================
                  // LOGO
                  // ==========================================================

                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFE2F1ED,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          22,
                        ),
                      ),
                      child: const Icon(
                        Icons.hub_rounded,
                        size: 42,
                        color:
                            AppTheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 28,
                  ),

                  // ==========================================================
                  // TITLE
                  // ==========================================================

                  const Center(
                    child: Text(
                      'Welcome to LabLink',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppTheme.text,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  const Center(
                    child: Text(
                      'Access and share institutional resources',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color:
                            AppTheme.mutedText,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 42,
                  ),

                  // ==========================================================
                  // EMAIL
                  // ==========================================================

                  const Text(
                    'Institutional Email',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          AppTheme.text,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  TextField(
                    controller:
                        _emailController,
                    keyboardType:
                        TextInputType
                            .emailAddress,
                    textInputAction:
                        TextInputAction.next,
                    decoration:
                        InputDecoration(
                      hintText:
                          'Enter your institutional email',
                      prefixIcon:
                          const Icon(
                        Icons
                            .email_outlined,
                      ),
                      filled: true,
                      fillColor:
                          Colors.white,
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),
                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),
                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                        borderSide:
                            const BorderSide(
                          color:
                              AppTheme
                                  .primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==========================================================
                  // PASSWORD
                  // ==========================================================

                  const Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          AppTheme.text,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  TextField(
                    controller:
                        _passwordController,
                    obscureText:
                        _obscurePassword,
                    textInputAction:
                        TextInputAction.done,
                    onSubmitted: (_) =>
                        _login(),
                    decoration:
                        InputDecoration(
                      hintText:
                          'Enter your password',
                      prefixIcon:
                          const Icon(
                        Icons
                            .lock_outline,
                      ),
                      suffixIcon:
                          IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                                !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons
                                  .visibility_outlined
                              : Icons
                                  .visibility_off_outlined,
                        ),
                      ),
                      filled: true,
                      fillColor:
                          Colors.white,
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),
                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),
                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                        borderSide:
                            const BorderSide(
                          color:
                              AppTheme
                                  .primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // ==========================================================
                  // FORGOT PASSWORD
                  // ==========================================================

                  Align(
                    alignment:
                        Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color:
                              AppTheme
                                  .secondary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  // ==========================================================
                  // ERROR
                  // ==========================================================

                  if (_errorMessage != null)
                    Container(
                      width:
                          double.infinity,
                      margin:
                          const EdgeInsets.only(
                        bottom: 16,
                      ),
                      padding:
                          const EdgeInsets.all(
                        12,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.red
                            .withValues(
                          alpha: 0.08,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Icon(
                            Icons
                                .error_outline,
                            color:
                                Colors.red,
                            size: 20,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style:
                                  const TextStyle(
                                color:
                                    Colors
                                        .red,
                                fontSize:
                                    13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ==========================================================
                  // SIGN IN
                  // ==========================================================

                  SizedBox(
                    width:
                        double.infinity,
                    height: 54,
                    child:
                        ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : _login,
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            AppTheme
                                .primary,
                        foregroundColor:
                            Colors.white,
                        disabledBackgroundColor:
                            AppTheme
                                .primary
                                .withValues(
                          alpha: 0.55,
                        ),
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2.5,
                                color:
                                    Colors
                                        .white,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style:
                                  TextStyle(
                                fontSize:
                                    16,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(
                    height: 28,
                  ),

                  // ==========================================================
                  // INFO
                  // ==========================================================

                  Center(
                    child: Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFEAF3F0,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          10,
                        ),
                      ),
                      child: const Text(
                        'Secure institutional access',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              AppTheme
                                  .mutedText,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  const Center(
                    child: Text(
                      'LabLink',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Color(
                          0xFF84918E,
                        ),
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}