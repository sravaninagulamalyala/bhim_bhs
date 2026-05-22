import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/auth_store.dart';
import '../../core/utils/loading_helper.dart';
import '../../core/widgets/common_widgets.dart';

String _date(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
String _month(DateTime d) => DateFormat('yyyy-MM').format(d);
DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

class AttendanceMeetingScreen extends StatefulWidget {
  const AttendanceMeetingScreen({super.key});
  @override
  State<AttendanceMeetingScreen> createState() => _AttendanceMeetingScreenState();
}

class _AttendanceMeetingScreenState extends State<AttendanceMeetingScreen> {
  DateTime date = DateTime.now();
  final title = TextEditingController(text: 'Monthly Meeting');
  final remarks = TextEditingController(text: 'General meeting');
  bool loading = false;

  Future<void> _create() async {
    if (title.text.trim().isEmpty) return showSnack(context, 'Meeting title is required');
    setState(() => loading = true);
    LoadingHelper.show(context);
    try {
      await ApiClient(context.read<AuthStore>()).post('/attendance/meeting', body: {'meetingDate': _date(date), 'title': title.text.trim(), 'remarks': remarks.text.trim()});
      if (mounted) showSnack(context, 'Meeting created');
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
      if (mounted) setState(() => loading = false);
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
          PrimaryButton(label: 'Create Meeting', loading: loading, onPressed: _create),
        ]),
      );
}

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});
  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final keyword = TextEditingController();
  DateTime selectedDate = DateTime.now();
  Map<String, dynamic>? meeting;
  List members = [];
  final marked = <int, bool>{};
  bool checkingMeeting = false;
  bool creatingMeeting = false;
  bool searching = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMeeting());
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: selectedDate);
    if (picked == null) return;
    setState(() {
      selectedDate = picked;
      meeting = null;
      members = [];
      marked.clear();
    });
    await _loadMeeting();
  }

  Future<void> _loadMeeting() async {
    setState(() => checkingMeeting = true);
    LoadingHelper.show(context);
    try {
      final data = await ApiClient(context.read<AuthStore>()).get('/attendance/meeting-by-date', query: {'date': _date(selectedDate)});
      setState(() => meeting = data is Map ? Map<String, dynamic>.from(data) : null);
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
      if (mounted) setState(() => checkingMeeting = false);
    }
  }

  Future<void> _createMeeting() async {
    setState(() => creatingMeeting = true);
    LoadingHelper.show(context);
    try {
      final data = await ApiClient(context.read<AuthStore>()).post('/attendance/meeting', body: {'meetingDate': _date(selectedDate), 'title': 'Monthly Meeting', 'remarks': 'General meeting'});
      setState(() => meeting = _meetingMap(data));
      if (mounted) showSnack(context, 'Meeting ready for selected date');
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
      if (mounted) setState(() => creatingMeeting = false);
    }
  }

  Future<void> _search() async {
    if (meeting == null) return showSnack(context, 'Create or load a meeting first');
    setState(() => searching = true);
    LoadingHelper.show(context);
    try {
      final data = await ApiClient(context.read<AuthStore>()).get('/search/members', query: {'keyword': keyword.text.trim()});
      setState(() => members = data is List ? data : []);
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
      if (mounted) setState(() => searching = false);
    }
  }

  Future<void> _save() async {
    final meetingId = _meetingId(meeting);
    if (meetingId == null) return showSnack(context, 'Create or load a meeting first');
    final items = marked.entries.map((e) => {'memberId': e.key, 'attended': e.value}).toList();
    if (items.isEmpty) return showSnack(context, 'Mark at least one member');
    setState(() => saving = true);
    LoadingHelper.show(context);
    try {
      await ApiClient(context.read<AuthStore>()).post('/attendance/mark', body: {'meetingId': meetingId, 'attendanceList': items});
      if (mounted) showSnack(context, 'Attendance saved');
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Mark Attendance',
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Selected Date: ${_date(selectedDate)}'),
                trailing: const Icon(Icons.calendar_month),
                onTap: _pickDate,
              ),
              if (!checkingMeeting && meeting == null) ...[
                const SizedBox(height: 8),
                PrimaryButton(label: 'Create Meeting for Selected Date', loading: creatingMeeting, onPressed: _createMeeting),
              ],
              if (meeting != null) ...[
                Text('${meeting?['title'] ?? 'Meeting'} • ${meeting?['remarks'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(controller: keyword, decoration: const InputDecoration(labelText: 'Search members'))),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: searching ? null : _search, icon: const Icon(Icons.search)),
                ]),
                const SizedBox(height: 8),
                PrimaryButton(label: 'Save Attendance', loading: saving, onPressed: _save),
              ],
            ]),
          ),
          Expanded(
            child: meeting == null
                ? const EmptyView('Select a date and create a meeting to mark attendance')
                : members.isEmpty
                    ? const EmptyView('Search members to mark attendance')
                    : ListView.builder(
                        itemCount: members.length,
                        itemBuilder: (_, i) {
                          final m = Map<String, dynamic>.from(members[i]);
                          final id = (m['id'] as num).toInt();
                          return CheckboxListTile(
                            value: marked[id] ?? false,
                            onChanged: (v) => setState(() => marked[id] = v ?? false),
                            title: Text('${m['fullName'] ?? ''}'),
                            subtitle: Text('${m['mobileNo'] ?? ''} • Family ${m['familyId'] ?? '-'} • ${m['houseNo'] ?? ''}'),
                          );
                        },
                      ),
          ),
        ]),
      );

  Map<String, dynamic>? _meetingMap(dynamic value) {
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);
    return {
      'meetingId': map['meetingId'] ?? map['id'],
      'meetingDate': map['meetingDate'],
      'title': map['title'],
      'remarks': map['remarks'],
    };
  }

  int? _meetingId(Map<String, dynamic>? value) {
    final id = value == null ? null : value['meetingId'] ?? value['id'];
    return id is num ? id.toInt() : int.tryParse('$id');
  }
}

class ViewAttendanceScreen extends StatefulWidget {
  const ViewAttendanceScreen({super.key});
  @override
  State<ViewAttendanceScreen> createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  final meetingsByDate = <DateTime, Map<String, dynamic>>{};
  Map<String, dynamic>? attendance;
  bool loadingDates = false;
  bool loadingDetails = false;

  @override
  void initState() {
    super.initState();
    selectedDay = _day(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMeetingDates(focusedDay));
  }

  Future<void> _loadMeetingDates(DateTime month) async {
    setState(() => loadingDates = true);
    LoadingHelper.show(context);
    try {
      final data = await ApiClient(context.read<AuthStore>()).get('/attendance/meeting-dates', query: {'month': _month(month)});
      final next = <DateTime, Map<String, dynamic>>{};
      if (data is List) {
        for (final item in data) {
          final map = Map<String, dynamic>.from(item);
          final date = DateTime.tryParse('${map['meetingDate']}');
          if (date != null) next[_day(date)] = map;
        }
      }
      setState(() {
        meetingsByDate
          ..clear()
          ..addAll(next);
      });
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
      if (mounted) setState(() => loadingDates = false);
    }
  }

  Future<void> _loadAttendance(DateTime date) async {
    if (!meetingsByDate.containsKey(_day(date))) {
      setState(() => attendance = null);
      return;
    }
    setState(() => loadingDetails = true);
    LoadingHelper.show(context);
    try {
      final data = await ApiClient(context.read<AuthStore>()).get('/attendance/by-date', query: {'date': _date(date)});
      setState(() => attendance = data is Map ? Map<String, dynamic>.from(data) : null);
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
      if (mounted) setState(() => loadingDetails = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedSummary = selectedDay == null ? null : meetingsByDate[_day(selectedDay!)];
    final present = attendance?['presentMembers'] is List ? attendance!['presentMembers'] as List : const [];
    final absent = attendance?['absentMembers'] is List ? attendance!['absentMembers'] as List : const [];
    return AppScaffold(
      title: 'View Attendance',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TableCalendar(
          firstDay: DateTime(2020),
          lastDay: DateTime(2100),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          eventLoader: (day) => meetingsByDate.containsKey(_day(day)) ? const ['meeting'] : const [],
          onDaySelected: (selected, focused) {
            setState(() {
              selectedDay = _day(selected);
              focusedDay = focused;
            });
            _loadAttendance(selected);
          },
          onPageChanged: (focused) {
            focusedDay = focused;
            _loadMeetingDates(focused);
          },
          calendarStyle: const CalendarStyle(markerDecoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focused) => meetingsByDate.containsKey(_day(day)) ? _greenDay(day) : null,
            todayBuilder: (context, day, focused) => meetingsByDate.containsKey(_day(day)) ? _greenDay(day, outlined: true) : null,
          ),
        ),
        const SizedBox(height: 16),
        if (selectedSummary != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _metric('Meeting Date', '${selectedSummary['meetingDate'] ?? ''}'),
                _metric('Present Count', '${selectedSummary['presentCount'] ?? present.length}'),
                _metric('Total Marked', '${selectedSummary['totalMarkedCount'] ?? (present.length + absent.length)}'),
              ]),
            ),
          ),
        if (!loadingDetails && selectedSummary == null) const EmptyView('Select a green date to view attendance'),
        if (!loadingDetails && attendance != null) ...[
          const SizedBox(height: 8),
          Text('Present Members', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (present.isEmpty) const Text('No present members marked'),
          for (final member in present) _AttendanceMemberTile(member: Map<String, dynamic>.from(member), present: true),
          if (absent.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Absent / Not Marked', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final member in absent) _AttendanceMemberTile(member: Map<String, dynamic>.from(member), present: false),
          ],
        ],
      ]),
    );
  }

  Widget _greenDay(DateTime day, {bool outlined = false}) => Container(
        margin: const EdgeInsets.all(6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: outlined ? Colors.white : Colors.green,
          border: outlined ? Border.all(color: Colors.green, width: 2) : null,
          shape: BoxShape.circle,
        ),
        child: Text('${day.day}', style: TextStyle(color: outlined ? Colors.green : Colors.white, fontWeight: FontWeight.w700)),
      );

  Widget _metric(String label, String value) => Expanded(
        child: Column(children: [
          Text(value, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ]),
      );
}

class _AttendanceMemberTile extends StatelessWidget {
  const _AttendanceMemberTile({required this.member, required this.present});
  final Map<String, dynamic> member;
  final bool present;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(present ? Icons.check_circle : Icons.cancel, color: present ? Colors.green : Colors.red),
          title: Text('${member['fullName'] ?? 'Member ${member['memberId'] ?? ''}'}'),
          subtitle: Text('${member['mobileNo'] ?? ''} • Family ${member['familyCode'] ?? member['familyId'] ?? '-'} • ${member['houseNo'] ?? ''}'),
        ),
      );
}
