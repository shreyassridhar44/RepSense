import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_config.dart';
import '../../core/theme/app_colors.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  const _ChatMessage(this.text, this.isUser);
}

class CoachPage extends StatefulWidget {
  const CoachPage({super.key});

  @override
  State<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends State<CoachPage> {
  final _input = TextEditingController();
  final _dio = Dio(BaseOptions(baseUrl: AppConfig.coachServiceUrl));
  final List<_ChatMessage> _messages = [
    const _ChatMessage('Hi! I\'m your RepSense AI Coach. Ask me anything about your form, '
        'recovery, or training plan.', false),
  ];
  bool _loading = false;

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text, true));
      _loading = true;
      _input.clear();
    });
    try {
      // POST /coach/ask — see backend/llm_coach_service
      final res = await _dio.post('/coach/ask', data: {'question': text});
      final reply = res.data['answer'] ?? "I'm not sure — try rephrasing that.";
      setState(() => _messages.add(_ChatMessage(reply, false)));
    } catch (_) {
      setState(() => _messages.add(const _ChatMessage(
          "I couldn't reach the coaching service. Check that llm_coach_service is running.",
          false)));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('AI Coach', style: Theme.of(context).textTheme.headlineLarge),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return Align(
                  alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: m.isUser ? AppColors.electricBlue : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(m.text, style: const TextStyle(color: Colors.white)),
                  ),
                );
              },
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SizedBox(
                  height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    decoration: const InputDecoration(hintText: 'Ask your coach…'),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _send,
                  icon: const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(backgroundColor: AppColors.electricBlue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
