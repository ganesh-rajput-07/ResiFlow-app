import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../gatekeeper/create_pass_screen.dart';
import '../scanner/qr_scanner_screen.dart';
import '../approvals/pre_approval_screen.dart';
import '../approvals/approval_management_screen.dart';
import '../admin/society_config_screen.dart';
import '../admin/invite_members_screen.dart';
import '../admin/manage_helpers_screen.dart';
import '../admin/resident_approval_screen.dart';
import '../finance/penalties_screen.dart';
import '../parking/parking_lots_screen.dart';
import '../finance/maintenance_finance_screen.dart';
import '../finance/resident_payments_screen.dart';
import '../finance/resident_penalties_screen.dart';
import '../finance/resident_finance_dashboard.dart';
import '../directory/society_directory_screen.dart';
import '../directory/helpers_directory_screen.dart';
import '../communication/community_forum_screen.dart';
import '../communication/notices_screen.dart';
import '../admin/society_info_screen.dart';
import '../admin/manage_residents_screen.dart';
import '../profile/profile_screen.dart';
import '../gatekeeper/guard_security_screen.dart';
import '../gatekeeper/visitor_logs_history_screen.dart';
import '../communication/raise_complaint_screen.dart';
import '../communication/manage_complaints_screen.dart';
import '../admin/guard_attendance_report_screen.dart';
import '../admin/manage_guards_screen.dart';
import '../profile/renting_details_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final role = user?['role'] ?? 'resident';
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png', 
              height: 32,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.business, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Dashboard', overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user?['first_name'] ?? user?['username'] ?? 'User'}!',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      if (user?['society_name'] != null)
                        Text(
                          '${user?['society_name']}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                if (role == 'resident' || role == 'committee') _buildUnitSwitcher(context),
              ],
            ),
            const SizedBox(height: 20),

            // ─── ADMIN & COMMITTEE PANEL ───
            if (role == 'admin' || role == 'committee') ...[
              _buildSection(
                title: 'Admin & Committee Panel',
                items: [
                  _DashboardItem(icon: Icons.settings, title: 'Society Config',
                    onTap: () => _push(context, const SocietyConfigScreen())),
                  _DashboardItem(icon: Icons.people_alt, title: 'Manage Residents',
                    onTap: () => _push(context, const ManageResidentsScreen())),
                  _DashboardItem(icon: Icons.person_add_alt_1, title: 'Invite Residents',
                    onTap: () => _push(context, const InviteMembersScreen())),
                  _DashboardItem(icon: Icons.how_to_reg, title: 'Approvals',
                    onTap: () => _push(context, const ResidentApprovalScreen())),
                  _DashboardItem(icon: Icons.vpn_key, title: 'Gate Pass Requests',
                    onTap: () => _push(context, const ApprovalManagementScreen())),
                  _DashboardItem(icon: Icons.gavel, title: 'Penalties',
                    onTap: () => _push(context, const PenaltiesScreen())),
                  _DashboardItem(icon: Icons.cleaning_services, title: 'Manage Staff',
                    onTap: () => _push(context, const ManageHelpersScreen())),
                  _DashboardItem(icon: Icons.currency_rupee, title: 'Finance',
                    onTap: () => _push(context, const MaintenanceFinanceScreen())),
                  _DashboardItem(icon: Icons.admin_panel_settings, title: 'Manage Guards',
                    onTap: () => _push(context, const ManageGuardsScreen())),
                  _DashboardItem(icon: Icons.feedback, title: 'Complaints',
                    onTap: () => _push(context, const ManageComplaintsScreen())),
                  _DashboardItem(icon: Icons.assignment_ind, title: 'Guard Attendance',
                    onTap: () => _push(context, const GuardAttendanceReportScreen())),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // ─── RESIDENT: QUICK ACCESS ───
            if (role != 'guard') ...[
              _buildSection(
                title: 'Quick Access',
                items: [
                  _DashboardItem(icon: Icons.qr_code_scanner, title: 'Gate Pass Request',
                    onTap: () => _push(context, const PreApprovalScreen())),
                  _DashboardItem(icon: Icons.history, title: 'Visitor Logs',
                    onTap: () => _push(context, const VisitorLogsHistoryScreen())),
                  _DashboardItem(icon: Icons.report_problem, title: 'Complaints',
                    onTap: () => _push(context, const RaiseComplaintScreen())),
                  _DashboardItem(icon: Icons.local_parking, title: 'Parking Lots',
                    onTap: () => _push(context, const ParkingLotsScreen())),
                  _DashboardItem(icon: Icons.vpn_key_outlined, title: 'Renting & Units',
                    onTap: () => _push(context, const RentingDetailsScreen())),
                  _DashboardItem(icon: Icons.cleaning_services, title: 'Helpers',
                    onTap: () => _push(context, const HelpersDirectoryScreen())),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // ─── RESIDENT: PAYMENTS & PENALTIES ───
            if (role != 'guard') ...[
              _buildSection(
                title: 'Payments & Dues',
                items: [
                  _DashboardItem(icon: Icons.payment, title: 'Maintenance',
                    onTap: () {
                      if (role == 'admin' || role == 'committee') {
                        _push(context, const MaintenanceFinanceScreen());
                      } else {
                        _push(context, const ResidentPaymentsScreen());
                      }
                    }),
                  _DashboardItem(icon: Icons.gavel, title: 'My Penalties',
                    onTap: () {
                      if (role == 'admin' || role == 'committee') {
                        _push(context, const PenaltiesScreen());
                      } else {
                        _push(context, const ResidentPenaltiesScreen());
                      }
                    }),
                  _DashboardItem(icon: Icons.people, title: 'Resident Directory',
                    onTap: () => _push(context, const SocietyDirectoryScreen())),
                  _DashboardItem(icon: Icons.info_outline, title: 'Society Info',
                    onTap: () => _push(context, const SocietyInfoScreen())),
                  _DashboardItem(icon: Icons.account_balance, title: 'Society Finance',
                    onTap: () => _push(context, const ResidentFinanceDashboard())),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // ─── GUARD: SECURITY ───
            if (role == 'guard' || role == 'admin') ...[
              _buildSection(
                title: 'Security & Gate',
                items: [
                  _DashboardItem(icon: Icons.security, title: 'Gate Management',
                    onTap: () => _push(context, const GuardSecurityScreen())),
                  _DashboardItem(icon: Icons.camera_alt_outlined, title: 'Quick Scan',
                    onTap: () => _push(context, const QRScannerScreen())),
                  _DashboardItem(icon: Icons.history, title: 'Visitor Logs',
                    onTap: () => _push(context, const VisitorLogsHistoryScreen())),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // ─── SOCIETY & COMMUNICATION (ALL ROLES) ───
            _buildSection(
              title: 'Society & Community',
              items: [
                _DashboardItem(icon: Icons.apartment, title: 'Society Info',
                  onTap: () => _push(context, const SocietyInfoScreen())),
                _DashboardItem(icon: Icons.campaign_outlined, title: 'Notices',
                  onTap: () => _push(context, const NoticesScreen())),
                _DashboardItem(icon: Icons.forum_outlined, title: 'Community',
                  onTap: () => _push(context, const CommunityForumScreen())),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitSwitcher(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final List units = user?['resident_units'] ?? [];
    final selectedUnit = auth.selectedUnit;

    if (units.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedUnit?['id'],
          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
          onChanged: (int? newValue) {
            final newUnit = units.firstWhere((u) => u['id'] == newValue);
            auth.setSelectedUnit(newUnit);
          },
          items: units.map<DropdownMenuItem<int>>((dynamic unit) {
            return DropdownMenuItem<int>(
              value: unit['id'],
              child: Text(
                'Unit ${unit['unit_number']}',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
          children: items,
        ),
      ],
    );
  }
}

class _DashboardItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DashboardItem({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 28),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
