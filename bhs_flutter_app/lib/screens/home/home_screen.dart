import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/auth_store.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import '../member_registration/member_registration_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> home = {};
  Map<String, dynamic> counts = {};
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = ApiClient(context.read<AuthStore>());
    try {
      final h = await api.get('/public/home-content');
      final c = await api.get('/public/counts');
      setState(() {
        home = h is Map ? Map<String, dynamic>.from(h) : {};
        counts = c is Map ? Map<String, dynamic>.from(c) : {};
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = '$e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = home['associationTitle'] ?? ApiConstants.associationName;
    final address = home['address'] ?? ApiConstants.address;
    final intro = home['ambedkarIntroduction'] ??
        'Bhimrao Ramji Ambedkar was an Indian jurist, economist, social reformer and politician who chaired the committee that drafted the Constitution of India based on the debates of the Constituent Assembly of India.';
    return AppScaffold(
      title: 'Home',
      body: loading
          ? const LoadingView()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (error != null) ErrorText(error!),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/ambedkar.jpg',
                        height: 160,
                        width: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          width: 160,
                          color: Colors.blue.shade50,
                          child: const Icon(Icons.account_balance, size: 72, color: Color(0xFF0D47A1)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text(ApiConstants.registrationNo, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(address, textAlign: TextAlign.center),
                  const SizedBox(height: 18),
                  Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(intro, style: const TextStyle(height: 1.45)))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _countCard('Active Families', '${counts['activeFamilyCount'] ?? 0}')),
                      const SizedBox(width: 8),
                      Expanded(child: _countCard('Active Members', '${counts['activeMemberCount'] ?? 0}')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _navButton('Staff Login', const StaffLoginScreen()),
                  _navButton('Member Login', const StaffLoginScreen(title: 'Member Login')),
                  _navButton('Member Registration', const MemberRegistrationScreen()),
                  const SizedBox(height: 20),
                  const Text(ApiConstants.copyright, textAlign: TextAlign.center),
                ],
              ),
            ),
    );
  }

  Widget _countCard(String title, String value) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), Text(title)]),
        ),
      );

  Widget _navButton(String label, Widget screen) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: OutlinedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)), child: Text(label)),
      );
}
