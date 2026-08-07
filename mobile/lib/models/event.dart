import 'category.dart';

class Event {
  final int id;
  final int categoryId;
  final String title;
  final String? description;
  final String? organizer;
  final String? location;
  final String? eventDate;
  final String? startTime;
  final String? endTime;
  final int quota;
  final String? image;
  final String status;
  final int registeredCount;
  final Category? category;

  const Event({
    required this.id,
    required this.categoryId,
    required this.title,
    this.description,
    this.organizer,
    this.location,
    this.eventDate,
    this.startTime,
    this.endTime,
    required this.quota,
    this.image,
    required this.status,
    this.registeredCount = 0,
    this.category,
  });

  bool get isOpen => status == 'Aktif';
  bool get isFull => quota > 0 && registeredCount >= quota;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as int,
      categoryId: (json['category_id'] as int?) ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      organizer: json['organizer'] as String?,
      location: json['location'] as String?,
      eventDate: json['event_date'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      quota: (json['quota'] as int?) ?? 0,
      image: json['image'] as String?,
      status: (json['status'] as String?) ?? 'Aktif',
      registeredCount: (json['registered_count'] as int?) ?? 0,
      category: json['category'] != null
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'organizer': organizer,
      'location': location,
      'event_date': eventDate,
      'start_time': startTime,
      'end_time': endTime,
      'quota': quota,
      'image': image,
      'status': status,
    };
  }
}
