import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/auth_store.dart';
import '../../core/widgets/common_widgets.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final search = TextEditingController();
  final adminId = TextEditingController();
  final password = TextEditingController();
  List members = [];
  List staff = [];
  Map<String, dynamic>? selectedMember;
  String role = 'STAFF';
  bool active = true;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  ApiClient get api => ApiClient(context.read<AuthStore>());

  Future<void> _memberSearch() async {
    final data = await api.get('/members/search', query: {'keyword': search.text.trim()});
    setState(() => members = data is List ? data : []);
  }

  Future<void> _loadStaff() async {
    try {
      final data = await api.get('/admin/staff');
      setState(() => staff = data is List ? data : []);
    } catch (_) {}
  }

  Future<void> _create() async {
    if (adminId.text.trim().isEmpty || password.text.isEmpty) {
      showSnack(context, 'Admin ID and password are required');
      return;
    }
    setState(() => loading = true);
    try {
      await api.post('/admin/staff/create', body: {
        'memberId': selectedMember?['id'],
        'adminId': adminId.text.trim(),
        'password': password.text,
        'role': role,
        'active': active,
      });
      adminId.clear();
      password.clear();
      await _loadStaff();
      if (mounted) showSnack(context, 'Staff created');
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Staff Management',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(child: TextField(controller: search, decoration: const InputDecoration(labelText: 'Search member by name/mobile'))),
          IconButton.filled(onPressed: _memberSearch, icon: const Icon(Icons.search)),
        ]),
        for (final m in members.take(5))
          RadioListTile<Map<String, dynamic>>(
            value: Map<String, dynamic>.from(m),
            groupValue: selectedMember,
            title: Text('${m['fullName'] ?? ''}'),
            subtitle: Text('ID: ${m['id']} • ${m['mobileNo'] ?? ''}'),
            onChanged: (v) => setState(() => selectedMember = v),
          ),
        const SizedBox(height: 12),
        TextFormField(readOnly: true, decoration: InputDecoration(labelText: 'Member ID', hintText: '${selectedMember?['id'] ?? ''}')),
        const SizedBox(height: 10),
        TextField(controller: adminId, decoration: const InputDecoration(labelText: 'Admin ID')),
        const SizedBox(height: 10),
        TextField(controller: password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: role,
          decoration: const InputDecoration(labelText: 'Role'),
          items: const ['SUPER_ADMIN', 'PRESIDENT', 'VICE_PRESIDENT', 'GENERAL_SECRETARY', 'JOINT_SECRETARY', 'ORG_SECRETARY', 'TREASURER', 'SECRETARY', 'STAFF', 'MEMBER']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => role = v ?? 'STAFF'),
        ),
        SwitchListTile(value: active, onChanged: (v) => setState(() => active = v), title: const Text('Active')),
        PrimaryButton(label: 'Create Staff Login', loading: loading, onPressed: _create),
        const Divider(),
        const Text('Existing staff', style: TextStyle(fontWeight: FontWeight.bold)),
        for (final s in staff) ListTile(title: Text('${s['adminId'] ?? ''}'), subtitle: Text('${s['role'] ?? ''} • Active: ${s['active'] ?? ''}')),
      ]),
    );
  }
}
