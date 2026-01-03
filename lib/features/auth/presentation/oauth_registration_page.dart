import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_app/core/utils/logger.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/features/auth/data/auth_repository.dart';
import 'package:kantin_app/features/invitation/providers/invitation_provider.dart';
import 'package:kantin_app/core/providers/appwrite_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// OAuth Registration Page
/// 
/// Dedicated page for Google OAuth users to select their role
/// This page is more robust than dialog for handling OAuth redirects
/// Data comes from authProvider.pendingOAuthRegistration
class OAuthRegistrationPage extends ConsumerStatefulWidget {
  const OAuthRegistrationPage({super.key});

  @override
  ConsumerState<OAuthRegistrationPage> createState() => _OAuthRegistrationPageState();
}

class _OAuthRegistrationPageState extends ConsumerState<OAuthRegistrationPage> {
  @override
  void initState() {
    super.initState();
    // Auto-register if intended role is already selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndAutoRegister();
    });
  }

  Future<void> _checkAndAutoRegister() async {
    AppLogger.info('🔍 [AUTO-REGISTER] Starting check...');
    final authState = ref.read(authProvider);
    final pendingOAuth = authState.pendingOAuthRegistration;

    if (pendingOAuth == null || pendingOAuth.intendedRole == null) {
      AppLogger.info('⏭️ [AUTO-REGISTER] No intended role - showing selection');
      return; // No auto-register, show role selection
    }

    // Auto-register based on intended role
    final role = pendingOAuth.intendedRole!;
    final email = pendingOAuth.email;
    final userId = pendingOAuth.userId;
    
    AppLogger.info('✅ [AUTO-REGISTER] Role: $role | Email: $email | ID: $userId');

    try {
      if (role == 'owner') {
        AppLogger.info('👔 [AUTO-REGISTER] Registering owner...');
        await ref.read(authProvider.notifier).registerAsOwner(email, userId);
        AppLogger.info('✅ [AUTO-REGISTER] Owner registered!');
      } else if (role == 'tenant' || role == 'staff') {
        AppLogger.info('🏪 [AUTO-REGISTER] Registering ${role.toUpperCase()}...');
        // For tenant/staff, retrieve pending code and assign
        AppLogger.info('💾 [AUTO-REGISTER] Retrieving pending code...');
        final prefs = await SharedPreferences.getInstance();
        final pendingCode = prefs.getString('pending_tenant_code');
        final pendingTenantId = prefs.getString('pending_tenant_id');
        final pendingDocId = prefs.getString('pending_invitation_doc_id');
        
        AppLogger.info('📋 [AUTO-REGISTER] Code: $pendingCode | TenantID: $pendingTenantId');

        if (pendingCode == null || pendingTenantId == null) {
          AppLogger.warning('⚠️ [AUTO-REGISTER] Missing tenant code! Redirecting to code entry...');
          
          // Instead of error, redirect to code entry page
          // User needs to input their invitation code first
          if (mounted) {
            if (role == 'staff') {
              AppLogger.info('🔄 Redirecting to staff code entry page');
              context.go('/enter-staff-code');
            } else {
              AppLogger.info('🔄 Redirecting to tenant code entry page');
              context.go('/enter-tenant-code');
            }
          }
          return; // Exit auto-register flow
        }

        // Register with appropriate role
        AppLogger.info('👤 [AUTO-REGISTER] Creating user profile...');
        
        // Create user profile WITH tenant_id directly in one step
        // This fixes document_not_found error caused by timing issues
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.createUserProfile(
          userId: userId,
          email: email,
          role: role,
          name: email.split('@')[0],
          subRole: role == 'staff' ? 'tenant_staff' : 'owner',
          tenantId: pendingTenantId, // ← FIX: Set tenant_id directly on creation
        );
        AppLogger.info('✅ [AUTO-REGISTER] User profile created with tenant_id!');

        // Call create-user function to set Auth labels (OAuth handler)
        AppLogger.info('🏷️ [AUTO-REGISTER] Setting Auth labels via create-user function...');
        try {
          final functions = ref.read(appwriteFunctionsProvider);
          await functions.createExecution(
            functionId: 'create-user',
            body: jsonEncode({
              'action': 'set_oauth_labels',
              'userId': userId,
              'role': role == 'tenant' ? 'tenant' : 'staff',
            }),
          );
          AppLogger.info('✅ [AUTO-REGISTER] Auth labels set successfully!');
        } catch (e) {
          AppLogger.error('⚠️ [AUTO-REGISTER] Failed to set labels (non-critical)', e);
        }

        // Mark invitation code as used
        if (pendingDocId != null) {
          AppLogger.info('✔️ [AUTO-REGISTER] Marking code as used...');
          final invitationRepo = ref.read(invitationRepositoryProvider);
          await invitationRepo.markAsUsed(pendingDocId, userId);
          AppLogger.info('✅ [AUTO-REGISTER] Code marked used!');
        }

        // Clear stored values
        AppLogger.info('🧹 [AUTO-REGISTER] Clearing storage...');
        await prefs.remove('pending_tenant_code');
        await prefs.remove('pending_tenant_id');
        await prefs.remove('pending_invitation_doc_id');
        AppLogger.info('✅ [AUTO-REGISTER] Storage cleared!');

        // DON'T refresh profile yet - router will auto-redirect and unmount widget!
        // Show dialog FIRST, then refresh and navigate
        
        AppLogger.info('🎉 [AUTO-REGISTER] Showing success dialog...');
        AppLogger.info('🔍 [AUTO-REGISTER] Widget mounted: $mounted | Role: $role');
        
        if (mounted) {
          // Store page context BEFORE showing dialog
          final pageContext = context;
          
          // Show dialog immediately (not post-frame since we control navigation now)
          AppLogger.info('📺 [AUTO-REGISTER] Displaying dialog...');
          
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              AppLogger.info('🏗️ [AUTO-REGISTER] Dialog builder called!');
              
              // Extract name from email (e.g., "john@gmail.com" -> "John")
              final userName = email.split('@')[0];
              final capitalizedName = userName[0].toUpperCase() + userName.substring(1);
              
              return AlertDialog(
                icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
                title: const Text('Registrasi Berhasil!'),
                content: Text(
                  'Akun ${role == 'tenant' ? 'Tenant' : 'Staff'} Anda berhasil dibuat.\n\n'
                  'Selamat datang di sistem! 🎉\n\n'
                  'Klik Lanjutkan untuk login.',
                  textAlign: TextAlign.center,
                ),
                actions: [
                  FilledButton(
                    onPressed: () {
                      AppLogger.info('👆 [AUTO-REGISTER] Lanjutkan button pressed!');
                      
                      // 1. Clear pending OAuth state FIRST
                      ref.read(authProvider.notifier).clearPendingOAuthRegistration();
                      AppLogger.info('🧹 [AUTO-REGISTER] Pending OAuth state cleared');
                      
                      // 2. Close dialog
                      Navigator.of(ctx).pop();
                      AppLogger.info('✅ [AUTO-REGISTER] Dialog closed');
                      
                      // 3. Navigate to login page using fresh context
                      // IMPORTANT: Use context here (not pageContext) to get current router
                      AppLogger.info('🚀 [AUTO-REGISTER] Redirecting to login page...');
                      GoRouter.of(pageContext).go('/login');
                    },
                    child: const Text('Lanjutkan'),
                  ),
                ],
              );
            },
          );
          
          AppLogger.info('✅ [AUTO-REGISTER] User will be auto-redirected to dashboard!');
        } else {
          AppLogger.error('❌ [AUTO-REGISTER] Widget not mounted!');
        }
      }
      AppLogger.info('🎉 [AUTO-REGISTER] Process complete!');
      // For owner, navigation will be handled by router based on user role
    } catch (e, stack) {
      AppLogger.error('💥 [AUTO-REGISTER] Failed!', e, stack);
      // Show error if auto-register fails
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Registration Failed'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final pendingOAuth = authState.pendingOAuthRegistration;

    // If no pending registration, redirect to home
    if (pendingOAuth == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/');
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If auto-registering, show loading
    if (pendingOAuth.intendedRole != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Membuat Akun...'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text(
                'Sistem sedang membuat akun Anda',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Mohon tunggu sebentar...',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Show role selection (only if no intended role)
    final email = pendingOAuth.email;
    final userId = pendingOAuth.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Peran Anda'),
        automaticallyImplyLeading: false, // Disable back button
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Icon(
                Icons.account_circle,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Akun Belum Terdaftar',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              
              // Description
              Text(
                'Akun Google Anda ($email) berhasil login, tetapi belum terdaftar di sistem.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              
              Text(
                'Silakan pilih peran Anda untuk melanjutkan:',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 32),
              
              // Owner Button
              FilledButton.icon(
                onPressed: authState.isLoading
                    ? null
                    : () async {
                        try {
                          await ref.read(authProvider.notifier).registerAsOwner(
                            email,
                            userId,
                          );
                          // Navigation handled by router based on user role
                        } catch (e) {
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Registration Failed'),
                                content: Text(e.toString()),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.business),
                label: authState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Pemilik Usaha'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              
              // Tenant Button
              FilledButton.tonalIcon(
                onPressed: authState.isLoading
                    ? null
                    : () async {
                        try {
                          await ref.read(authProvider.notifier).registerAsTenant(
                            email,
                            userId,
                          );
                          
                          // Router will auto-redirect based on tenant_id
                          // No manual navigation needed!
                        } catch (e) {
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Registration Failed'),
                                content: Text(e.toString()),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.store),
                label: authState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Tenant'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              
              // Staff Button
              FilledButton.tonalIcon(
                onPressed: authState.isLoading
                    ? null
                    : () async {
                        try {
                          await ref.read(authProvider.notifier).registerAsStaff(
                            email,
                            userId,
                          );
                          
                          // Router will auto-redirect based on tenant_id
                          // No manual navigation needed!
                        } catch (e) {
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Registration Failed'),
                                content: Text(e.toString()),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.person),
                label: authState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Staff'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              
              const Spacer(),
              
              // Cancel Button
              OutlinedButton(
                onPressed: authState.isLoading
                    ? null
                    : () async {
                        AppLogger.info('🔙 User cancelled registration - logging out');
                        
                        // Logout from OAuth session
                        await ref.read(authProvider.notifier).logout();
                        
                        if (context.mounted) {
                          context.go('/');
                        }
                      },
                child: const Text('Logout (Batalkan)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
