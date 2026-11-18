import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/ai_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// UI-07 AI Order Assistant (FR-AI-02).
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [
    const ChatMessage(
        fromUser: false,
        text: 'Hi! I can help with flavours, prices and how to order. What would you like to know?'),
  ];
  bool _thinking = false;

  static const _quick = {
    'Prices': 'How much are your rolls?',
    'How to order': 'How do I place a pre-order?',
    'Delivery': 'How does delivery work?',
  };

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final q = text.trim();
    if (q.isEmpty || _thinking) return;
    _input.clear();
    setState(() {
      _messages.add(ChatMessage(fromUser: true, text: q));
      _thinking = true;
    });
    _toBottom();
    // Send only the recent conversation, without the greeting.
    final history = _messages.skip(1).toList();
    final reply = await context.read<AiService>().ask(
        history.length > 10 ? history.sublist(history.length - 10) : history);
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(fromUser: false, text: reply));
      _thinking = false;
    });
    _toBottom();
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        }
      });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return CnnoPage(
      title: 'Order Assistant',
      bottom: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              textInputAction: TextInputAction.send,
              onSubmitted: _send,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Ask about CNNO',
                counterText: '',
                fillColor: CnnoColors.softPink.withValues(alpha: 0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                enabledBorder:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Send',
            onPressed: _thinking ? null : () => _send(_input.text),
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              itemCount: _messages.length + (_thinking ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return _Bubble(fromUser: false, child: Text('Typing...', style: t.bodyMedium?.copyWith(color: CnnoColors.muted)));
                }
                final m = _messages[i];
                return _Bubble(
                  fromUser: m.fromUser,
                  child: Text(m.text,
                      style: t.bodyMedium?.copyWith(color: m.fromUser ? Colors.white : CnnoColors.text)),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                for (final e in _quick.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(label: Text(e.key), onPressed: () => _send(e.value)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Text('AI answers come from the CNNO menu and can be wrong. Contact CNNO if unsure.',
                style: t.bodySmall?.copyWith(color: CnnoColors.muted, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.fromUser, required this.child});
  final bool fromUser;
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
        alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: fromUser ? CnnoColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: fromUser ? null : Border.all(color: CnnoColors.softPink),
          ),
          child: child,
        ),
      );
}
