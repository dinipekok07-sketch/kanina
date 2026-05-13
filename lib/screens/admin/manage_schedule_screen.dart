import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/schedule_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/custom_button.dart';

class ManageScheduleScreen extends StatefulWidget {
  const ManageScheduleScreen({super.key});

  @override
  State<ManageScheduleScreen> createState() => _ManageScheduleScreenState();
}

class _ManageScheduleScreenState extends State<ManageScheduleScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scheduleProvider = context.read<ScheduleProvider>();
      final session = scheduleProvider.currentSession;
      if (session != null) {
        _titleController.text = session.title;
        _descriptionController.text = session.description;
        _startDate = session.startDate;
        _startTime = TimeOfDay.fromDateTime(session.startDate);
        _endDate = session.endDate;
        _endTime = TimeOfDay.fromDateTime(session.endDate);
        _isActive = session.isActive;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  DateTime? _combineDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _saveSchedule(BuildContext context) {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final startDateTime = _combineDateTime(_startDate, _startTime);
    final endDateTime = _combineDateTime(_endDate, _endTime);

    if (title.isEmpty || description.isEmpty || startDateTime == null || endDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    if (startDateTime.isAfter(endDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waktu mulai harus sebelum waktu selesai')),
      );
      return;
    }

    context.read<ScheduleProvider>().updateSession(
      title: title,
      description: description,
      startDate: startDateTime,
      endDate: endDateTime,
      isActive: _isActive,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Jadwal berhasil diperbarui')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Jadwal Voting'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, scheduleProvider, _) {
          final session = scheduleProvider.currentSession;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Konfigurasi Jadwal Pemilihan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Pemilihan',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Start Date & Time
                const Text(
                  'Waktu Mulai',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _selectStartDate(context),
                        child: Text(_startDate != null
                            ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                            : 'Pilih Tanggal'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _selectStartTime(context),
                        child: Text(_startTime != null
                            ? _startTime!.format(context)
                            : 'Pilih Waktu'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // End Date & Time
                const Text(
                  'Waktu Selesai',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _selectEndDate(context),
                        child: Text(_endDate != null
                            ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                            : 'Pilih Tanggal'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _selectEndTime(context),
                        child: Text(_endTime != null
                            ? _endTime!.format(context)
                            : 'Pilih Waktu'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Status Toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Status Voting',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Switch(
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                        activeColor: const Color(0xFF1A5F7A),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isActive ? 'Voting sedang aktif' : 'Voting tidak aktif',
                  style: TextStyle(
                    color: _isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                CustomButton(
                  label: 'Simpan Perubahan',
                  onPressed: () => _saveSchedule(context),
                  backgroundColor: const Color(0xFF1A5F7A),
                ),

                const SizedBox(height: 24),

                // Current Status
                if (session != null) ...[
                  const Text(
                    'Status Saat Ini',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Judul: ${session.title}'),
                        Text('Deskripsi: ${session.description}'),
                        Text('Mulai: ${session.startDate}'),
                        Text('Selesai: ${session.endDate}'),
                        Text('Status: ${session.isActive ? 'Aktif' : 'Tidak Aktif'}'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
