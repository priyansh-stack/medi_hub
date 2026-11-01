import 'package:equatable/equatable.dart';
import 'clinical_guidelines.dart';

enum ClinicalInputType {
  singleChoiceDropdown,
  singleChoiceRadio,
  multiChoiceChips,
  datePicker,
  numericMeasurement,
  yesNoUnknown,
  clinicalConditionSelector,
  medicationSelector,
  allergySelector,
  severityDropdown,
  durationInput,
  multilineText,
  emergencyContactForm,
  fileUploadNote,
}

enum SensitivityClass {
  standard,
  sensitive,
  highlySensitive,
}

/// Clinically defined option for dropdowns, selectors, and radio buttons
class ClinicalFieldOption extends Equatable {
  final String id;
  final String label;
  final String? code; // ICD-10, SNOMED CT, ATC, LOINC
  final String? description;

  const ClinicalFieldOption({
    required this.id,
    required this.label,
    this.code,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'code': code,
      'description': description,
    };
  }

  factory ClinicalFieldOption.fromMap(Map<String, dynamic> map) {
    return ClinicalFieldOption(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
      code: map['code'] as String?,
      description: map['description'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, label, code];
}

/// Field-level clinical validation rule with explicit error messages
class ClinicalValidationRule extends Equatable {
  final String ruleId;
  final num? min;
  final num? max;
  final bool allowFutureDates;
  final int? minAgeYears;
  final int? maxAgeYears;
  final String? pattern;
  final int? maxCharacters;
  final String errorMessage;
  final bool isWarningOnly; // e.g. unusual values requiring clinical confirmation

  const ClinicalValidationRule({
    required this.ruleId,
    this.min,
    this.max,
    this.allowFutureDates = false,
    this.minAgeYears,
    this.maxAgeYears,
    this.pattern,
    this.maxCharacters,
    required this.errorMessage,
    this.isWarningOnly = false,
  });

  @override
  List<Object?> get props => [
        ruleId,
        min,
        max,
        allowFutureDates,
        minAgeYears,
        maxAgeYears,
        pattern,
        maxCharacters,
        errorMessage,
        isWarningOnly,
      ];
}

/// Dynamic Field Definition controlling presentation, validation, and clinical logic
class ClinicalFieldDefinition extends Equatable {
  final String fieldId;
  final String label;
  final String description;
  final int healthTier; // 1, 2, 3, 4
  final String moduleId; // section id, e.g. 't1_blood_group'
  final ClinicalInputType inputType;
  final List<ClinicalFieldOption> options;
  final String? unit; // e.g. 'mmHg', 'bpm', 'cm', 'kg', 'mg/dL'
  final bool requiredState;
  final List<ClinicalValidationRule> validationRules;
  final String? conditionalParentId; // fieldId this depends on
  final dynamic conditionalValue; // value required in parent to display this field
  final bool hasOtherOption; // shows conditional textfield when 'Other' selected
  final SensitivityClass sensitivityClass;
  final String? consentCategory;
  final ClinicalGuidelineReference? guidelineReference;
  final int displayOrder;
  final int? characterLimit;

  const ClinicalFieldDefinition({
    required this.fieldId,
    required this.label,
    required this.description,
    required this.healthTier,
    required this.moduleId,
    required this.inputType,
    this.options = const [],
    this.unit,
    this.requiredState = false,
    this.validationRules = const [],
    this.conditionalParentId,
    this.conditionalValue,
    this.hasOtherOption = false,
    this.sensitivityClass = SensitivityClass.standard,
    this.consentCategory,
    this.guidelineReference,
    this.displayOrder = 0,
    this.characterLimit,
  });

  bool get isGated => sensitivityClass != SensitivityClass.standard;

  @override
  List<Object?> get props => [
        fieldId,
        label,
        healthTier,
        moduleId,
        inputType,
        unit,
        requiredState,
        conditionalParentId,
        conditionalValue,
        sensitivityClass,
      ];
}

