import '../models/story_model.dart';
import '../models/quiz_model.dart';

/// Mock data source for Peblo's AI Story Buddy challenge.
/// Simulates a network fetch for stories and quizzes.
class MockDataSource {
  /// Our fixed story for this challenge. In a real app, this would be
  /// fetched dynamically from a server.
  static const String storyText =
      "Once upon a time, a clever little robot named Pip lost his shiny blue gear in the Whispering Woods. Pip was known throughout the Digital Village for solving puzzles faster than any other bot. With the missing gear, his circuits sputtered and his logic pathways tangled. Determined, Pip ventured into the Whispering Woods, where rustling leaves and mysterious hums echoed through the ancient trees. Along the way, Pip made friends with a wise old owl named Hoot and a playful squirrel named Sparkle. Together, they followed clues left by the wind and discovered that the gear had been taken by a curious chipmunk who wanted to use it to fix her tiny burrow bridge. Pip kindly offered to help repair the bridge using other materials, and the chipmunk returned the blue gear with gratitude. Pip was happy to have his gear back and had made new friends too!";

  /// Mock fetch — simulates a real network call with a tiny delay
  /// to demonstrate loading states. In production, use http package.
  static Future<Story> fetchStory() async {
    // In production: await Future.delayed(const Duration(seconds: 1-3));
    await Future.delayed(const Duration(milliseconds: 600));

    return Story(
      id: 's_01',
      title: 'Pip the Robot in the Whispering Woods',
      text: storyText,
    );
  }

  /// Mock JSON quiz from the challenge brief.
  /// In production, this would come from a backend API.
  static QuizQuestion fetchQuiz() {
    const quizJson = {
      "question": "What colour was Pip the Robot's lost gear?",
      "options": ["Red", "Green", "Blue", "Yellow"],
      "answer": "Blue",
    };

    return QuizQuestion.fromJson(quizJson);
  }
}
