import 'package:flutter/material.dart';
import '../../../core/clinical/clinical_guidelines.dart';
import '../../../core/constants/app_colors.dart';

class ClinicalGuidelineDialog extends StatelessWidget {
  final ClinicalGuidelineReference guideline;

  const ClinicalGuidelineDialog({super.key, required this.guideline});

  static void show(BuildContext context, ClinicalGuidelineReference guideline) {
    showDialog(
      context: context,
      builder: (ctx) => ClinicalGuidelineDialog(guideline: guideline),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isApproved = guideline.reviewStatus.toLowerCase() == 'approved';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                guideline.ruleId,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isApproved ? AppColors.successBg : AppColors.warningBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                guideline.reviewStatus.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isApproved ? AppColors.success : AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          guideline.guidelineName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 28),

              // Details grid
              _buildDetailRow('Source Document / Authority', guideline.sourceRef),
              _buildDetailRow('Guideline Version / Edition', '${guideline.version} (${guideline.publicationDate})'),
              if (guideline.terminologyCode.isNotEmpty)
                _buildDetailRow('Coding Standard & Terminology Code', '${guideline.codeSystem}: ${guideline.terminologyCode}'),
              _buildDetailRow('Accepted Clinical Range / Values', guideline.acceptedRange),
              _buildDetailRow('Applicable Population', guideline.applicablePopulation),
              if (guideline.notes.isNotEmpty)
                _buildDetailRow('Clinical Context & Practice Guidance', guideline.notes),

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close Rationale', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
