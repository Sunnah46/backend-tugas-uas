import 'event.dart';
import 'ticket.dart';
import 'user.dart';

class Registration {
  final int id;
  final int userId;
  final int eventId;
  final String? registrationDate;
  final String status;
  final Event? event;
  final User? user;
  final Ticket? ticket;

  const Registration({
    required this.id,
    required this.userId,
    required this.eventId,
    this.registrationDate,
    required this.status,
    this.event,
    this.user,
    this.ticket,
  });

  factory Registration.fromJson(Map<String, dynamic> json) {
    return Registration(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      eventId: json['event_id'] as int,
      registrationDate: json['registration_date'] as String?,
      status: (json['status'] as String?) ?? 'Menunggu',
      event: json['event'] != null
          ? Event.fromJson(json['event'] as Map<String, dynamic>)
          : null,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      ticket: json['ticket'] != null
          ? Ticket.fromJson(json['ticket'] as Map<String, dynamic>)
          : null,
    );
  }
}
