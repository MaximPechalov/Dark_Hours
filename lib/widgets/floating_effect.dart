import 'package:flutter/material.dart';

class FloatingEffect extends StatefulWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const FloatingEffect({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  State<FloatingEffect> createState() => _FloatingEffectState();
}

class _FloatingEffectState extends State<FloatingEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_controller);

    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.5),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.forward();
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
        return FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.color,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: widget.color, size: 14),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      widget.text,
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Хелпер для показа всплывающего эффекта
class FloatingEffectOverlay {
  static void show(
    BuildContext context,
    String text, {
    Color color = Colors.green,
    IconData? icon,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.4,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Center(
            child: FloatingEffect(
              text: text,
              color: color,
              icon: icon,
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(milliseconds: 1600), () {
      entry.remove();
    });
  }
}