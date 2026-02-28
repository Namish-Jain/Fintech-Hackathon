/// Represents a single FinBytes news micro-learning card.
class Byte {
  final String id;
  final String title;
  final String source;

  /// Exactly 3 bullet-point summaries, each jargon-free and concise.
  final List<String> summaryBullets;

  /// Simplified "Explain Like I'm 5" version of the story.
  final String eli5Content;

  /// One of: Markets | Economy | Policy | Company Moves |
  ///         Money & Credit | Personal Finance | Crypto
  final String category;

  const Byte({
    required this.id,
    required this.title,
    required this.source,
    required this.summaryBullets,
    required this.eli5Content,
    required this.category,
  }) : assert(
         summaryBullets.length == 3,
         'summaryBullets must contain exactly 3 items',
       );

  /// Creates a [Byte] from a Supabase/JSON map (Phase 3 ready).
  factory Byte.fromMap(Map<String, dynamic> map) {
    return Byte(
      id: map['id'] as String,
      title: map['title'] as String,
      source: map['source'] as String,
      summaryBullets: List<String>.from(map['summary_bullets'] as List),
      eli5Content: map['eli5_content'] as String,
      category: map['category'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'source': source,
    'summary_bullets': summaryBullets,
    'eli5_content': eli5Content,
    'category': category,
  };

  @override
  String toString() => 'Byte(id: $id, category: $category, title: $title)';
}
