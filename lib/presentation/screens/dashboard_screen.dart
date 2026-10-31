import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/plan_catalog.dart';
import '../../data/models/family_model.dart';
import '../../data/models/member_profile_model.dart';
import '../../data/models/plan_model.dart';
import '../../data/models/subscription_model.dart';
import '../../data/models/user_model.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/onboarding/onboarding_cubit.dart';
import '../../logic/onboarding/onboarding_state.dart';
import '../widgets/custom_button.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel user;
  final MemberProfileModel? memberProfile;
  final FamilyModel? family;
  final SubscriptionModel? subscription;
  final PlanModel? plan;
  final VoidCallback onChangePlan;

  const DashboardScreen({
    super.key,
    required this.user,
    this.memberProfile,
    this.family,
    this.subscription,
    this.plan,
    required this.onChangePlan,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedNavIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(title: 'Overview', icon: Icons.dashboard_rounded),
    _NavItem(title: 'Family Group', icon: Icons.family_restroom_rounded),
    _NavItem(title: 'Health Profile', icon: Icons.person_rounded),
    _NavItem(title: 'Subscription', icon: Icons.card_membership_rounded),
    _NavItem(title: 'Medical Records', icon: Icons.folder_shared_rounded),
    _NavItem(title: 'Consultations', icon: Icons.calendar_month_rounded),
  ];

  OnboardingCubit? _getCubit([BuildContext? ctx]) {
    try {
      return (ctx ?? context).read<OnboardingCubit>();
    } catch (_) {
      return null;
    }
  }

  AuthBloc? _getAuthBloc([BuildContext? ctx]) {
    try {
      return (ctx ?? context).read<AuthBloc>();
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = _getCubit();
      if (cubit != null) {
        final obState = cubit.state;
        if (obState is! OnboardingLoaded || obState.bundle.memberProfile == null) {
          cubit.loadOnboarding(widget.user);
        }
      }
    });
  }

  UserModel _getActiveUser([BuildContext? ctx]) {
    final cubit = _getCubit(ctx);
    final obState = cubit?.state;
    if (obState is OnboardingLoaded) return obState.bundle.user;
    return widget.user;
  }

  MemberProfileModel? _getActiveProfile([BuildContext? ctx]) {
    final cubit = _getCubit(ctx);
    final obState = cubit?.state;
    if (obState is OnboardingLoaded && obState.bundle.memberProfile != null) {
      return obState.bundle.memberProfile;
    }
    return widget.memberProfile;
  }

  FamilyModel? _getActiveFamily([BuildContext? ctx]) {
    final cubit = _getCubit(ctx);
    final obState = cubit?.state;
    if (obState is OnboardingLoaded && obState.bundle.family != null) {
      return obState.bundle.family;
    }
    return widget.family;
  }

  SubscriptionModel? _getActiveSubscription([BuildContext? ctx]) {
    final cubit = _getCubit(ctx);
    final obState = cubit?.state;
    if (obState is OnboardingLoaded && obState.bundle.subscription != null) {
      return obState.bundle.subscription;
    }
    return widget.subscription;
  }

  PlanModel _getActivePlan([BuildContext? ctx]) {
    final cubit = _getCubit(ctx);
    final obState = cubit?.state;
    if (obState is OnboardingLoaded) {
      if (obState.selectedPlan != null) return obState.selectedPlan!;
      if (obState.bundle.subscription != null) {
        return PlanCatalog.findById(obState.bundle.subscription!.planId);
      }
    }
    final sub = _getActiveSubscription(ctx);
    if (sub != null) {
      return PlanCatalog.findById(sub.planId);
    }
    return widget.plan ?? PlanCatalog.familyBasic;
  }

  void _showProfileModal(BuildContext context) {
    final user = _getActiveUser(context);
    final profile = _getActiveProfile(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Member Profile Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildDetailTile('Member ID', user.memberId ?? 'N/A'),
            _buildDetailTile('Full Name', profile?.fullName.isNotEmpty == true ? profile!.fullName : user.fullName),
            _buildDetailTile('Email', user.email),
            _buildDetailTile('Phone', profile?.phone ?? 'Not provided'),
            _buildDetailTile(
              'Date of Birth',
              profile?.dateOfBirth != null
                  ? DateFormat('dd MMM yyyy').format(profile!.dateOfBirth!)
                  : 'Not provided',
            ),
            _buildDetailTile('Gender', profile?.gender ?? 'Not specified'),
            _buildDetailTile('Blood Group', profile?.bloodGroup ?? 'Not specified'),
            _buildDetailTile('Address', profile?.address.formatted.isNotEmpty == true ? profile!.address.formatted : 'Not provided'),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Close',
              variant: ButtonVariant.outline,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showFamilySettingsModal(BuildContext context) {
    final user = _getActiveUser(context);
    final family = _getActiveFamily(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Family Group Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildDetailTile('Family ID', family?.familyId ?? 'N/A'),
            _buildDetailTile('Family Name', family?.familyName ?? 'N/A'),
            _buildDetailTile('Family Admin', '${user.fullName} (${user.email})'),
            _buildDetailTile('Description', family?.description ?? 'No description provided'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.info),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Adding other family members is excluded from this MVP release and will be available in the upcoming release.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Close',
              variant: ButtonVariant.outline,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildDetailTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      context.watch<OnboardingCubit>();
    } catch (_) {}
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: SafeArea(
          child: Row(
            children: [
              // Permanent Sidebar for Desktop / Tablet
              SizedBox(
                width: 270,
                child: _buildSidebar(context),
              ),
              Container(width: 1, color: AppColors.border),
              // Main Content Area
              Expanded(
                child: Column(
                  children: [
                    _buildTopHeader(context, showMenuButton: false),
                    const Divider(height: 1, thickness: 1, color: AppColors.border),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          final cubit = _getCubit(context);
                          if (cubit != null) {
                            await cubit.refreshBundle(widget.user.uid);
                          }
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 880),
                              child: _buildActiveTabContent(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile / Narrow Layout
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(_navItems[_selectedNavIndex].title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              final cubit = _getCubit(context);
              if (cubit != null) {
                cubit.refreshBundle(widget.user.uid);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: () {
              final auth = _getAuthBloc(context);
              if (auth != null) {
                auth.add(AuthLogoutRequested());
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: _buildSidebar(context, isDrawer: true),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final cubit = _getCubit(context);
            if (cubit != null) {
              await cubit.refreshBundle(widget.user.uid);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: _buildActiveTabContent(context),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex > 3 ? 0 : _selectedNavIndex,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.family_restroom_rounded), label: 'Family'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.card_membership_rounded), label: 'Plan'),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, {required bool showMenuButton}) {
    final subscription = _getActiveSubscription(context);
    final user = _getActiveUser(context);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          if (showMenuButton) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            _navItems[_selectedNavIndex].title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          // Plan Badge Pill
          _buildSubscriptionStatusBadge(subscription?.status ?? 'UNKNOWN'),
          const SizedBox(width: 14),
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Refresh data',
            onPressed: () {
              final cubit = _getCubit(context);
              if (cubit != null) {
                cubit.refreshBundle(user.uid);
              }
            },
          ),
          const SizedBox(width: 4),
          // Quick Logout Button
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Log out',
            onPressed: () {
              final auth = _getAuthBloc(context);
              if (auth != null) {
                auth.add(AuthLogoutRequested());
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, {bool isDrawer = false}) {
    final user = _getActiveUser(context);
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MediHub Brand Emblem
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MediHub',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'Health & Family Portal',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),

          const SizedBox(height: 12),

          // Navigation Links
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: _navItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedNavIndex == index;

                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    setState(() {
                      _selectedNavIndex = index;
                    });
                    if (isDrawer) {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primarySurface : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 20,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // User Profile Footer
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.scaffoldBg.withValues(alpha: 0.4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : 'M',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        user.memberId ?? user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.textSecondary),
                  tooltip: 'Sign Out',
                  onPressed: () {
                    final auth = _getAuthBloc(context);
                    if (auth != null) {
                      auth.add(AuthLogoutRequested());
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent(BuildContext context) {
    switch (_selectedNavIndex) {
      case 0:
        return _buildOverviewTab(context);
      case 1:
        return _buildFamilyTab(context);
      case 2:
        return _buildHealthProfileTab(context);
      case 3:
        return _buildSubscriptionTab(context);
      case 4:
        return _buildMedicalRecordsTab(context);
      case 5:
        return _buildConsultationsTab(context);
      default:
        return _buildOverviewTab(context);
    }
  }

  // ================= TAB 0: OVERVIEW =================
  Widget _buildOverviewTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Banner
        _buildWelcomeBanner(),
        const SizedBox(height: 20),

        // 3 Key Stats
        _buildQuickStatsGrid(),
        const SizedBox(height: 20),

        // Family Overview Card
        _buildFamilyCard(context),
        const SizedBox(height: 16),

        // Member Profile Card
        _buildProfileCard(context),
        const SizedBox(height: 16),

        // Subscription Card
        _buildSubscriptionCard(context),
        const SizedBox(height: 24),
      ],
    );
  }

  // ================= TAB 1: FAMILY GROUP =================
  Widget _buildFamilyTab(BuildContext context) {
    final user = _getActiveUser(context);
    final profile = _getActiveProfile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFamilyCard(context),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.people_outline, color: AppColors.primary, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Household Members Roster',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primarySurface,
                    child: Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary),
                  ),
                  title: Text(
                    user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${profile?.gender ?? 'Admin'} • ${user.memberId ?? 'ID Assigned'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'FAMILY ADMIN',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_add_alt_1_outlined, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Add Family Member slot ready for next release phase.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(90, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        onPressed: () => _showFamilySettingsModal(context),
                        child: const Text('Manage'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= TAB 2: HEALTH PROFILE =================
  Widget _buildHealthProfileTab(BuildContext context) {
    final user = _getActiveUser(context);
    final profile = _getActiveProfile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileCard(context),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.contact_mail_outlined, color: AppColors.primary, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Contact & Emergency Records',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildProfileField('Registered Email', user.email, Icons.email_outlined),
                const SizedBox(height: 12),
                _buildProfileField('Phone Number', profile?.phone ?? 'Not provided', Icons.phone_outlined),
                const SizedBox(height: 12),
                _buildProfileField('Emergency Address', profile?.address.formatted.isNotEmpty == true ? profile!.address.formatted : 'Not provided', Icons.location_on_outlined),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= TAB 3: SUBSCRIPTION =================
  Widget _buildSubscriptionTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubscriptionCard(context),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Included Plan Features',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const Divider(height: 24),
                _buildFeatureCheck('Shared Family Health Records Vault'),
                _buildFeatureCheck('Emergency Contact & Doctor Records'),
                _buildFeatureCheck('Member Profile ID Anchor System'),
                _buildFeatureCheck('Zero Cloud Function Overhead (Direct Client Firestore)'),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.upgrade_rounded),
                    label: const Text('Change or Upgrade Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: widget.onChangePlan,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= TAB 4: MEDICAL RECORDS =================
  Widget _buildMedicalRecordsTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.folder_shared_rounded, color: AppColors.primary, size: 24),
                          SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Family Health Vault',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                      label: const Text('Upload Record'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Document storage vault enabled for next release.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildVaultCategory(Icons.medication_outlined, 'Prescriptions', '0 active prescriptions logged'),
                _buildVaultCategory(Icons.biotech_outlined, 'Lab Test Reports', 'Blood test & diagnostics archive'),
                _buildVaultCategory(Icons.vaccines_outlined, 'Immunization History', 'Vaccine schedules up to date'),
                _buildVaultCategory(Icons.warning_amber_rounded, 'Allergies & Alerts', 'No active critical alerts recorded'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= TAB 5: CONSULTATIONS =================
  Widget _buildConsultationsTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 24),
                          SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Doctor Consultations & Appointments',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(130, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Book Appointment'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tele-consultation booking module scheduled for upcoming release.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const Divider(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.event_available_rounded, size: 48, color: AppColors.primary.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text(
                        'No upcoming appointments scheduled',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Schedule a routine family checkup or tele-consultation anytime.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= WIDGET HELPERS =================
  Widget _buildWelcomeBanner() {
    final user = _getActiveUser();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'ONBOARDING COMPLETED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Welcome, ${user.fullName}!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your digital health identity and family hub are active and ready.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    final user = _getActiveUser();
    final profile = _getActiveProfile();
    final family = _getActiveFamily();
    final subscription = _getActiveSubscription();
    final plan = _getActivePlan();

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'Family Hub',
            value: family?.familyName ?? 'Household Hub',
            subtitle: '1 Active Member',
            icon: Icons.diversity_1_rounded,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMetricTile(
            title: 'Health Identity',
            value: user.memberId ?? 'Assigned',
            subtitle: profile?.bloodGroup != null
                ? 'Blood: ${profile!.bloodGroup}'
                : 'Profile Active',
            icon: Icons.badge_outlined,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMetricTile(
            title: 'Active Plan',
            value: plan.name,
            subtitle: (subscription?.status ?? '') == 'FREE'
                ? '₹0 Free Tier'
                : 'Active Tier',
            icon: Icons.workspace_premium_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              Icon(icon, size: 18, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFamilyCard(BuildContext context) {
    final user = _getActiveUser(context);
    final family = _getActiveFamily(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.family_restroom,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          family?.familyName ?? 'Family Hub',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Group ID: ${family?.familyId ?? 'fam_${user.uid}'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 14, color: AppColors.primaryDark),
                      SizedBox(width: 4),
                      Text(
                        'Family Admin',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (family?.description != null && family!.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                family!.description!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const Divider(height: 24, color: AppColors.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Members: 1 (Admin Profile)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.settings_outlined, size: 16),
                  label: const Text('Family Settings'),
                  onPressed: () => _showFamilySettingsModal(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final user = _getActiveUser(context);
    final profile = _getActiveProfile(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person_pin_circle_outlined, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'My Member Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    user.memberId ?? 'ID assigned',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: AppColors.border),
            _buildProfileField(
              'Full Name',
              profile?.fullName.isNotEmpty == true ? profile!.fullName : user.fullName,
              Icons.person_outline,
            ),
            const SizedBox(height: 8),
            _buildProfileField(
              'Date of Birth',
              profile?.dateOfBirth != null
                  ? DateFormat('dd MMM yyyy').format(profile!.dateOfBirth!)
                  : 'Not provided',
              Icons.cake_outlined,
            ),
            const SizedBox(height: 8),
            _buildProfileField(
              'Gender & Blood',
              '${profile?.gender ?? 'Not specified'} • Blood: ${profile?.bloodGroup ?? 'Not specified'}',
              Icons.medical_information_outlined,
            ),
            const SizedBox(height: 8),
            _buildProfileField(
              'Address',
              profile?.address.formatted.isNotEmpty == true ? profile!.address.formatted : 'Not provided',
              Icons.location_on_outlined,
            ),
            const Divider(height: 20, color: AppColors.border),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('View Full Profile'),
                onPressed: () => _showProfileModal(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context) {
    final subscription = _getActiveSubscription(context);
    final plan = _getActivePlan(context);
    final subStatus = subscription?.status ?? 'UNKNOWN';
    final isFree = subStatus == 'FREE';
    final isFailed = subStatus == 'PAYMENT_FAILED';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.card_membership_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Subscription & Plan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                _buildSubscriptionStatusBadge(subStatus),
              ],
            ),
            const Divider(height: 20, color: AppColors.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isFree
                          ? '₹0 / Free Plan'
                          : '₹${subscription?.amount.toInt() ?? plan.amount.toInt()} / month (Mock Billing)',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                OutlinedButton(
                  onPressed: widget.onChangePlan,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(110, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Change Plan'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payment Mode:',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        subscription?.paymentMode ?? 'MOCK',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transaction ID:',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        subscription?.mockTransactionId ?? 'None',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (plan.memberLimitDescription.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Member Limit:',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          plan.memberLimitDescription,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (isFailed) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Simulated payment failed. Tap Change Plan to retry checkout.',
                        style: TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionStatusBadge(String status) {
    Color bg;
    Color textColor;
    String label;

    switch (status) {
      case 'MOCK_ACTIVE':
        bg = AppColors.successBg;
        textColor = AppColors.success;
        label = 'MOCK ACTIVE';
        break;
      case 'FREE':
        bg = AppColors.infoBg;
        textColor = AppColors.info;
        label = 'FREE PLAN';
        break;
      case 'PAYMENT_FAILED':
        bg = AppColors.errorBg;
        textColor = AppColors.error;
        label = 'PAYMENT FAILED';
        break;
      default:
        bg = AppColors.mockBadgeBg;
        textColor = AppColors.mockBadgeText;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFeatureCheck(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaultCategory(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _NavItem {
  final String title;
  final IconData icon;

  const _NavItem({required this.title, required this.icon});
}
