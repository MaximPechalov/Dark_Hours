import 'package:flutter/material.dart';

class AnimatedStatBar extends StatefulWidget {
  final String icon;
  final int value;
  final Color color;
  final int maxValue;

  const AnimatedStatBar({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
    this.maxValue = 100,
  });

  @override
  State<AnimatedStatBar> createState() => _AnimatedStatBarState();
}

class _AnimatedStatBarState extends State<AnimatedStatBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late int _displayValue;
  late double _previousPercent;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value;
    _previousPercent = widget.value / widget.maxValue;

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _updatePulseState();
  }

  @override
  void didUpdateWidget(AnimatedStatBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousPercent = oldWidget.value / widget.maxValue;
      setState(() => _displayValue = widget.value);
      _updatePulseState();
    }
  }

  void _updatePulseState() {
    if (widget.value < 20 && widget.value > 0) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = (widget.value / widget.maxValue).clamp(0.0, 1.0);
    final isCritical = widget.value < 20 && widget.value > 0;
    final isZero = widget.value <= 0;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseOpacity = isCritical
            ? 0.6 + (_pulseController.value * 0.4)
            : 1.0;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.icon, style: const TextStyle(fontSize: 10)),
                const SizedBox(width: 2),
                AnimatedOpacity(
                  opacity: pulseOpacity,
                  duration: const Duration(milliseconds: 100),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: isZero
                          ? Colors.grey
                          : (isCritical ? Colors.red : widget.color),
                      fontSize: _displayValue != widget.value ? 13 : 11,
                      fontWeight: FontWeight.bold,
                    ),
                    child: Text('$_displayValue'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: _previousPercent,
                  end: percent,
                ),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.grey[900],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isZero
                          ? Colors.grey
                          : (isCritical ? Colors.red : widget.color),
                    ),
                    minHeight: 3,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}