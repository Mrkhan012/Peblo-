import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/quiz_model.dart';
import '../providers/quiz_provider.dart';
import '../theme/app_theme.dart';

/// The data-driven quiz card.
///
/// This widget knows NOTHING about the number of options, the
/// question text, or the answer. It receives a [QuizQuestion]
/// and renders whatever the data says. To support a new question
/// shape, you change the model — not the widget.
///
/// Why a 2-column grid for 4+ options?
///  - 2 options: 1 column
///  - 3 options: 1 column (roomy, kid-friendly tap targets)
///  - 4-6 options: 2 columns — keeps the card compact on small
///    Android screens, the most common device class in our
///    target audience.
class QuizCard extends StatelessWidget {
  final QuizQuestion question;
  final QuizProvider provider;
  final VoidCallback? onCorrect;

  const QuizCard({
    super.key,
    required this.question,
    required this.provider,
    this.onCorrect,
  });

  @override
  Widget build(BuildContext context) {
    // Re-render only when this provider's fields change — keeps
    // parent rebuilds from cascading.
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
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
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
            color: AppColors.accent.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.psychology_alt_outlined,
            color: AppColors.primaryDark,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            question.question,
            style: Theme.of(context).textTheme.titleLarge,
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
    Color border = AppColors.primary.withValues(alpha: 0.18);
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
                provider.submit(option, question.answer);
                if (option == question.answer) {
                  HapticFeedback.mediumImpact();
                  onCorrect?.call();
                }
              },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: fillWidth ? double.infinity : null,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: 1.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              trailing,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  option,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                        color: text,
                        fontWeight: FontWeight.w600,
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
      width: 28,
      height: 28,
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
            ),
      ),
    );
  }
}
