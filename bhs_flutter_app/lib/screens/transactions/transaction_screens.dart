import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/auth_store.dart';
import '../../core/widgets/common_widgets.dart';

String _ym(DateTime d) => DateFormat('yyyy-MM').format(d);
String _date(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

class TransactionEntryScreen extends StatefulWidget {
  const TransactionEntryScreen({super.key});
  @override
  State<TransactionEntryScreen> createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends State<TransactionEntryScreen> {
  DateTime date = DateTime.now();
  String type = 'CREDIT';
  final keyword = TextEditingController();
  final amount = TextEditingController();
  final remarks = TextEditingController();
  List members = [];
  Map<String, dynamic>? selected;

  Future<void> _search() async {
    final data = await ApiClient(context.read<AuthStore>()).get('/members/search', query: {'keyword': keyword.text.trim()});
    setState(() => members = data is List ? data : []);
  }

  Future<void> _save() async {
    if (amount.text.trim().isEmpty) return showSnack(context, 'Amount is required');
    try {
      await ApiClient(context.read<AuthStore>()).post('/transactions', body: {
        'transactionDate': _date(date),
        'transactionType': type,
        'familyId': type == 'CREDIT' && selected != null ? selected!['familyId'] : null,
        'memberId': type == 'CREDIT' && selected != null ? selected!['id'] : null,
        'amount': num.tryParse(amount.text.trim()),
        'remarks': remarks.text.trim(),
      });
      if (mounted) showSnack(context, 'Transaction saved');
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Transaction Entry',
        body: ListView(padding: const EdgeInsets.all(16), children: [
          ListTile(
            title: Text('Transaction Date: ${_date(date)}'),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final picked = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: date);
              if (picked != null) setState(() => date = picked);
            },
          ),
          DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'Transaction Type'), items: const ['CREDIT', 'DEBIT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => type = v ?? 'CREDIT')),
          if (type == 'CREDIT') ...[
            const SizedBox(height: 10),
            Row(children: [Expanded(child: TextField(controller: keyword, decoration: const InputDecoration(labelText: 'Search family/member'))), IconButton.filled(onPressed: _search, icon: const Icon(Icons.search))]),
            for (final m in members.take(4)) RadioListTile<Map<String, dynamic>>(value: Map<String, dynamic>.from(m), groupValue: selected, title: Text('${m['fullName']}'), subtitle: Text('Family ${m['familyId'] ?? '-'}'), onChanged: (v) => setState(() => selected = v)),
          ],
          const SizedBox(height: 10),
          TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount')),
          const SizedBox(height: 10),
          TextField(controller: remarks, decoration: const InputDecoration(labelText: 'Remarks'), minLines: 2, maxLines: 3),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Save Transaction', onPressed: _save),
        ]),
      );
}

class TransactionViewScreen extends StatefulWidget {
  const TransactionViewScreen({super.key});
  @override
  State<TransactionViewScreen> createState() => _TransactionViewScreenState();
}

class _TransactionViewScreenState extends State<TransactionViewScreen> {
  DateTime month = DateTime.now();
  List rows = [];
  Map balance = {};
  Map summary = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = ApiClient(context.read<AuthStore>());
    try {
      final r = await api.get('/transactions');
      final b = await api.get('/transactions/balance');
      final s = await api.get('/transactions/monthly-summary', query: {'month': _ym(month)});
      setState(() {
        rows = r is List ? r : [];
        balance = b is Map ? b : {};
        summary = s is Map ? s : {};
      });
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Transactions View',
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [Expanded(child: Text('Month: ${_ym(month)}')), FilledButton(onPressed: _load, child: const Text('Refresh'))]),
              Row(children: [
                Expanded(child: _tile('Credit', '${summary['totalCredit'] ?? balance['totalCredit'] ?? 0}')),
                Expanded(child: _tile('Debit', '${summary['totalDebit'] ?? balance['totalDebit'] ?? 0}')),
                Expanded(child: _tile('Balance', '${summary['balance'] ?? balance['balance'] ?? 0}')),
              ]),
            ]),
          ),
          Expanded(
            child: rows.isEmpty
                ? const EmptyView('No transactions found')
                : ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (_, i) => ListTile(
                      title: Text('${rows[i]['transactionType']} • ₹${rows[i]['amount']}'),
                      subtitle: Text('${rows[i]['transactionDate']} • ${rows[i]['remarks'] ?? ''}'),
                    ),
                  ),
          ),
        ]),
      );

  Widget _tile(String label, String value) => Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [Text(value, style: const TextStyle(fontWeight: FontWeight.bold)), Text(label)])));
}
