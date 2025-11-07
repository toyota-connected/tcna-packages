import 'package:flutter/cupertino.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF5F7FA), Color(0xFFE8EBF0)],
        ),
      ),
      child: const Center(
        child: Text('Notifications Screen', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
