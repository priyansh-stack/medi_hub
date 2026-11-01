import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/models/family_model.dart';
import '../../../data/models/health_record_model.dart';
import '../../../data/models/member_profile_model.dart';
import '../../../data/models/plan_model.dart';
import '../../../data/models/subscription_model.dart';
import '../../../data/models/user_model.dart';

class OverviewTab extends StatelessWidget {
  final UserModel user;
  final MemberProfileModel? profile;
  final FamilyModel? family;
  final SubscriptionModel? subscription;
  final PlanModel plan;
  final List<HealthRecordModel> recentRecords;
  final List<AppointmentModel> upcomingAppointments;
  final Function(int tabIndex)? onNavigateToTab;
  final VoidCallback? onViewFullProfile;

  const OverviewTab({
    super.key,
    required this.user,
    this.profile,
    this.family,
    this.subscription,
    required this.plan,
    this.recentRecords = const [],
    this.upcomingAppointments = const [],
    this.onNavigateToTab,
    this.onViewFullProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A. Welcome Banner
        _buildWelcomeBanner(),
        const SizedBox(height: 24),

        // B. Clean Empty Dashboard Placeholder
        _buildEmptyOverviewPlaceholder(context),
      ],
    );
  }

  // ================= A. WELCOME BANNER =================
  Widget _buildWelcomeBanner() {
    final now = DateTime.now();
    final formattedDate = DateFormat('d MMM yyyy').format(now);
    final statusText = user.onboardingStatus.toDisplayTitle();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 13, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      statusText.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Welcome, ${user.fullName.isNotEmpty ? user.fullName : 'Member'}!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your digital health identity and family hub are active and ready.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ================= B. EMPTY OVERVIEW PLACEHOLDER =================
  Widget _buildEmptyOverviewPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to MediHub',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select an option from the sidebar to view your Family Group, manage Health Records, book Appointments, or review your Subscription.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
