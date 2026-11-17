import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/ai_chat_models.dart';
import 'ai_recommendation_primitives.dart';

/// Neo-Brutalist catalog package header banner above recommended consultants.
class AiCatalogPackageBanner extends StatelessWidget {
  final AiPackageRecommendation package;

  const AiCatalogPackageBanner({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    final categoryLabel = _resolveCategoryLabel(package);
    final metaLabel = _resolveMetaLabel(package);
    final priceLabel = package.priceIdr > 0
        ? CurrencyFormatter.format(
            package.priceIdr,
            currencyCode: 'IDR',
            isIdrBase: true,
          )
        : 'Sesuai paket';
    final titleText = package.packageTitle.trim().isNotEmpty
        ? package.packageTitle.trim()
        : categoryLabel;
    final textScale = aiEffectiveTextScale(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: NeoBrutalism.cardDecoration(
        backgroundColor: NeoBrutalism.darkTeal,
        borderRadius: NeoBrutalism.radiusLg,
        shadowOffset: 3.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AiNeoBadge(
                label: categoryLabel,
                backgroundColor: NeoBrutalism.lime,
              ),
              if (metaLabel.isNotEmpty)
                AiNeoBadge(
                  label: metaLabel,
                  backgroundColor: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final titleWidget = Text(
                titleText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: aiCardTextStyle(
                  context,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.25,
                ),
              );
              final priceBadge = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: NeoBrutalism.border(width: 1.5),
                ),
                child: Text(
                  priceLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: aiCardTextStyle(
                    context,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: NeoBrutalism.dark,
                  ),
                ),
              );

              if (constraints.maxWidth < 250 || textScale >= 1.35) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 8),
                    priceBadge,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: titleWidget),
                  const SizedBox(width: 10),
                  Flexible(flex: 0, child: priceBadge),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static String _resolveCategoryLabel(AiPackageRecommendation pkg) {
    if (pkg.categoryTag.trim().isNotEmpty) return pkg.categoryTag.trim();
    if (pkg.packageCode.trim().isNotEmpty) return pkg.packageCode.trim();
    return 'Paket Rekomendasi';
  }

  static String _resolveMetaLabel(AiPackageRecommendation pkg) {
    final parts = <String>[];
    if (pkg.sessionCount > 0) parts.add('${pkg.sessionCount} sesi');
    if (pkg.durationMinutes > 0) parts.add('${pkg.durationMinutes} menit');
    return parts.join(' • ');
  }
}
