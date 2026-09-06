import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'institution_model.dart';
import 'institution_registry.dart';

class InstitutionLogoWidget extends StatelessWidget {
  final InstitutionModel? institution;
  final String? institutionId;
  final String? walletName;
  final String? walletType;
  final double size;
  final bool showBorder;
  final bool isCircle;
  final double borderWidth;

  const InstitutionLogoWidget({
    super.key,
    this.institution,
    this.institutionId,
    this.walletName,
    this.walletType,
    this.size = 26.0,
    this.showBorder = true,
    this.isCircle = true,
    this.borderWidth = 1.5,
  });

  InstitutionModel _resolveInstitution() {
    if (institution != null) return institution!;
    return InstitutionRegistry.findByWallet(
      institutionId: institutionId,
      name: walletName ?? '',
      type: walletType ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final inst = _resolveInstitution();
    final iconInnerSize = size * 0.62;

    Widget imageContent;
    if (inst.isSvg) {
      imageContent = SvgPicture.asset(
        inst.logoAsset,
        width: iconInnerSize,
        height: iconInnerSize,
        fit: BoxFit.contain,
        placeholderBuilder: (ctx) => Icon(
          inst.fallbackIcon,
          size: iconInnerSize * 0.9,
          color: inst.brandColor,
        ),
      );
    } else {
      imageContent = Image.asset(
        inst.logoAsset,
        width: iconInnerSize,
        height: iconInnerSize,
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) => Icon(
          inst.fallbackIcon,
          size: iconInnerSize * 0.9,
          color: inst.brandColor,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(size * 0.3),
        border: showBorder ? Border.all(color: Colors.black, width: borderWidth) : null,
      ),
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size),
        child: imageContent,
      ),
    );
  }
}
