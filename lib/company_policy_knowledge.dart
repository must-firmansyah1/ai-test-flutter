import 'company_policy_models.dart';

abstract class PolicyKnowledgeRepository {
  List<KnowledgeChunk> allChunks();

  List<KnowledgeChunk> search(String query, {int limit = 3});

  String policyContext();
}

class InMemoryPolicyKnowledgeRepository implements PolicyKnowledgeRepository {
  InMemoryPolicyKnowledgeRepository() {
    _chunks = const [
      KnowledgeChunk(
        id: 'annual_leave',
        title: 'Annual Leave',
        text: 'Annual leave entitlement is 20 days per calendar year.',
        tags: ['leave', 'annual', 'vacation'],
      ),
      KnowledgeChunk(
        id: 'sick_leave',
        title: 'Sick Leave',
        text:
            'Sick leave entitlement is 10 days per calendar year. A medical certificate is required for 3 consecutive sick days or more.',
        tags: ['leave', 'sick', 'medical'],
      ),
      KnowledgeChunk(
        id: 'national_holidays',
        title: 'National Holidays',
        text: 'Company holidays follow the official national holiday calendar.',
        tags: ['holiday', 'calendar', 'national'],
      ),
      KnowledgeChunk(
        id: 'reimbursement',
        title: 'Reimbursement',
        text:
            'Reimbursement requests must be submitted within 14 days after the expense date with valid receipts attached.',
        tags: ['expense', 'reimbursement', 'receipt'],
      ),
      KnowledgeChunk(
        id: 'remote_work',
        title: 'Remote Work',
        text:
            'Remote work requests must be approved by the direct manager before the workday starts.',
        tags: ['remote', 'wfh', 'manager'],
      ),
    ];
  }

  late final List<KnowledgeChunk> _chunks;

  @override
  List<KnowledgeChunk> allChunks() => List.unmodifiable(_chunks);

  @override
  List<KnowledgeChunk> search(String query, {int limit = 3}) {
    final tokens = query
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.isNotEmpty)
        .toSet();

    final scored = _chunks.map((chunk) {
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

  @override
  String policyContext() {
    return _chunks
        .map((chunk) => '${chunk.title}: ${chunk.text}')
        .join('\n');
  }
}
