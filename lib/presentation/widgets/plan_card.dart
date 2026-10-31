import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/plan_model.dart';

class PlanCard extends StatelessWidget {
  final PlanModel plan;
  final bool isSelected;
  final VoidCallback onSelect;

  const PlanCard({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    // When selected: Rich Forest Green card with white text as in s-2 mockup
    // When unselected: Crisp White card with dark text
    final isCardDark = isSelected;
    final cardBgColor = isCardDark ? AppColors.cardSelectedBg : Colors.white;
    final titleColor = isCardDark ? Colors.white : AppColors.textPrimary;
    final priceColor = isCardDark ? Colors.white : AppColors.primary;
    final descColor = isCardDark ? Colors.white.withValues(alpha: 0.85) : AppColors.textSecondary;
    final borderColor = isCardDark ? AppColors.primaryDark : AppColors.border;

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isCardDark ? 2 : 1),
          boxShadow: isCardDark
              ? [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.2),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      plan.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    if (plan.isPopular) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.popularTagBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'POPULAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCardDark ? Colors.white : AppColors.border,
                      width: 2,
                    ),
                    color: isCardDark ? Colors.white : Colors.transparent,
                  ),
                  child: isCardDark
                      ? const Icon(Icons.check, size: 16, color: AppColors.primary)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  plan.formattedPrice,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: priceColor,
                  ),
                ),
                if (!plan.isFree) ...[
                  const SizedBox(width: 4),
                  Text(
                    '/ month',
                    style: TextStyle(
                      fontSize: 13,
                      color: descColor,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isCardDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 15,
                    color: isCardDark ? Colors.white : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    plan.memberLimitDescription,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isCardDark ? Colors.white : AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              plan.description,
              style: TextStyle(
                fontSize: 13,
                color: descColor,
                height: 1.35,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                color: isCardDark ? Colors.white.withValues(alpha: 0.2) : AppColors.border,
                height: 1,
              ),
            ),
            ...plan.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: isCardDark ? Colors.white : AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 12,
                          color: isCardDark ? Colors.white.withValues(alpha: 0.95) : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
