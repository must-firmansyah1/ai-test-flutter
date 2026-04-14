import 'company_policy_models.dart';

List<KnowledgeChunk> searchKnowledgeChunks(
  List<KnowledgeChunk> chunks,
  String query, {
  int limit = 3,
}) {
  final tokens = query
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((token) => token.isNotEmpty)
      .toSet();

  final scored = chunks.map((chunk) {
    final text = '${chunk.title} ${chunk.text} ${chunk.tags.join(' ')}'
        .toLowerCase();
    var score = 0;
    for (final token in tokens) {
      if (text.contains(token)) {
        score += 2;
      }
      if (chunk.tags.any((tag) => tag.toLowerCase() == token)) {
        score += 1;
      }
    }
    return (chunk: chunk, score: score);
  }).toList()
    ..sort((a, b) => b.score.compareTo(a.score));

  return scored
      .where((entry) => entry.score > 0)
      .map((entry) => entry.chunk)
      .take(limit)
      .toList();
}
