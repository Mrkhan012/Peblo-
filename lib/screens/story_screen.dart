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
    return ChangeNotifierProvider(
      create: (_) => QuizProvider(),
      child: Stack(
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
      ),
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
      return Column(
        key: const ValueKey('quiz_view'),
        children: [
          _buildHeaderRow(mood),
          const SizedBox(height: 30),
          _buildSuccessMessage(quizProvider),
          const SizedBox(height: 30),
          QuizCard(
            question: storyProvider.quiz!,
            provider: quizProvider,
            onCorrect: _onCorrectAnswer,
          ),
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

    return ElevatedButton(
      onPressed: storyProvider.playStory,
      child: const Text('Read Me a Story'),
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

    Future.delayed(const Duration(seconds: 2), () {
      _showConfetti = false;
      setState(() {});
    });
  }
}
