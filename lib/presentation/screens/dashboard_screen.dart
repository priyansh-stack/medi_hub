import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/plan_catalog.dart';
import '../../data/models/appointment_model.dart';
import '../../data/models/family_model.dart';
import '../../data/models/health_record_model.dart';
import '../../data/models/member_profile_model.dart';
import '../../data/models/plan_model.dart';
import '../../data/models/subscription_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/appointments_repository.dart';
import '../../data/repositories/family_repository.dart';
import '../../data/repositories/health_records_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/onboarding/onboarding_cubit.dart';
import '../../logic/onboarding/onboarding_state.dart';
import 'dashboard/appointments_tab.dart';
import 'dashboard/family_group_tab.dart';
import 'dashboard/health_records_tab.dart';
import 'dashboard/my_health_profile_tab.dart';
import 'dashboard/overview_tab.dart';
import 'dashboard/subscription_tab.dart';

class _NavItem {
  final String title;
  final IconData icon;

  const _NavItem({required this.title, required this.icon});
}

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
  bool _triggerAddMember = false;

  // The 5 canonical MediHub Sidebar Navigation Items
  static const List<_NavItem> _navItems = [
    _NavItem(title: 'Dashboard', icon: Icons.dashboard_rounded),
    _NavItem(title: 'Family Group', icon: Icons.family_restroom_rounded),
    _NavItem(title: 'Health Records', icon: Icons.folder_shared_rounded),
    _NavItem(title: 'Appointments', icon: Icons.calendar_month_rounded),
    _NavItem(title: 'Subscription', icon: Icons.card_membership_rounded),
  ];

  List<HealthRecordModel> _overviewRecentRecords = [];
  List<AppointmentModel> _overviewUpcomingAppointments = [];

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

  HealthRecordsRepository? _getHealthRecordsRepo([BuildContext? ctx]) {
    try {
      return (ctx ?? context).read<HealthRecordsRepository>();
    } catch (_) {
      try {
        return HealthRecordsRepository();
      } catch (_) {
        return null;
      }
    }
  }

  AppointmentsRepository? _getAppointmentsRepo([BuildContext? ctx]) {
    try {
      return (ctx ?? context).read<AppointmentsRepository>();
    } catch (_) {
      try {
        return AppointmentsRepository();
      } catch (_) {
        return null;
      }
    }
  }

  SubscriptionRepository? _getSubscriptionRepo([BuildContext? ctx]) {
    try {
      return (ctx ?? context).read<SubscriptionRepository>();
    } catch (_) {
      try {
        return SubscriptionRepository();
      } catch (_) {
        return null;
      }
    }
  }

  FamilyRepository? _getFamilyRepo([BuildContext? ctx]) {
    try {
      return (ctx ?? context).read<FamilyRepository>();
    } catch (_) {
      try {
        return FamilyRepository();
      } catch (_) {
        return null;
      }
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
      _fetchOverviewData();
    });
  }

  Future<void> _fetchOverviewData() async {
    final memberId = widget.user.memberId ?? 'mem_${widget.user.uid}';
    try {
      final hRepo = _getHealthRecordsRepo();
      if (hRepo != null) {
        final recs = await hRepo.getHealthRecords(memberId);
        if (mounted) setState(() => _overviewRecentRecords = recs);
      }
      final aRepo = _getAppointmentsRepo();
      if (aRepo != null) {
        final apts = await aRepo.getAppointments(memberId);
        final upcoming = apts.where((a) => a.status.toLowerCase() == 'upcoming').toList();
        if (mounted) setState(() => _overviewUpcomingAppointments = upcoming);
      }
    } catch (_) {}
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
    return widget.plan ?? PlanCatalog.familyBasic;
  }

  void _showProfileModal(BuildContext context) {
    final user = _getActiveUser(context);
    final profile = _getActiveProfile(context);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Member Health Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: MyHealthProfileTab(
                  user: user,
                  profile: profile,
                  onSaveProfile: (updatedProfile) async {
                    final cubit = _getCubit(context);
                    if (cubit != null) {
                      await cubit.updateMemberProfile(updatedProfile);
                    }
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Member profile updated successfully!'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      context.watch<OnboardingCubit>();
    } catch (_) {}

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 700 && screenWidth < 1024;

    if (isDesktop || isTablet) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        floatingActionButton: _buildAddMemberFab(),
        body: SafeArea(
          child: Row(
            children: [
              // Permanent Sidebar
              _buildSidebar(context, width: isDesktop ? 260 : 220),

              // Main Body Content
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
                          await _fetchOverviewData();
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 960),
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

    // Mobile Layout
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      floatingActionButton: _buildAddMemberFab(),
      appBar: AppBar(
        title: Text(_navItems[_selectedNavIndex].title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              final cubit = _getCubit(context);
              if (cubit != null) cubit.refreshBundle(widget.user.uid);
              _fetchOverviewData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: () {
              final auth = _getAuthBloc(context);
              if (auth != null) auth.add(AuthLogoutRequested());
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
            if (cubit != null) await cubit.refreshBundle(widget.user.uid);
            await _fetchOverviewData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: _buildActiveTabContent(context),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex > 4 ? 0 : _selectedNavIndex,
        onTap: (index) {
          setState(() => _selectedNavIndex = index);
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.family_restroom_rounded), label: 'Family'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_shared_rounded), label: 'Records'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Appointments'),
          BottomNavigationBarItem(icon: Icon(Icons.card_membership_rounded), label: 'Subscription'),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, {required bool showMenuButton}) {
    final subscription = _getActiveSubscription(context);

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
          _buildSubscriptionStatusBadge(subscription?.status ?? 'FREE'),
          const SizedBox(width: 14),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Refresh data',
            onPressed: () {
              final cubit = _getCubit(context);
              if (cubit != null) cubit.refreshBundle(widget.user.uid);
              _fetchOverviewData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dashboard refreshed.'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionStatusBadge(String status) {
    Color bg = AppColors.primarySurface;
    Color fg = AppColors.primary;

    final upper = status.toUpperCase();
    if (upper == 'PAYMENT_FAILED' || upper == 'FAILED') {
      bg = AppColors.error.withValues(alpha: 0.1);
      fg = AppColors.error;
    } else if (upper == 'FREE') {
      bg = AppColors.scaffoldBg;
      fg = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            upper == 'MOCK_ACTIVE' ? 'MOCK ACTIVE' : upper,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, {double width = 260, bool isDrawer = false}) {
    final user = _getActiveUser(context);

    return Container(
      width: isDrawer ? null : width,
      color: Colors.white,
      child: Column(
        children: [
          // Branding Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 22,
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

          const SizedBox(height: 10),

          // 7 Navigation Links
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
                    setState(() => _selectedNavIndex = index);
                    if (isDrawer) Navigator.pop(context);
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
          Builder(
            builder: (context) {
              final plan = _getActivePlan(context);
              String planTag;
              if (plan.id == 'plan_family_pro' || plan.name.toLowerCase().contains('pro')) {
                planTag = 'PRO';
              } else if (plan.id == 'plan_family_premium' || plan.name.toLowerCase().contains('premium')) {
                planTag = 'PREMIUM';
              } else {
                planTag = 'FREE';
              }

              return Container(
                padding: const EdgeInsets.all(14),
                color: AppColors.scaffoldBg.withValues(alpha: 0.4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'M',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.memberId ?? 'mem_${user.uid}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  'Active ($planTag)',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.textSecondary),
                      tooltip: 'Sign Out',
                      onPressed: () {
                        final auth = _getAuthBloc(context);
                        if (auth != null) auth.add(AuthLogoutRequested());
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddMemberFab() {
    return FloatingActionButton.extended(
      onPressed: () {
        setState(() {
          _selectedNavIndex = 1;
          _triggerAddMember = true;
        });
      },
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
      label: const Text(
        'Add Family Member',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.2),
      ),
    );
  }

  Widget _buildActiveTabContent(BuildContext context) {
    final user = _getActiveUser(context);
    final profile = _getActiveProfile(context);
    final family = _getActiveFamily(context);
    final subscription = _getActiveSubscription(context);
    final plan = _getActivePlan(context);
    final memberId = user.memberId ?? (profile?.memberId ?? 'mem_${user.uid}');
    final familyId = family?.familyId ?? 'fam_${user.uid}';

    switch (_selectedNavIndex) {
      case 0:
        return OverviewTab(
          user: user,
          profile: profile,
          family: family,
          subscription: subscription,
          plan: plan,
          recentRecords: _overviewRecentRecords,
          upcomingAppointments: _overviewUpcomingAppointments,
          onNavigateToTab: (index) => setState(() => _selectedNavIndex = index),
          onViewFullProfile: () => _showProfileModal(context),
        );
      case 1:
        return FamilyGroupTab(
          user: user,
          profile: profile,
          family: family,
          repository: _getFamilyRepo(context),
          autoOpenAddMember: _triggerAddMember,
          onAddMemberClosed: () {
            if (mounted) {
              setState(() => _triggerAddMember = false);
            }
          },
          onUpdateFamilyName: (famId, newName) async {
            final cubit = _getCubit(context);
            if (cubit != null) {
              await cubit.updateFamilyName(famId, newName);
            }
          },
          onSaveProfile: (updatedProfile) async {
            final cubit = _getCubit(context);
            if (cubit != null) {
              await cubit.updateMemberProfile(updatedProfile);
            }
          },
        );
      case 2:
        return HealthRecordsTab(
          memberId: memberId,
          familyId: familyId,
          userName: user.fullName,
          repository: _getHealthRecordsRepo(context),
          onRecordsUpdated: _fetchOverviewData,
        );
      case 3:
        return AppointmentsTab(
          memberId: memberId,
          familyId: familyId,
          patientName: user.fullName,
          repository: _getAppointmentsRepo(context),
          onAppointmentsUpdated: _fetchOverviewData,
        );
      case 4:
        return SubscriptionTab(
          familyId: familyId,
          subscription: subscription,
          plan: plan,
          repository: _getSubscriptionRepo(context),
          onChangePlan: widget.onChangePlan,
        );
      default:
        return OverviewTab(
          user: user,
          profile: profile,
          family: family,
          subscription: subscription,
          plan: plan,
          recentRecords: _overviewRecentRecords,
          upcomingAppointments: _overviewUpcomingAppointments,
          onNavigateToTab: (index) => setState(() => _selectedNavIndex = index),
          onViewFullProfile: () => _showProfileModal(context),
        );
    }
  }
}
