import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StoryCard extends StatefulWidget {
  final String title;
  final String body;
  final int shakeTrigger;

  const StoryCard({
    super.key,
    required this.title,
    required this.body,
    required this.shakeTrigger,
  });

  @override
  State<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard>
    with TickerProviderStateMixin {
  late final AnimationController _shakeCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<Offset> _slideOffset;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _slideOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 0),
    ).animate(_shakeCtrl);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _setupShake();
    _pulseCtrl.forward();
  }

  @override
  void didUpdateWidget(StoryCard old) {
    super.didUpdateWidget(old);
    if (widget.shakeTrigger != old.shakeTrigger) {
      _setupShake();
    }
  }

  void _setupShake() {
    if (widget.shakeTrigger > 0) {
      _pulseCtrl.reset();
      _shakeCtrl.forward().then((_) {
        _pulseCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _pulseAnimation,
      child: SlideTransition(
        position: _slideOffset,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.06),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.7),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      color: AppColors.accentDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkDark,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Once upon a time...',
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: AppColors.inkSoft,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: 48,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: AppColors.primaryGradient,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.body,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      height: 1.5,
                      color: AppColors.inkDark,
                    ),
              ),
              if (widget.shakeTrigger > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Wrong answer! ',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, child) {
                        return Text(
                          'Try again! ',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mint,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
