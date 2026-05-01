import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';

class GuardAttendanceReportScreen extends StatefulWidget {
  const GuardAttendanceReportScreen({super.key});

  @override
  State<GuardAttendanceReportScreen> createState() => _GuardAttendanceReportScreenState();
}

class _GuardAttendanceReportScreenState extends State<GuardAttendanceReportScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _attendance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.guardAttendance);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _attendance = data is List ? data : data['results'] ?? []);
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guard Attendance Report')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAttendance,
              child: _attendance.isEmpty
                  ? const Center(child: Text('No attendance records found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _attendance.length,
                      itemBuilder: (context, index) {
                        final a = _attendance[index];
                        final login = DateTime.parse(a['login_time']);
                        final logout = a['logout_time'] != null ? DateTime.parse(a['logout_time']) : null;
                        
                        Duration? shiftDuration;
                        if (logout != null) {
                          shiftDuration = logout.difference(login);
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(a['guard_name']?[0] ?? 'G'),
                            ),
                            title: Text(a['guard_name'] ?? 'Guard', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date: ${DateFormat('dd MMM yyyy').format(login)}'),
                                Text('In: ${DateFormat('hh:mm a').format(login)} • Out: ${logout != null ? DateFormat('hh:mm a').format(logout) : 'Active'}'),
                              ],
                            ),
                            trailing: logout != null 
                                ? Text('${shiftDuration!.inHours}h ${shiftDuration.inMinutes % 60}m', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))
                                : const Chip(label: Text('On Duty', style: TextStyle(color: Colors.white, fontSize: 10)), backgroundColor: Colors.green),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
