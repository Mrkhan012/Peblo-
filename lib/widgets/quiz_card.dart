import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/quiz_model.dart';
import '../providers/quiz_provider.dart';
import '../theme/app_theme.dart';

class QuizCard extends StatelessWidget {
  final QuizQuestion question;
  final QuizProvider provider;
  final VoidCallback? onCorrect;
  final VoidCallback? onWrong;

  const QuizCard({
    super.key,
    required this.question,
    required this.provider,
    this.onCorrect,
    this.onWrong,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: provider,
      builder: (context, _) {
        final options = question.options;
        final useGrid = options.length >= 4;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.08),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.6),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              const SizedBox(height: 18),
              if (useGrid)
                _buildGrid(context, options)
              else
                _buildColumn(context, options),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.psychology_alt_rounded,
            color: AppColors.accentDark,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            question.question,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildColumn(BuildContext context, List<String> options) {
    return Column(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          _buildOption(context, options[i], i),
          if (i != options.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildGrid(BuildContext context, List<String> options) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.4,
      ),
      itemCount: options.length,
      itemBuilder: (context, i) =>
          _buildOption(context, options[i], i, fillWidth: false),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String option,
    int index, {
    bool fillWidth = true,
  }) {
    final selected = provider.selectedOption;
    final isThisCorrect = option == question.answer;
    final isThisSelected = selected == option;
    final isWronglySelected = provider.status == QuizStatus.wrong &&
        isThisSelected &&
        !isThisCorrect;
    final isSuccessSelected = provider.status == QuizStatus.success &&
        isThisSelected;
    final showCorrect = provider.status == QuizStatus.success && isThisCorrect;

    Color bg = Colors.white;
    Color border = AppColors.primary.withValues(alpha: 0.16);
    Color text = AppColors.inkDark;
    Widget? trailing;

    if (isWronglySelected) {
      bg = AppColors.error.withValues(alpha: 0.10);
      border = AppColors.error;
    } else if (isSuccessSelected || showCorrect) {
      bg = AppColors.success.withValues(alpha: 0.12);
      border = AppColors.success;
    }

    if (isWronglySelected) {
      trailing = const Icon(Icons.close_rounded, color: AppColors.error);
    } else if (isSuccessSelected || showCorrect) {
      trailing = const Icon(Icons.check_rounded, color: AppColors.success);
    } else {
      trailing = _LetterBadge(letter: String.fromCharCode(65 + index));
    }

    final btn = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: provider.status == QuizStatus.success
            ? null
            : () {
                HapticFeedback.lightImpact();
                final wasCorrect = option == question.answer;
                provider.submit(option, question.answer);
                if (wasCorrect) {
                  HapticFeedback.mediumImpact();
                  onCorrect?.call();
                } else {
                  HapticFeedback.heavyImpact();
                  onWrong?.call();
                }
              },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: fillWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: 1.6),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: border.withValues(alpha: 0.10),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              trailing,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: text,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return btn;
  }
}

class _LetterBadge extends StatelessWidget {
  final String letter;
  const _LetterBadge({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Text(
        letter,
        style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: AppColors.primaryDark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
