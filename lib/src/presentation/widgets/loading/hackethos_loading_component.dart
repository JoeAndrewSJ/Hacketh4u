import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';

class HackethosLoadingComponent extends StatefulWidget {
  final String? message;
  final double? size;
  final bool showImage;

  const HackethosLoadingComponent({
    super.key,
    this.message,
    this.size,
    this.showImage = true,
  });

  @override
  State<HackethosLoadingComponent> createState() => _HackethosLoadingComponentState();
}

class _HackethosLoadingComponentState extends State<HackethosLoadingComponent>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? 120.0;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Modern animated loader
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing circle
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 0.8 + (_pulseController.value * 0.2);
                  final opacity = 0.1 + (_pulseController.value * 0.05);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(opacity),
                      ),
                    ),
                  );
                },
              ),

              // Rotating gradient ring
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: Container(
                      width: size * 0.8,
                      height: size * 0.8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            primaryColor.withOpacity(0),
                            primaryColor.withOpacity(0.3),
                            primaryColor,
                            primaryColor.withOpacity(0.3),
                            primaryColor.withOpacity(0),
                          ],
                          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Inner rotating ring (opposite direction)
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -_rotationController.value * 2 * math.pi * 1.5,
                    child: Container(
                      width: size * 0.5,
                      height: size * 0.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            primaryColor.withOpacity(0),
                            primaryColor.withOpacity(0.5),
                            primaryColor.withOpacity(0),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Center logo/image or icon
              if (widget.showImage)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 0.95 + (_pulseController.value * 0.1);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: size * 1,
                        height: size * 1,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/loading.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.flash_on_rounded,
                                size: size * 0.2,
                                color: primaryColor,
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),

        SizedBox(height: size * 0.3),

        // Loading message with wave animation
        if (widget.message != null) ...[
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return Opacity(
                opacity: 0.7 + (_waveController.value * 0.3),
                child: Text(
                  widget.message!,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // Modern animated dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                final delay = index * 0.15;
                final value = (_waveController.value + delay) % 1.0;
                final opacity = 0.3 + (math.sin(value * math.pi) * 0.7);
                final offset = math.sin(value * math.pi) * 6;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Transform.translate(
                    offset: Offset(0, -offset),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(opacity),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(opacity * 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}