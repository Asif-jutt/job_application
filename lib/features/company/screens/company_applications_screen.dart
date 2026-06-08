import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompanyApplicationsScreen extends ConsumerWidget {
  const CompanyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Applications')),
      body: const Center(
        child: Text('No applications yet'),
      ),
    );
  }
}
