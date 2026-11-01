import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/plan_catalog.dart';
import '../../data/models/family_model.dart';
import '../../data/models/user_model.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_state.dart';
import '../../logic/checkout/checkout_cubit.dart';
import '../../logic/onboarding/onboarding_cubit.dart';
import '../../logic/onboarding/onboarding_state.dart';
import '../../presentation/screens/auth_screen.dart';
import '../../presentation/screens/contact_address_screen.dart';
import '../../presentation/screens/create_family_screen.dart';
import '../../presentation/screens/dashboard_screen.dart';
import '../../presentation/screens/mock_checkout_screen.dart';
import '../../presentation/screens/personal_health_profile_screen.dart';
import '../../presentation/screens/select_plan_screen.dart';
import '../../presentation/screens/verify_email_screen.dart';
import '../../presentation/screens/welcome_screen.dart';

class RouterRefreshListenable extends ChangeNotifier {
  late final StreamSubscription<AuthState> _authSub;
  late final StreamSubscription<OnboardingState> _onboardingSub;

  RouterRefreshListenable(AuthBloc authBloc, OnboardingCubit onboardingCubit) {
    _authSub = authBloc.stream.listen((authState) {
      if (authState is Authenticated) {
        onboardingCubit.loadOnboarding(authState.user);
      }
      notifyListeners();
    });
    _onboardingSub = onboardingCubit.stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _authSub.cancel();
    _onboardingSub.cancel();
    super.dispose();
  }
}

class AppRouter {
  static GoRouter createRouter({
    required AuthBloc authBloc,
    required OnboardingCubit onboardingCubit,
    required CheckoutCubit checkoutCubit,
  }) {
    if (authBloc.state is Authenticated) {
      onboardingCubit.loadOnboarding((authBloc.state as Authenticated).user);
    }

    final refreshListenable = RouterRefreshListenable(authBloc, onboardingCubit);

    return GoRouter(
      initialLocation: '/',
      refreshListenable: refreshListenable,
      redirect: (BuildContext context, GoRouterState state) {
        final authState = authBloc.state;
        final currentPath = state.uri.path;

        final isAuth = authState is Authenticated;
        final isPublicRoute = currentPath == '/' ||
            currentPath == '/auth' ||
            currentPath == '/login' ||
            currentPath == '/register';

        if (!isAuth) {
          // If unauthenticated, allow public routes or redirect to welcome '/'
          return isPublicRoute ? null : '/';
        }

        final user = (onboardingCubit.state is OnboardingLoaded)
            ? (onboardingCubit.state as OnboardingLoaded).bundle.user
            : authState.user;

        // If user has completed onboarding:
        if (user.onboardingStatus == OnboardingStep.completed) {
          // Allow dashboard or plan change/checkout
          if (currentPath == '/dashboard' || currentPath == '/plan' || currentPath == '/checkout') {
            return null;
          }
          return '/dashboard';
        }

        // If user is authenticated but hasn't completed onboarding:
        // Prevent premature access to dashboard
        if (currentPath == '/dashboard') {
          return _stepToPath(user.onboardingStatus);
        }

        // Note: Email verification requirement is bypassed due to Firebase limitation.
        // If authenticated user tries to access public routes or verify-email, redirect to current onboarding step
        if (isPublicRoute || currentPath == '/verify-email') {
          return _stepToPath(user.onboardingStatus);
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => WelcomeScreen(
            onNavigateToRegister: () => context.go('/auth?tab=register'),
            onNavigateToLogin: () => context.go('/auth?tab=login'),
          ),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) {
            final tabParam = state.uri.queryParameters['tab'];
            final initialTab = tabParam == 'register' ? AuthTab.register : AuthTab.login;
            return AuthScreen(
              initialTab: initialTab,
              onBackToHome: () => context.go('/'),
            );
          },
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => AuthScreen(
            initialTab: AuthTab.register,
            onBackToHome: () => context.go('/'),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => AuthScreen(
            initialTab: AuthTab.login,
            onBackToHome: () => context.go('/'),
          ),
        ),
        GoRoute(
          path: '/verify-email',
          builder: (context, state) {
            final authState = authBloc.state;
            final user = authState is Authenticated ? authState.user : _dummyUser;
            return VerifyEmailScreen(user: user);
          },
        ),
        GoRoute(
          path: '/contact',
          builder: (context, state) {
            final bundle = _getBundle(onboardingCubit, authBloc);
            return ContactAddressScreen(
              user: bundle.user,
              initialProfile: bundle.memberProfile,
            );
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) {
            final bundle = _getBundle(onboardingCubit, authBloc);
            return PersonalHealthProfileScreen(
              user: bundle.user,
              initialProfile: bundle.memberProfile,
            );
          },
        ),
        GoRoute(
          path: '/family',
          builder: (context, state) {
            final bundle = _getBundle(onboardingCubit, authBloc);
            return CreateFamilyScreen(
              user: bundle.user,
              initialFamily: bundle.family,
            );
          },
        ),
        GoRoute(
          path: '/plan',
          builder: (context, state) {
            final bundle = _getBundle(onboardingCubit, authBloc);
            final family = bundle.family ??
                FamilyModel(
                  familyId: 'fam_${bundle.user.uid}',
                  familyName: '${bundle.user.fullName.split(' ').first} Household',
                  adminUid: bundle.user.uid,
                );

            final onboardingState = onboardingCubit.state;
            final selectedPlan = onboardingState is OnboardingLoaded
                ? onboardingState.selectedPlan
                : null;

            return SelectPlanScreen(
              user: bundle.user,
              family: family,
              initialSelectedPlan: selectedPlan,
            );
          },
        ),
        GoRoute(
          path: '/checkout',
          builder: (context, state) {
            final bundle = _getBundle(onboardingCubit, authBloc);
            final family = bundle.family ??
                FamilyModel(
                  familyId: 'fam_${bundle.user.uid}',
                  familyName: '${bundle.user.fullName.split(' ').first} Household',
                  adminUid: bundle.user.uid,
                );

            final onboardingState = onboardingCubit.state;
            final targetPlan = (onboardingState is OnboardingLoaded
                    ? onboardingState.selectedPlan
                    : null) ??
                (bundle.user.pendingPlanId != null
                    ? PlanCatalog.findById(bundle.user.pendingPlanId!)
                    : PlanCatalog.familyPro);

            return MockCheckoutScreen(
              user: bundle.user,
              family: family,
              plan: targetPlan,
              onPaymentCompleted: () {
                context.go('/dashboard');
              },
              onReturnToPlanSelection: () {
                context.go('/plan');
              },
            );
          },
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) {
            final bundle = _getBundle(onboardingCubit, authBloc);
            final onboardingState = onboardingCubit.state;
            final selectedPlan = (onboardingState is OnboardingLoaded
                    ? onboardingState.selectedPlan
                    : null) ??
                (bundle.subscription != null
                    ? PlanCatalog.findById(bundle.subscription!.planId)
                    : PlanCatalog.familyBasic);

            return DashboardScreen(
              user: bundle.user,
              memberProfile: bundle.memberProfile,
              family: bundle.family,
              subscription: bundle.subscription,
              plan: selectedPlan,
              onChangePlan: () {
                context.go('/plan');
              },
            );
          },
        ),
      ],
    );
  }

  static String _stepToPath(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.noAccount:
        return '/';
      case OnboardingStep.accountCreated:
      case OnboardingStep.emailVerified:
        return '/contact';
      case OnboardingStep.contactSaved:
        return '/profile';
      case OnboardingStep.profileSaved:
        return '/family';
      case OnboardingStep.familyCreated:
        return '/plan';
      case OnboardingStep.planSelected:
        return '/checkout';
      case OnboardingStep.completed:
        return '/dashboard';
    }
  }

  static _BundleHelper _getBundle(OnboardingCubit onboardingCubit, AuthBloc authBloc) {
    final obState = onboardingCubit.state;
    if (obState is OnboardingLoaded) {
      return _BundleHelper(
        user: obState.bundle.user,
        memberProfile: obState.bundle.memberProfile,
        family: obState.bundle.family,
        subscription: obState.bundle.subscription,
      );
    }
    final authState = authBloc.state;
    UserModel user;
    if (authState is Authenticated) {
      user = authState.user;
    } else {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        user = UserModel(
          uid: fbUser.uid,
          fullName: fbUser.displayName ?? 'MediHub User',
          email: fbUser.email ?? 'user@medihub.health',
          emailVerified: true,
          onboardingStatus: OnboardingStep.emailVerified,
        );
      } else {
        user = _dummyUser;
      }
    }
    final resolvedMemberId = (user.memberId != null && user.memberId!.isNotEmpty)
        ? user.memberId!
        : (user.uid.isNotEmpty && user.uid != 'guest' ? 'mem_${user.uid}' : null);
    final resolvedUser = user.copyWith(memberId: resolvedMemberId);
    return _BundleHelper(user: resolvedUser);
  }

  static final UserModel _dummyUser = UserModel(
    uid: 'guest',
    fullName: 'MediHub Guest',
    email: 'guest@medihub.health',
    emailVerified: false,
    onboardingStatus: OnboardingStep.noAccount,
  );
}

class _BundleHelper {
  final UserModel user;
  final dynamic memberProfile;
  final dynamic family;
  final dynamic subscription;

  _BundleHelper({
    required this.user,
    this.memberProfile,
    this.family,
    this.subscription,
  });
}
