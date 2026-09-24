import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'services/api_service.dart';
import 'services/auth_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiService();
  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: api),
        ChangeNotifierProvider(create: (_) => AuthState(api)..restore()),
      ],
      child: const RoktoDorkarApp(),
    ),
  );
}

class RoktoDorkarApp extends StatelessWidget {
  const RoktoDorkarApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Rokto Dorkar',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: Consumer<AuthState>(
      builder: (context, auth, _) {
        if (auth.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return auth.signedIn ? const HomeShell() : const AuthScreen();
      },
    ),
  );
}
