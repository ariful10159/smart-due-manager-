class AuthService {
  Future<void> signIn(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}
