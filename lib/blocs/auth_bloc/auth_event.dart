abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested({required this.email, required this.password});
}

class LogoutRequested extends AuthEvent {}

class BalanceDeducted extends AuthEvent {
  final double amount;
  BalanceDeducted(this.amount);
}
