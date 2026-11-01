import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/plan_catalog.dart';
import '../../../data/models/payment_transaction_model.dart';
import '../../../data/models/plan_model.dart';
import '../../../data/models/subscription_model.dart';
import '../../../data/repositories/subscription_repository.dart';

class SubscriptionTab extends StatefulWidget {
  final String familyId;
  final SubscriptionModel? subscription;
  final PlanModel plan;
  final SubscriptionRepository? repository;
  final VoidCallback onChangePlan;

  const SubscriptionTab({
    super.key,
    required this.familyId,
    this.subscription,
    required this.plan,
    this.repository,
    required this.onChangePlan,
  });

  @override
  State<SubscriptionTab> createState() => _SubscriptionTabState();
}

class _SubscriptionTabState extends State<SubscriptionTab> {
  List<PaymentTransactionModel> _transactions = [];
  bool _isLoadingTransactions = true;

  @override
  void initState() {
    super.initState();
    _fetchPaymentHistory();
  }

  Future<void> _fetchPaymentHistory() async {
    if (widget.repository == null) {
      if (mounted) setState(() => _isLoadingTransactions = false);
      return;
    }
    setState(() => _isLoadingTransactions = true);
    try {
      final list = await widget.repository!.getPaymentHistory(widget.familyId);
      if (mounted) {
        setState(() {
          _transactions = list;
          _isLoadingTransactions = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingTransactions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.subscription;
    final plan = widget.plan;
    final startDate = sub?.createdAt ?? DateTime.now();
    final renewalDate = startDate.add(const Duration(days: 30));
    final status = sub?.status ?? 'FREE';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Current Plan Overview Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.card_membership_rounded, color: AppColors.primary, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              plan.isFree ? 'Free Forever' : '₹${plan.amount} / month (Mock Billing)',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _buildStatusPill(status),
                  ],
                ),
                const Divider(height: 24),

                _buildInfoRow('Billing Interval', 'Monthly (Simulated)'),
                const SizedBox(height: 8),
                _buildInfoRow('Member Limit', plan.memberLimit),
                const SizedBox(height: 8),
                _buildInfoRow('Subscription ID', sub?.subscriptionId ?? 'sub_basic_default'),
                const SizedBox(height: 8),
                _buildInfoRow('Start Date', DateFormat('d MMMM yyyy').format(startDate)),
                const SizedBox(height: 8),
                _buildInfoRow('Mock Renewal Date', DateFormat('d MMMM yyyy').format(renewalDate)),
                const SizedBox(height: 8),
                _buildInfoRow('Payment Mode', 'MOCK (Test simulation)'),
                const SizedBox(height: 18),

                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upgrade_rounded, size: 16),
                      label: const Text('Change or Upgrade Plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      onPressed: widget.onChangePlan,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // 2. Available MediHub Tiers
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.grid_view_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Available Family Plans',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const Divider(height: 20),
                ...PlanCatalog.plans.map((p) {
                  final isCurrent = p.id == plan.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.primarySurface : AppColors.scaffoldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent ? AppColors.primary : AppColors.border,
                        width: isCurrent ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  ),
                                  if (isCurrent) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text('CURRENT PLAN',
                                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${p.memberLimit} • ${p.features.first}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          p.isFree ? 'Free' : '₹${p.amount}/mo',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // 3. Mock Payment & Transaction History
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Mock Payment History',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      tooltip: 'Refresh history',
                      onPressed: _fetchPaymentHistory,
                    ),
                  ],
                ),
                const Divider(height: 20),

                if (_isLoadingTransactions)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary)))
                else if (_transactions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 30, color: AppColors.textSecondary),
                        SizedBox(height: 8),
                        Text('No mock transactions recorded yet', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppColors.scaffoldBg),
                      columns: const [
                        DataColumn(label: Text('Transaction ID', style: TextStyle(fontWeight: FontWeight.w700))),
                        DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w700))),
                        DataColumn(label: Text('Plan', style: TextStyle(fontWeight: FontWeight.w700))),
                        DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.w700))),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w700))),
                        DataColumn(label: Text('Mode', style: TextStyle(fontWeight: FontWeight.w700))),
                      ],
                      rows: _transactions.map((tx) {
                        return DataRow(
                          cells: [
                            DataCell(Text(tx.transactionId, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                            DataCell(Text(DateFormat('dd/MM/yyyy HH:mm').format(tx.createdAt), style: const TextStyle(fontSize: 12))),
                            DataCell(Text(tx.planName, style: const TextStyle(fontSize: 12))),
                            DataCell(Text('₹${tx.amount}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                            DataCell(_buildStatusPill(tx.status)),
                            DataCell(Text(tx.paymentMode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatusPill(String status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        upper == 'MOCK_ACTIVE' ? 'MOCK ACTIVE' : upper,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}

