import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job_model.dart';
import '../../auth/provider/auth_provider.dart';
import '../constants/company_constants.dart';
import '../provider/company_jobs_provider.dart';

class CompanyPostJobScreen extends ConsumerStatefulWidget {
  const CompanyPostJobScreen({super.key});

  @override
  ConsumerState<CompanyPostJobScreen> createState() =>
      _CompanyPostJobScreenState();
}

class _CompanyPostJobScreenState extends ConsumerState<CompanyPostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _postJob() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authNotifierProvider).value;
    if (user == null) return;

    setState(() => _isPosting = true);

    final job = JobModel(
      id: '',
      title: _titleController.text,
      company: user.displayName ?? 'Company',
      description: _descriptionController.text,
      location: _locationController.text,
      salary: _salaryController.text.isNotEmpty ? _salaryController.text : null,
      isPremium: true,
      source: JobSource.firestore,
      postedAt: DateTime.now(),
      companyId: user.uid,
    );

    final result = await ref.read(companyPostJobProvider).postPremiumJob(job);
    setState(() => _isPosting = false);

    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted successfully!')),
        );
        _formKey.currentState!.reset();
      },
      failure: (msg, _) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(CompanyConstants.postJobTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: CompanyConstants.jobTitleLabel,
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 4,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(
                  labelText: 'Salary Range',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isPosting ? null : _postJob,
                child: _isPosting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Publish Premium Job'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
