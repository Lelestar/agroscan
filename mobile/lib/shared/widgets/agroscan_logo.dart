import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants.dart';

/// Brand mark from [AgroConstants.logoAsset] (SVG).
class AgroScanLogo extends StatelessWidget {
  const AgroScanLogo({
    super.key,
    this.size = 28,
    this.fit = BoxFit.contain,
  });

  final double size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        AgroConstants.logoAsset,
        fit: fit,
      ),
    );
  }
}
