class ApiConstants {
  // Use your local IP address for physical device, or 10.0.2.2 for Android Emulator
  // Adjust this based on where your Django server is running
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  static const String login = '$baseUrl/auth/login/';
  static const String register = '$baseUrl/auth/register/';
  static const String profile = '$baseUrl/auth/profile/';
  static const String refresh = '$baseUrl/auth/token/refresh/';
  
  static const String societies = '$baseUrl/society/societies/';
  
  static const String gatePasses = '$baseUrl/gatekeeper/gate-passes/';
  static const String gatePassesCreate = '$baseUrl/gatekeeper/gate-passes/create-pass/';
  static const String qrValidate = '$baseUrl/gatekeeper/gate-passes/validate/';
  
  static const String preApprovals = '$baseUrl/gatekeeper/pre-approvals/';
}
