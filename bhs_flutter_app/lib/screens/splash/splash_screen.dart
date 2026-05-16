import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/ambedkar.jpg',
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const CircleAvatar(radius: 60, child: Icon(Icons.account_balance, size: 56)),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                ApiConstants.associationName,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
