class Ticket {
  final int id;
  final int registrationId;
  final String ticketCode;
  final String? qrCode;
  final int? eventId;
  final String? eventTitle;

  const Ticket({
    required this.id,
    required this.registrationId,
    required this.ticketCode,
    this.qrCode,
    this.eventId,
    this.eventTitle,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final registration = json['registration'];
    int? eventId;
    String? eventTitle;
    if (registration is Map<String, dynamic>) {
      eventId = registration['event_id'] as int?;
      final event = registration['event'];
      if (event is Map<String, dynamic>) {
        eventTitle = event['title'] as String?;
      }
    }
    return Ticket(
      id: json['id'] as int,
      registrationId: json['registration_id'] as int,
      ticketCode: (json['ticket_code'] as String?) ?? '',
      qrCode: json['qr_code'] as String?,
      eventId: eventId,
      eventTitle: eventTitle,
    );
  }
}
