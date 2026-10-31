import 'package:uuid/uuid.dart';
import '../models/family_membership_model.dart';
import '../models/family_model.dart';
import '../models/member_profile_model.dart';
import '../models/subscription_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';

class OnboardingBundle {
  final UserModel user;
  final MemberProfileModel? memberProfile;
  final FamilyModel? family;
  final FamilyMembershipModel? membership;
  final SubscriptionModel? subscription;

  const OnboardingBundle({
    required this.user,
    this.memberProfile,
    this.family,
    this.membership,
    this.subscription,
  });
}

class OnboardingRepository {
  final FirestoreService _firestoreService;
  final LocalStorageService _localStorageService;
  final Uuid _uuid;

  OnboardingRepository({
    FirestoreService? firestoreService,
    LocalStorageService? localStorageService,
    Uuid? uuid,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _localStorageService = localStorageService ?? LocalStorageService(),
        _uuid = uuid ?? const Uuid();

  /// Step 4: Save Contact & Address Details
  Future<UserModel> saveContactAndAddress({
    required UserModel currentUser,
    String? phone,
    required AddressModel address,
  }) async {
    final memberId = (currentUser.memberId != null && currentUser.memberId!.isNotEmpty)
        ? currentUser.memberId!
        : 'mem_${currentUser.uid}';

    final existingProfile = await _firestoreService.getMemberProfile(memberId);
    final updatedProfile = existingProfile != null
        ? existingProfile.copyWith(
            fullName: currentUser.fullName.isNotEmpty ? currentUser.fullName : existingProfile.fullName,
            phone: phone ?? existingProfile.phone,
            address: address,
            updatedAt: DateTime.now(),
          )
        : MemberProfileModel(
            memberId: memberId,
            fullName: currentUser.fullName,
            gender: 'Not specified',
            phone: phone,
            address: address,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

    await _firestoreService.saveMemberProfile(updatedProfile);

    // Update user record
    final updatedUser = currentUser.copyWith(
      memberId: memberId,
      onboardingStatus: currentUser.onboardingStatus.index < OnboardingStep.contactSaved.index
          ? OnboardingStep.contactSaved
          : currentUser.onboardingStatus,
      updatedAt: DateTime.now(),
    );

    await _firestoreService.updateUser(currentUser.uid, {
      'memberId': memberId,
      'onboardingStatus': updatedUser.onboardingStatus.toDbValue(),
    });

    await _localStorageService.saveUser(updatedUser);

    return updatedUser;
  }

  /// Step 5: Save Personal Health Profile
  Future<UserModel> savePersonalHealthProfile({
    required UserModel currentUser,
    required String fullName,
    required DateTime dateOfBirth,
    required String gender,
    String? bloodGroup,
    String? phone,
    AddressModel? address,
  }) async {
    final memberId = (currentUser.memberId != null && currentUser.memberId!.isNotEmpty)
        ? currentUser.memberId!
        : 'mem_${currentUser.uid}';

    final existingProfile = await _firestoreService.getMemberProfile(memberId);

    final finalAddress = (address != null && address.line.isNotEmpty)
        ? address
        : (existingProfile?.address ?? const AddressModel(
            line: '',
            city: '',
            state: '',
            country: '',
            postalCode: '',
          ));

    final profile = MemberProfileModel(
      memberId: memberId,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      bloodGroup: bloodGroup,
      phone: (phone != null && phone.isNotEmpty) ? phone : existingProfile?.phone,
      address: finalAddress,
      createdAt: existingProfile?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.saveMemberProfile(profile);

    // Update user record with memberId & fullName if edited
    final updatedUser = currentUser.copyWith(
      fullName: fullName,
      memberId: memberId,
      onboardingStatus: currentUser.onboardingStatus.index < OnboardingStep.profileSaved.index
          ? OnboardingStep.profileSaved
          : currentUser.onboardingStatus,
      updatedAt: DateTime.now(),
    );

    await _firestoreService.updateUser(currentUser.uid, {
      'fullName': fullName,
      'memberId': memberId,
      'onboardingStatus': updatedUser.onboardingStatus.toDbValue(),
    });

    await _localStorageService.saveUser(updatedUser);

    return updatedUser;
  }

  /// Step 6: Create Family & Link Admin Membership
  Future<FamilyModel> createFamilyGroup({
    required UserModel currentUser,
    required String familyName,
    String? description,
  }) async {
    // 1. Resolve actual user and ensure memberId exists
    var user = currentUser;
    if (user.memberId == null || user.memberId!.isEmpty) {
      final dbUser = await _firestoreService.getUser(currentUser.uid);
      if (dbUser?.memberId != null && dbUser!.memberId!.isNotEmpty) {
        user = dbUser;
      } else {
        final cached = await _localStorageService.getCachedUser();
        if (cached?.memberId != null && cached!.memberId!.isNotEmpty) {
          user = cached;
        } else {
          final newMemberId = 'mem_${user.uid}';
          user = user.copyWith(memberId: newMemberId);
          await _firestoreService.updateUser(user.uid, {'memberId': newMemberId});
        }
      }
    }

    final memberId = (user.memberId != null && user.memberId!.isNotEmpty)
        ? user.memberId!
        : 'mem_${user.uid}';

    // 2. Deterministic familyId: fam_{uid} or existing family
    final deterministicFamilyId = 'fam_${user.uid}';
    final existingFamily = await _firestoreService.getFamily(deterministicFamilyId) ??
        await _firestoreService.getFamilyByAdmin(user.uid);

    final actualFamilyId = existingFamily?.familyId ?? deterministicFamilyId;

    final family = FamilyModel(
      familyId: actualFamilyId,
      familyName: familyName,
      description: description,
      adminUid: user.uid,
      createdAt: existingFamily?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.saveFamily(family);

    // 3. Create or ensure ADMIN membership (deterministic id ${familyId}_${memberId})
    final existingMembership = await _firestoreService.getAdminMembership(
      actualFamilyId,
      memberId,
    );

    if (existingMembership == null) {
      final membershipId = '${actualFamilyId}_$memberId';
      final membership = FamilyMembershipModel(
        membershipId: membershipId,
        familyId: actualFamilyId,
        memberId: memberId,
        role: 'ADMIN',
        status: 'ACTIVE',
        createdAt: DateTime.now(),
      );
      await _firestoreService.saveMembership(membership);
    }

    // 4. Update user's onboardingStatus
    final updatedStatus = user.onboardingStatus.index < OnboardingStep.familyCreated.index
        ? OnboardingStep.familyCreated
        : user.onboardingStatus;

    await _firestoreService.updateOnboardingStatus(
      user.uid,
      updatedStatus,
    );

    final updatedUser = user.copyWith(
      memberId: memberId,
      onboardingStatus: updatedStatus,
      updatedAt: DateTime.now(),
    );
    await _localStorageService.saveUser(updatedUser);

    return family;
  }

  /// Load complete bundle for current state / dashboard
  Future<OnboardingBundle> loadOnboardingBundle(String uid, [UserModel? fallbackUser]) async {
    UserModel? user;
    try {
      user = await _firestoreService.getUser(uid);
    } catch (_) {}
    user ??= fallbackUser ?? await _localStorageService.getCachedUser();
    if (user == null) {
      throw Exception('User record not found for uid: $uid');
    }

    final memberId = (user.memberId != null && user.memberId!.isNotEmpty)
        ? user.memberId!
        : 'mem_$uid';

    MemberProfileModel? profile;
    try {
      profile = await _firestoreService.getMemberProfile(memberId);
    } catch (_) {}

    FamilyModel? family;
    try {
      family = await _firestoreService.getFamily('fam_$uid') ??
          await _firestoreService.getFamilyByAdmin(uid);
    } catch (_) {}

    FamilyMembershipModel? membership;
    SubscriptionModel? subscription;

    if (family != null) {
      try {
        membership = await _firestoreService.getAdminMembership(
          family.familyId,
          memberId,
        );
      } catch (_) {}
      try {
        subscription = await _firestoreService.getSubscriptionForFamily(family.familyId);
      } catch (_) {}
    }

    final resolvedUser = user.copyWith(memberId: memberId);

    return OnboardingBundle(
      user: resolvedUser,
      memberProfile: profile,
      family: family,
      membership: membership,
      subscription: subscription,
    );
  }
}
