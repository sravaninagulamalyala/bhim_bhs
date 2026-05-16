import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/auth_store.dart';
import '../../core/widgets/common_widgets.dart';
import '../dashboard/dashboard_screen.dart';

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key, this.title = 'Staff Login'});
  final String title;

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final formKey = GlobalKey<FormState>();
  final adminId = TextEditingController();
  final password = TextEditingController();
  final captcha = TextEditingController(text: '1234');
  String captchaText = '1234';
  String? captchaKey;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadCaptcha();
  }

  Future<void> _loadCaptcha() async {
    try {
      final data = await ApiClient(context.read<AuthStore>()).get('/auth/captcha');
      if (data is Map) {
        setState(() {
          captchaText = '${data['text'] ?? '1234'}';
          captchaKey = '${data['key'] ?? ''}';
        });
      }
    } catch (_) {}
  }

  Future<void> _login() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      final auth = context.read<AuthStore>();
      final data = await ApiClient(auth).post('/auth/login', body: {
        'adminId': adminId.text.trim(),
        'password': password.text,
        'captcha': captcha.text.trim(),
        'captchaKey': captchaKey,
      });
      final staff = data['staff'] ?? {};
      await auth.save(
        token: '${data['token']}',
        role: '${data['role']}',
        staffName: '${staff['fullName'] ?? staff['adminId'] ?? adminId.text}',
        adminId: '${staff['adminId'] ?? adminId.text}',
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashboardScreen()), (_) => false);
    } catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.title,
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: adminId, decoration: const InputDecoration(labelText: 'Admin ID'), validator: _required),
            const SizedBox(height: 12),
            TextFormField(controller: password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true, validator: _required),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextFormField(controller: captcha, decoration: const InputDecoration(labelText: 'Captcha'), validator: _required)),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: _loadCaptcha, child: Text(captchaText)),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Login', loading: loading, onPressed: _login),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
}
