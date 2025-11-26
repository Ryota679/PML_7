import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_app/core/utils/logger.dart';
import 'package:kantin_app/features/registration/data/registration_submission_repository.dart';

/// Registration Submission State
class RegistrationSubmissionState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  RegistrationSubmissionState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  RegistrationSubmissionState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return RegistrationSubmissionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Registration Submission Notifier
class RegistrationSubmissionNotifier
    extends StateNotifier<RegistrationSubmissionState> {
  final RegistrationSubmissionRepository _repository;

  RegistrationSubmissionNotifier(this._repository)
      : super(RegistrationSubmissionState());

  /// Submit registration
  Future<bool> submitRegistration({
    required String fullName,
    required String email,
    required String password,
    required String businessName,
    required String businessType,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      AppLogger.info('Submitting registration for: $email');

      await _repository.submitRegistration(
        fullName: fullName,
        email: email,
        password: password,
        businessName: businessName,
        businessType: businessType,
        phone: phone,
      );

      state = state.copyWith(isLoading: false, isSuccess: true);
      AppLogger.info('Registration submitted successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to submit registration', e, stackTrace);

      String errorMessage = 'Gagal mengirim registrasi';
      if (e.toString().contains('Document already exists')) {
        errorMessage = 'Email sudah terdaftar';
      } else if (e.toString().contains('Invalid email')) {
        errorMessage = 'Format email tidak valid';
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        isSuccess: false,
      );
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = RegistrationSubmissionState();
  }
}

/// Registration Submission Provider
final registrationSubmissionProvider = StateNotifierProvider<
    RegistrationSubmissionNotifier, RegistrationSubmissionState>((ref) {
  final repository = ref.watch(registrationSubmissionRepositoryProvider);
  return RegistrationSubmissionNotifier(repository);
});
