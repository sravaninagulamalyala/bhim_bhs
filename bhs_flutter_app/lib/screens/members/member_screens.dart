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

  Future<void> _search() async {
    final data = await ApiClient(context.read<AuthStore>()).get('/members/search', query: {'keyword': keyword.text.trim()});
    setState(() => members = data is List ? data : []);
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Member Update',
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: TextField(controller: keyword, decoration: const InputDecoration(labelText: 'Search member'))),
              IconButton.filled(onPressed: _search, icon: const Icon(Icons.search)),
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

  Future<void> _searchMembers() async {
    final data = await ApiClient(context.read<AuthStore>()).get('/members/search', query: {'keyword': memberKeyword.text.trim()});
    setState(() => members = data is List ? data : []);
  }

  Future<void> _searchFamilies() async {
    final data = await ApiClient(context.read<AuthStore>()).get('/members/search', query: {'keyword': familyKeyword.text.trim()});
    setState(() => familyCandidates = data is List ? data.where((e) => e['familyId'] != null).toList() : []);
  }

  Future<void> _map() async {
    if (member == null || familySource == null) return showSnack(context, 'Select member and family');
    try {
      await ApiClient(context.read<AuthStore>()).post('/members/map-family', body: {'memberId': member!['id'], 'familyId': familySource!['familyId']});
      if (mounted) showSnack(context, 'Family mapped');
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Family Mapping',
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [Expanded(child: TextField(controller: memberKeyword, decoration: const InputDecoration(labelText: 'Search member'))), IconButton.filled(onPressed: _searchMembers, icon: const Icon(Icons.search))]),
          for (final m in members.take(4)) RadioListTile<Map<String, dynamic>>(value: Map<String, dynamic>.from(m), groupValue: member, title: Text('${m['fullName']}'), subtitle: Text('Current family: ${m['familyId'] ?? '-'}'), onChanged: (v) => setState(() => member = v)),
          const Divider(),
          Row(children: [Expanded(child: TextField(controller: familyKeyword, decoration: const InputDecoration(labelText: 'Search/select family by member/house'))), IconButton.filled(onPressed: _searchFamilies, icon: const Icon(Icons.search))]),
          for (final f in familyCandidates.take(4)) RadioListTile<Map<String, dynamic>>(value: Map<String, dynamic>.from(f), groupValue: familySource, title: Text('Family ${f['familyId']} • ${f['houseNo'] ?? ''}'), subtitle: Text('${f['fullName'] ?? ''}'), onChanged: (v) => setState(() => familySource = v)),
          PrimaryButton(label: 'Map Member to Family', onPressed: _map),
        ]),
      );
}
