// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_swap_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tenantSwapServiceHash() => r'4023489deaa11b7b151f960aec60225bde653b25';

/// Handles tenant selection when user is downgraded from trial to free tier
///
/// Free tier Business Owners can only have 2 active tenants.
/// During D-7 selection window, they choose which 2 to keep active.
///
/// Copied from [tenantSwapService].
@ProviderFor(tenantSwapService)
final tenantSwapServiceProvider =
    AutoDisposeProvider<TenantSwapService>.internal(
      tenantSwapService,
      name: r'tenantSwapServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$tenantSwapServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TenantSwapServiceRef = AutoDisposeProviderRef<TenantSwapService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
