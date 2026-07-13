import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../models/interview_config.dart';
import '../providers/interview_provider.dart';
import '../utils/constants.dart';
import '../widgets/brand_logo.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_glow_button.dart';
import 'interview_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  static const routeName = '/setup';

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roleController = TextEditingController(text: 'Flutter Developer');
  final _topicController = TextEditingController();

  String _selectedMode = AppConstants.interviewModes.first;
  String _selectedDifficulty = AppConstants.difficulties[1];
  String _selectedPersona = AppConstants.personas.first;
  bool _includeCamera = false;
  double _questionCount = 5;
  String? _resumePath;
  String? _resumeFileName;
  bool _resumeUploaded = false;

  @override
  void dispose() {
    _roleController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _pickResumeFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'pdf'],
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _resumePath = result.files.single.path!;
      _resumeFileName = result.files.single.name;
      _resumeUploaded = false;
    });
  }

  Future<void> _pickAndUploadResume(InterviewProvider provider) async {
    await _pickResumeFile();
    if (_resumePath == null || !mounted) {
      return;
    }
    await _uploadResumeIfNeeded(provider);
  }

  Future<bool> _uploadResumeIfNeeded(InterviewProvider provider) async {
    if (_resumePath == null) {
      return true;
    }

    await provider.uploadResume(_resumePath!);
    if (!mounted) {
      return false;
    }

    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage!)),
      );
      return false;
    }

    setState(() {
      _resumeUploaded = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Resume uploaded successfully: ${_resumeFileName ?? 'resume'}'),
      ),
    );
    return true;
  }

  Future<void> _startInterview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<InterviewProvider>();
    final config = InterviewConfig(
      mode: _selectedMode,
      role: _roleController.text.trim(),
      difficulty: _selectedDifficulty,
      persona: _selectedPersona,
      questionCount: _questionCount.round(),
      customTopic:
          _selectedMode == 'Custom Topic' ? _topicController.text.trim() : null,
      includeCamera: _includeCamera,
      resumePath: _resumePath,
    );

    if (config.resumePath != null && !_resumeUploaded) {
      final uploaded = await _uploadResumeIfNeeded(provider);
      if (!uploaded) {
        return;
      }
    }

    await provider.startInterview(config);
    if (!mounted) {
      return;
    }
    if (provider.errorMessage == null) {
      Navigator.pushNamed(context, InterviewScreen.routeName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InterviewProvider>();

    return Scaffold(
      appBar: AppBar(title: const BrandAppBarTitle()),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF07131A), Color(0xFF05080F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Build Your Session',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Configure a premium mock interview with the exact role, tone, and challenge level you want.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        value: _selectedMode,
                        items: AppConstants.interviewModes
                            .map(
                              (mode) => DropdownMenuItem(
                                value: mode,
                                child: Text(mode),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedMode = value);
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Interview Mode'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _roleController,
                        decoration: const InputDecoration(
                          labelText: 'Target Role',
                          hintText: 'e.g. Product Designer',
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Enter a target role'
                            : null,
                      ),
                      if (_selectedMode == 'Custom Topic') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _topicController,
                          decoration: const InputDecoration(
                            labelText: 'Custom Topic',
                            hintText: 'e.g. System design for fintech',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Enter a custom topic'
                                  : null,
                        ),
                      ],
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedDifficulty,
                        items: AppConstants.difficulties
                            .map(
                              (difficulty) => DropdownMenuItem(
                                value: difficulty,
                                child: Text(difficulty),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedDifficulty = value);
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Difficulty'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedPersona,
                        items: AppConstants.personas
                            .map(
                              (persona) => DropdownMenuItem(
                                value: persona,
                                child: Text(persona),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPersona = value);
                          }
                        },
                        decoration:
                            const InputDecoration(labelText: 'Interviewer Persona'),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Question Count: ${_questionCount.round()}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Slider(
                        value: _questionCount,
                        min: 5,
                        max: 10,
                        divisions: 5,
                        activeColor: const Color(0xFF00E5FF),
                        onChanged: (value) => setState(() => _questionCount = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _includeCamera,
                        activeColor: const Color(0xFF00E5FF),
                        onChanged: (value) => setState(() => _includeCamera = value),
                        title: const Text('Capture camera frames during answers'),
                        subtitle: const Text(
                          'Useful for sending optional visual context to the backend.',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _resumeFileName ?? 'No resume selected',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: provider.isBusy
                                ? null
                                : () => _pickAndUploadResume(provider),
                            icon: const Icon(Icons.upload_file_rounded),
                            label: const Text('Upload Resume'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _resumeUploaded
                              ? 'Resume uploaded successfully. Follow-up questions will use its content.'
                              : 'Accepted for demo: .txt and .pdf resumes. Pick a file to use resume-based follow-up questions.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryGlowButton(
                    label: 'Begin Interview',
                    icon: Icons.auto_awesome_rounded,
                    isLoading: provider.isBusy,
                    onPressed: provider.isBusy ? null : () => _startInterview(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
