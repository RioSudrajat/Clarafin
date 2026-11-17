import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import 'ai_recommendation_primitives.dart';

/// Practitioner avatar with safe asset/network error fallback to initials badge.
class AiConsultantAvatar extends StatelessWidget {
  final String name;
  final String avatarUrl;

  const AiConsultantAvatar({
    super.key,
    required this.name,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = avatarUrl.trim();
    final initials = extractInitials(name);

    Widget fallback() => ColoredBox(
      color: NeoBrutalism.primaryLight,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              initials,
              style: aiCardTextStyle(
                context,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: NeoBrutalism.dark,
              ),
            ),
          ),
        ),
      ),
    );

    final isAsset = trimmedUrl.startsWith('assets/');
    final isNetwork =
        trimmedUrl.startsWith('https://') || trimmedUrl.startsWith('http://');

    return ExcludeSemantics(
      child: Container(
        width: 48,
        height: 48,
        decoration: NeoBrutalism.circleDecoration(
          backgroundColor: NeoBrutalism.primaryLight,
          shadowOffset: 0,
        ),
        child: ClipOval(
          child: isAsset
              ? Image.asset(
                  trimmedUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback(),
                )
              : isNetwork
              ? Image.network(
                  trimmedUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback(),
                )
              : fallback(),
        ),
      ),
    );
  }

  /// Extracts up to two non-honorific initials from a practitioner display name.
  static String extractInitials(String rawName) {
    final primaryName = rawName.split(',').first.trim();
    if (primaryName.isEmpty) return 'K';
    final tokens = primaryName
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final withoutHonorific = tokens.where((w) => !w.endsWith('.')).toList();
    final source = withoutHonorific.isNotEmpty ? withoutHonorific : tokens;
    return source.take(2).map((w) => w[0].toUpperCase()).join();
  }
}
