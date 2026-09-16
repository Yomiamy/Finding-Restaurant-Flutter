import 'dart:math';
import 'package:flutter/material.dart';

import '../../../features/foundation/foundation_barrel.dart';

/// 命運大轉盤彈窗元件
class DecisionRouletteDialog extends StatefulWidget {
  const DecisionRouletteDialog({
    super.key,
    required this.title,
    required this.options,
    required this.onWinnerSelected,
  });

  final String title;
  final List<String> options;
  final void Function(String winner) onWinnerSelected;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<String> options,
    required void Function(String winner) onWinnerSelected,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => DecisionRouletteDialog(
        title: title,
        options: options,
        onWinnerSelected: onWinnerSelected,
      ),
    );
  }

  @override
  State<DecisionRouletteDialog> createState() => _DecisionRouletteDialogState();
}

class _DecisionRouletteDialogState extends State<DecisionRouletteDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  double _startAngle = 0;
  double _targetAngle = 0;
  bool _isSpinning = false;
  String? _winner;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCirc,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final totalAngle = _targetAngle % (2 * pi);
        final sliceAngle = 2 * pi / widget.options.length;
        // 頂部指針位於 3*pi/2 (270度) 或 -pi/2
        final normalizedAngle = (2 * pi - (totalAngle % (2 * pi))) % (2 * pi);
        // 指針指向上方 (12點鐘方向)
        final pointerAngle = (normalizedAngle + 3 * pi / 2) % (2 * pi);
        final winnerIndex = (pointerAngle / sliceAngle).floor() % widget.options.length;
        final selected = widget.options[winnerIndex];

        setState(() {
          _isSpinning = false;
          _winner = selected;
        });

        widget.onWinnerSelected(selected);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning || widget.options.isEmpty) return;

    final random = Random();
    // 轉動 6 ~ 10 圈加上隨機角度
    final extraRounds = 6 + random.nextInt(5);
    final randomAngle = random.nextDouble() * 2 * pi;
    _startAngle = _targetAngle % (2 * pi);
    _targetAngle = _startAngle + (extraRounds * 2 * pi) + randomAngle;

    _animation = Tween<double>(
      begin: _startAngle,
      end: _targetAngle,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    setState(() {
      _isSpinning = true;
      _winner = null;
    });

    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeSize.radius12),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(ThemeSize.space20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.casino_rounded, color: Colors.deepOrange),
                      const SizedBox(width: ThemeSize.space8),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: '關閉',
                ),
              ],
            ),
            const SizedBox(height: ThemeSize.space16),
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      final angle = _isSpinning ? _animation.value : _targetAngle;
                      return Transform.rotate(
                        angle: angle,
                        child: CustomPaint(
                          size: const Size(250, 250),
                          painter: _RouletteWheelPainter(
                            options: widget.options,
                            colorScheme: colorScheme,
                          ),
                        ),
                      );
                    },
                  ),
                  // 中心裝飾指針
                  Positioned(
                    top: 2,
                    child: CustomPaint(
                      size: const Size(20, 24),
                      painter: _PointerPainter(color: colorScheme.error),
                    ),
                  ),
                  // 中心按鈕圓心
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.restaurant,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ThemeSize.space16),
            if (_winner != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ThemeSize.space16,
                  vertical: ThemeSize.space8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(ThemeSize.radius8),
                ),
                child: Column(
                  children: [
                    Text(
                      '🎉 命運欽點！今晚就吃：',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: ThemeSize.space4),
                    Text(
                      _winner!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Text(
                _isSpinning ? '命運輪盤飛速旋轉中...' : '點擊下方按鈕，讓命運幫您決定！',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: ThemeSize.space20),
            if (_winner != null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSpinning ? null : _spin,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('再轉一次'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ThemeSize.radius8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: ThemeSize.space8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        if (mounted && Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('太棒了！'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ThemeSize.radius8),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              FilledButton.icon(
                onPressed: _isSpinning ? null : _spin,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(_isSpinning ? '轉動中...' : '🎲 轉動命運！'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ThemeSize.radius8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RouletteWheelPainter extends CustomPainter {
  _RouletteWheelPainter({
    required this.options,
    required this.colorScheme,
  });

  final List<String> options;
  final ColorScheme colorScheme;

  static const List<Color> _palette = [
    Color(0xFFFF7043),
    Color(0xFFFFB74D),
    Color(0xFF4DB6AC),
    Color(0xFF81C784),
    Color(0xFF64B5F6),
    Color(0xFFBA68C8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (options.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sliceAngle = 2 * pi / options.length;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < options.length; i++) {
      paint.color = _palette[i % _palette.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sliceAngle,
        sliceAngle,
        true,
        paint,
      );

      // 繪製扇區文字
      canvas.save();
      final textAngle = i * sliceAngle + sliceAngle / 2;
      canvas.translate(center.dx, center.dy);
      canvas.rotate(textAngle);

      final textSpan = TextSpan(
        text: options[i],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black45,
              blurRadius: 2,
            ),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: radius * 0.65);

      textPainter.paint(
        canvas,
        Offset(radius * 0.25, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // 外圈邊框
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _RouletteWheelPainter oldDelegate) =>
      oldDelegate.options != options;
}

class _PointerPainter extends CustomPainter {
  _PointerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PointerPainter oldDelegate) =>
      oldDelegate.color != color;
}
