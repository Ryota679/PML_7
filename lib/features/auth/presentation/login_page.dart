import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_app/core/config/appwrite_config.dart';
import 'package:kantin_app/features/auth/data/auth_repository.dart';
import 'package:kantin_app/features/auth/providers/auth_provider.dart';
import 'package:kantin_app/shared/models/user_model.dart';
import 'package:kantin_app/shared/repositories/tenant_repository.dart';
import 'package:kantin_app/features/tenant/providers/upgrade_token_provider.dart';
import 'package:kantin_app/shared/widgets/deactivated_user_dialog.dart';
import 'package:kantin_app/shared/widgets/device_switch_dialog.dart';
import 'package:kantin_app/shared/widgets/session_expired_dialog.dart';
import 'package:kantin_app/core/utils/device_info_helper.dart';

/// Login Page
/// 
/// Halaman login untuk owner_business dan tenant
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _dialogShown = false; // Track if dialog has been shown

  @override
  void initState() {
    super.initState();
    // Check for deactivated user after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowDeactivatedDialog();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check again when dependencies change (router redirects)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowDeactivatedDialog();
      _checkAndShowDeviceSwitchDialog();
      _checkAndShowSessionExpiredDialog();
    });
  }

  void _checkAndShowDeactivatedDialog() async {
    if (!mounted) return;
    
    final authState = ref.read(authProvider);
    
    // If user is deactivated and dialog hasn't been shown yet
    if (authState.isDeactivatedUser && authState.user != null && !_dialogShown) {
      _dialogShown = true; // Mark as shown to prevent multiple dialogs
      
if (kDebugMode) print('🚨 [LOGIN] Auto-showing deactivated dialog after router redirect');
      final user = authState.user!;
      final userRole = (user.subRole == 'staff') ? 'staff' : 'tenant_user';
      
      await _showDeactivatedUserDialog(user, userRole);
    }
  }

  Future<void> _showDeactivatedUserDialog(UserModel user, String userRole) async {
    // Fetch owner data (tenant owner for staff, business owner for tenant_user)
    String ownerName = 'Owner';
    String ownerEmail = 'owner@example.com';
    String ownerPhone = '628123456789';
    
    try {
      if (userRole == 'staff' && user.tenantId != null) {
        // Staff: fetch tenant owner data
  if (kDebugMode) print('📍 [LOGIN] Fetching tenant owner data for staff');
        
        final tenantRepo = ref.read(tenantRepositoryProvider);
        final tenant = await tenantRepo.getTenantById(user.tenantId!);
        
        if (tenant != null) {
          ownerName = tenant.name;
          
          // Fetch tenant owner user
          final authRepo = ref.read(authRepositoryProvider);
          final response = await authRepo.database.listDocuments(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.usersCollectionId,
            queries: [
              Query.equal('role', 'tenant'),
              Query.isNull('sub_role'),
              Query.equal('tenant_id', user.tenantId!),
              Query.limit(1),
            ],
          );
          
          if (response.documents.isNotEmpty) {
            final ownerUser = UserModel.fromDocument(response.documents.first);
            ownerEmail = ownerUser.email;
            ownerPhone = ownerUser.phone ?? '628123456789';
      if (kDebugMode) print('✅ [LOGIN] Tenant owner data loaded: $ownerName');
          }
        }
      } else if (userRole == 'tenant_user' && user.tenantId != null) {
        // Tenant User: fetch business owner data
  if (kDebugMode) print('📍 [LOGIN] Fetching business owner data for tenant user');
        
        final tenantRepo = ref.read(tenantRepositoryProvider);
        final tenant = await tenantRepo.getTenantById(user.tenantId!);
        
        if (tenant != null) {
          // Fetch business owner using tenant.ownerId
          final authRepo = ref.read(authRepositoryProvider);
          final response = await authRepo.database.listDocuments(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.usersCollectionId,
            queries: [
              Query.equal('user_id', tenant.ownerId),
              Query.limit(1),
            ],
          );
          
          if (response.documents.isNotEmpty) {
            final businessOwner = UserModel.fromDocument(response.documents.first);
            ownerName = businessOwner.fullName;
            ownerEmail = businessOwner.email;
            ownerPhone = businessOwner.phone ?? '628123456789';
      if (kDebugMode) print('✅ [LOGIN] Business owner data loaded: $ownerName');
          }
        }
      }
    } catch (e) {
if (kDebugMode) print('⚠️ [LOGIN] Failed to fetch owner data: $e');
      // Continue with default values
    }
    
    if (!mounted) return;
    
    // Store the page context before showing dialog
    final pageContext = context;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeactivatedUserDialog(
        userRole: userRole,
        ownerName: ownerName,
        ownerEmail: ownerEmail,
        ownerPhone: ownerPhone,
        onLogout: () {
    if (kDebugMode) print('🔴 [LOGOUT] Button clicked - starting logout flow');
          
          // CRITICAL: Clear the deactivated flag FIRST
    if (kDebugMode) print('🔴 [LOGOUT] Clearing deactivated flag...');
          ref.read(authProvider.notifier).clearDeactivatedFlag();
          _dialogShown = false;
    if (kDebugMode) print('✅ [LOGOUT] Flag cleared');
          
          // Navigate immediately (no delay, no async)
    if (kDebugMode) print('🚀 [LOGOUT] Navigating to /guest immediately');
          pageContext.go('/guest');
        },
        onUpgrade: userRole == 'tenant_user' ? () {
          // Generate secure token for payment page access
    if (kDebugMode) print('📱 [UPGRADE] Tenant user wants to upgrade');
          
          final token = ref.read(upgradeTokenProvider.notifier).generateToken(
            userId: user.userId, // Use userId (non-nullable) not id
            userEmail: user.email,
          );
          
          // DON'T clear flag yet - need it for router detection
          // Flag will be cleared by payment page after successful load
          _dialogShown = false;
          
          // Navigate to public payment page with token
          final paymentUrl = '/payment/tenant-upgrade?token=$token';
    if (kDebugMode) print('🚀 [UPGRADE] Navigating to: $paymentUrl');
          pageContext.go(paymentUrl);
        } : null, // Staff doesn't have upgrade option
      ),
    );
  }
  
  void _checkAndShowDeviceSwitchDialog() async {
    if (!mounted) return;
    
    final authState = ref.read(authProvider);
    
    // If device switch detected and dialog hasn't been shown yet
    if (authState.showDeviceSwitchDialog && !_dialogShown) {
      _dialogShown = true; // Mark as shown to prevent multiple dialogs
      
      if (kDebugMode) print('🔄 [LOGIN] Auto-showing device switch dialog');
      
      // Import device switch dialog
      final currentDevice = DeviceInfoHelper.getPlatform();
      final previousDevice = authState.previousLoginDevice;
      final previousLoginAt = authState.previousLoginAt;
      
      await showDialog(
        context: context,
        builder: (_) => DeviceSwitchDialog(
          currentDevice: currentDevice,
          previousDevice: previousDevice,
          previousLoginAt: previousLoginAt,
        ),
      );
      
      // Clear flag after dialog dismissed
      if (mounted) {
        ref.read(authProvider.notifier).clearDeviceSwitchFlag();
        _dialogShown = false;
      }
    }
  }
  
  void _checkAndShowSessionExpiredDialog() async {
    if (!mounted) return;
    
    final authState = ref.read(authProvider);
    
    // If session expired and user was force logged out
    if (authState.sessionExpired && !_dialogShown) {
      _dialogShown = true; // Mark as shown to prevent multiple dialogs
      
      if (kDebugMode) print('⚠️  [LOGIN] Auto-showing session expired dialog');
      
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => SessionExpiredDialog(
          onDismiss: () {
            Navigator.of(context).pop();
          },
        ),
      );
      
      // Clear flag after dialog dismissed
      if (mounted) {
        // Reset flag by setting sessionExpired = false
        // We do this by just resetting to empty AuthState since user already logged out
        _dialogShown = false;
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (!success) {
if (kDebugMode) print('🔍 [LOGIN] Login failed, checking reason...');
      final authState = ref.read(authProvider);
      
if (kDebugMode) print('🔍 [LOGIN] isDeactivatedUser: ${authState.isDeactivatedUser}');
if (kDebugMode) print('🔍 [LOGIN] user: ${authState.user?.username}');
      
      // Check if login failed due to deactivated user
      if (authState.isDeactivatedUser && authState.user != null) {
  if (kDebugMode) print('🚨 [LOGIN] Deactivated user detected in login_page!');
        final user = authState.user!;
        final userRole = (user.subRole == 'staff') ? 'staff' : 'tenant_user';
        
  if (kDebugMode) print('📱 [LOGIN] Showing deactivated dialog for role: $userRole');
        
        // Show deactivated dialog
        if (!mounted) {
    if (kDebugMode) print('⚠️ [LOGIN] Widget not mounted!');
          return;
        }
        
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => DeactivatedUserDialog(
            userRole: userRole,
            // Use dummy data for now
            ownerName: userRole == 'staff' 
                ? 'Tenant Owner Demo' 
                : 'Business Owner Demo',
            ownerEmail: userRole == 'staff'
                ? 'tenant@example.com'
                : 'bo@example.com',
            ownerPhone: userRole == 'staff'
                ? '628987654321'
                : '628123456789',
            onLogout: () async {
              // Already logged out in auth_provider, just close dialog
              Navigator.of(context).pop();
            },
            onUpgrade: null,
          ),
        );
  if (kDebugMode) print('✅ [LOGIN] Dialog closed');
        
        // CRITICAL: Clear the deactivated flag after dialog is dismissed
        // This allows the router to navigate away normally
        if (mounted) {
          ref.read(authProvider.notifier).clearDeactivatedFlag();
    if (kDebugMode) print('✅ [LOGIN] Deactivated flag cleared');
        }
        return;
      }
      
      // Normal error (wrong password, etc)
if (kDebugMode) print('⚠️ [LOGIN] Normal error, showing snackbar');
      final error = authState.error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Login gagal'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Login success - proceed normally (remove old check)
    if (kDebugMode) print('✅ [LOGIN] Login successful, proceeding to dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Icon
                  Icon(
                    Icons.restaurant_menu,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    'Tenant QR-Order',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    'Masuk ke akun Anda',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'nama@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email tidak boleh kosong';
                      }
                      if (!value.contains('@')) {
                        return 'Email tidak valid';
                      }
                      return null;
                    },
                    enabled: !authState.isLoading,
                  ),
                  const SizedBox(height: 16),
                  
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Masukkan password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      if (value.length < 8) {
                        return 'Password minimal 8 karakter';
                      }
                      return null;
                    },
                    enabled: !authState.isLoading,
                  ),
                  const SizedBox(height: 8),
                  
                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: authState.isLoading
                          ? null
                          : () {
                              _showForgotPasswordDialog();
                            },
                      child: const Text('Lupa Password?'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Login Button
                  FilledButton(
                    onPressed: authState.isLoading ? null : _handleLogin,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Masuk'),
                  ),
                  const SizedBox(height: 16),
                  
                  // OR Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'ATAU',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Google Sign In Button
                  OutlinedButton.icon(
                    onPressed: authState.isLoading
                        ? null
                        : () async {
                            // Call Google OAuth handler
                            await ref
                                .read(authProvider.notifier)
                                .handleGoogleSignIn(context);
                          },
                    icon: Image.asset(
                      'assets/images/google_logo.png',
                      height: 24,
                      width: 24,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to Icon if image not found
                        return const Icon(Icons.account_circle);
                      },
                    ),
                    label: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Login dengan Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Registration Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum punya akun?'),
                      TextButton(
                        onPressed: () {
                          context.go('/register');
                        },
                        child: const Text('Daftar sebagai Business Owner'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Info untuk customer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pelanggan tidak perlu login.\nCukup scan QR code di meja.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
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

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lupa Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan email Anda untuk menerima link reset password.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'nama@example.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final email = emailController.text.trim();
              
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email tidak valid'),
                  ),
                );
                return;
              }
              
              final success = await ref
                  .read(authProvider.notifier)
                  .requestPasswordReset(email);
              
              if (!context.mounted) return;
              
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Email reset password telah dikirim'
                        : 'Gagal mengirim email reset password',
                  ),
                  backgroundColor: success
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
              );
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }
}
