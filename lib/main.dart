import 'package:flutter/material.dart';

import 'package:roadee_flutter/screens/login_screen.dart';
import 'package:roadee_flutter/screens/home_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'constants.dart';

import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  MapboxOptions.setAccessToken(mapBoxToken);
  Stripe.publishableKey = publishableKey;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Roadie',
      theme: ThemeData(
        // primarySwatch: Colors.green,
        fontFamily: 'SF Pro Display',
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Auth state listener
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen(); // User is signed in
        } else {
          return const LoginScreen(); // Not signed in
        }
      },
    );
  }
}
