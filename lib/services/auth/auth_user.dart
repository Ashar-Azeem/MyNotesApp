import 'package:firebase_auth/firebase_auth.dart' show User;

class AuthUser {
  final bool isUserVerified;
  final String? email;
  AuthUser({required this.isUserVerified, required this.email});

  //This works as an copy constructor
  factory AuthUser.fromFirebase(User user) =>
      AuthUser(isUserVerified: user.emailVerified, email: user.email);
}
