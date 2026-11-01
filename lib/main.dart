import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/appointments_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/health_records_repository.dart';
import 'data/repositories/onboarding_repository.dart';
import 'data/repositories/subscription_repository.dart';
import 'data/services/local_storage_service.dart';
import 'firebase_options.dart';
import 'logic/auth/auth_bloc.dart';
import 'logic/auth/auth_event.dart';
import 'logic/checkout/checkout_cubit.dart';
import 'logic/onboarding/onboarding_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  final localStorageService = LocalStorageService();
  runApp(MediHubApp(localStorageService: localStorageService));
}

class MediHubApp extends StatelessWidget {
  final LocalStorageService localStorageService;

  MediHubApp({
    super.key,
    LocalStorageService? localStorageService,
  }) : localStorageService = localStorageService ?? LocalStorageService();

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LocalStorageService>.value(
          value: localStorageService,
        ),
        RepositoryProvider<AuthRepository>(
          create: (_) => AuthRepository(localStorageService: localStorageService),
        ),
        RepositoryProvider<OnboardingRepository>(
          create: (_) => OnboardingRepository(localStorageService: localStorageService),
        ),
        RepositoryProvider<SubscriptionRepository>(
          create: (_) => SubscriptionRepository(localStorageService: localStorageService),
        ),
        RepositoryProvider<HealthRecordsRepository>(
          create: (_) => HealthRecordsRepository(),
        ),
        RepositoryProvider<AppointmentsRepository>(
          create: (_) => AppointmentsRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            )..add(AuthCheckRequested()),
          ),
          BlocProvider<OnboardingCubit>(
            create: (context) => OnboardingCubit(
              onboardingRepository: context.read<OnboardingRepository>(),
              subscriptionRepository: context.read<SubscriptionRepository>(),
            ),
          ),
          BlocProvider<CheckoutCubit>(
            create: (context) => CheckoutCubit(
              subscriptionRepository: context.read<SubscriptionRepository>(),
            ),
          ),
        ],
        child: const MediHubRouterApp(),
      ),
    );
  }
}

class MediHubRouterApp extends StatefulWidget {
  const MediHubRouterApp({super.key});

  @override
  State<MediHubRouterApp> createState() => _MediHubRouterAppState();
}

class _MediHubRouterAppState extends State<MediHubRouterApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter(
      authBloc: context.read<AuthBloc>(),
      onboardingCubit: context.read<OnboardingCubit>(),
      checkoutCubit: context.read<CheckoutCubit>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'MediHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
    );
  }
}
