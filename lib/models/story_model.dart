/// Lightweight story model. In production this would be fetched
/// from a CMS or backend; for the challenge we keep the snippet
/// from the brief and mock a single network-style fetch.
class Story {
  final String id;
  final String title;
  final String text;

  const Story({
    required this.id,
    required this.title,
    required this.text,
  });
}
