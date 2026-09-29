import 'package:flutter/material.dart';

class ShimmerButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color baseColor;
  final Color shimmerColor;
  final Color textColor;
  final IconData? icon;
  final EdgeInsets padding;

  const ShimmerButton({
    super.key,
    required this.text,
    this.onPressed,
    this.baseColor = const Color.fromARGB(255, 200, 180, 100),
    this.shimmerColor = Colors.white,
    this.textColor = Colors.black,
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
    // Период 4 секунды: блик занимает ~1.5 сек, остальное — пауза
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000),
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
        // Позиция блика: -0.5 → 1.5 за первую половину цикла,
        // затем пауза
        final progress = _controller.value;
        final shimmerX = progress < 0.4
            ? (-0.5 + (progress / 0.4) * 2.0) // быстрое движение
            : 2.0; // за пределами — невидим

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: widget.baseColor.withOpacity(0.25),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: widget.baseColor,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(8),
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: [
                      Colors.transparent,
                      widget.shimmerColor.withOpacity(0.5),
                      Colors.transparent,
                    ],
                    stops: [
                      (shimmerX - 0.25).clamp(0.0, 1.0),
                      shimmerX.clamp(0.0, 1.0),
                      (shimmerX + 0.25).clamp(0.0, 1.0),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds);
                },
                blendMode: BlendMode.plus,
                child: Container(
                  padding: widget.padding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 18,
                          color: widget.textColor,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: widget.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}