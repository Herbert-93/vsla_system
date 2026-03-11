import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/app_state_provider.dart';
import 'screens/auth/bank_selection_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/group_leader_dashboard.dart';
import 'screens/dashboard/member_dashboard.dart';
import 'screens/members/member_list_screen.dart';
import 'screens/members/member_registration_screen.dart';
import 'screens/settings/group_settings_screen.dart';
import 'screens/meetings/meeting_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await DatabaseService.instance.initializeDatabase();

  runApp(const VSLAApp());
}

class VSLAApp extends StatelessWidget {
  const VSLAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ],
      child: MaterialApp(
        title: 'VSLA Desktop',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade800),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const BankSelectionScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/group-dashboard': (context) => const GroupLeaderDashboard(),
          '/member-dashboard': (context) => MemberDashboard(
                memberId: ModalRoute.of(context)!.settings.arguments as String,
              ),
          '/members': (context) => MemberListScreen(
                members: const [],
                groupId: ModalRoute.of(context)!.settings.arguments as String,
              ),
          '/add-member': (context) => MemberRegistrationScreen(
                groupId: ModalRoute.of(context)!.settings.arguments as String,
              ),
          '/settings': (context) => const GroupSettingsScreen(),
          '/meeting': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map;
            return MeetingScreen(
              group: args['group'],
              members: args['members'],
            );
          },
          '/reports': (context) => ReportsScreen(
                groupId: ModalRoute.of(context)!.settings.arguments as String,
              ),
        },
      ),
    );
  }
}
