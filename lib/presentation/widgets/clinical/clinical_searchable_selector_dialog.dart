import 'package:flutter/material.dart';
import '../../../core/clinical/clinical_field_definition.dart';
import '../../../core/constants/app_colors.dart';

class ClinicalSearchableSelectorDialog extends StatefulWidget {
  final String title;
  final List<ClinicalFieldOption> options;
  final String? initialSelectedId;
  final bool allowOther;

  const ClinicalSearchableSelectorDialog({
    super.key,
    required this.title,
    required this.options,
    this.initialSelectedId,
    this.allowOther = true,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required List<ClinicalFieldOption> options,
    String? initialSelectedId,
    bool allowOther = true,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => ClinicalSearchableSelectorDialog(
        title: title,
        options: options,
        initialSelectedId: initialSelectedId,
        allowOther: allowOther,
      ),
    );
  }

  @override
  State<ClinicalSearchableSelectorDialog> createState() => _ClinicalSearchableSelectorDialogState();
}

class _ClinicalSearchableSelectorDialogState extends State<ClinicalSearchableSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _otherController = TextEditingController();
  List<ClinicalFieldOption> _filteredOptions = [];
  bool _isCustomOtherSelected = false;

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
    _searchController.addListener(_onSearchChanged);

    if (widget.initialSelectedId != null &&
        widget.initialSelectedId!.isNotEmpty &&
        !widget.options.any((o) => o.id == widget.initialSelectedId || o.label == widget.initialSelectedId)) {
      _isCustomOtherSelected = true;
      _otherController.text = widget.initialSelectedId!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = widget.options;
      } else {
        _filteredOptions = widget.options.where((opt) {
          final matchesLabel = opt.label.toLowerCase().contains(query);
          final matchesCode = opt.code?.toLowerCase().contains(query) ?? false;
          final matchesDesc = opt.description?.toLowerCase().contains(query) ?? false;
          return matchesLabel || matchesCode || matchesDesc;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search clinical catalogue or code (e.g. Penicillin, Insulin, E10)...',
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),

              // Custom Other Specification if selected
              if (_isCustomOtherSelected) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Specify Custom Clinical Term / Drug / Allergen:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _otherController,
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: 'Enter clinical name...',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onPressed: () {
                              final text = _otherController.text.trim();
                              if (text.isNotEmpty) {
                                Navigator.pop(context, text);
                              }
                            },
                            child: const Text('Confirm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Options list
              Expanded(
                child: _filteredOptions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off, size: 40, color: AppColors.textSecondary),
                            const SizedBox(height: 8),
                            const Text(
                              'No matching clinical terms found.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            if (widget.allowOther) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.edit_note, size: 18),
                                label: const Text('Enter Custom "Other" Term'),
                                onPressed: () {
                                  setState(() {
                                    _isCustomOtherSelected = true;
                                    _otherController.text = _searchController.text.trim();
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredOptions.length + (widget.allowOther ? 1 : 0),
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (ctx, index) {
                          if (index == _filteredOptions.length) {
                            return ListTile(
                              leading: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                              title: const Text(
                                'Other (Specify Clinical Term)',
                                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                              subtitle: const Text('Enter term not listed in standard catalogue', style: TextStyle(fontSize: 11)),
                              onTap: () {
                                setState(() {
                                  _isCustomOtherSelected = true;
                                  _otherController.text = _searchController.text.trim();
                                });
                              },
                            );
                          }

                          final opt = _filteredOptions[index];
                          final isSelected = widget.initialSelectedId == opt.id || widget.initialSelectedId == opt.label;

                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    opt.label,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (opt.code != null && opt.code!.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.scaffoldBg,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(
                                      opt.code!,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: opt.description != null && opt.description!.isNotEmpty
                                ? Text(opt.description!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))
                                : null,
                            trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20) : null,
                            onTap: () {
                              Navigator.pop(context, opt.label);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

