import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../core/network/api_client.dart';
import '../../core/storage/auth_store.dart';
import '../../core/widgets/common_widgets.dart';

class ExcelUploadScreen extends StatefulWidget {
  const ExcelUploadScreen({super.key});
  @override
  State<ExcelUploadScreen> createState() => _ExcelUploadScreenState();
}

class _ExcelUploadScreenState extends State<ExcelUploadScreen> {
  File? file;
  bool loading = false;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls']);
    if (result?.files.single.path != null) setState(() => file = File(result!.files.single.path!));
  }

  Future<void> _upload() async {
    if (file == null) return showSnack(context, 'Choose Excel file first');
    setState(() => loading = true);
    try {
      await ApiClient(context.read<AuthStore>()).multipart('/admin/members/upload-excel', file!, 'file');
      if (mounted) showSnack(context, 'Excel uploaded successfully');
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Excel Upload',
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            OutlinedButton.icon(onPressed: _pick, icon: const Icon(Icons.attach_file), label: Text(file?.path.split(Platform.pathSeparator).last ?? 'Choose Excel File')),
            const SizedBox(height: 12),
            PrimaryButton(label: 'Upload', loading: loading, onPressed: _upload),
          ]),
        ),
      );
}

class MemberUpdateScreen extends StatefulWidget {
  const MemberUpdateScreen({super.key});
  @override
  State<MemberUpdateScreen> createState() => _MemberUpdateScreenState();
}

class _MemberUpdateScreenState extends State<MemberUpdateScreen> {
  final keyword = TextEditingController();
  List members = [];
  bool loading = false;

  Future<void> _search() async {
    setState(() => loading = true);
    try {
      final data = await ApiClient(context.read<AuthStore>()).get('/members/search', query: {'keyword': keyword.text.trim()});
      setState(() => members = data is List ? data : []);
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Member Update',
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: TextField(controller: keyword, decoration: const InputDecoration(labelText: 'Search member'))),
              IconButton.filled(onPressed: loading ? null : _search, icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search)),
            ]),
          ),
          if (loading) const LinearProgressIndicator(),
          Expanded(
            child: members.isEmpty
                ? const EmptyView('Search and select a member')
                : ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (_, i) => ListTile(
                      title: Text('${members[i]['fullName'] ?? ''}'),
                      subtitle: Text('${members[i]['mobileNo'] ?? ''} • ${members[i]['houseNo'] ?? ''}'),
                      trailing: const Icon(Icons.edit),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MemberEditScreen(member: Map<String, dynamic>.from(members[i])))).then((_) => _search()),
                    ),
                  ),
          ),
        ]),
      );
}

class MemberEditScreen extends StatefulWidget {
  const MemberEditScreen({super.key, required this.member});
  final Map<String, dynamic> member;
  @override
  State<MemberEditScreen> createState() => _MemberEditScreenState();
}

class _MemberEditScreenState extends State<MemberEditScreen> {
  late final Map<String, TextEditingController> c;
  late bool active;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    c = {
      for (final k in ['firstName', 'lastName', 'fatherOrHusbandName', 'age', 'sex', 'mobileNo', 'alternateMobileNo', 'address', 'houseNo', 'area'])
        k: TextEditingController(text: '${widget.member[k] ?? ''}')
    };
    active = widget.member['active'] != false;
  }

  Future<void> _save() async {
    setState(() => loading = true);
    final body = {for (final e in c.entries) e.key: e.key == 'age' ? int.tryParse(e.value.text) : e.value.text.trim(), 'active': active};
    try {
      await ApiClient(context.read<AuthStore>()).put('/members/${widget.member['id']}', body: body);
      if (mounted) {
        showSnack(context, 'Member updated');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Edit Member',
        body: ListView(padding: const EdgeInsets.all(16), children: [
          for (final e in c.entries) ...[
            TextField(controller: e.value, decoration: InputDecoration(labelText: _label(e.key)), keyboardType: e.key == 'age' ? TextInputType.number : TextInputType.text),
            const SizedBox(height: 10),
          ],
          SwitchListTile(value: active, onChanged: (v) => setState(() => active = v), title: const Text('Active')),
          PrimaryButton(label: 'Save Changes', loading: loading, onPressed: _save),
        ]),
      );

  String _label(String key) => key.replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}').trim();
}

class FamilyMappingScreen extends StatefulWidget {
  const FamilyMappingScreen({super.key});
  @override
  State<FamilyMappingScreen> createState() => _FamilyMappingScreenState();
}

class _FamilyMappingScreenState extends State<FamilyMappingScreen> {
  final memberKeyword = TextEditingController();
  final familyKeyword = TextEditingController();
  List members = [];
  List familyCandidates = [];
  Map<String, dynamic>? member;
  Map<String, dynamic>? familySource;
  int? memberId;
  int? familyId;
  bool searchingMembers = false;
  bool searchingFamilies = false;
  bool loading = false;

  Future<void> _searchMembers() async {
    setState(() => searchingMembers = true);
    try {
      final data = await ApiClient(context.read<AuthStore>()).get('/members/search', query: {'keyword': memberKeyword.text.trim()});
      setState(() {
        members = data is List ? data : [];
        if (memberId != null && !members.any((m) => _id(m) == memberId)) {
          member = null;
          memberId = null;
        }
      });
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) setState(() => searchingMembers = false);
    }
  }

  Future<void> _searchFamilies() async {
    setState(() => searchingFamilies = true);
    try {
      final data = await ApiClient(context.read<AuthStore>()).get('/members/search', query: {'keyword': familyKeyword.text.trim()});
      setState(() {
        familyCandidates = data is List ? data.where((e) => e['familyId'] != null).toList() : [];
        if (familyId != null && !familyCandidates.any((f) => _familyId(f) == familyId)) {
          familySource = null;
          familyId = null;
        }
      });
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) setState(() => searchingFamilies = false);
    }
  }

  Future<void> _map() async {
    if (memberId == null || familyId == null) return showSnack(context, 'Select member and family');
    setState(() => loading = true);
    try {
      await ApiClient(context.read<AuthStore>()).post('/members/map-family', body: {'memberId': memberId, 'familyId': familyId});
      if (mounted) showSnack(context, 'Family mapped');
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Family Mapping',
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [Expanded(child: TextField(controller: memberKeyword, decoration: const InputDecoration(labelText: 'Search member'))), IconButton.filled(onPressed: searchingMembers ? null : _searchMembers, icon: searchingMembers ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search))]),
          if (searchingMembers) const LinearProgressIndicator(),
          for (final m in members.take(4))
            if (_id(m) != null)
              RadioListTile<int>(
                value: _id(m)!,
                groupValue: memberId,
                title: Text('${m['fullName']}'),
                subtitle: Text('Current family: ${m['familyId'] ?? '-'}'),
                onChanged: (v) => setState(() {
                  memberId = v;
                  member = Map<String, dynamic>.from(m);
                }),
              ),
          const Divider(),
          Row(children: [Expanded(child: TextField(controller: familyKeyword, decoration: const InputDecoration(labelText: 'Search/select family by member/house'))), IconButton.filled(onPressed: searchingFamilies ? null : _searchFamilies, icon: searchingFamilies ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search))]),
          if (searchingFamilies) const LinearProgressIndicator(),
          for (final f in familyCandidates.take(4))
            if (_familyId(f) != null)
              RadioListTile<int>(
                value: _familyId(f)!,
                groupValue: familyId,
                title: Text('Family ${f['familyId']} • ${f['houseNo'] ?? ''}'),
                subtitle: Text('${f['fullName'] ?? ''}'),
                onChanged: (v) => setState(() {
                  familyId = v;
                  familySource = Map<String, dynamic>.from(f);
                }),
              ),
          if (member != null) Text('Selected member: ${member?['fullName'] ?? ''}'),
          if (familySource != null) Text('Selected family: ${familySource?['familyId'] ?? ''}'),
          PrimaryButton(label: 'Map Member to Family', loading: loading, onPressed: _map),
        ]),
      );

  int? _id(dynamic value) => value is Map && value['id'] is num ? (value['id'] as num).toInt() : null;
  int? _familyId(dynamic value) => value is Map && value['familyId'] is num ? (value['familyId'] as num).toInt() : null;
}
