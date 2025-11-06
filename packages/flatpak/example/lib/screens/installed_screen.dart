import 'package:flutter/material.dart';

class InstalledScreen extends StatelessWidget {
  const InstalledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Center(
        child: Text(
          'Profile Screen',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}