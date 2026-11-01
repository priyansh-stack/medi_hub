import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MockPaymentBanner extends StatelessWidget {
  const MockPaymentBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.mockBadgeBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mockBadgeBorder, width: 1.5),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.science_outlined,
            color: AppColors.mockBadgeText,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'TEST / MOCK PAYMENT MODE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.mockBadgeText,
                      ),
                    ),
                    Badge(
                      label: Text('SIMULATION'),
                      backgroundColor: AppColors.mockBadgeText,
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'No real money, credit cards, UPI PINs, or bank credentials are required or processed. This checkout is an interactive simulation for stakeholder review.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.mockBadgeText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
