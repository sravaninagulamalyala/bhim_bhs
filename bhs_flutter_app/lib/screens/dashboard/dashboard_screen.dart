import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/storage/auth_store.dart';
import '../../core/utils/roles.dart';
import '../../core/widgets/common_widgets.dart';
import '../attendance/attendance_screens.dart';
import '../members/member_screens.dart';
import '../profile/profile_screen.dart';
import '../reports/report_screens.dart';
import '../search/member_family_search_screen.dart';
import '../staff/staff_management_screen.dart';
import '../transactions/transaction_screens.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthStore>().role;
    final cards = <_DashCard>[
      if (Roles.isSuperAdmin(role)) _DashCard('Excel Upload', Icons.upload_file, const ExcelUploadScreen()),
      if (Roles.isSuperAdmin(role)) _DashCard('Staff Management', Icons.admin_panel_settings, const StaffManagementScreen()),
      if (Roles.canUpdateMembers(role)) _DashCard('Members', Icons.people, const MemberUpdateScreen()),
      if (Roles.canUpdateMembers(role)) _DashCard('Family Mapping', Icons.family_restroom, const FamilyMappingScreen()),
      if (Roles.canManageAttendance(role)) _DashCard('Attendance Meeting', Icons.event_note, const AttendanceMeetingScreen()),
      if (Roles.canManageAttendance(role)) _DashCard('Attendance', Icons.fact_check, const MarkAttendanceScreen()),
      if (!Roles.canManageAttendance(role)) _DashCard('Attendance View', Icons.visibility, const ViewAttendanceScreen()),
      if (Roles.canManageTransactions(role)) _DashCard('Transactions', Icons.payments, const TransactionEntryScreen()),
      if (!Roles.canManageTransactions(role)) _DashCard('Transactions View', Icons.receipt_long, const TransactionViewScreen()),
      _DashCard('Reports', Icons.bar_chart, const ReportsScreen()),
      _DashCard('Search', Icons.search, const MemberFamilySearchScreen()),
    ];
    return AppScaffold(
      title: 'Dashboard',
      actions: [IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())), icon: const Icon(Icons.account_circle))],
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: cards.length,
        itemBuilder: (_, i) => InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => cards[i].screen)),
          child: Card(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(cards[i].icon, size: 42, color: const Color(0xFF0D47A1)),
              const SizedBox(height: 12),
              Text(cards[i].title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _DashCard {
  _DashCard(this.title, this.icon, this.screen);
  final String title;
  final IconData icon;
  final Widget screen;
}
