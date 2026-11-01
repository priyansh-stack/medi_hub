import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/health_record_model.dart';
import '../../../data/repositories/health_records_repository.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class HealthRecordsTab extends StatefulWidget {
  final String memberId;
  final String familyId;
  final String userName;
  final HealthRecordsRepository? repository;
  final VoidCallback onRecordsUpdated;

  const HealthRecordsTab({
    super.key,
    required this.memberId,
    required this.familyId,
    required this.userName,
    this.repository,
    required this.onRecordsUpdated,
  });

  @override
  State<HealthRecordsTab> createState() => _HealthRecordsTabState();
}

class _HealthRecordsTabState extends State<HealthRecordsTab> {
  List<HealthRecordModel> _records = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _sortNewestFirst = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecords() async {
    if (widget.repository == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final records = await widget.repository!.getHealthRecords(widget.memberId);
      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
        widget.onRecordsUpdated();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<HealthRecordModel> get _filteredRecords {
    var list = _records.where((r) {
      final matchesCategory = _selectedCategory == 'All' || r.category == _selectedCategory;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          r.title.toLowerCase().contains(q) ||
          (r.doctorOrHospital?.toLowerCase().contains(q) ?? false) ||
          r.category.toLowerCase().contains(q) ||
          (r.description?.toLowerCase().contains(q) ?? false);
      return matchesCategory && matchesSearch;
    }).toList();

    list.sort((a, b) => _sortNewestFirst
        ? b.documentDate.compareTo(a.documentDate)
        : a.documentDate.compareTo(b.documentDate));
    return list;
  }

  void _showUploadRecordDialog() {
    final titleController = TextEditingController();
    final doctorController = TextEditingController();
    final descriptionController = TextEditingController();
    final dateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
    DateTime selectedDate = DateTime.now();
    String selectedCategory = HealthRecordModel.categories.first;
    PlatformFile? pickedFile;
    Uint8List? pickedFileBytes;
    int? pickedFileSize;
    bool isUploading = false;
    String? fileError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 24),
                  SizedBox(width: 10),
                  Text('Upload Health Record', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload diagnostic reports, prescriptions, or vaccination records to your secure health vault.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),

                      // Document Title
                      CustomTextField(
                        label: 'Document Title *',
                        controller: titleController,
                        hint: 'e.g. Annual Blood Chemistry Panel',
                        prefixIcon: Icons.title_rounded,
                      ),
                      const SizedBox(height: 14),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Record Category *',
                          prefixIcon: Icon(Icons.category_outlined, size: 20),
                        ),
                        items: HealthRecordModel.categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedCategory = val);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Date Picker
                      CustomTextField(
                        label: 'Document Date (DD/MM/YYYY) *',
                        controller: dateController,
                        prefixIcon: Icons.calendar_today_outlined,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_month, color: AppColors.primary),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(1980),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              selectedDate = picked;
                              setModalState(() {
                                dateController.text = DateFormat('dd/MM/yyyy').format(picked);
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Doctor / Hospital
                      CustomTextField(
                        label: 'Doctor / Clinic / Hospital (Optional)',
                        controller: doctorController,
                        hint: 'e.g. Dr. Ramesh Sharma / Fortis Hospital',
                        prefixIcon: Icons.local_hospital_outlined,
                      ),
                      const SizedBox(height: 14),

                      // Description
                      CustomTextField(
                        label: 'Notes or Summary (Optional)',
                        controller: descriptionController,
                        maxLines: 2,
                        hint: 'e.g. Cholesterol levels within normal range.',
                        prefixIcon: Icons.notes_rounded,
                      ),
                      const SizedBox(height: 16),

                      // File Picker Section
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: fileError != null ? AppColors.error : AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.attach_file_rounded, size: 18, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      pickedFile == null ? 'Select Document File' : pickedFile!.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: pickedFile == null ? AppColors.textSecondary : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: const Size(80, 32),
                                  ),
                                  icon: const Icon(Icons.folder_open_rounded, size: 15),
                                  label: const Text('Browse', style: TextStyle(fontSize: 12)),
                                  onPressed: isUploading
                                      ? null
                                      : () async {
                                          final file = await FilePicker.pickFile(
                                            type: FileType.custom,
                                            allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                                          );
                                          if (file != null) {
                                            final fileSize = file.lengthSync() ?? (await file.length()) ?? 0;
                                            if (fileSize > 10 * 1024 * 1024) {
                                              setModalState(() {
                                                fileError = 'File exceeds maximum limit of 10 MB.';
                                                pickedFile = null;
                                                pickedFileBytes = null;
                                                pickedFileSize = null;
                                              });
                                            } else {
                                              final bytes = await file.readAsBytes();
                                              setModalState(() {
                                                pickedFile = file;
                                                pickedFileBytes = bytes;
                                                pickedFileSize = fileSize;
                                                fileError = null;
                                              });
                                            }
                                          }
                                        },
                                ),
                              ],
                            ),
                            if (pickedFile != null && pickedFileSize != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Size: ${(pickedFileSize! / (1024 * 1024)).toStringAsFixed(2)} MB • Format: ${pickedFile!.extension?.toUpperCase() ?? 'DOC'}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ] else ...[
                              const SizedBox(height: 4),
                              const Text(
                                'Supported formats: PDF, JPG, JPEG, PNG (Max 10 MB)',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                            if (fileError != null) ...[
                              const SizedBox(height: 6),
                              Text(fileError!, style: const TextStyle(fontSize: 12, color: AppColors.error)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: isUploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload_rounded, size: 16),
                  label: Text(isUploading ? 'Uploading...' : 'Upload & Save'),
                  onPressed: isUploading
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a document title.')),
                            );
                            return;
                          }
                          if (pickedFile == null || pickedFileBytes == null) {
                            setModalState(() => fileError = 'Please select a file to upload.');
                            return;
                          }

                          setModalState(() => isUploading = true);
                          try {
                            final ext = pickedFile!.extension?.toLowerCase() ?? 'pdf';
                            String mimeType = 'application/pdf';
                            if (ext == 'jpg' || ext == 'jpeg') mimeType = 'image/jpeg';
                            if (ext == 'png') mimeType = 'image/png';

                            if (widget.repository != null) {
                              await widget.repository!.uploadRecord(
                                memberId: widget.memberId,
                                familyId: widget.familyId,
                                title: title,
                                category: selectedCategory,
                                documentDate: selectedDate,
                                doctorOrHospital: doctorController.text.trim().isNotEmpty
                                    ? doctorController.text.trim()
                                    : null,
                                description: descriptionController.text.trim().isNotEmpty
                                    ? descriptionController.text.trim()
                                    : null,
                                fileName: pickedFile!.name,
                                bytes: pickedFileBytes!,
                                mimeType: mimeType,
                                uploadedBy: widget.userName,
                              );
                            }

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              _fetchRecords();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Record uploaded and encrypted in vault!'),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              setModalState(() => isUploading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Upload failed: $e'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRecordDetailsDialog(HealthRecordModel record) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  record.title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModalDetailRow('Category', record.category),
                _buildModalDetailRow('Document Date', DateFormat('d MMMM yyyy').format(record.documentDate)),
                if (record.doctorOrHospital?.isNotEmpty == true)
                  _buildModalDetailRow('Doctor / Hospital', record.doctorOrHospital!),
                if (record.description?.isNotEmpty == true)
                  _buildModalDetailRow('Notes', record.description!),
                _buildModalDetailRow('File Name', record.fileName),
                _buildModalDetailRow('File Type', record.fileType.toUpperCase()),
                _buildModalDetailRow('File Size', '${(record.fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB'),
                if (record.uploadedAt != null)
                  _buildModalDetailRow('Uploaded On', DateFormat('d MMM yyyy, h:mm a').format(record.uploadedAt!)),
                _buildModalDetailRow('Uploaded By', record.uploadedBy.isNotEmpty ? record.uploadedBy : 'Self'),
                const Divider(height: 24),
                // Security notice
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Encrypted Storage: Accessible only to authorized family members.',
                          style: TextStyle(fontSize: 11, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            if (record.documentUrl.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: const Text('View / Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // In Flutter Web, launching the URL opens the storage file
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Document URL ready: ${record.fileName}'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(HealthRecordModel record) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Health Record?'),
          content: Text(
            'Are you sure you want to delete "${record.title}"? This will permanently remove the record and its attached file from the vault.',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  if (widget.repository != null) {
                    await widget.repository!.deleteRecord(record);
                  }
                  _fetchRecords();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Record deleted from health vault.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModalDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRecords;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Action Header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_shared_rounded, color: AppColors.primary, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Personal Health Records Vault',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Upload Record'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: _showUploadRecordDialog,
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Search Bar & Sort Toggle
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search records by title, doctor, or keyword...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      icon: Icon(_sortNewestFirst ? Icons.arrow_downward : Icons.arrow_upward, size: 16),
                      label: Text(_sortNewestFirst ? 'Newest' : 'Oldest', style: const TextStyle(fontSize: 12)),
                      onPressed: () => setState(() => _sortNewestFirst = !_sortNewestFirst),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Category Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('All'),
                      ...HealthRecordModel.categories.map(_buildCategoryChip),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Record List / Loading / Empty State
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (filtered.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.primarySurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.folder_open_rounded, size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _records.isEmpty
                          ? 'Your health vault is empty'
                          : 'No records found for "$_selectedCategory"',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _records.isEmpty
                          ? 'Upload your prescriptions, lab test reports, and immunization records securely.'
                          : 'Try selecting another category or clear your search keyword.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    if (_records.isEmpty)
                      CustomButton(
                        text: 'Upload First Health Record',
                        icon: Icons.upload_file_rounded,
                        width: 240,
                        onPressed: _showUploadRecordDialog,
                      ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final record = filtered[index];
              return _buildRecordCard(record);
            },
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) => setState(() => _selectedCategory = category),
      ),
    );
  }

  Widget _buildRecordCard(HealthRecordModel record) {
    final dateStr = DateFormat('d MMM yyyy').format(record.documentDate);
    final sizeMb = (record.fileSizeBytes / (1024 * 1024)).toStringAsFixed(2);

    IconData getCategoryIcon(String cat) {
      switch (cat) {
        case 'Prescriptions':
          return Icons.medication_outlined;
        case 'Lab Reports':
          return Icons.biotech_outlined;
        case 'Immunization':
          return Icons.vaccines_outlined;
        case 'Medical Conditions':
          return Icons.healing_outlined;
        case 'Allergies':
          return Icons.warning_amber_rounded;
        case 'Medications':
          return Icons.medical_services_outlined;
        default:
          return Icons.description_outlined;
      }
    }

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(getCategoryIcon(record.category), color: AppColors.primary, size: 22),
        ),
        title: Text(
          record.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(
              '${record.category} • Date: $dateStr ${record.doctorOrHospital != null ? '• Dr: ${record.doctorOrHospital}' : ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              'File: ${record.fileName} ($sizeMb MB)',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
              tooltip: 'View details',
              onPressed: () => _showRecordDetailsDialog(record),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
              tooltip: 'Delete record',
              onPressed: () => _showDeleteConfirmation(record),
            ),
          ],
        ),
        onTap: () => _showRecordDetailsDialog(record),
      ),
    );
  }
}
