import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../widgets/kyy_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.next});

  final Widget next;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  Timer? _navTimer;
  bool _showContinue = false;

  @override
  void initState() {
    super.initState();
    _navTimer = Timer(const Duration(milliseconds: 1400), _navigateNext);
    // If something goes wrong (e.g., init hangs), let user continue manually.
    Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _showContinue = true);
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _navigateNext() {
    if (!mounted) return;
    try {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => widget.next,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved =
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );
    } catch (_) {
      // Fallback: show continue button.
      if (mounted) setState(() => _showContinue = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const KyyBackground(intensity: 0.95),
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = Curves.easeOutBack.transform(_controller.value);
                  final glow = Curves.easeIn.transform(_controller.value);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: 0.85 + 0.2 * t,
                        child: Container(
                          height: 92,
                          width: 92,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            gradient: LinearGradient(
                              colors: [
                                cs.primary.withValues(alpha: 0.95),
                                cs.secondary.withValues(alpha: 0.9),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 28,
                                spreadRadius: 1,
                                color: cs.primary.withValues(alpha: 0.28 * glow),
                              ),
                            ],
                          ),
                          child: const _ScalesMark(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Opacity(
                        opacity: math.min(1, _controller.value * 1.2),
                        child: Column(
                          children: [
                            Text(
                              AppStrings.appTitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppStrings.appSubtitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Opacity(
                        opacity: math.min(1, _controller.value * 1.4),
                        child: SizedBox(
                          width: 180,
                          child: LinearProgressIndicator(
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(999),
                            backgroundColor: cs.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      if (_showContinue) ...[
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _navigateNext,
                          child: const Text('Continue'),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScalesMark extends StatelessWidget {
  const _ScalesMark();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _ScalesPainter(color: cs.onPrimary),
      child: const SizedBox.expand(),
    );
  }
}

class _ScalesPainter extends CustomPainter {
  _ScalesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final top = size.height * 0.28;
    final mid = size.height * 0.48;
    final left = size.width * 0.26;
    final right = size.width * 0.74;

    canvas.drawLine(Offset(cx, top), Offset(cx, size.height * 0.78), paint);
    canvas.drawLine(Offset(left, mid), Offset(right, mid), paint);

    final bowlPaint = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final bowlR = size.width * 0.13;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(left, size.height * 0.62), radius: bowlR),
      0,
      math.pi,
      false,
      bowlPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(right, size.height * 0.62), radius: bowlR),
      0,
      math.pi,
      false,
      bowlPaint,
    );

    final linkPaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(left, mid), Offset(left, size.height * 0.52), linkPaint);
    canvas.drawLine(
        Offset(right, mid), Offset(right, size.height * 0.52), linkPaint);

    final basePaint = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..strokeWidth = 3.5;
    canvas.drawLine(
      Offset(cx - size.width * 0.18, size.height * 0.78),
      Offset(cx + size.width * 0.18, size.height * 0.78),
      basePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScalesPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
