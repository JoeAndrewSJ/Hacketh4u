import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CommunityChatScreen extends StatelessWidget {
  const CommunityChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Chat'),
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Community Chat Screen'),
      ),
    );
  }
}
