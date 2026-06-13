import '../models/story_model.dart';
import '../models/quiz_model.dart';

class MockDataSource {
  static const String storyText =
      "Once upon a time, a clever little robot named Pip lost his shiny blue gear in the Whispering Woods. Pip was known throughout the Digital Village for solving puzzles faster than any other bot. With the missing gear, his circuits sputtered and his logic pathways tangled. Determined, Pip ventured into the Whispering Woods, where rustling leaves and mysterious hums echoed through the ancient trees. Along the way, Pip made friends with a wise old owl named Hoot and a playful squirrel named Sparkle. Together, they followed clues left by the wind and discovered that the gear had been taken by a curious chipmunk who wanted to use it to fix her tiny burrow bridge. Pip kindly offered to help repair the bridge using other materials, and the chipmunk returned the blue gear with gratitude. Pip was happy to have his gear back and had made new friends too!";

  static Future<Story> fetchStory() async {
    await Future.delayed(const Duration(milliseconds: 600));

    return Story(
      id: 's_01',
      title: 'Pip the Robot in the Whispering Woods',
      text: storyText,
    );
  }

  static List<QuizQuestion> fetchQuizzes() {
    final quizList = [
      {
        "id": "q1",
        "question": "What colour was Pip the Robot's lost gear?",
        "options": ["Red", "Green", "Blue", "Yellow"],
        "answer": "Blue",
      },
      {
        "id": "q2",
        "question": "Who was Pip's first friend in the Whispering Woods?",
        "options": ["Hoot the Owl", "Sparkle the Squirrel", "Chipmunk", "A rabbit"],
        "answer": "Hoot the Owl",
      },
      {
        "id": "q3",
        "question": "What did the chipmunk want to fix with the gear?",
        "options": ["Her house", "A tiny burrow bridge", "Her food store", "A tree"],
        "answer": "A tiny burrow bridge",
      },
      {
        "id": "q4",
        "question": "Where was Pip known for solving puzzles?",
        "options": ["Robo City", "Digital Village", "Tech Town", "Metal Mountain"],
        "answer": "Digital Village",
      },
    ];

    return quizList
        .map((json) => QuizQuestion.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }
}
