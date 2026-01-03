import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/features/invitation/data/invitation_repository.dart';
import 'package:kantin_app/shared/providers/appwrite_provider.dart';

/// Invitation Repository Provider
final invitationRepositoryProvider = Provider<InvitationRepository>((ref) {
  final database = ref.watch(appwriteDatabaseProvider);
  return InvitationRepository(database);
});
