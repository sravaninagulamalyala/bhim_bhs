import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/auth_store.dart';
import '../../core/widgets/common_widgets.dart';

String _ym(DateTime d) => DateFormat('yyyy-MM').format(d);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime month = DateTime.now();
  Map counts = {};
  Map contribution = {};
  Map heatmap = {};
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final api = ApiClient(context.read<AuthStore>());
    try {
      final c = await api.get('/reports/family-member-count');
      final m = await api.get('/reports/monthly-contribution', query: {'month': _ym(month)});
      final h = await api.get('/reports/heatmap', query: {'month': _ym(month)});
      setState(() {
        counts = c is Map ? c : {};
        contribution = m is Map ? m : {};
        heatmap = h is Map ? h : {};
      });
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _download(String type) async {
    try {
      final bytes = await ApiClient(context.read<AuthStore>()).download('/reports/download', query: {'type': type, 'month': _ym(month)});
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/bhs_${type.toLowerCase()}_${_ym(month)}.xlsx');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Reports',
        body: loading
            ? const LoadingView()
            : ListView(padding: const EdgeInsets.all(16), children: [
                Row(children: [Expanded(child: Text('Month: ${_ym(month)}')), FilledButton(onPressed: _load, child: const Text('Refresh'))]),
                Row(children: [
                  Expanded(child: _reportCard('Total Families', '${counts['activeFamilyCount'] ?? 0}')),
                  Expanded(child: _reportCard('Total Members', '${counts['activeMemberCount'] ?? 0}')),
                ]),
                _reportCard('Monthly Contribution', '${contribution['totalContribution'] ?? 0}'),
                _reportCard('Heatmap Days', '${(heatmap['dailyCredits'] is Map) ? (heatmap['dailyCredits'] as Map).length : 0}'),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: () => _download('CONTRIBUTED'), child: const Text('Download Contributed Family List')),
                OutlinedButton(onPressed: () => _download('NON_CONTRIBUTED'), child: const Text('Download Non-Contributed Family List')),
                OutlinedButton(onPressed: () => _download('ALL'), child: const Text('Download All Family List')),
              ]),
      );

  Widget _reportCard(String title, String value) => Card(
        child: Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))])),
      );
}

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});
  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  DateTime month = DateTime.now();
  Map daily = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final data = await ApiClient(context.read<AuthStore>()).get('/reports/heatmap', query: {'month': _ym(month)});
      final d = data is Map && data['dailyCredits'] is Map ? data['dailyCredits'] as Map : {};
      setState(() => daily = d);
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    return AppScaffold(
      title: 'Heatmap View',
      body: loading
          ? const LoadingView()
          : ListView(padding: const EdgeInsets.all(16), children: [
              Row(children: [Expanded(child: Text('Month: ${_ym(month)}')), FilledButton(onPressed: _load, child: const Text('Refresh'))]),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 6, mainAxisSpacing: 6),
                itemCount: days,
                itemBuilder: (_, i) {
                  final day = i + 1;
                  final contributed = daily.containsKey('$day') || daily.containsKey(day);
                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: contributed ? Colors.green : Colors.red.shade300, borderRadius: BorderRadius.circular(6)),
                    child: Text('$day', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Row(children: [_Legend(Colors.green, 'Contributed'), SizedBox(width: 12), _Legend(Colors.red, 'Not contributed'), SizedBox(width: 12), _Legend(Colors.grey, 'Inactive/no data')]),
            ]),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.text);
  final Color color;
  final String text;
  @override
  Widget build(BuildContext context) => Row(children: [Container(width: 14, height: 14, color: color), const SizedBox(width: 4), Text(text)]);
}
