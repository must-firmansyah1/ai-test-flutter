import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'app_bootstrap.dart';
import 'company_policy_models.dart';

class PolicyAssistantService {
  PolicyAssistantService._();

  static final PolicyAssistantService instance = PolicyAssistantService._();

  static const String modelName = 'gemini-3-flash-preview';

  FirebaseAI _backend() {
    if (AppBootstrap.useAppCheck) {
      return FirebaseAI.googleAI(
        appCheck: FirebaseAppCheck.instance,
        useLimitedUseAppCheckTokens: true,
      );
    }
    return FirebaseAI.googleAI();
  }

  Future<GenerateContentResponse> sendPrompt({
    required AssistantMode mode,
    required String prompt,
    required String systemInstruction,
    required List<PendingAttachment> attachments,
    String? contextText,
    List<FunctionDeclaration> functionDeclarations = const [],
  }) async {
    final model = _backend().generativeModel(
      model: modelName,
      systemInstruction: Content.system(systemInstruction),
      generationConfig: GenerationConfig(
        temperature: mode == AssistantMode.general ? 0.7 : 0,
        maxOutputTokens: 512,
        responseMimeType: 'text/plain',
      ),
      tools: functionDeclarations.isEmpty
          ? const []
          : [Tool.functionDeclarations(functionDeclarations)],
      toolConfig: functionDeclarations.isEmpty
          ? null
          : ToolConfig(
              functionCallingConfig: FunctionCallingConfig.any(
                functionDeclarations.map((d) => d.name).toSet(),
              ),
            ),
    );

    final parts = <Part>[];
    if (contextText != null && contextText.trim().isNotEmpty) {
      parts.add(TextPart(contextText.trim()));
    }
    parts.add(TextPart(prompt));
    for (final attachment in attachments) {
      parts.add(
        InlineDataPart(
          attachment.mimeType,
          attachment.bytes,
        ),
      );
    }

    return model.generateContent([Content.multi(parts)]);
  }

  Future<GenerateContentResponse> sendPolicyPrompt({
    required String prompt,
    required String policyContext,
    required List<PendingAttachment> attachments,
  }) {
    return sendPrompt(
      mode: AssistantMode.policy,
      prompt: prompt,
      systemInstruction: '''
You are a company policy assistant.
Answer only using the policy context provided in the user's message.
If the context does not contain the answer, say that you cannot confirm it from the given policy.
Do not use outside knowledge.
''',
      attachments: attachments,
      contextText: 'Policy context:\n$policyContext',
    );
  }

  Future<GenerateContentResponse> sendKnowledgePrompt({
    required String prompt,
    required String knowledgeContext,
    required List<PendingAttachment> attachments,
  }) {
    return sendPrompt(
      mode: AssistantMode.knowledge,
      prompt: prompt,
      systemInstruction: '''
You are a grounded company knowledge assistant.
Answer only using the retrieved knowledge context provided in the user's message.
If the retrieved context is insufficient, say that you need more information.
Do not use outside knowledge.
''',
      attachments: attachments,
      contextText: 'Retrieved knowledge context:\n$knowledgeContext',
    );
  }

  Future<GenerateContentResponse> sendToolPrompt({
    required String prompt,
    required List<PendingAttachment> attachments,
    required List<FunctionDeclaration> tools,
  }) {
    return sendPrompt(
      mode: AssistantMode.tools,
      prompt: prompt,
      systemInstruction: '''
You are a company policy app router.
Choose exactly one tool call from the allowed tool set.
Do not answer with free-form text when a tool can satisfy the request.
Only return supported actions.
''',
      attachments: attachments,
      functionDeclarations: tools,
    );
  }
}

String mimeTypeForAttachment(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.txt')) return 'text/plain';
  if (lower.endsWith('.md')) return 'text/markdown';
  if (lower.endsWith('.csv')) return 'text/csv';
  return 'application/octet-stream';
}

int attachmentSizeKb(Uint8List bytes) => (bytes.length / 1024).ceil();
