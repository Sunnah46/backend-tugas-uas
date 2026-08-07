import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../models/event.dart';
import '../../models/event_theme.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';

class EventFormScreen extends StatefulWidget {
  final Event? event;

  const EventFormScreen({super.key, this.event});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _api = ApiService.instance;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _organizerController;
  late final TextEditingController _locationController;
  late final TextEditingController _quotaController;

  int? _categoryId;
  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _status = 'Aktif';
  String? _selectedThemeAsset;
  List<Category> _categories = [];
  bool _loading = false;
  bool _submitting = false;

  bool get _isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(text: event?.description ?? '');
    _organizerController = TextEditingController(text: event?.organizer ?? '');
    _locationController = TextEditingController(text: event?.location ?? '');
    _quotaController = TextEditingController(
      text: event?.quota.toString() ?? '0',
    );
    _selectedThemeAsset = event?.image;
    _categoryId = event?.categoryId;
    _status = event?.status ?? 'Aktif';
    _date = event?.eventDate != null ? DateTime.tryParse(event!.eventDate!) : null;
    _startTime = _parseTime(event?.startTime);
    _endTime = _parseTime(event?.endTime);
    _loadCategories();
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.length < 5) return null;
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _organizerController.dispose();
    _locationController.dispose();
    _quotaController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _api.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        if (_categoryId == null && categories.isNotEmpty) {
          _categoryId = categories.first.id;
        }
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori event')),
      );
      return;
    }

    final data = {
      'category_id': _categoryId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'organizer': _organizerController.text.trim(),
      'location': _locationController.text.trim(),
      'event_date': _date != null ? _formatDate(_date!) : null,
      'start_time': _startTime != null ? _formatTime(_startTime!) : null,
      'end_time': _endTime != null ? _formatTime(_endTime!) : null,
      'quota': int.tryParse(_quotaController.text.trim()) ?? 0,
      'image': _selectedThemeAsset,
      'status': _status,
    };

    setState(() => _submitting = true);
    try {
      if (_isEdit) {
        await _api.updateEvent(widget.event!.id, data);
      } else {
        await _api.createEvent(data);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Event diperbarui' : 'Event dibuat')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Event' : 'Tambah Event')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul Event',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Judul wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _categories
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.categoryName),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _organizerController,
                      decoration: const InputDecoration(
                        labelText: 'Penyelenggara',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Lokasi',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(
                              _date == null
                                  ? 'Pilih Tanggal'
                                  : _formatDate(_date!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickTime(isStart: true),
                            icon: const Icon(Icons.schedule),
                            label: Text(
                              _startTime == null
                                  ? 'Mulai'
                                  : _formatTime(_startTime!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickTime(isStart: false),
                            icon: const Icon(Icons.schedule),
                            label: Text(
                              _endTime == null ? 'Selesai' : _formatTime(_endTime!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quotaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Kuota (0 = tanpa batas)',
                        prefixIcon: Icon(Icons.people_outline),
                      ),
                      validator: (v) {
                        final value = int.tryParse(v ?? '');
                        if (value == null || value < 0) {
                          return 'Kuota harus angka >= 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Tema Gambar',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: EventTheme.all.map((theme) {
                        final selected =
                            _selectedThemeAsset == theme.asset;
                        return InkWell(
                          onTap: () => setState(() {
                            _selectedThemeAsset = selected
                                ? null
                                : theme.asset;
                          }),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                width: 2,
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.4),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    theme.asset,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                if (selected)
                                  const Center(
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                        DropdownMenuItem(
                          value: 'Selesai',
                          child: Text('Selesai'),
                        ),
                        DropdownMenuItem(
                          value: 'Ditutup',
                          child: Text('Ditutup'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _status = v ?? 'Aktif'),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEdit ? 'Simpan Perubahan' : 'Buat Event'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
