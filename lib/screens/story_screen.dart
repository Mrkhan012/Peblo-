import 'package:flutter/material.dart';
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
      body: SafeArea(
        child: _buildBody(context),
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
            colors: [AppColors.primary, AppColors.accent, AppColors.mint],
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
        const SizedBox(height: 30),
        if (storyProvider.story != null)
          StoryCard(
            title: storyProvider.story!.title,
            body: storyProvider.story!.text,
            shakeTrigger: quizProvider.shakeTick,
          ),
        const SizedBox(height: 40),
        _buildControlRow(storyProvider),
      ],
    );
  }

  Widget _buildHeaderRow(BuddyMood mood) {
    return Row(
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: BuddyWidget(mood: mood, size: 160),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Story Buddy',
                style: Theme.of(context)
                    .textTheme
                    .displayLarge!
                    .copyWith(fontSize: 36),
              ),
              const SizedBox(height: 10),
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

  Widget _buildSuccessMessage(QuizProvider quizProvider) {
    final isCorrect = quizProvider.isCorrect;
    if (isCorrect) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.celebration_rounded,
              color: AppColors.success,
              size: 24,
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.sentiment_dissatisfied_rounded,
              color: AppColors.error,
              size: 24,
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
          const SizedBox(height: 10),
          Text(
            'Pip is telling you the story...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: storyProvider.stopStory,
            child: Text(
              'Stop',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 18,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        ElevatedButton(
          onPressed: storyProvider.playStory,
          child: const Text('Read Me a Story'),
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
    return const Column(
      children: [
        CircularProgressIndicator(color: AppColors.primary),
        SizedBox(height: 20),
        Text('Loading your story...'),
      ],
    );
  }

  Widget _buildErrorUI(String? message) {
    return Column(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: AppColors.error,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          'Oops!',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          message ?? 'Something went wrong',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
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
          ElevatedButton(
            onPressed: () {
              Provider.of<StoryProvider>(context, listen: false).retry();
            },
            child: const Text('Try Again'),
          ),
      ],
    );
  }

  void _onCorrectAnswer() {
    _showConfetti = true;
    setState(() {});
    _confetti.play();

    final storyProvider = Provider.of<StoryProvider>(context, listen: false);
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    if (!quizProvider.voicePlayed) {
      storyProvider.tts.speakFeedback(true);
      quizProvider.markVoicePlayed();
    }

    Future.delayed(const Duration(seconds: 2), () {
      _showConfetti = false;
      setState(() {});
    });
  }

  Widget _buildQuizProgress(StoryProvider storyProvider) {
    final total = storyProvider.quizzes.length;
    final current = storyProvider.currentQuizIndex + 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < total; i++) ...[
          Container(
            width: i + 1 <= current ? 28 : 12,
            height: 12,
            decoration: BoxDecoration(
              color: i + 1 <= current
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          if (i != total - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }

  Widget _buildNextButton(
      StoryProvider storyProvider, QuizProvider quizProvider) {
    final hasMore = storyProvider.hasMoreQuizzes;
    return ElevatedButton(
      onPressed: () {
        if (hasMore) {
          storyProvider.moveToNextQuiz();
          quizProvider.resetForNewQuestion();
        } else {
          storyProvider.moveToNextQuiz();
        }
      },
      child: Text(hasMore ? 'Next Question' : 'Finish'),
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
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            color: AppColors.success,
            size: 72,
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
        const SizedBox(height: 24),
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
              _scoreRow(
                  'Score', '$score%', AppColors.primary, big: true),
              const SizedBox(height: 10),
              _scoreRow('Correct answers', '$correct / $total',
                  AppColors.success),
              const SizedBox(height: 6),
              _scoreRow('First-try wins', '$firstTry / $total',
                  AppColors.mint),
            ],
          ),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () {
            Provider.of<StoryProvider>(context, listen: false).loadInitial();
            Provider.of<QuizProvider>(context, listen: false).reset();
          },
          child: const Text('Play Again'),
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
}
