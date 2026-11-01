import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/repositories/appointments_repository.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AppointmentsTab extends StatefulWidget {
  final String memberId;
  final String familyId;
  final String patientName;
  final AppointmentsRepository? repository;
  final VoidCallback onAppointmentsUpdated;

  const AppointmentsTab({
    super.key,
    required this.memberId,
    required this.familyId,
    required this.patientName,
    this.repository,
    required this.onAppointmentsUpdated,
  });

  @override
  State<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {
  List<AppointmentModel> _appointments = [];
  bool _isLoading = true;
  String _activeStatus = 'Upcoming'; // 'Upcoming', 'Completed', 'Cancelled'

  static const List<String> _specialities = [
    'General Physician',
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Orthopedic',
    'Neurologist',
    'ENT Specialist',
    'Dentist',
    'Psychiatrist',
    'Gynecologist',
  ];

  static const List<String> _timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:30 AM',
    '02:00 PM',
    '03:30 PM',
    '05:00 PM',
    '06:30 PM',
  ];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    if (widget.repository == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final list = await widget.repository!.getAppointments(widget.memberId);
      if (mounted) {
        setState(() {
          _appointments = list;
          _isLoading = false;
        });
        widget.onAppointmentsUpdated();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<AppointmentModel> get _filteredAppointments {
    return _appointments.where((a) => a.status.toLowerCase() == _activeStatus.toLowerCase()).toList();
  }

  void _showBookAppointmentDialog() {
    final doctorController = TextEditingController();
    final reasonController = TextEditingController();
    final dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 1))),
    );
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedSpeciality = _specialities.first;
    String selectedTime = _timeSlots.first;
    String selectedType = 'In-person';
    bool isSaving = false;

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
                  Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 24),
                  SizedBox(width: 10),
                  Text('Book Doctor Appointment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Info summary
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Patient: ${widget.patientName} (${widget.memberId})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Doctor Name
                      CustomTextField(
                        label: 'Doctor Name *',
                        controller: doctorController,
                        hint: 'e.g. Dr. Ananya Sen',
                        prefixIcon: Icons.medication_liquid_outlined,
                      ),
                      const SizedBox(height: 14),

                      // Speciality Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: selectedSpeciality,
                        decoration: const InputDecoration(
                          labelText: 'Speciality *',
                          prefixIcon: Icon(Icons.medical_services_outlined, size: 20),
                        ),
                        items: _specialities.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedSpeciality = val);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Appointment Type (In-person vs Teleconsultation)
                      DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Consultation Mode *',
                          prefixIcon: Icon(Icons.video_camera_front_outlined, size: 20),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'In-person', child: Text('In-person Hospital Visit')),
                          DropdownMenuItem(value: 'Teleconsultation', child: Text('Video Teleconsultation')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedType = val);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Date & Time Row
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Date (DD/MM/YYYY) *',
                              controller: dateController,
                              prefixIcon: Icons.calendar_today_outlined,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 90)),
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedTime,
                              decoration: const InputDecoration(
                                labelText: 'Time Slot *',
                                prefixIcon: Icon(Icons.access_time_rounded, size: 18),
                              ),
                              items: _timeSlots.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => selectedTime = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Reason for appointment
                      CustomTextField(
                        label: 'Reason for Appointment (Optional)',
                        controller: reasonController,
                        maxLines: 2,
                        hint: 'e.g. Follow-up consultation for blood pressure check',
                        prefixIcon: Icons.help_outline_rounded,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final docName = doctorController.text.trim();
                          if (docName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a doctor name.')),
                            );
                            return;
                          }

                          setModalState(() => isSaving = true);
                          try {
                            if (widget.repository != null) {
                              await widget.repository!.createAppointment(
                                memberId: widget.memberId,
                                familyId: widget.familyId,
                                patientName: widget.patientName,
                                doctorName: docName,
                                speciality: selectedSpeciality,
                                appointmentDate: selectedDate,
                                appointmentTime: selectedTime,
                                appointmentType: selectedType,
                                reason: reasonController.text.trim().isNotEmpty
                                    ? reasonController.text.trim()
                                    : null,
                              );
                            }

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              _fetchAppointments();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Appointment scheduled successfully!'),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              setModalState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to book: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  child: Text(isSaving ? 'Scheduling...' : 'Confirm Appointment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRescheduleDialog(AppointmentModel appointment) {
    DateTime newDate = appointment.appointmentDate;
    String newTime = appointment.appointmentTime;
    final dateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(newDate));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Reschedule Appointment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Doctor: ${appointment.doctorName} (${appointment.speciality})',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'New Date (DD/MM/YYYY)',
                    controller: dateController,
                    prefixIcon: Icons.calendar_today_outlined,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: newDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          newDate = picked;
                          setModalState(() {
                            dateController.text = DateFormat('dd/MM/yyyy').format(picked);
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _timeSlots.contains(newTime) ? newTime : _timeSlots.first,
                    decoration: const InputDecoration(labelText: 'New Time Slot'),
                    items: _timeSlots.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => newTime = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    if (widget.repository != null) {
                      await widget.repository!.rescheduleAppointment(appointment.appointmentId, newDate, newTime);
                    }
                    _fetchAppointments();
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Appointment rescheduled!'), backgroundColor: AppColors.primary),
                      );
                    }
                  },
                  child: const Text('Confirm Reschedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCancelConfirmation(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Cancel Appointment?'),
          content: Text(
            'Are you sure you want to cancel your consultation with ${appointment.doctorName} on ${DateFormat('d MMM yyyy').format(appointment.appointmentDate)}?',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Appointment')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                if (widget.repository != null) {
                  await widget.repository!.cancelAppointment(appointment.appointmentId);
                }
                _fetchAppointments();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appointment cancelled.'), behavior: SnackBarBehavior.floating),
                  );
                }
              },
              child: const Text('Cancel Appointment'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAppointments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action Header
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
                        Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Doctor Appointments & Consultations',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Book Appointment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: _showBookAppointmentDialog,
                    ),
                  ],
                ),
                const Divider(height: 22),

                // Status Tabs: Upcoming, Completed, Cancelled
                Row(
                  children: [
                    _buildStatusTab('Upcoming'),
                    const SizedBox(width: 8),
                    _buildStatusTab('Completed'),
                    const SizedBox(width: 8),
                    _buildStatusTab('Cancelled'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // List / Empty State
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
                      child: const Icon(Icons.event_available_rounded, size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No $_activeStatus appointments',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _activeStatus == 'Upcoming'
                          ? 'You have no scheduled doctor visits or teleconsultations.'
                          : 'No appointments under "$_activeStatus" status.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    if (_activeStatus == 'Upcoming')
                      CustomButton(
                        text: 'Book New Appointment',
                        icon: Icons.add,
                        width: 220,
                        onPressed: _showBookAppointmentDialog,
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
              final apt = filtered[index];
              return _buildAppointmentCard(apt);
            },
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatusTab(String status) {
    final isSelected = _activeStatus == status;
    return ChoiceChip(
      label: Text(status),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => setState(() => _activeStatus = status),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel apt) {
    final dateStr = DateFormat('EEEE, d MMM yyyy').format(apt.appointmentDate);
    final isTele = apt.appointmentType == 'Teleconsultation';

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primarySurface,
                      child: Icon(
                        isTele ? Icons.video_camera_front_outlined : Icons.local_hospital_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          apt.doctorName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${apt.speciality} • ${apt.appointmentType}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBg(apt.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    apt.status.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _getStatusColor(apt.status)),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '$dateStr at ${apt.appointmentTime}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
            if (apt.reason?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(
                'Reason: ${apt.reason!}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
            if (apt.status == 'Upcoming') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(100, 32),
                    ),
                    icon: const Icon(Icons.update_rounded, size: 14),
                    label: const Text('Reschedule', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showRescheduleDialog(apt),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(80, 32),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 14),
                    label: const Text('Cancel', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showCancelConfirmation(apt),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return AppColors.primarySurface;
      case 'completed':
        return AppColors.infoBg;
      case 'cancelled':
        return AppColors.error.withValues(alpha: 0.1);
      default:
        return AppColors.scaffoldBg;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return AppColors.primary;
      case 'completed':
        return AppColors.info;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
