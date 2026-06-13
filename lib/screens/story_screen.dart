import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';

import '../providers/story_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/buddy_widget.dart';
import '../widgets/story_card.dart';
import '../widgets/quiz_card.dart';
import '../theme/app_theme.dart';

class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StoryProvider>(context, listen: false).loadInitial();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Stack(
      children: [
        _buildMainContent(context),
        if (_showConfetti)
          ConfettiWidget(
            confettiController: _confetti,
            blastDirection: -1,
            emissionFrequency: 0.02,
            numberOfParticles: 50,
            colors: [
              AppColors.primary,
              AppColors.accent,
              AppColors.mint,
              AppColors.pink
            ],
            gravity: 0.2,
          ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final storyProvider = Provider.of<StoryProvider>(context);
    final quizProvider = Provider.of<QuizProvider>(context);

    BuddyMood mood = BuddyMood.idle;
    if (storyProvider.phase == StoryPhase.playing) {
      mood = BuddyMood.listening;
    } else if (storyProvider.phase == StoryPhase.completed) {
      if (quizProvider.isCorrect) {
        mood = BuddyMood.cheering;
      } else {
        mood = BuddyMood.idle;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeOut,
        child: _buildPhaseContent(storyProvider, quizProvider, mood),
      ),
    );
  }

  Widget _buildPhaseContent(
    StoryProvider storyProvider,
    QuizProvider quizProvider,
    BuddyMood mood,
  ) {
    final phase = storyProvider.phase;
    final isError = phase == StoryPhase.error;
    final isLoading =
        phase == StoryPhase.loadingStory || phase == StoryPhase.preparing;
    final isCompleted = phase == StoryPhase.completed;

    if (isError) {
      return _buildErrorUI(storyProvider.errorMessage);
    }

    if (isLoading) {
      return _buildLoadingUI();
    }

    if (isCompleted) {
      final currentQuiz = storyProvider.currentQuiz;
      if (currentQuiz == null) {
        return _buildAllQuizzesDoneUI();
      }
      return Column(
        key: const ValueKey('quiz_view'),
        children: [
          _buildHeaderRow(mood),
          const SizedBox(height: 20),
          _buildQuizProgress(storyProvider),
          const SizedBox(height: 20),
          _buildSuccessMessage(quizProvider),
          const SizedBox(height: 20),
          QuizCard(
            key: ValueKey('quiz_${currentQuiz.id}'),
            question: currentQuiz,
            provider: quizProvider,
            onCorrect: _onCorrectAnswer,
            onWrong: () {
              if (!quizProvider.voicePlayed) {
                storyProvider.tts.speakFeedback(false);
                quizProvider.markVoicePlayed();
              }
            },
          ),
          if (quizProvider.isCorrect) ...[
            const SizedBox(height: 24),
            _buildNextButton(storyProvider, quizProvider),
          ],
        ],
      );
    }

    return Column(
      key: const ValueKey('story_view'),
      children: [
        _buildHeaderRow(mood),
        const SizedBox(height: 24),
        if (storyProvider.story != null)
          StoryCard(
            title: storyProvider.story!.title,
            body: storyProvider.story!.text,
            shakeTrigger: quizProvider.shakeTick,
          ),
        const SizedBox(height: 32),
        _buildControlRow(storyProvider),
      ],
    );
  }

  Widget _buildHeaderRow(BuddyMood mood) {
    return Row(
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: BuddyWidget(mood: mood, size: 140),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: Text(
                  'AI Story Buddy',
                  style: Theme.of(context)
                      .textTheme
                      .displayLarge!
                      .copyWith(fontSize: 32, color: Colors.white),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enjoy a magical story!',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuizProgress(StoryProvider storyProvider) {
    final total = storyProvider.quizzes.length;
    final current = storyProvider.currentQuizIndex + 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isDone = i < current;
        final isActive = i == current - 1;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isActive ? 28 : 14,
            height: 10,
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.success
                  : (isActive
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.18)),
              borderRadius: BorderRadius.circular(5),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSuccessMessage(QuizProvider quizProvider) {
    final isCorrect = quizProvider.isCorrect;
    if (isCorrect) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.success.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Amazing! You got it!',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: AppColors.success,
                    ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.error.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Try again, you can do it!',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: AppColors.error,
                    ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildControlRow(StoryProvider storyProvider) {
    if (storyProvider.isPlaying) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.mint),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Pip is telling you the story...',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: storyProvider.stopStory,
            icon: const Icon(Icons.stop_circle_outlined, size: 22),
            label: const Text('Stop'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: storyProvider.playStory,
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: const Text('Read Me a Story'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: storyProvider.skipToQuiz,
          icon: const Icon(Icons.skip_next_rounded, size: 20),
          label: const Text('Skip to Quiz'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 1.6,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingUI() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your story...',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorUI(String? message) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Oops!',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 12),
          Text(
            message ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          if (message?.contains('TTS') == true || message?.contains('engine') == true)
            OutlinedButton(
              onPressed: () {
                Provider.of<StoryProvider>(context, listen: false).skipToQuiz();
              },
              child: const Text('Skip to Quiz'),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                Provider.of<StoryProvider>(context, listen: false).retry();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
        ],
      ),
    );
  }

  Widget _buildNextButton(
      StoryProvider storyProvider, QuizProvider quizProvider) {
    final hasMore = storyProvider.hasMoreQuizzes;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: AppColors.accentGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          if (hasMore) {
            storyProvider.moveToNextQuiz();
            quizProvider.resetForNewQuestion();
          } else {
            storyProvider.moveToNextQuiz();
          }
        },
        icon: Icon(
          hasMore
              ? Icons.arrow_forward_rounded
              : Icons.flag_rounded,
        ),
        label: Text(hasMore ? 'Next Question' : 'Finish'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: AppColors.inkDark,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }

  Widget _buildAllQuizzesDoneUI() {
    final quizProvider = Provider.of<QuizProvider>(context);
    final total = Provider.of<StoryProvider>(context).quizzes.length;
    final correct = quizProvider.correctCount;
    final firstTry = quizProvider.firstTryCount;
    final score = total > 0 ? ((correct / total) * 100).round() : 0;
    final stars = score >= 80 ? 3 : (score >= 50 ? 2 : 1);
    String title;
    String subtitle;
    if (score == 100) {
      title = 'Perfect score!';
      subtitle = 'You got every question right!';
    } else if (score >= 80) {
      title = 'Amazing work!';
      subtitle = 'Pip is so proud of you!';
    } else if (score >= 50) {
      title = 'Good job!';
      subtitle = 'Keep practicing, you will get there!';
    } else {
      title = 'Nice try!';
      subtitle = 'Listen to the story again and try once more!';
    }

    return Column(
      key: const ValueKey('all_done'),
      children: [
        _buildHeaderRow(BuddyMood.cheering),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accent, AppColors.coral],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.5),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            color: Colors.white,
            size: 64,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final filled = i < stars;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                color: filled ? AppColors.accent : AppColors.inkSoft,
                size: 44,
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              _scoreRow('Score', '$score%', AppColors.primary, big: true),
              const SizedBox(height: 10),
              _scoreRow(
                  'Correct answers', '$correct / $total', AppColors.success),
              const SizedBox(height: 6),
              _scoreRow('First-try wins', '$firstTry / $total', AppColors.mint),
            ],
          ),
        ),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            Provider.of<StoryProvider>(context, listen: false).loadInitial();
            Provider.of<QuizProvider>(context, listen: false).reset();
          },
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Play Again'),
        ),
      ],
    );
  }

  Widget _scoreRow(String label, String value, Color color,
      {bool big = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w500,
              ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: big ? 28 : 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  void _onCorrectAnswer() {
    _showConfetti = true;
    setState(() {});
    _confetti.play();

    Future.delayed(const Duration(seconds: 2), () {
      _showConfetti = false;
      setState(() {});
    });
  }
}
