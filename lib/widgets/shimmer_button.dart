import 'package:flutter/material.dart';

class ShimmerButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color baseColor;
  final Color shimmerColor;
  final IconData? icon;
  final EdgeInsets padding;

  const ShimmerButton({
    super.key,
    required this.text,
    this.onPressed,
    this.baseColor = const Color.fromARGB(255, 200, 180, 100),
    this.shimmerColor = Colors.white,
    this.icon,
    this.padding = const EdgeInsets.symmetric(vertical: 18),
  });

  @override
  State<ShimmerButton> createState() => _ShimmerButtonState();
}

class _ShimmerButtonState extends State<ShimmerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
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
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: widget.baseColor.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.baseColor,
              foregroundColor: Colors.black,
              padding: widget.padding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              overlayColor: Colors.transparent,
            ),
            child: Stack(
              children: [
                // Основной текст
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 16),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      widget.text,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
                // Shimmer
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        final shimmerX = -1.0 + _controller.value * 3.0;
                        return LinearGradient(
                          colors: [
                            Colors.transparent,
                            widget.shimmerColor.withOpacity(0.6),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                          begin: Alignment(shimmerX - 1, 0),
                          end: Alignment(shimmerX + 1, 0),
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcATop,
                      child: Container(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}