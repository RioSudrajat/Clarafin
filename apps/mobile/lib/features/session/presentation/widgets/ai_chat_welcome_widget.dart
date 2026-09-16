import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class AiChatWelcomeWidget extends StatelessWidget {
  final ValueChanged<String> onSelectPrompt;

  const AiChatWelcomeWidget({super.key, required this.onSelectPrompt});

  static const List<Map<String, String>> suggestedPrompts = [
    {'emoji': '💰', 'text': 'Analisa pengeluaran bulan ini'},
    {'emoji': '📊', 'text': 'Tips investasi untuk pemula'},
    {'emoji': '🎯', 'text': 'Cara mencapai target tabungan'},
    {'emoji': '💳', 'text': 'Strategi lunasi pinjaman'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: NeoBrutalism.lime,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(0, 3), blurRadius: 0),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.smart_toy_rounded,
                size: 44,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Halo! Saya Clarafin AI 🤖',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Asisten finansial cerdasmu.\nTanyakan analisa pengeluaran, simulasi tabungan, atau tips investasi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
            ),
            itemCount: suggestedPrompts.length,
            itemBuilder: (context, index) {
              final prompt = suggestedPrompts[index];
              return InkWell(
                onTap: () => onSelectPrompt('${prompt['emoji']} ${prompt['text']}'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 0),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(prompt['emoji']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(
                        prompt['text']!,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
