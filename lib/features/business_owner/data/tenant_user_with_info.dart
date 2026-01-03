import 'package:kantin_app/shared/models/user_model.dart';

/// Model for tenant user with tenant name included
class TenantUserWithInfo {
  final UserModel user;
  final String tenantName;
  final String? tenantType;

  TenantUserWithInfo({
    required this.user,
    required this.tenantName,
    this.tenantType,
  });
}
