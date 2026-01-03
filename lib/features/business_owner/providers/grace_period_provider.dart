import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/core/providers/appwrite_provider.dart';
import 'package:kantin_app/features/business_owner/services/grace_period_service.dart';

/// Provider for Grace Period Service
final gracePeriodServiceProvider = Provider<GracePeriodService>((ref) {
  final databases = ref.watch(appwriteDatabasesProvider);
  return GracePeriodService(databases);
});
