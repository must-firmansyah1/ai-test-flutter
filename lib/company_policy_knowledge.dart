import 'company_policy_models.dart';

abstract class PolicyKnowledgeRepository {
  Future<void> ensureSeeded();

  Future<List<KnowledgeChunk>> allChunks();

  Future<List<KnowledgeChunk>> search(String query, {int limit = 3});

  Future<String> policyContext();
}

const List<KnowledgeChunk> defaultPolicyChunks = [
  KnowledgeChunk(
    id: 'annual_leave',
    title: 'Annual Leave',
    text: 'Annual leave entitlement is 20 days per calendar year.',
    tags: ['leave', 'annual', 'vacation'],
    section: 'leave_policy',
  ),
  KnowledgeChunk(
    id: 'sick_leave',
    title: 'Sick Leave',
    text:
        'Sick leave entitlement is 10 days per calendar year. A medical certificate is required for 3 consecutive sick days or more.',
    tags: ['leave', 'sick', 'medical'],
    section: 'leave_policy',
  ),
  KnowledgeChunk(
    id: 'national_holidays',
    title: 'National Holidays',
    text: 'Company holidays follow the official national holiday calendar.',
    tags: ['holiday', 'calendar', 'national'],
    section: 'holiday_policy',
  ),
  KnowledgeChunk(
    id: 'reimbursement',
    title: 'Reimbursement',
    text:
        'Reimbursement requests must be submitted within 14 days after the expense date with valid receipts attached.',
    tags: ['expense', 'reimbursement', 'receipt'],
    section: 'reimbursement_policy',
  ),
  KnowledgeChunk(
    id: 'remote_work',
    title: 'Remote Work',
    text:
        'Remote work requests must be approved by the direct manager before the workday starts.',
    tags: ['remote', 'wfh', 'manager'],
    section: 'remote_work_policy',
  ),
];

class InMemoryPolicyKnowledgeRepository implements PolicyKnowledgeRepository {
  InMemoryPolicyKnowledgeRepository({
    List<KnowledgeChunk>? seedChunks,
  }) : _chunks = List<KnowledgeChunk>.unmodifiable(
          seedChunks ?? defaultPolicyChunks,
        );

  final List<KnowledgeChunk> _chunks;

  @override
  Future<void> ensureSeeded() async {}

  @override
  Future<List<KnowledgeChunk>> allChunks() async => _chunks;

  @override
  Future<List<KnowledgeChunk>> search(String query, {int limit = 3}) async {
    return searchKnowledgeChunks(_chunks, query, limit: limit);
  }

  @override
  Future<String> policyContext() async {
    final chunks = await allChunks();
    return chunks.map((chunk) => '${chunk.title}: ${chunk.text}').join('\n');
  }
}

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
