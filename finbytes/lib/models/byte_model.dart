/// Represents a single FinBytes card, sourced from the `finbytes` table
/// joined with `news_articles` for the headline and source name.
class Byte {
  final String id;           // finbytes.id
  final String articleId;    // finbytes.article_id
  final String category;     // finbytes.category
  final String headline;     // news_articles.headline
  final String sourceName;   // news_articles.source_name
  final String summaryOverview;        // finbytes.summary_overview  (tab 0)
  final String summaryEli5;            // finbytes.summary_eli5      (tab 1)
  final String actionableTakeaway;     // finbytes.actionable_takeaway (tab 2)
  final String simulatedPublicReaction;// finbytes.simulated_public_reaction (tab 3)
  final int    impactScore;            // finbytes.impact_score

  const Byte({
    required this.id,
    required this.articleId,
    required this.category,
    required this.headline,
    required this.sourceName,
    required this.summaryOverview,
    required this.summaryEli5,
    required this.actionableTakeaway,
    required this.simulatedPublicReaction,
    required this.impactScore,
  });

  /// Constructs a [Byte] from the Supabase row returned by the joined query:
  ///   finbytes.*, news_articles!inner(headline, source_name)
  factory Byte.fromMap(Map<String, dynamic> map) {
    final article = map['news_articles'] as Map<String, dynamic>? ?? {};
    return Byte(
      id:                       map['id'] as String,
      articleId:                map['article_id'] as String,
      category:                 map['category'] as String? ?? '',
      headline:                 article['headline'] as String? ?? '',
      sourceName:               article['source_name'] as String? ?? '',
      summaryOverview:          _clean(map['summary_overview']),
      summaryEli5:              _clean(map['summary_eli5']),
      actionableTakeaway:       _clean(map['actionable_takeaway']),
      simulatedPublicReaction:  _clean(map['simulated_public_reaction']),
      impactScore:              (map['impact_score'] as num?)?.toInt() ?? 0,
    );
  }

  /// Cleans a DB summary field that may be stored as a JSON-style array string
  /// e.g. '["sentence one", "sentence two", "sentence three"]' or a plain string.
  /// Returns a clean string with each item on its own line, ready to display.
  static String _clean(dynamic raw) {
    if (raw == null) return '';
    final str = raw.toString().trim();
    if (str.isEmpty) return '';

    // Detect array format: starts with [ and ends with ]
    if (str.startsWith('[') && str.endsWith(']')) {
      // Strip outer brackets
      final inner = str.substring(1, str.length - 1).trim();
      if (inner.isEmpty) return '';

      // Split on  ,  boundaries — items may be "quoted" or unquoted
      // Strategy: split on  ","  or  '  ,  '  patterns then strip quotes
      final parts = <String>[];
      // Use a simple state-machine split respecting quoted strings
      final buffer = StringBuffer();
      bool inQuote = false;
      String quoteChar = '';
      for (int i = 0; i < inner.length; i++) {
        final ch = inner[i];
        if (!inQuote && (ch == '"' || ch == "'")) {
          inQuote = true;
          quoteChar = ch;
        } else if (inQuote && ch == quoteChar) {
          inQuote = false;
        } else if (!inQuote && ch == ',') {
          final part = buffer.toString().trim();
          if (part.isNotEmpty) parts.add(part);
          buffer.clear();
        } else {
          buffer.write(ch);
        }
      }
      final last = buffer.toString().trim();
      if (last.isNotEmpty) parts.add(last);

      if (parts.isNotEmpty) {
        return parts.map((p) => p.trim()).where((p) => p.isNotEmpty).join('\n\n');
      }
    }

    // Already plain text — return as-is
    return str;
  }

  @override
  String toString() => 'Byte(id: $id, category: $category, score: $impactScore)';
}
