import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_bootstrap.dart';
import 'company_policy_app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid:
            kDebugMode
                ? const AndroidDebugProvider()
                : const AndroidPlayIntegrityProvider(),
      );
      AppBootstrap.useAppCheck = true;
    } catch (error) {
      AppBootstrap.useAppCheck = false;
      debugPrint('Firebase App Check activation skipped: $error');
    }

    runApp(const CompanyPolicyApp());
  } catch (error) {
    runApp(BootstrapErrorApp(error: error));
  }
}

class BootstrapErrorApp extends StatelessWidget {
  const BootstrapErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Firebase bootstrap failed',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Check Firebase initialization and the platform-specific Firebase options.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
