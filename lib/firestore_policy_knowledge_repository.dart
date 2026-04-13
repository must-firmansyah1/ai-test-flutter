import 'package:cloud_firestore/cloud_firestore.dart';

import 'company_policy_knowledge.dart';
import 'company_policy_models.dart';

class FirestorePolicyKnowledgeRepository implements PolicyKnowledgeRepository {
  FirestorePolicyKnowledgeRepository({
    FirebaseFirestore? firestore,
    this.knowledgeBaseId = 'company_policy',
    this.collectionRoot = 'knowledge_bases',
    this.seedChunks = defaultPolicyChunks,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String knowledgeBaseId;
  final String collectionRoot;
  final List<KnowledgeChunk> seedChunks;

  CollectionReference<Map<String, dynamic>> get _chunksRef => _firestore
      .collection(collectionRoot)
      .doc(knowledgeBaseId)
      .collection('chunks');

  @override
  Future<void> ensureSeeded() async {
    final snapshot = await _chunksRef.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final chunk in seedChunks) {
      batch.set(_chunksRef.doc(chunk.id), {
        ...chunk.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  @override
  Future<List<KnowledgeChunk>> allChunks() async {
    final snapshot = await _chunksRef.get();
    return snapshot.docs.map(_chunkFromDoc).toList();
  }

  @override
  Future<List<KnowledgeChunk>> search(String query, {int limit = 3}) async {
    final chunks = await allChunks();
    return searchKnowledgeChunks(chunks, query, limit: limit);
  }

  @override
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

class HybridPolicyKnowledgeRepository implements PolicyKnowledgeRepository {
  HybridPolicyKnowledgeRepository({
    required this.remote,
    required this.fallback,
  });

  final PolicyKnowledgeRepository remote;
  final PolicyKnowledgeRepository fallback;
  bool _remoteAvailable = false;

  @override
  Future<void> ensureSeeded() async {
    try {
      await remote.ensureSeeded();
      _remoteAvailable = true;
    } catch (_) {
      _remoteAvailable = false;
    }
  }

  @override
  Future<List<KnowledgeChunk>> allChunks() async {
    if (_remoteAvailable) {
      try {
        return await remote.allChunks();
      } catch (_) {
        _remoteAvailable = false;
      }
    }
    return fallback.allChunks();
  }

  @override
  Future<List<KnowledgeChunk>> search(String query, {int limit = 3}) async {
    if (_remoteAvailable) {
      try {
        return await remote.search(query, limit: limit);
      } catch (_) {
        _remoteAvailable = false;
      }
    }
    return fallback.search(query, limit: limit);
  }

  @override
  Future<String> policyContext() async {
    final chunks = await allChunks();
    return chunks.map((chunk) => '${chunk.title}: ${chunk.text}').join('\n');
  }
}
