class ApiConstants {
  // Update this to hit the production Vercel deployment
  static const String baseUrl = 'https://resiflow-backend.vercel.app/api';
  
  // Auth
  static const String login = '$baseUrl/auth/login/';
  static const String register = '$baseUrl/auth/register/';
  static const String profile = '$baseUrl/auth/profile/';
  static const String refresh = '$baseUrl/auth/token/refresh/';
  
  // Society Config & Management
  static const String societies = '$baseUrl/society/societies/';
  static String societyDetail(int id) => '$societies$id/';
  static String societyByInvite(String code) => '$societies/by-invite/?code=$code';
  static String generateInvite(int id) => '$societies$id/generate-invite/';
  static const String wingsList = '$baseUrl/society/wings/';
  static const String unitsList = '$baseUrl/society/units/';
  static const String amenities = '$baseUrl/society/amenities/';
  static const String documents = '$baseUrl/society/documents/';
  static String setupWing(int id) => '$societies$id/setup-wing/';
  static String joinSociety(int id) => '$societies$id/join/';
  static const String joinRequests = '$baseUrl/society/join-requests/';
  static const String submitJoinRequest = '$baseUrl/society/join-requests/submit/';
  static const String parkingLots = '$baseUrl/society/parking-lots/';
  static String assignParkingTenant(int id) => '$parkingLots$id/assign-tenant/';
  
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
  static const String expenses = '$baseUrl/finance/expenses/';
  static const String income = '$baseUrl/finance/income/';
  static const String financeSummary = '$baseUrl/finance/income/finance-summary/';
  
  // Gatekeeper
  static const String visitorLogs = '$baseUrl/gatekeeper/visitor-logs/';
  static const String visitorCheckout = '$baseUrl/gatekeeper/visitor-logs/'; // + id + /checkout/
  static const String guardAttendance = '$baseUrl/gatekeeper/attendance/';
  static const String guardLogin = '$baseUrl/gatekeeper/attendance/login/';
  static const String guardLogout = '$baseUrl/gatekeeper/attendance/logout/';

  
  // Directory
  static const String helpers = '$baseUrl/directory/staff/';
  static const String members = '$baseUrl/directory/members/';
  static const String manageResidents = '$baseUrl/auth/manage-residents/';
  static const String manageGuards = '$baseUrl/auth/manage-guards/';
}
