import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../shared/widgets/app_bottom_nav.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/auth_login_screen.dart';
import '../features/auth/presentation/screens/auth_register_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_welcome_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_history_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_tracker_focus_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_advisory_focus_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_wallet_goal_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_daily_ritual_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_wallet_setup_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_set_goal_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/wallet/presentation/screens/wallet_screen.dart';
import '../features/wallet/presentation/screens/wallet_detail_screen.dart';
import '../features/wallet/presentation/screens/add_wallet_institution_screen.dart';
import '../features/wallet/presentation/screens/manual_wallet_entry_screen.dart';
import '../features/budget/presentation/screens/budget_screen.dart';
import '../features/consult/presentation/screens/consult_list_screen.dart';
import '../features/consult/presentation/screens/consult_detail_screen.dart';
import '../features/consult/presentation/screens/booking_flow_screen.dart';
import '../features/goals/presentation/screens/add_edit_goal_screen.dart';
import '../features/goals/presentation/screens/goal_detail_screen.dart';
import '../features/budget/presentation/screens/add_edit_budget_screen.dart';
import '../features/bills/presentation/screens/add_edit_bill_screen.dart';
import '../features/consult/presentation/screens/booking_payment_screen.dart';
import '../features/transaction/presentation/screens/transaction_entry_screen.dart';
import '../features/transaction/presentation/screens/transaction_history_screen.dart';
import '../features/transaction/presentation/screens/ai_draft_review_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/security_settings_screen.dart';
import '../features/profile/presentation/screens/notification_settings_screen.dart';
import '../features/profile/presentation/screens/help_support_screen.dart';
import '../features/report/presentation/screens/report_dashboard_screen.dart';
import '../features/session/presentation/screens/branch_session_screen.dart';
import '../features/session/presentation/screens/ai_chat_screen.dart';
import '../features/consult/presentation/screens/consult_chat_screen.dart';
import '../features/transaction/presentation/screens/transaction_success_screen.dart';
import '../features/match_expert/presentation/screens/match_expert_screen.dart';
import '../features/notification/presentation/screens/notification_screen.dart';
import '../features/services/presentation/screens/financial_health_screen.dart';
import '../features/services/presentation/screens/financial_test_catalog_screen.dart';
import '../features/services/presentation/screens/kpr_simulation_screen.dart';
import '../features/services/presentation/screens/financial_calculator_screen.dart';
import '../features/services/presentation/screens/debt_payoff_strategy_screen.dart';
import '../features/services/presentation/screens/voucher_screen.dart';
import '../features/export/presentation/screens/export_data_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../core/models/transaction_model.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (previous, next) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

// Keys for each navigator branch
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _budgetNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'budget');
final _consultNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'consult');
final _walletNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'wallet');

final goRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final location = state.matchedLocation;

      // Allow splash screen to display its animation
      if (location == '/splash') {
        return null;
      }

      final isAuthRoute = location == '/login' ||
          location == '/register' ||
          location.startsWith('/onboarding');

      // Not logged in and attempting to visit a protected route
      if (!auth.isLoggedIn) {
        return isAuthRoute ? null : '/login';
      }

      // Logged in and attempting to visit login or register
      if (location == '/login' || location == '/register') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      // --- Auth & Onboarding (outside shell) ---
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AuthLoginScreen(),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AuthRegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingWelcomeScreen(),
        routes: [
          GoRoute(
            path: 'history',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const OnboardingHistoryScreen(),
          ),
          GoRoute(
            path: 'tracker-focus',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const OnboardingTrackerFocusScreen(),
          ),
          GoRoute(
            path: 'advisory-focus',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const OnboardingAdvisoryFocusScreen(),
          ),
          GoRoute(
            path: 'wallet-goal',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const OnboardingWalletGoalScreen(),
          ),
          GoRoute(
            path: 'daily-ritual',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const OnboardingDailyRitualScreen(),
          ),
          GoRoute(
            path: 'wallet-setup',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const OnboardingWalletSetupScreen(),
          ),
          GoRoute(
            path: 'goal',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const OnboardingSetGoalScreen(),
          ),
        ],
      ),

      // --- Main App Shell with Bottom Nav (4 branches) ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Branch 1: Consult
          StatefulShellBranch(
            navigatorKey: _consultNavigatorKey,
            routes: [
              GoRoute(
                path: '/consult',
                builder: (context, state) => ConsultListScreen(
                  initialCategory: state.uri.queryParameters['category'],
                ),
              ),
            ],
          ),
          // Branch 2: Wallet
          StatefulShellBranch(
            navigatorKey: _walletNavigatorKey,
            routes: [
              GoRoute(
                path: '/wallet',
                builder: (context, state) => const WalletScreen(),
              ),
            ],
          ),
          // Branch 3: Budget (internal tabs for Goals/Budget/Bills)
          StatefulShellBranch(
            navigatorKey: _budgetNavigatorKey,
            routes: [
              GoRoute(
                path: '/budget',
                builder: (context, state) {
                  final tabParam = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 1;
                  return BudgetScreen(initialTab: tabParam);
                },
              ),
            ],
          ),
        ],
      ),

      // --- Routes shown ABOVE the shell (full-screen, no bottom nav) ---
      GoRoute(
        path: '/goal/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddEditGoalScreen(),
      ),
      GoRoute(
        path: '/goal/edit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AddEditGoalScreen(goalId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/goal/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => GoalDetailScreen(goalId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/budget/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddEditBudgetScreen(),
      ),
      GoRoute(
        path: '/budget/edit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AddEditBudgetScreen(budgetId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/bill/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddEditBillScreen(),
      ),
      GoRoute(
        path: '/bill/edit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AddEditBillScreen(billId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/consult/chat',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ConsultChatScreen(),
      ),
      GoRoute(
        path: '/consult/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ConsultDetailScreen(consultantId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/wallet/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddWalletInstitutionScreen(),
      ),
      GoRoute(
        path: '/wallet/manual',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ManualWalletEntryScreen(
            institutionId: extra?['institutionId'] as String?,
            institutionName: extra?['institutionName'] as String? ?? '',
            institutionType: extra?['institutionType'] as String? ?? 'Bank',
          );
        },
      ),
      GoRoute(
        path: '/wallet/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => WalletDetailScreen(walletId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/booking/:consultantId/service',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BookingFlowScreen(
          consultantId: state.pathParameters['consultantId']!,
          initialStep: 0,
        ),
      ),
      GoRoute(
        path: '/booking/:consultantId/time',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BookingFlowScreen(
          consultantId: state.pathParameters['consultantId']!,
          initialStep: 1,
        ),
      ),
      GoRoute(
        path: '/booking/:consultantId/pre-consult',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BookingFlowScreen(
          consultantId: state.pathParameters['consultantId']!,
          initialStep: 2,
        ),
      ),
      GoRoute(
        path: '/booking/:consultantId/payment',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BookingPaymentScreen(consultantId: state.pathParameters['consultantId']!),
      ),
      GoRoute(
        path: '/transaction/entry',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TransactionEntryScreen(
            prefilledType: extra?['type'] as String?,
            prefilledTargetGoalId: extra?['targetGoalId'] as String?,
            prefilledSourceWalletId: extra?['sourceWalletId'] as String?,
            prefilledTargetWalletId: extra?['targetWalletId'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/transaction/success',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TransactionSuccessScreen(
            returnTo: extra?['returnTo'] as String?,
            transaction: extra?['transaction'] as TransactionModel?,
          );
        },
      ),
      GoRoute(
        path: '/transaction/history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TransactionHistoryScreen(),
      ),
      GoRoute(
        path: '/draft/review',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AiDraftReviewScreen(),
      ),
      GoRoute(
        path: '/reporting',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReportDashboardScreen(),
      ),
      GoRoute(
        path: '/export',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExportDataScreen(),
      ),
      GoRoute(
        path: '/score',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FinancialHealthScreen(),
      ),
      GoRoute(
        path: '/financial-test',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FinancialTestCatalogScreen(),
      ),
      GoRoute(
        path: '/tools/kpr',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const KprSimulationScreen(),
      ),
      GoRoute(
        path: '/tools/calculator',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FinancialCalculatorScreen(),
      ),
      GoRoute(
        path: '/tools/debt-payoff',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DebtPayoffStrategyScreen(),
      ),
      GoRoute(
        path: '/vouchers',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const VoucherScreen(),
      ),
      GoRoute(
        path: '/session',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BranchSessionScreen(),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: 'security',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const SecuritySettingsScreen(),
          ),
          GoRoute(
            path: 'notifications',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
          GoRoute(
            path: 'support',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const HelpSupportScreen(),
          ),
        ],
      ),

      GoRoute(
        path: '/ai-chat',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AiChatScreen(),
      ),
      GoRoute(
        path: '/match-expert',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MatchExpertScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationScreen(),
      ),
    ],
  );
});
