import 'package:cloud_firestore/cloud_firestore.dart';

import 'company_policy_knowledge.dart';
import 'company_policy_models.dart';

class PolicyKnowledgeRepository {
  PolicyKnowledgeRepository({
    FirebaseFirestore? firestore,
    this.knowledgeBaseId = 'company_policy',
    this.collectionRoot = 'knowledge_bases',
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String knowledgeBaseId;
  final String collectionRoot;

  CollectionReference<Map<String, dynamic>> get _chunksRef => _firestore
      .collection(collectionRoot)
      .doc(knowledgeBaseId)
      .collection('chunks');

  Future<List<KnowledgeChunk>> allChunks() async {
    final snapshot = await _chunksRef.get();
    return snapshot.docs.map(_chunkFromDoc).toList();
  }

  Future<List<KnowledgeChunk>> search(String query, {int limit = 3}) async {
    final chunks = await allChunks();
    return searchKnowledgeChunks(chunks, query, limit: limit);
  }

  Future<String> policyContext() async {
    final chunks = await allChunks();
    return chunks.map((chunk) => '${chunk.title}: ${chunk.text}').join('\n');
  }

  Future<void> upsertChunk(KnowledgeChunk chunk) async {
    await _chunksRef.doc(chunk.id).set({
      ...chunk.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  KnowledgeChunk _chunkFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return KnowledgeChunk.fromMap({
      ...data,
      'id': data['id']?.toString() ?? doc.id,
    });
  }
}