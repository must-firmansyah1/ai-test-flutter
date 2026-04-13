import 'dart:typed_data';

enum AssistantMode {
  general,
  policy,
  knowledge,
  tools,
}

class PendingAttachment {
  const PendingAttachment({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String mimeType;
  final Uint8List bytes;
}

class KnowledgeChunk {
  const KnowledgeChunk({
    required this.id,
    required this.title,
    required this.text,
    this.tags = const <String>[],
    this.source = 'company_policy_handbook',
    this.section,
    this.version = 1,
  });

  final String id;
  final String title;
  final String text;
  final List<String> tags;
  final String source;
  final String? section;
  final int version;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'tags': tags,
      'source': source,
      'section': section,
      'version': version,
    };
  }

  factory KnowledgeChunk.fromMap(Map<String, Object?> map) {
    return KnowledgeChunk(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      tags: (map['tags'] as List<dynamic>? ?? const <dynamic>[])
          .map((tag) => tag.toString())
          .toList(),
      source: map['source']?.toString() ?? 'company_policy_handbook',
      section: map['section']?.toString(),
      version: (map['version'] as num?)?.toInt() ?? 1,
    );
  }
}

class AssistantMessage {
  const AssistantMessage({
    required this.isUser,
    required this.text,
    this.details,
  });

  factory AssistantMessage.user(String text) => AssistantMessage(
        isUser: true,
        text: text,
      );

  factory AssistantMessage.assistant(
    String text, {
    String? details,
  }) =>
      AssistantMessage(
        isUser: false,
        text: text,
        details: details,
      );

  final bool isUser;
  final String text;
  final String? details;
}

class LeaveRequest {
  const LeaveRequest({
    required this.name,
    required this.department,
    required this.days,
    required this.reason,
    
    required this.createdAt,
  });

  final String name;
  final String department;
  final int days;
  final String reason;
  final DateTime createdAt;
}
