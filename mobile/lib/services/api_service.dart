import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/app_notification.dart';
import '../models/category.dart';
import '../models/event.dart';
import '../models/paginated.dart';
import '../models/registration.dart';
import '../models/ticket.dart';
import '../models/user.dart';
import 'api_exception.dart';

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  String? _token;

  set token(String? value) => _token = value;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (query != null && query.isNotEmpty) {
      return uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...query.map((k, v) => MapEntry(k, v.toString())),
      });
    }
    return uri;
  }

  dynamic _decode(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      body = {'message': response.body};
    }

    if (response.statusCode >= 400) {
      final message = _extractErrorMessage(body);
      throw ApiException(message, statusCode: response.statusCode);
    }
    return body;
  }

  String _extractErrorMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body['errors'] is Map<String, dynamic>) {
        final errors = body['errors'] as Map<String, dynamic>;
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) return value.first.toString();
          if (value is String && value.isNotEmpty) return value;
        }
      }
      if (body['message'] is String) return body['message'] as String;
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = _uri(path, query);
    final encoded = body != null ? jsonEncode(body) : null;

    late http.Response response;
    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: _headers);
      case 'POST':
        response = await http.post(uri, headers: _headers, body: encoded);
      case 'PUT':
        response = await http.put(uri, headers: _headers, body: encoded);
      case 'DELETE':
        response = await http.delete(uri, headers: _headers);
      default:
        throw ApiException('Metode tidak didukung');
    }

    final decoded = _decode(response);
    return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
  }

  List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data is List) {
      return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Paginated<T> _parsePaginated<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return Paginated(
      items: _parseList(json['data'], fromJson),
      currentPage: (json['current_page'] as int?) ?? 1,
      lastPage: (json['last_page'] as int?) ?? 1,
      total: (json['total'] as int?) ?? 0,
    );
  }

  // AUTH
  Future<(User, String)> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final json = await _request('POST', '/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
      'phone': phone,
    });
    return (
      User.fromJson(json['user'] as Map<String, dynamic>),
      json['token'] as String,
    );
  }

  Future<(User, String)> login({
    required String email,
    required String password,
  }) async {
    final json = await _request('POST', '/auth/login', body: {
      'email': email,
      'password': password,
    });
    return (
      User.fromJson(json['user'] as Map<String, dynamic>),
      json['token'] as String,
    );
  }

  Future<void> logout() async {
    await _request('POST', '/auth/logout');
  }

  Future<User> me() async {
    final json = await _request('GET', '/auth/me');
    return User.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<User> updateProfile({
    String? name,
    String? phone,
    String? password,
  }) async {
    final json = await _request('PUT', '/auth/profile', body: {
      'name': ?name,
      'phone': ?phone,
      'password': ?password,
    });
    return User.fromJson(json['user'] as Map<String, dynamic>);
  }

  // CATEGORIES
  Future<List<Category>> getCategories() async {
    final json = await _request('GET', '/categories');
    return _parseList(json['data'], Category.fromJson);
  }

  Future<Category> createCategory(String name, String? description) async {
    final json = await _request('POST', '/categories', body: {
      'category_name': name,
      if (description != null && description.isNotEmpty) 'description': description,
    });
    return Category.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Category> updateCategory(int id, String name, String? description) async {
    final json = await _request('PUT', '/categories/$id', body: {
      'category_name': name,
      if (description != null && description.isNotEmpty) 'description': description,
    });
    return Category.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> deleteCategory(int id) async {
    await _request('DELETE', '/categories/$id');
  }

  // EVENTS
  Future<Paginated<Event>> getEvents({
    int? categoryId,
    String? search,
    String? status,
    int page = 1,
  }) async {
    final json = await _request('GET', '/events', query: {
      'category_id': ?categoryId,
      if (search != null && search.isNotEmpty) 'search': search,
      'status': ?status,
      'page': page,
    });
    return _parsePaginated(json, Event.fromJson);
  }

  Future<Event> getEvent(int id) async {
    final json = await _request('GET', '/events/$id');
    return Event.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Event> createEvent(Map<String, dynamic> data) async {
    final json = await _request('POST', '/events', body: data);
    return Event.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Event> updateEvent(int id, Map<String, dynamic> data) async {
    final json = await _request('PUT', '/events/$id', body: data);
    return Event.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> deleteEvent(int id) async {
    await _request('DELETE', '/events/$id');
  }

  // REGISTRATIONS
  Future<Paginated<Registration>> getRegistrations({int page = 1}) async {
    final json = await _request('GET', '/registrations', query: {'page': page});
    return _parsePaginated(json, Registration.fromJson);
  }

  Future<Registration> getRegistration(int id) async {
    final json = await _request('GET', '/registrations/$id');
    return Registration.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Registration> createRegistration(int eventId) async {
    final json = await _request('POST', '/registrations', body: {'event_id': eventId});
    return Registration.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Registration> updateRegistration(int id, String status) async {
    final json = await _request('PUT', '/registrations/$id', body: {'status': status});
    return Registration.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> deleteRegistration(int id) async {
    await _request('DELETE', '/registrations/$id');
  }

  // TICKETS
  Future<Paginated<Ticket>> getTickets({int page = 1}) async {
    final json = await _request('GET', '/tickets', query: {'page': page});
    return _parsePaginated(json, Ticket.fromJson);
  }

  Future<Ticket> getTicket(int id) async {
    final json = await _request('GET', '/tickets/$id');
    return Ticket.fromJson(json['data'] as Map<String, dynamic>);
  }

  // NOTIFICATIONS
  Future<Paginated<AppNotification>> getNotifications({int page = 1}) async {
    final json = await _request('GET', '/notifications', query: {'page': page});
    return _parsePaginated(json, AppNotification.fromJson);
  }

  Future<void> markNotificationRead(int id, {bool isRead = true}) async {
    await _request('PUT', '/notifications/$id/read', body: {'is_read': isRead});
  }
}
