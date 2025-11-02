import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/bloc/auth/auth_bloc.dart';
import '../../../core/bloc/auth/auth_event.dart';
import '../../../core/theme/app_theme.dart';

class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LogoutDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? screenWidth * 0.9 : 320,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with clean background
              Container(
                width: isSmallScreen ? 56 : 64,
                height: isSmallScreen ? 56 : 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.logout_rounded,
                    size: isSmallScreen ? 28 : 32,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),

              SizedBox(height: isSmallScreen ? 16 : 20),

              // Title
              Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 22,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                  letterSpacing: 0.2,
                ),
              ),

              SizedBox(height: isSmallScreen ? 8 : 10),

              // Message
              Text(
                'Are you sure you want to sign out from your account?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
                  color: isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
                  height: 1.5,
                ),
              ),

              SizedBox(height: isSmallScreen ? 20 : 24),

              // Action Buttons - Properly aligned
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: SizedBox(
                      height: isSmallScreen ? 44 : 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.grey.shade800.withOpacity(0.5)
                              : const Color(0xFFF5F5F5),
                          foregroundColor: isDark
                              ? AppTheme.textPrimaryDark
                              : const Color(0xFF1A1A1A),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Sign Out Button
                  Expanded(
                    child: SizedBox(
                      height: isSmallScreen ? 44 : 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.read<AuthBloc>().add(AuthLogoutRequested());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryLight,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
