import 'package:amplify_flutter/amplify_flutter.dart' hide Emitter;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../models/session.dart';
import '../../services/amplify_auth_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AmplifyAuthService _auth = AmplifyAuthService();

  AuthBloc() : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<BalanceDeducted>(_onBalanceDeducted);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    // Demo mode bypass for testing
    if (event.email == 'demo@goguard.com' && event.password == 'demo123') {
      final session = Session(
        userId: 'demo-user-123',
        balance: 5000.00,
        sessionToken: 'demo-token',
        recentContacts: [],
        transactionHistory: [],
      );
      emit(AuthSuccess(session));
      return;
    }
    
    try {
      final result = await _auth.signIn(
        email: event.email,
        password: event.password,
      );

      if (result.isSignedIn) {
        final user = await _auth.getCurrentUser();
        final session = Session(
          userId: user?.userId ?? user?.username ?? 'unknown',
          balance: 5000.00,
          sessionToken: '',
          recentContacts: [],
          transactionHistory: [],
        );
        emit(AuthSuccess(session));
      } else {
        emit(AuthFailure('Sign in incomplete. Check your email for a verification code.'));
      }
    } on AuthException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure('Login failed. Please try again.'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _auth.signOut();
    } catch (_) {}
    emit(AuthInitial());
  }

  void _onBalanceDeducted(
    BalanceDeducted event,
    Emitter<AuthState> emit,
  ) {
    if (state is AuthSuccess) {
      final s = (state as AuthSuccess).session;
      final newSession = Session(
        userId: s.userId,
        balance: (s.balance - event.amount).clamp(0.0, double.infinity),
        sessionToken: s.sessionToken,
        recentContacts: s.recentContacts,
        transactionHistory: s.transactionHistory,
      );
      emit(AuthSuccess(newSession));
    }
  }
}
