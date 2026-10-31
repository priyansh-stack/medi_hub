import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<String>? stepLabels;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    this.subtitle,
    this.onBack,
    this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    final labels = stepLabels ?? ['Contact', 'Profile', 'Family', 'Plan'];

    return Container(
      color: AppColors.scaffoldBg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          // Stepper Circles with connecting lines
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSteps * 2 - 1, (index) {
              if (index.isOdd) {
                // Connecting line
                final stepIndex = index ~/ 2;
                final isDone = stepIndex < currentStep - 1;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isDone ? AppColors.stepActive : AppColors.stepLine,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              } else {
                // Circle
                final stepNum = (index ~/ 2) + 1;
                final isActive = stepNum == currentStep;
                final isCompleted = stepNum < currentStep;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted || isActive
                            ? AppColors.stepActive
                            : Colors.white,
                        border: Border.all(
                          color: isCompleted || isActive
                              ? AppColors.stepActive
                              : AppColors.stepInactive,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : Text(
                                '$stepNum',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isActive ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                      ),
                    ),
                    if (labels.length >= stepNum) ...[
                      const SizedBox(height: 4),
                      Text(
                        labels[stepNum - 1],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive ? AppColors.textPrimary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                );
              }
            }),
          ),
          const SizedBox(height: 16),
          // Screen Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
