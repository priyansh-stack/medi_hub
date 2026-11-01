import 'package:uuid/uuid.dart';
import '../models/appointment_model.dart';
import '../services/firestore_service.dart';

class AppointmentsRepository {
  final FirestoreService _firestoreService;
  final Uuid _uuid;

  AppointmentsRepository({
    FirestoreService? firestoreService,
    Uuid? uuid,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _uuid = uuid ?? const Uuid();

  Future<List<AppointmentModel>> getAppointments(String memberId) async {
    return await _firestoreService.getAppointmentsForMember(memberId);
  }

  Future<AppointmentModel> createAppointment({
    required String memberId,
    required String familyId,
    required String patientName,
    required String doctorName,
    required String speciality,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String appointmentType,
    String? reason,
  }) async {
    final appointmentId = 'apt_${_uuid.v4().substring(0, 8)}';

    final appointment = AppointmentModel(
      appointmentId: appointmentId,
      memberId: memberId,
      familyId: familyId,
      patientName: patientName,
      doctorName: doctorName,
      speciality: speciality,
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      appointmentType: appointmentType,
      reason: reason,
      status: 'Upcoming',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.saveAppointment(appointment);
    return appointment;
  }

  Future<void> rescheduleAppointment(
    String appointmentId,
    DateTime newDate,
    String newTime,
  ) async {
    await _firestoreService.rescheduleAppointment(
      appointmentId,
      newDate,
      newTime,
    );
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await _firestoreService.updateAppointmentStatus(
      appointmentId,
      'Cancelled',
    );
  }
}

