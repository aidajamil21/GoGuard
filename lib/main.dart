import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'blocs/auth_bloc/auth_bloc.dart';
import 'blocs/auth_bloc/auth_state.dart';
import 'blocs/transfer_bloc/transfer_bloc.dart';
import 'blocs/whitelist_cubit/whitelist_cubit.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/transfer/recipient_entry_screen.dart';
import 'screens/transfer/scam_check_screen.dart';
import 'screens/transfer/amount_screen.dart';
import 'screens/transfer/analysing_screen.dart';
import 'screens/transfer/warning_screen.dart';
import 'screens/transfer/transfer_loading_screen.dart';
import 'screens/transfer/success_screen.dart';
import 'screens/transfer/new_success_screen.dart';
import 'screens/error/error_screens.dart';
import 'screens/whitelist/whitelist_screen.dart';
import 'screens/scam_db/scam_db_screen.dart';
import 'services/simple_amplify_config.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SimpleAmplifyConfig.configure();
  } catch (e) {
    debugPrint('⚠️ Amplify configuration error: $e');
  }
  runApp(const GOguardApp());
}

class GOguardApp extends StatelessWidget {
  const GOguardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()),
        BlocProvider(create: (_) => TransferBloc()),
        BlocProvider(create: (_) => WhitelistCubit()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            context.read<TransferBloc>().setUserId(state.session.userId);
          }
        },
        child: MaterialApp(
          title: 'GOguard',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.jade),
            useMaterial3: true,
            textTheme: GoogleFonts.dmSansTextTheme(),
            scaffoldBackgroundColor: AppColors.surface,
          ),
          initialRoute: '/login',
          routes: {
            '/login':                      (_) => const LoginScreen(),
            '/register':                   (_) => const RegisterScreen(),
            '/home':                       (_) => const HomeScreen(),
            '/transfer/recipient':         (_) => const RecipientEntryScreen(),
            '/transfer/recipient-check':   (_) => const ScamCheckScreen(),
            '/transfer/amount':            (_) => const AmountScreen(),
            '/transfer/analysing':         (_) => const AnalysingScreen(),
            '/transfer/warning':           (_) => const WarningScreen(),
            '/transfer/loading':           (_) => const TransferLoadingScreen(),
            '/transfer/success':           (_) => const NewSuccessScreen(), // Breather window enabled
            '/error/scam-blocked':         (_) => const ScamBlockedScreen(),
            '/error/insufficient-funds':   (_) => const InsufficientFundsScreen(),
            '/error/timeout':              (_) => const TimeoutScreen(),
            '/whitelist':                  (_) => const WhitelistScreen(),
            '/scam-db':                    (_) => const ScamDbScreen(),
          },
        ),
      ),
    );
  }
}
