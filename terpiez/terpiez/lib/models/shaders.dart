import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'dart:math';

class ShaderPainter extends CustomPainter {
  ShaderPainter({required this.shader, required this.t});

  FragmentShader shader;
  double t;

  final int start = DateTime.now().millisecondsSinceEpoch;
  double get current => 1.0 * (DateTime.now().millisecondsSinceEpoch - start) / 1000;

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, t * pi ); 
    final paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class ShaderWidget extends StatefulWidget {
  const ShaderWidget({super.key, required this.child});
  final Widget child;

  @override
  State<StatefulWidget> createState() => _ShaderState();
}

class _ShaderState extends State<ShaderWidget> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderBuilder(
        assetKey: 'shaders/checkers.glsl',
        //assetKey: 'shaders/animated_bg.glsl',
        (context, shader, child) => CustomPaint(
          size: MediaQuery.of(context).size,
          painter: ShaderPainter(shader: shader, t: _controller.value),
          child: child,
        ),
      child: child),
    child: widget.child);
  }
}