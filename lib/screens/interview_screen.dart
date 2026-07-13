import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:animate_do/animate_do.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/message_model.dart';
import '../providers/interview_provider.dart';
import '../utils/helpers.dart';
import '../widgets/brand_logo.dart';
import '../widgets/glass_card.dart';
import '../widgets/mic_button.dart';
import '../widgets/score_badge.dart';
import '../widgets/waveform_widget.dart';
import 'home_screen.dart';
import 'results_screen.dart';

class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key});

  static const routeName = '/interview';
  static const AssetImage chatbotBackground =
      AssetImage('assets/animations/chatbot.gif');

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  late final TextEditingController _responseController;
  late final ScrollController _scrollController;
  Timer? _postureTimer;
  bool _handledCompletion = false;
  bool _isScreenReady = false;
  bool _hasSpokenInitialMessage = false;
  bool _micPermissionDenied = false;
  String _cameraStatus = 'Good';
  String? _lastPostureIssue;
  String? _lastShownError;
  bool _didPrecacheBackground = false;

  @override
  void initState() {
    super.initState();
    _responseController = TextEditingController();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _isScreenReady = true;
      context.read<InterviewProvider>().setTtsEnabled(true);
      _syncMicPermissionState();
      _startPostureMonitoring();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheBackground) {
      return;
    }
    _didPrecacheBackground = true;
    precacheImage(InterviewScreen.chatbotBackground, context);
  }

  @override
  void dispose() {
    final provider = context.read<InterviewProvider>();
    provider.setTtsEnabled(false);
    provider.stopSpeaking();
    provider.stopListening();
    _postureTimer?.cancel();
    _responseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _syncMicPermissionState() async {
    final status = await Permission.microphone.status;
    if (!mounted) {
      return;
    }
    setState(() {
      _micPermissionDenied = !status.isGranted;
    });
  }

  Future<bool> _requestMicPermission() async {
    final currentStatus = await Permission.microphone.status;
    final status = currentStatus.isGranted
        ? currentStatus
        : await Permission.microphone.request();

    if (status.isGranted) {
      if (mounted) {
        setState(() {
          _micPermissionDenied = false;
        });
      }
      return true;
    }

    if (!mounted) {
      return false;
    }

    setState(() {
      _micPermissionDenied = true;
    });

    if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Microphone permission is permanently denied. Enable it in app settings.',
          ),
        ),
      );
      await openAppSettings();
      return false;
    }

    if (status.isRestricted || status.isLimited) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone access is limited on this device.'),
        ),
      );
      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Microphone permission required')),
    );
    return false;
  }

  void _startPostureMonitoring() {
    _postureTimer?.cancel();
    _postureTimer = Timer.periodic(const Duration(seconds: 9), (_) {
      if (!mounted) {
        return;
      }
      final provider = context.read<InterviewProvider>();
      if (!(provider.config?.includeCamera ?? false) || !provider.isCameraReady) {
        return;
      }

      final roll = Random().nextInt(100);
      String nextStatus = 'Good';
      String? issue;

      if (roll > 82) {
        nextStatus = 'Head Down';
        issue = 'Head down';
      } else if (roll > 68) {
        nextStatus = 'Too Much Movement';
        issue = 'Too much movement';
      } else if (roll > 55) {
        nextStatus = 'Not Facing Camera';
        issue = 'Not facing camera';
      }

      if (_cameraStatus != nextStatus) {
        setState(() {
          _cameraStatus = nextStatus;
        });
      }

      if (issue != null && issue != _lastPostureIssue) {
        _lastPostureIssue = issue;
        provider.triggerMotivationalFeedback(issue);
      }

      if (issue == null) {
        _lastPostureIssue = null;
      }
    });
  }

  Future<void> _handleMicTap(InterviewProvider provider) async {
    final hasPermission = await _requestMicPermission();
    if (!hasPermission) {
      return;
    }

    final initialized = await provider.initializeSpeech();
    if (!initialized) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition is unavailable on this device.'),
        ),
      );
      return;
    }

    await provider.toggleListening();
  }

  Future<void> _cancelInterview(InterviewProvider provider) async {
    provider.setTtsEnabled(false);
    await provider.stopSpeaking();
    await provider.stopListening();
    await provider.resetSession();
    if (!mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(
      context,
      HomeScreen.routeName,
      (route) => false,
    );
  }

  Future<bool> _handleExitRequest(InterviewProvider provider) async {
    await _cancelInterview(provider);
    return false;
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 140,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InterviewProvider>(
      child: const _InterviewBackgroundLayer(),
      builder: (context, provider, child) {
        final messages = provider.visibleMessages;

        if (_responseController.text != provider.draftResponse) {
          _responseController.value = TextEditingValue(
            text: provider.draftResponse,
            selection: TextSelection.collapsed(
              offset: provider.draftResponse.length,
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _scrollToBottom();
          if (_isScreenReady &&
              !_hasSpokenInitialMessage &&
              messages.isNotEmpty &&
              !messages.last.isUser) {
            _hasSpokenInitialMessage = true;
            provider.speakCurrentQuestionIfReady();
          }
          if (provider.isInterviewCompleted && !_handledCompletion) {
            _handledCompletion = true;
            Navigator.pushReplacementNamed(context, ResultsScreen.routeName);
          }
          if (provider.errorMessage != null &&
              provider.errorMessage != _lastShownError) {
            _lastShownError = provider.errorMessage;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(provider.errorMessage!)),
            );
            provider.clearError();
          }
        });

        return WillPopScope(
          onWillPop: () => _handleExitRequest(provider),
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              resizeToAvoidBottomInset: true,
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandAppBarTitle(),
                    Text(
                      'Question ${provider.questionCount}/${provider.maxQuestions}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    onPressed:
                        provider.isSpeaking ? () => provider.stopSpeaking() : null,
                    icon: const Icon(Icons.volume_off_rounded),
                    tooltip: 'Stop speech',
                  ),
                ],
              ),
              body: Stack(
                children: [
                  Positioned.fill(
                    child: child!,
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                          child: Column(
                            children: [
                              _InterviewHeader(provider: provider),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: _CancelInterviewButton(
                                  onPressed: () => _cancelInterview(provider),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                                itemCount:
                                    messages.length + (provider.isTyping ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= messages.length) {
                                    return const _TypingBubble();
                                  }
                                  return _ChatBubble(message: messages[index]);
                                },
                              ),
                              if (provider.config?.includeCamera ?? false)
                                Positioned(
                                  top: 8,
                                  right: 16,
                                  child: _CameraOverlay(
                                    controller: provider.cameraController,
                                    status: _cameraStatus,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _Composer(
                          controller: _responseController,
                          isListening: provider.isListening,
                          isBusy: provider.isBusy,
                          micEnabled: !_micPermissionDenied,
                          onChanged: (value) => provider.updateDraft(value),
                          onMicTap: provider.isBusy
                              ? () {}
                              : () => _handleMicTap(provider),
                          onSend:
                              provider.isBusy ? null : () => provider.submitResponse(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InterviewBackgroundLayer extends StatelessWidget {
  const _InterviewBackgroundLayer();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: Opacity(
              opacity: 0.10,
              child: Image(
                image: InterviewScreen.chatbotBackground,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: ColoredBox(
            color: Color(0xB3000000),
          ),
        ),
      ],
    );
  }
}

class _CancelInterviewButton extends StatelessWidget {
  const _CancelInterviewButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.red.withOpacity(0.18),
            border: Border.all(color: Colors.redAccent.withOpacity(0.8)),
          ),
          child: TextButton(
            onPressed: onPressed,
            child: Text(
              'Cancel Interview',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraOverlay extends StatelessWidget {
  const _CameraOverlay({
    required this.controller,
    required this.status,
  });

  final CameraController? controller;
  final String status;

  @override
  Widget build(BuildContext context) {
    final isGood = status == 'Good';
    final statusLabel = isGood ? 'Good' : 'Distracted';
    return GlassContainer(
      radius: 18,
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        width: 126,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 106,
                height: 140,
                child: controller != null && controller!.value.isInitialized
                    ? CameraPreview(controller!)
                    : Container(
                        color: Colors.white.withOpacity(0.04),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.videocam_off_rounded,
                          color: Color(0xFF00E5FF),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isGood ? const Color(0xFF00E5FF) : Colors.orangeAccent,
                    boxShadow: [
                      BoxShadow(
                        color: (isGood ? const Color(0xFF00E5FF) : Colors.orangeAccent)
                            .withOpacity(0.45),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  isGood ? const Color(0xFF00E5FF) : Colors.orangeAccent,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (!isGood)
                        Text(
                          status,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InterviewHeader extends StatelessWidget {
  const _InterviewHeader({required this.provider});

  final InterviewProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.16),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.config?.topicLabel ?? 'Interview',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${provider.config?.persona ?? ''} - ${provider.config?.difficulty ?? ''}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (provider.turns.isNotEmpty)
                ScoreBadge(
                  score: provider.averageScore.round(),
                  label: '${Helpers.formatAverage(provider.turns)} avg',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final MessageModel message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bubbleGradient = isUser
        ? const LinearGradient(
            colors: [Color(0xFF6CE5B1), Color(0xFF56CFE1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              Colors.white.withOpacity(0.14),
              Colors.white.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return FadeInUp(
      key: ValueKey('${message.timestamp.microsecondsSinceEpoch}_${message.role}'),
      duration: const Duration(milliseconds: 300),
      from: 16,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: bubbleGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(24),
                    topRight: const Radius.circular(24),
                    bottomLeft: Radius.circular(isUser ? 24 : 8),
                    bottomRight: Radius.circular(isUser ? 8 : 24),
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser &&
                        message.isQuestion &&
                        message.questionNumber != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Question ${message.questionNumber}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF6CE5B1),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    Text(
                      message.content,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isUser ? Colors.black : null,
                          ),
                    ),
                    if (message.score != null && !message.isQuestion)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ScoreBadge(
                          score: message.score!,
                          label: 'Answer score',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI is typing...'),
                SizedBox(height: 10),
                _ThinkingIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinkingIndicator extends StatefulWidget {
  const _ThinkingIndicator();

  @override
  State<_ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<_ThinkingIndicator> {
  late final Future<bool> _hasLottieAsset;

  @override
  void initState() {
    super.initState();
    _hasLottieAsset = rootBundle
        .loadString('assets/animations/ai_thinking.json')
        .then((_) => true)
        .catchError((_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasLottieAsset,
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return Lottie.asset(
            'assets/animations/ai_thinking.json',
            height: 80,
            fit: BoxFit.contain,
          );
        }

        return const SizedBox(
          width: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TypingDot(),
              _TypingDot(),
              _TypingDot(),
            ],
          ),
        );
      },
    );
  }
}

class _TypingDot extends StatefulWidget {
  const _TypingDot();

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF6CE5B1),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isListening,
    required this.isBusy,
    required this.micEnabled,
    required this.onChanged,
    required this.onMicTap,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isListening;
  final bool isBusy;
  final bool micEnabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onMicTap;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        keyboardInset > 0 ? keyboardInset + 12 : 20,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: const Color(0xFF111827).withOpacity(0.86),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  onChanged: onChanged,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Speak or type your answer...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: isListening
                      ? Container(
                          key: const ValueKey('listening_banner'),
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFFFF4D6D).withOpacity(0.14),
                            border: Border.all(
                              color: const Color(0xFFFF7B72).withOpacity(0.45),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF7B72),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Listening... your speech is being transcribed live.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFFFFB3BE),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Row(
                  children: [
                    Expanded(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: isListening ? 1 : 0.65,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            WaveformWidget(isActive: isListening),
                            const SizedBox(height: 4),
                            Text(
                              isListening
                                  ? 'Your words are appearing in the text box above'
                                  : micEnabled
                                      ? 'Tap the mic, speak, then review or edit before sending'
                                      : 'Enable microphone permission to use voice input',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: micEnabled ? 1 : 0.45,
                      child: MicButton(
                        isListening: isListening,
                        onTap: micEnabled ? onMicTap : () {},
                      ),
                    ),
                    const SizedBox(width: 10),
                    FloatingActionButton.small(
                      heroTag: 'send_answer_button',
                      onPressed: onSend,
                      backgroundColor: const Color(0xFF6CE5B1),
                      foregroundColor: Colors.black,
                      child: isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
