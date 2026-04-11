import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    );
    runApp(const MyApp());
  } catch (error) {
    runApp(BootstrapErrorApp(error: error));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase AI Explore',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF005BBB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
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
                    'If you are running this on Android, make sure Firebase App Check is configured, '
                    'the debug token is registered in Firebase Console, and the Firebase config '
                    'matches the target platform.',
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

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Model from the Firebase AI Logic getting-started docs.
  static const String _modelName = 'gemini-3-flash-preview';

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  late final GenerativeModel _model;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final ai = FirebaseAI.googleAI(
      appCheck: FirebaseAppCheck.instance,
      useLimitedUseAppCheckTokens: true,
    );
    _model = ai.generativeModel(model: _modelName);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? prompt]) async {
    final text = (prompt ?? _controller.text).trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_ChatMessage.user(text));
      _isSending = true;
    });
    _controller.clear();

    _scrollToBottom();

    try {
      final response = await _model.generateContent([Content.text(text)]);
      final answer = response.text?.trim();
      setState(() {
        _messages.add(
          _ChatMessage.ai(
            answer == null || answer.isEmpty
                ? 'Model tidak mengembalikan teks.'
                : answer,
          ),
        );
      });
    } catch (error) {
      setState(() {
        _messages.add(
          _ChatMessage.ai('An error occurred while calling Firebase AI: $error'),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 96,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF4FF), Color(0xFFF7FAFF), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Firebase AI Explore',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Firebase Core + App Check + Gemini through Firebase AI Logic',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusChip(
                        icon: Icons.check_circle_rounded,
                        label: 'Firebase ready',
                        color: theme.colorScheme.primary,
                      ),
                      _StatusChip(
                        icon: Icons.verified_user_rounded,
                        label: 'App Check',
                        color: theme.colorScheme.tertiary,
                      ),
                      _StatusChip(
                        icon: Icons.smart_toy_rounded,
                        label: _modelName,
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: _messages.isEmpty
                        ? _EmptyState(onPromptSelected: _sendMessage)
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return _MessageBubble(message: message);
                            },
                          ),
                  ),
                ),
              ),
              if (_isSending)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _QuickPrompt(
                          label: 'Summarize this project',
                          onTap: () => _sendMessage(
                            'Provide a short summary of what is already set up in this Flutter project.',
                          ),
                        ),
                        _QuickPrompt(
                          label: 'Explain Firebase AI',
                          onTap: () => _sendMessage(
                            'Briefly explain how Firebase AI Logic is used in Flutter.',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.06),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              minLines: 1,
                              maxLines: 5,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              decoration: const InputDecoration(
                                hintText: 'Ask Firebase AI something...',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: _isSending ? null : _sendMessage,
                            icon: const Icon(Icons.send_rounded),
                            label: const Text('Send'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.isUser,
    required this.text,
  });

  factory _ChatMessage.user(String text) => _ChatMessage(isUser: true, text: text);

  factory _ChatMessage.ai(String text) => _ChatMessage(isUser: false, text: text);

  final bool isUser;
  final String text;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final backgroundColor =
        isUser ? theme.colorScheme.primary : const Color(0xFFF2F5FA);
    final foregroundColor = isUser ? Colors.white : theme.colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isUser ? 20 : 6),
              bottomRight: Radius.circular(isUser ? 6 : 20),
            ),
          ),
          child: Text(
            message.text,
            style: theme.textTheme.bodyMedium?.copyWith(color: foregroundColor),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      side: BorderSide(color: color.withValues(alpha: 0.2)),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }
}

class _QuickPrompt extends StatelessWidget {
  const _QuickPrompt({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFD9E2F2)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPromptSelected});

  final Future<void> Function([String? prompt]) onPromptSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Ready to chat with Firebase AI',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try one of the quick prompts below or type your own question.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _QuickPrompt(
                  label: 'Explain Firebase AI',
                  onTap: () => onPromptSelected(
                    'Briefly explain how Firebase AI Logic is used in Flutter.',
                  ),
                ),
                _QuickPrompt(
                  label: 'Create a roadmap',
                  onTap: () => onPromptSelected(
                    'Create a short roadmap for extending this Flutter app with Firebase.',
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
