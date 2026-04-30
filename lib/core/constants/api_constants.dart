class ApiConstants {
  // Update this to hit the production Vercel deployment
  static const String baseUrl = 'https://resiflow-backend.vercel.app/api';
  
  // Auth
  static const String login = '$baseUrl/auth/login/';
  static const String register = '$baseUrl/auth/register/';
  static const String profile = '$baseUrl/auth/profile/';
  static const String refresh = '$baseUrl/auth/token/refresh/';
  
  // Society
  static const String societies = '$baseUrl/society/societies/';
  static const String wingsList = '$baseUrl/society/wings/';
  static const String unitsList = '$baseUrl/society/units/';
  static String societyDetail(int id) => '$societies$id/';
  static String setupWing(int id) => '$societies$id/setup-wing/';
  static String joinSociety(int id) => '$societies$id/join/';
  
  // Gatekeeper
  static const String gatePasses = '$baseUrl/gatekeeper/gate-passes/';
  static const String gatePassesCreate = '$baseUrl/gatekeeper/gate-passes/create-pass/';
  static const String qrValidate = '$baseUrl/gatekeeper/gate-passes/validate/';
  static const String preApprovals = '$baseUrl/gatekeeper/pre-approvals/';
  
  // Communication
  static const String notices = '$baseUrl/communication/notices/';
  static const String communityPosts = '$baseUrl/communication/community-posts/';
  static const String communityComments = '$baseUrl/communication/community-comments/';
  static const String complaints = '$baseUrl/communication/complaints/';
  
  // Finance
  static const String paymentSettings = '$baseUrl/finance/payment-settings/';
  static const String bills = '$baseUrl/finance/bills/';
  static const String generateMonthlyBills = '$baseUrl/finance/bills/generate-monthly/';
  static const String penalties = '$baseUrl/finance/penalties/';
  
  // Directory
  static const String helpers = '$baseUrl/directory/staff/';
  static const String members = '$baseUrl/directory/members/';
}
