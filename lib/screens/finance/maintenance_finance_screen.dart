import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'finance_dashboard_screen.dart';
import 'payment_settings_screen.dart';
import 'monthly_tracker_screen.dart';
import 'generate_bills_screen.dart';
import 'penalties_screen.dart';
import 'payment_verification_screen.dart';
import 'expenses_screen.dart';
import 'income_screen.dart';

class MaintenanceFinanceScreen extends StatelessWidget {
  const MaintenanceFinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance & Finance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Overview Section ---
            const _SectionHeader(title: 'Overview'),
            const SizedBox(height: 8),
            _FinanceCard(
              icon: Icons.dashboard,
              title: 'Finance Dashboard',
              subtitle: 'Society balance, income vs expenses, pending collections',
              color: AppTheme.primaryColor,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceDashboardScreen())),
            ),
            const SizedBox(height: 24),

            // --- Billing Section ---
            const _SectionHeader(title: 'Billing'),
            const SizedBox(height: 8),
            _FinanceCard(
              icon: Icons.settings,
              title: 'Payment Settings',
              subtitle: 'Default amount, bank details, UPI & payment modes',
              color: Colors.teal,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentSettingsScreen())),
            ),
            const SizedBox(height: 12),
            _FinanceCard(
              icon: Icons.receipt_long,
              title: 'Generate Monthly Bills',
              subtitle: 'Create maintenance bills for all units at once',
              color: Colors.indigo,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GenerateBillsScreen())),
            ),
            const SizedBox(height: 12),
            _FinanceCard(
              icon: Icons.bar_chart,
              title: 'Monthly Tracker',
              subtitle: 'View paid/pending status & export to Excel',
              color: Colors.deepOrange,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyTrackerScreen())),
            ),
            const SizedBox(height: 12),
            _FinanceCard(
              icon: Icons.fact_check,
              title: 'Pending Verifications',
              subtitle: 'Approve offline cash and bank transfer payments',
              color: Colors.amber.shade700,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentVerificationScreen())),
            ),
            const SizedBox(height: 24),

            // --- Income & Expenses Section ---
            const _SectionHeader(title: 'Income & Expenses'),
            const SizedBox(height: 8),
            _FinanceCard(
              icon: Icons.trending_up,
              title: 'Society Income',
              subtitle: 'Hall bookings, parking rent, interest & other income',
              color: Colors.green,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomeScreen())),
            ),
            const SizedBox(height: 12),
            _FinanceCard(
              icon: Icons.trending_down,
              title: 'Society Expenses',
              subtitle: 'Electricity, water, security, repairs & all expenses',
              color: Colors.red.shade600,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen())),
            ),
            const SizedBox(height: 24),

            // --- Penalties Section ---
            const _SectionHeader(title: 'Penalties'),
            const SizedBox(height: 8),
            _FinanceCard(
              icon: Icons.gavel,
              title: 'Penalties',
              subtitle: 'Issue & manage penalties for residents',
              color: Colors.red,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PenaltiesScreen())),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textLight, letterSpacing: 1.2),
    );
  }
}

class _FinanceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FinanceCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
