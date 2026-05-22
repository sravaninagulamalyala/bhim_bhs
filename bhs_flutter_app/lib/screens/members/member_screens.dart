import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../core/network/api_client.dart';
import '../../core/storage/auth_store.dart';
import '../../core/utils/loading_helper.dart';
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
    LoadingHelper.show(context);
    try {
      await ApiClient(context.read<AuthStore>()).multipart('/admin/members/upload-excel', file!, 'file');
      if (mounted) showSnack(context, 'Excel uploaded successfully');
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
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
    LoadingHelper.show(context);
    try {
      final data = await ApiClient(context.read<AuthStore>()).get('/members/search', query: {'keyword': keyword.text.trim()});
      setState(() => members = data is List ? data : []);
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
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
              IconButton.filled(onPressed: loading ? null : _search, icon: const Icon(Icons.search)),
            ]),
          ),
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
      for (final k in ['firstName', 'lastName', 'fullName', 'fatherOrHusbandName', 'age', 'sex', 'mobileNo', 'alternateMobileNo', 'address', 'houseNo', 'area'])
        k: TextEditingController(text: '${widget.member[k] ?? ''}')
    };
    active = widget.member['active'] != false;
  }

  Future<void> _save() async {
    setState(() => loading = true);
    LoadingHelper.show(context);
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
      if (mounted) LoadingHelper.hide(context);
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
    LoadingHelper.show(context);
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
      if (mounted) LoadingHelper.hide(context);
      if (mounted) setState(() => searchingMembers = false);
    }
  }

  Future<void> _searchFamilies() async {
    setState(() => searchingFamilies = true);
    LoadingHelper.show(context);
    try {
      final data = await ApiClient(context.read<AuthStore>()).get('/families/search', query: {'keyword': familyKeyword.text.trim()});
      setState(() {
        familyCandidates = data is List ? data : [];
        if (familyId != null && !familyCandidates.any((f) => _familyId(f) == familyId)) {
          familySource = null;
          familyId = null;
        }
      });
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
      if (mounted) setState(() => searchingFamilies = false);
    }
  }

  Future<void> _map() async {
    if (memberId == null || familyId == null) return showSnack(context, 'Select member and family');
    final api = ApiClient(context.read<AuthStore>());
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm family mapping'),
        content: const Text('Do you want to map this member to this family?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Map')),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    setState(() => loading = true);
    LoadingHelper.show(context);
    try {
      await api.post('/members/map-family', body: {'memberId': memberId, 'familyId': familyId});
      if (mounted) showSnack(context, 'Family mapped');
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) LoadingHelper.hide(context);
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _selectFamily(Map<String, dynamic> family) async {
    setState(() {
      familyId = _familyId(family);
      familySource = family;
    });
    await _map();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Family Mapping',
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [Expanded(child: TextField(controller: memberKeyword, decoration: const InputDecoration(labelText: 'Search member by name / mobile / house'))), IconButton.filled(onPressed: searchingMembers ? null : _searchMembers, icon: const Icon(Icons.search))]),
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
          if (member != null)
            Card(
              child: ListTile(
                title: Text('${member?['fullName'] ?? ''}'),
                subtitle: Text('Mobile: ${member?['mobileNo'] ?? ''} • House: ${member?['houseNo'] ?? ''} • Current family: ${member?['familyId'] ?? '-'}'),
              ),
            ),
          const Divider(),
          const Text('Search Family / Family Members to Map', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [Expanded(child: TextField(controller: familyKeyword, decoration: const InputDecoration(labelText: 'Family code / house / head / member / mobile'))), IconButton.filled(onPressed: searchingFamilies ? null : _searchFamilies, icon: const Icon(Icons.search))]),
          for (final f in familyCandidates)
            if (_familyId(f) != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${f['familyCode'] ?? 'Family ${f['familyId']}'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Head: ${f['familyHeadName'] ?? ''}'),
                    Text('House: ${f['houseNo'] ?? ''} • Area: ${f['area'] ?? ''}'),
                    Text('Total Members: ${f['totalMembers'] ?? 0}'),
                    Text('Members: ${_names(f['memberNames'])}'),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: loading ? null : () => _selectFamily(Map<String, dynamic>.from(f)),
                        child: const Text('Select Family'),
                      ),
                    ),
                  ]),
                ),
              ),
          if (familySource != null) Text('Selected family: ${familySource?['familyCode'] ?? familySource?['familyId'] ?? ''}'),
          PrimaryButton(label: 'Map Member to Family', loading: loading, onPressed: _map),
        ]),
      );

  int? _id(dynamic value) => value is Map && value['id'] is num ? (value['id'] as num).toInt() : null;
  int? _familyId(dynamic value) => value is Map && value['familyId'] is num ? (value['familyId'] as num).toInt() : null;
  String _names(dynamic value) => value is List ? value.join(', ') : '';
}
