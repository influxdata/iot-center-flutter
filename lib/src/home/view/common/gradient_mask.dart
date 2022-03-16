import 'package:flutter/material.dart';

class GradientMask extends StatelessWidget {
  GradientMask({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.topRight,
        stops: [
          0,
          0.8,
        ],
        colors: [
          Color.fromRGBO(155, 42, 255, 1),
          Color.fromRGBO(211, 9, 113, 1),
        ],
      ).createShader(bounds),
      child: child,
    );
  }
}
