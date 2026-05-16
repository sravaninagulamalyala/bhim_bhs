import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/auth_store.dart';
import '../../core/widgets/common_widgets.dart';

class MemberFamilySearchScreen extends StatefulWidget {
  const MemberFamilySearchScreen({super.key});

  @override
  State<MemberFamilySearchScreen> createState() => _MemberFamilySearchScreenState();
}

class _MemberFamilySearchScreenState extends State<MemberFamilySearchScreen> {
  final keyword = TextEditingController();
  List items = [];
  bool loading = false;

  Future<void> _search() async {
    setState(() => loading = true);
    try {
      final data = await ApiClient(context.read<AuthStore>()).get('/search/member-family', query: {'keyword': keyword.text.trim()});
      setState(() => items = data is List ? data : []);
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Member Family Search',
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: TextField(controller: keyword, decoration: const InputDecoration(labelText: 'Name / mobile / house number'))),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: _search, icon: const Icon(Icons.search)),
          ]),
        ),
        if (loading) const LinearProgressIndicator(),
        Expanded(
          child: items.isEmpty
              ? const EmptyView('Search members to view family details')
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final row = Map<String, dynamic>.from(items[i]);
                    final member = Map<String, dynamic>.from(row['member'] ?? {});
                    final family = row['familyMembers'] is List ? row['familyMembers'] as List : [];
                    return _MemberCard(member: member, family: family);
                  },
                ),
        ),
      ]),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.family});
  final Map<String, dynamic> member;
  final List family;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${member['fullName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          _line('Father/Husband', member['fatherOrHusbandName']),
          _line('Age / Sex', '${member['age'] ?? ''} / ${member['sex'] ?? ''}'),
          _line('Mobile', member['mobileNo']),
          _line('House No', member['houseNo']),
          _line('Area', member['area']),
          _line('Family Code', member['familyId']),
          if (family.isNotEmpty) const Divider(),
          for (final f in family.take(5)) Text('• ${f['fullName'] ?? ''} (${f['mobileNo'] ?? ''})'),
        ]),
      ),
    );
  }

  Widget _line(String label, Object? value) => Padding(padding: const EdgeInsets.only(top: 4), child: Text('$label: ${value ?? ''}'));
}
