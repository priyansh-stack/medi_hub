import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';

class AuthRepository {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  final LocalStorageService _localStorageService;

  AuthRepository({
    AuthService? authService,
    FirestoreService? firestoreService,
    LocalStorageService? localStorageService,
  })  : _authService = authService ?? AuthService(),
        _firestoreService = firestoreService ?? FirestoreService(),
        _localStorageService = localStorageService ?? LocalStorageService();

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  User? get currentFirebaseUser => _authService.currentUser;

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final credential = await _authService.signUpWithEmailAndPassword(
      email: email,
      password: password,
      fullName: fullName,
    );

    final uid = credential.user!.uid;
    // Verification is bypassed due to Firebase limitation, user proceeds directly to onboarding
    final userModel = UserModel(
      uid: uid,
      fullName: fullName,
      email: email,
      emailVerified: true,
      memberId: 'mem_$uid',
      onboardingStatus: OnboardingStep.emailVerified,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.createUser(userModel);
    await _localStorageService.saveUser(userModel);
    return userModel;
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final credential = await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    var userModel = await _firestoreService.getUser(uid);

    // If user record doesn't exist in Firestore (legacy/edge case), synthesize it
    if (userModel == null) {
      userModel = UserModel(
        uid: uid,
        fullName: credential.user!.displayName ?? 'MediHub User',
        email: email,
        emailVerified: true,
        memberId: 'mem_$uid',
        onboardingStatus: OnboardingStep.emailVerified,
      );
      await _firestoreService.createUser(userModel);
    } else {
      final effectiveMemberId = (userModel.memberId != null && userModel.memberId!.isNotEmpty)
          ? userModel.memberId!
          : 'mem_$uid';

      // Ensure user is verified (verification requirement bypassed)
      if (!userModel.emailVerified ||
          userModel.onboardingStatus == OnboardingStep.accountCreated ||
          userModel.memberId != effectiveMemberId) {
        final newStatus = userModel.onboardingStatus == OnboardingStep.accountCreated
            ? OnboardingStep.emailVerified
            : userModel.onboardingStatus;
        userModel = userModel.copyWith(
          emailVerified: true,
          memberId: effectiveMemberId,
          onboardingStatus: newStatus,
        );
        await _firestoreService.updateUser(uid, {
          'emailVerified': true,
          'memberId': effectiveMemberId,
          'onboardingStatus': newStatus.toDbValue(),
        });
      }
    }

    await _localStorageService.saveUser(userModel);
    if (userModel.onboardingStatus == OnboardingStep.completed) {
      await _localStorageService.setOnboardingCompleted(true);
    }

    return userModel;
  }

  Future<UserModel?> getCurrentUserModel() async {
    final user = _authService.currentUser;
    if (user == null) {
      return await _localStorageService.getCachedUser();
    }
    var userModel = await _firestoreService.getUser(user.uid);
    if (userModel != null) {
      final effectiveMemberId = (userModel.memberId != null && userModel.memberId!.isNotEmpty)
          ? userModel.memberId!
          : 'mem_${user.uid}';

      if (!userModel.emailVerified ||
          userModel.onboardingStatus == OnboardingStep.accountCreated ||
          userModel.memberId != effectiveMemberId) {
        final newStatus = userModel.onboardingStatus == OnboardingStep.accountCreated
            ? OnboardingStep.emailVerified
            : userModel.onboardingStatus;
        userModel = userModel.copyWith(
          emailVerified: true,
          memberId: effectiveMemberId,
          onboardingStatus: newStatus,
        );
        await _firestoreService.updateUser(user.uid, {
          'emailVerified': true,
          'memberId': effectiveMemberId,
          'onboardingStatus': newStatus.toDbValue(),
        });
      }
    }

    if (userModel != null) {
      await _localStorageService.saveUser(userModel);
      if (userModel.onboardingStatus == OnboardingStep.completed) {
        await _localStorageService.setOnboardingCompleted(true);
      }
    } else {
      userModel = await _localStorageService.getCachedUser();
    }

    return userModel;
  }

  Future<UserModel?> getLocallyStoredUser() async {
    return await _localStorageService.getCachedUser();
  }

  Future<void> saveLocally(UserModel user) async {
    await _localStorageService.saveUser(user);
    if (user.onboardingStatus == OnboardingStep.completed) {
      await _localStorageService.setOnboardingCompleted(true);
    }
  }

  Future<bool> checkEmailVerified(UserModel currentUser) async {
    return true;
  }

  Future<void> resendVerificationEmail() async {
    await _authService.sendEmailVerification();
  }

  Future<void> correctEmailAndResend({
    required UserModel currentUser,
    required String newEmail,
  }) async {
    await _authService.updateEmailAndResendVerification(newEmail);
    await _firestoreService.updateUser(currentUser.uid, {
      'email': newEmail,
      'emailVerified': false,
      'onboardingStatus': OnboardingStep.accountCreated.toDbValue(),
    });
  }

  Future<void> sendPasswordReset(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  Future<void> signOut() async {
    await _authService.signOut();
    await _localStorageService.clearAll();
  }
}
