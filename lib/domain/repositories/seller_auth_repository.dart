abstract class SellerAuthRepository {
  Future<Map<String, dynamic>> loginWithPassword({required String email, required String password});
  Future<bool> sendEmailOtp(String email);
  Future<Map<String, dynamic>> verifyEmailOtp({required String email, required String otp});
  Future<bool> setupPassword(String newPassword);
  Future<bool> forgotPassword(String email);
  Future<bool> resetPassword({required String token, required String newPassword});
  Future<void> logout();
  Future<bool> isAuthenticated();
  Future<String?> getSavedToken();
  Future<String?> getSavedSellerId();
}
