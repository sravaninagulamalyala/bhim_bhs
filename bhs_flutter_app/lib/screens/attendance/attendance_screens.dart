import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/auth_store.dart';
import '../../core/widgets/common_widgets.dart';

String _date(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

class AttendanceMeetingScreen extends StatefulWidget {
  const AttendanceMeetingScreen({super.key});
  @override
  State<AttendanceMeetingScreen> createState() => _AttendanceMeetingScreenState();
}

class _AttendanceMeetingScreenState extends State<AttendanceMeetingScreen> {
  DateTime date = DateTime.now();
  final title = TextEditingController();
  final remarks = TextEditingController();

  Future<void> _create() async {
    try {
      await ApiClient(context.read<AuthStore>()).post('/attendance/meeting', body: {'meetingDate': _date(date), 'title': title.text.trim(), 'remarks': remarks.text.trim()});
      if (mounted) showSnack(context, 'Meeting created');
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Attendance Meeting',
        body: ListView(padding: const EdgeInsets.all(16), children: [
          ListTile(
            title: Text('Meeting Date: ${_date(date)}'),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final picked = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: date);
              if (picked != null) setState(() => date = picked);
            },
          ),
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 10),
          TextField(controller: remarks, decoration: const InputDecoration(labelText: 'Remarks'), minLines: 2, maxLines: 3),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Create Meeting', onPressed: _create),
        ]),
      );
}

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});
  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final meetingId = TextEditingController();
  final keyword = TextEditingController();
  List members = [];
  final marked = <int, bool>{};

  Future<void> _search() async {
    final data = await ApiClient(context.read<AuthStore>()).get('/members/search', query: {'keyword': keyword.text.trim()});
    setState(() => members = data is List ? data : []);
  }

  Future<void> _save() async {
    if (meetingId.text.trim().isEmpty) return showSnack(context, 'Meeting ID is required');
    final items = marked.entries.map((e) => {'memberId': e.key, 'attended': e.value}).toList();
    if (items.isEmpty) return showSnack(context, 'Mark at least one member');
    try {
      await ApiClient(context.read<AuthStore>()).post('/attendance/mark', body: {'meetingId': int.tryParse(meetingId.text), 'attendance': items});
      if (mounted) showSnack(context, 'Attendance saved');
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Mark Attendance',
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              TextField(controller: meetingId, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Meeting ID')),
              const SizedBox(height: 10),
              Row(children: [Expanded(child: TextField(controller: keyword, decoration: const InputDecoration(labelText: 'Search members'))), IconButton.filled(onPressed: _search, icon: const Icon(Icons.search))]),
              const SizedBox(height: 8),
              PrimaryButton(label: 'Save Attendance', onPressed: _save),
            ]),
          ),
          Expanded(
            child: members.isEmpty
                ? const EmptyView('Search members to mark attendance')
                : ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (_, i) {
                      final m = members[i];
                      final id = m['id'] as int;
                      return CheckboxListTile(
                        value: marked[id] ?? false,
                        onChanged: (v) => setState(() => marked[id] = v ?? false),
                        title: Text('${m['fullName'] ?? ''}'),
                        subtitle: Text('${m['mobileNo'] ?? ''} • Family ${m['familyId'] ?? '-'}'),
                      );
                    },
                  ),
          ),
        ]),
      );
}

class ViewAttendanceScreen extends StatefulWidget {
  const ViewAttendanceScreen({super.key});
  @override
  State<ViewAttendanceScreen> createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  DateTime date = DateTime.now();
  final meetingId = TextEditingController();
  List rows = [];

  Future<void> _byDate() async {
    final data = await ApiClient(context.read<AuthStore>()).get('/attendance/by-date', query: {'date': _date(date)});
    setState(() => rows = data is List ? data : []);
  }

  Future<void> _byMeeting() async {
    if (meetingId.text.trim().isEmpty) return;
    final data = await ApiClient(context.read<AuthStore>()).get('/attendance/by-meeting/${meetingId.text.trim()}');
    setState(() => rows = data is List ? data : []);
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'View Attendance',
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                Expanded(child: Text('Date: ${_date(date)}')),
                TextButton(onPressed: () async {
                  final picked = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: date);
                  if (picked != null) setState(() => date = picked);
                }, child: const Text('Select')),
                FilledButton(onPressed: _byDate, child: const Text('Load')),
              ]),
              Row(children: [Expanded(child: TextField(controller: meetingId, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Meeting ID'))), IconButton.filled(onPressed: _byMeeting, icon: const Icon(Icons.search))]),
            ]),
          ),
          Expanded(
            child: rows.isEmpty
                ? const EmptyView('No attendance records')
                : ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (_, i) => ListTile(
                      title: Text('Member ${rows[i]['memberId']}'),
                      subtitle: Text('Family ${rows[i]['familyId'] ?? '-'} • Marked by ${rows[i]['markedBy'] ?? ''}'),
                      trailing: Icon(rows[i]['attended'] == true ? Icons.check_circle : Icons.cancel, color: rows[i]['attended'] == true ? Colors.green : Colors.red),
                    ),
                  ),
          ),
        ]),
      );
}
