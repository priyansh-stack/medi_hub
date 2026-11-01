import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/clinical/clinical_field_definition.dart';
import '../../../core/constants/app_colors.dart';
import 'clinical_guideline_dialog.dart';
import 'clinical_searchable_selector_dialog.dart';

class ClinicalFieldRenderer extends StatefulWidget {
  final ClinicalFieldDefinition field;
  final dynamic initialValue;
  final ValueChanged<dynamic> onChanged;
  final String? errorMessage;
  final DateTime? memberDob;

  const ClinicalFieldRenderer({
    super.key,
    required this.field,
    required this.initialValue,
    required this.onChanged,
    this.errorMessage,
    this.memberDob,
  });

  @override
  State<ClinicalFieldRenderer> createState() => _ClinicalFieldRendererState();
}

class _ClinicalFieldRendererState extends State<ClinicalFieldRenderer> {
  late TextEditingController _textController;
  late TextEditingController _otherTextController;
  String? _currentValue;
  String? _dataState; // 'known', 'unknown', 'notapplicable', 'declined'
  bool _showOtherField = false;

  @override
  void initState() {
    super.initState();
    _initValueState();
  }

  void _initValueState() {
    final raw = widget.initialValue;
    if (raw is Map) {
      _dataState = raw['state']?.toString().toLowerCase();
      _currentValue = raw['value']?.toString();
    } else if (raw != null) {
      _currentValue = raw.toString();
      _dataState = 'known';
    } else {
      _currentValue = null;
      _dataState = null;
    }

    _textController = TextEditingController(text: _currentValue ?? '');
    _otherTextController = TextEditingController();

    if (_currentValue != null &&
        widget.field.options.isNotEmpty &&
        !widget.field.options.any((o) => o.id == _currentValue || o.label == _currentValue)) {
      _showOtherField = true;
      _otherTextController.text = _currentValue!;
    }
  }

  @override
  void didUpdateWidget(covariant ClinicalFieldRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      final raw = widget.initialValue;
      String? newVal;
      String? newState;
      if (raw is Map) {
        newState = raw['state']?.toString().toLowerCase();
        newVal = raw['value']?.toString();
      } else if (raw != null) {
        newVal = raw.toString();
        newState = 'known';
      }

      if (newVal != _currentValue || newState != _dataState) {
        setState(() {
          _currentValue = newVal;
          _dataState = newState;
          _textController.text = newVal ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _otherTextController.dispose();
    super.dispose();
  }

  void _notifyChange(String? value, {String state = 'completed'}) {
    setState(() {
      _currentValue = value;
      _dataState = state;
    });

    widget.onChanged({
      'value': value,
      'state': state,
      'lastModified': DateTime.now().toIso8601String(),
    });
  }

  void _markExplicitState(String stateKey) {
    setState(() {
      if (_dataState == stateKey) {
        // Deselect
        _dataState = null;
        _currentValue = null;
        _textController.clear();
        widget.onChanged(null);
      } else {
        _dataState = stateKey;
        _currentValue = null;
        _textController.clear();
        widget.onChanged({
          'state': stateKey,
          'value': stateKey.toUpperCase(),
          'lastModified': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final guideline = field.guidelineReference;
    final isExplicitState = _dataState == 'unknown' || _dataState == 'notapplicable' || _dataState == 'declined';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.errorMessage != null
              ? AppColors.error
              : isExplicitState
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.border,
          width: widget.errorMessage != null ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field Header: Label & Guideline Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            field.label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (field.requiredState) ...[
                          const SizedBox(width: 4),
                          const Text(
                            '*',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      field.description,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
              if (guideline != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => ClinicalGuidelineDialog.show(context, guideline),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_outlined, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          guideline.ruleId,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Primary Control (if not bypassed by explicit Unknown / Not Applicable state)
          if (!isExplicitState) ...[
            _buildInputControl(),
            if (_showOtherField) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _otherTextController,
                decoration: const InputDecoration(
                  labelText: 'Specify Other Details',
                  hintText: 'Enter clinical detail...',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (val) {
                  _notifyChange(val.trim());
                },
              ),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Recorded state: ${_dataState?.toUpperCase()} (No details required)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],

          // Validation Error Message
          if (widget.errorMessage != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: AppColors.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.errorMessage!,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),

          // Clinical Data State Bar (Explicit Unknown, Not Applicable, Declined)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Mark state:',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              _buildStateChip('unknown', 'Unknown', _dataState == 'unknown'),
              _buildStateChip('notapplicable', 'Not Applicable', _dataState == 'notapplicable'),
              if (field.isGated || field.healthTier >= 3)
                _buildStateChip('declined', 'Declined', _dataState == 'declined'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputControl() {
    final field = widget.field;

    switch (field.inputType) {
      case ClinicalInputType.singleChoiceDropdown:
      case ClinicalInputType.severityDropdown:
        return _buildDropdownControl();

      case ClinicalInputType.singleChoiceRadio:
      case ClinicalInputType.yesNoUnknown:
        return _buildRadioControl();

      case ClinicalInputType.datePicker:
        return _buildDatePickerControl();

      case ClinicalInputType.numericMeasurement:
        return _buildNumericControl();

      case ClinicalInputType.clinicalConditionSelector:
      case ClinicalInputType.medicationSelector:
      case ClinicalInputType.allergySelector:
        return _buildSearchableSelectorControl();

      case ClinicalInputType.multiChoiceChips:
        return _buildMultiChoiceControl();

      case ClinicalInputType.multilineText:
      default:
        return _buildTextControl();
    }
  }

  Widget _buildDropdownControl() {
    final options = widget.field.options;
    final selectedMatch = options.any((o) => o.id == _currentValue || o.label == _currentValue);

    return DropdownButtonFormField<String>(
      initialValue: selectedMatch ? _currentValue : null,
      decoration: InputDecoration(
        hintText: 'Select ${widget.field.label}...',
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      isExpanded: true,
      items: [
        ...options.map((opt) => DropdownMenuItem<String>(
              value: opt.id,
              child: Text(
                opt.label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            )),
        if (widget.field.hasOtherOption)
          const DropdownMenuItem<String>(
            value: 'other_custom',
            child: Text('Other (Specify custom details)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
      ],
      onChanged: (val) {
        if (val == 'other_custom') {
          setState(() {
            _showOtherField = true;
          });
        } else {
          setState(() {
            _showOtherField = false;
          });
          _notifyChange(val);
        }
      },
    );
  }

  Widget _buildRadioControl() {
    final options = widget.field.options;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = _currentValue == opt.id || _currentValue == opt.label;
        return ChoiceChip(
          label: Text(
            opt.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
            ),
          ),
          selected: isSelected,
          selectedColor: AppColors.primarySurface,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
          onSelected: (selected) {
            if (selected) {
              _notifyChange(opt.id);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildDatePickerControl() {
    DateTime? currentDate = DateTime.tryParse(_currentValue ?? '');

    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final firstDate = widget.memberDob ?? DateTime(1900);
        final isPastOnly = widget.field.validationRules.any((r) => !r.allowFutureDates);
        final lastDate = isPastOnly ? now : now.add(const Duration(days: 365 * 10));

        final initial = currentDate != null && currentDate.isAfter(firstDate) && currentDate.isBefore(lastDate)
            ? currentDate
            : isPastOnly
                ? now
                : now;

        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: firstDate,
          lastDate: lastDate,
          helpText: 'Select ${widget.field.label}',
        );

        if (picked != null) {
          final formattedIso = DateFormat('yyyy-MM-dd').format(picked);
          _notifyChange(formattedIso);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              currentDate != null ? DateFormat('dd/MM/yyyy').format(currentDate) : 'Select date (DD/MM/YYYY)...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: currentDate != null ? FontWeight.w600 : FontWeight.w400,
                color: currentDate != null ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericControl() {
    return TextField(
      controller: _textController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: 'Enter measurement...',
        suffixText: widget.field.unit,
        suffixStyle: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: (val) {
        _notifyChange(val.trim());
      },
    );
  }

  Widget _buildSearchableSelectorControl() {
    final hasValue = _currentValue != null && _currentValue!.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final selected = await ClinicalSearchableSelectorDialog.show(
                context,
                title: 'Select ${widget.field.label}',
                options: widget.field.options,
                initialSelectedId: _currentValue,
                allowOther: widget.field.hasOtherOption,
              );
              if (selected != null) {
                _notifyChange(selected);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
                color: hasValue ? AppColors.primarySurface.withValues(alpha: 0.3) : Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasValue ? _currentValue! : 'Search clinical catalogue for ${widget.field.label}...',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
                        color: hasValue ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasValue) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
            tooltip: 'Clear selection',
            onPressed: () {
              _notifyChange(null);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildMultiChoiceControl() {
    final selectedItems = _currentValue != null ? _currentValue!.split(';').map((e) => e.trim()).toList() : <String>[];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.field.options.map((opt) {
        final isSelected = selectedItems.contains(opt.id) || selectedItems.contains(opt.label);
        return FilterChip(
          label: Text(opt.label, style: const TextStyle(fontSize: 12)),
          selected: isSelected,
          selectedColor: AppColors.primarySurface,
          checkmarkColor: AppColors.primary,
          onSelected: (selected) {
            final updated = List<String>.from(selectedItems);
            if (selected) {
              updated.add(opt.label);
            } else {
              updated.remove(opt.label);
              updated.remove(opt.id);
            }
            _notifyChange(updated.join('; '));
          },
        );
      }).toList(),
    );
  }

  Widget _buildTextControl() {
    return TextField(
      controller: _textController,
      maxLines: 2,
      maxLength: widget.field.characterLimit,
      decoration: InputDecoration(
        hintText: 'Enter clinical details for ${widget.field.label}...',
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: (val) {
        _notifyChange(val.trim());
      },
    );
  }

  Widget _buildStateChip(String stateKey, String label, bool isSelected) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primarySurface,
      backgroundColor: AppColors.scaffoldBg,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
        width: isSelected ? 1.2 : 0.8,
      ),
      onSelected: (_) => _markExplicitState(stateKey),
    );
  }
}

