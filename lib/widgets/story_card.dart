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
    this.shakeTrigger = 0,
  });

  @override
  State<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void didUpdateWidget(covariant StoryCard old) {
    super.didUpdateWidget(old);
    if (widget.shakeTrigger != old.shakeTrigger) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final dx = 14 * (1 - t) * _sine(t * 8);
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: _buildCard(),
    );
  }

  double _sine(double x) {
    final xPi = x * 3.141592653589793;
    final xPi2 = xPi * 0.5;
    return (xPi - xPi2 * (xPi2 * xPi2) / 6);
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.body,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
