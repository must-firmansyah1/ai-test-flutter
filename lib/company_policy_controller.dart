import 'package:file_picker/file_picker.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

import 'company_policy_knowledge.dart';
import 'company_policy_models.dart';
import 'policy_assistant_service.dart';

class CompanyPolicyController extends ChangeNotifier {
  CompanyPolicyController({
    required this.knowledgeRepository,
  }) {
    assistantMessages.add(
      AssistantMessage.assistant(
        'Hi, I am ready to help with company policy, documents, and app actions.',
      ),
    );
  }

  final PolicyKnowledgeRepository knowledgeRepository;

  final TextEditingController assistantPromptController = TextEditingController();
  final TextEditingController leaveNameController = TextEditingController();
  final TextEditingController leaveDepartmentController = TextEditingController();
  final TextEditingController leaveDaysController = TextEditingController();
  final TextEditingController leaveReasonController = TextEditingController();
  final TextEditingController knowledgeQueryController = TextEditingController();

  final List<AssistantMessage> assistantMessages = [];
  final List<PendingAttachment> attachments = [];
  final List<LeaveRequest> leaveRequests = [];

  AssistantMode assistantMode = AssistantMode.policy;
  int currentTabIndex = 0;
  bool assistantOpen = false;
  bool isSending = false;
  List<KnowledgeChunk> lastRetrievedChunks = [];

  List<FunctionDeclaration> get toolDeclarations => [
        FunctionDeclaration(
          'open_dashboard',
          'Open the dashboard tab.',
          parameters: const {},
        ),
        FunctionDeclaration(
          'open_policy_page',
          'Open the policy tab.',
          parameters: const {},
        ),
        FunctionDeclaration(
          'open_form_page',
          'Open the leave request form tab.',
          parameters: const {},
        ),
        FunctionDeclaration(
          'open_knowledge_page',
          'Open the knowledge base tab.',
          parameters: const {},
        ),
        FunctionDeclaration(
          'fill_leave_form',
          'Prefill the leave request form fields.',
          parameters: {
            'name': Schema.string(description: 'Employee name.'),
            'department': Schema.string(description: 'Employee department.'),
            'days': Schema.string(description: 'Requested leave days.'),
            'reason': Schema.string(description: 'Reason for leave request.'),
          },
          optionalParameters: const ['name', 'department', 'days', 'reason'],
        ),
        FunctionDeclaration(
          'submit_leave_form',
          'Submit the current leave request form.',
          parameters: const {},
        ),
        FunctionDeclaration(
          'search_knowledge',
          'Search the knowledge base and show the best matches.',
          parameters: {
            'query': Schema.string(description: 'Search query.'),
          },
          optionalParameters: const ['query'],
        ),
      ];

  @override
  void dispose() {
    assistantPromptController.dispose();
    leaveNameController.dispose();
    leaveDepartmentController.dispose();
    leaveDaysController.dispose();
    leaveReasonController.dispose();
    knowledgeQueryController.dispose();
    super.dispose();
  }

  void openAssistant([bool value = true]) {
    assistantOpen = value;
    notifyListeners();
  }

  void toggleAssistant() {
    assistantOpen = !assistantOpen;
    notifyListeners();
  }

  void setMode(AssistantMode mode) {
    assistantMode = mode;
    notifyListeners();
  }

  void openTab(int index) {
    currentTabIndex = index;
    notifyListeners();
  }

  void addAttachment(PendingAttachment attachment) {
    attachments.add(attachment);
    notifyListeners();
  }

  void addAttachments(List<PendingAttachment> newAttachments) {
    attachments.addAll(newAttachments);
    notifyListeners();
  }

  void removeAttachmentAt(int index) {
    if (index < 0 || index >= attachments.length) return;
    attachments.removeAt(index);
    notifyListeners();
  }

  void clearAttachments() {
    attachments.clear();
    notifyListeners();
  }

  void prefillLeaveForm({
    String? name,
    String? department,
    String? days,
    String? reason,
  }) {
    if (name != null) leaveNameController.text = name;
    if (department != null) leaveDepartmentController.text = department;
    if (days != null) leaveDaysController.text = days;
    if (reason != null) leaveReasonController.text = reason;
    openTab(2);
  }

  void clearAssistantMessages() {
    assistantMessages
      ..clear()
      ..add(
        AssistantMessage.assistant(
          'Conversation cleared. Start a new request when ready.',
        ),
      );
    notifyListeners();
  }

  Future<void> pickAttachments() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.any,
    );
    if (result == null) {
      return;
    }

    final picked = <PendingAttachment>[];
    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null) {
        continue;
      }
      picked.add(
        PendingAttachment(
          name: file.name,
          mimeType: mimeTypeForAttachment(file.name),
          bytes: bytes,
        ),
      );
    }

    if (picked.isNotEmpty) {
      addAttachments(picked);
    }
  }

  Future<void> searchKnowledge(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    knowledgeQueryController.text = normalized;
    lastRetrievedChunks = knowledgeRepository.search(normalized);
    openTab(3);
    notifyListeners();
  }

  Future<void> submitLeaveForm() async {
    final days = int.tryParse(leaveDaysController.text.trim());
    if (days == null || days <= 0) {
      assistantMessages.add(
        AssistantMessage.assistant(
          'Leave request not submitted because the number of days is invalid.',
        ),
      );
      notifyListeners();
      return;
    }

    final request = LeaveRequest(
      name: leaveNameController.text.trim(),
      department: leaveDepartmentController.text.trim(),
      days: days,
      reason: leaveReasonController.text.trim(),
      createdAt: DateTime.now(),
    );
    leaveRequests.insert(0, request);
    openTab(2);
    assistantMessages.add(
      AssistantMessage.assistant(
        'Leave request submitted for ${request.name} (${request.days} days).',
      ),
    );
    notifyListeners();
  }

  Future<void> sendAssistantPrompt() async {
    final prompt = assistantPromptController.text.trim();
    if (prompt.isEmpty || isSending) return;

    isSending = true;
    assistantMessages.add(AssistantMessage.user(prompt));
    notifyListeners();

    try {
      final response = await _runAssistant(prompt);
      final functionCalls = response.functionCalls.toList();
      for (final call in functionCalls) {
        await _handleFunctionCall(call);
      }

      final text = response.text?.trim();
      if (text != null && text.isNotEmpty) {
        assistantMessages.add(AssistantMessage.assistant(text));
      } else if (functionCalls.isNotEmpty) {
        assistantMessages.add(
          AssistantMessage.assistant(
            'Executed ${functionCalls.length} action(s) from the prompt.',
          ),
        );
      } else {
        assistantMessages.add(
          AssistantMessage.assistant(
            'No response text was returned. Try a more specific instruction.',
          ),
        );
      }
    } catch (error) {
      assistantMessages.add(
        AssistantMessage.assistant('AI request failed: $error'),
      );
    } finally {
      assistantPromptController.clear();
      isSending = false;
      notifyListeners();
    }
  }

  Future<GenerateContentResponse> _runAssistant(String prompt) async {
    switch (assistantMode) {
      case AssistantMode.general:
        return PolicyAssistantService.instance.sendPrompt(
          mode: AssistantMode.general,
          prompt: prompt,
          systemInstruction: '''
You are a helpful internal company policy app assistant.
Use concise, practical answers.
You may use the uploaded attachments if they are relevant.
''',
          attachments: attachments,
        );
      case AssistantMode.policy:
        final policyContext = knowledgeRepository.policyContext();
        return PolicyAssistantService.instance.sendPolicyPrompt(
          prompt: prompt,
          policyContext: policyContext,
          attachments: attachments,
        );
      case AssistantMode.knowledge:
        lastRetrievedChunks = knowledgeRepository.search(prompt);
        final contextText = lastRetrievedChunks.isEmpty
            ? knowledgeRepository.policyContext()
            : lastRetrievedChunks
                .map((chunk) => '[${chunk.title}] ${chunk.text}')
                .join('\n\n');
        return PolicyAssistantService.instance.sendKnowledgePrompt(
          prompt: prompt,
          knowledgeContext: contextText,
          attachments: attachments,
        );
      case AssistantMode.tools:
        return PolicyAssistantService.instance.sendToolPrompt(
          prompt: prompt,
          attachments: attachments,
          tools: toolDeclarations,
        );
    }
  }

  Future<void> _handleFunctionCall(FunctionCall call) async {
    switch (call.name) {
      case 'open_dashboard':
        openTab(0);
        assistantMessages.add(
          AssistantMessage.assistant('Dashboard tab opened.'),
        );
        return;
      case 'open_policy_page':
        openTab(1);
        assistantMessages.add(
          AssistantMessage.assistant('Policy tab opened.'),
        );
        return;
      case 'open_form_page':
        openTab(2);
        assistantMessages.add(
          AssistantMessage.assistant('Leave form tab opened.'),
        );
        return;
      case 'open_knowledge_page':
        openTab(3);
        assistantMessages.add(
          AssistantMessage.assistant('Knowledge tab opened.'),
        );
        return;
      case 'fill_leave_form':
        prefillLeaveForm(
          name: call.args['name']?.toString(),
          department: call.args['department']?.toString(),
          days: call.args['days']?.toString(),
          reason: call.args['reason']?.toString(),
        );
        assistantMessages.add(
          AssistantMessage.assistant(
            'Leave form fields were prefilled by AI.',
          ),
        );
        return;
      case 'submit_leave_form':
        await submitLeaveForm();
        return;
      case 'search_knowledge':
        await searchKnowledge(call.args['query']?.toString() ?? '');
        assistantMessages.add(
          AssistantMessage.assistant('Knowledge search completed by AI.'),
        );
        return;
      default:
        assistantMessages.add(
          AssistantMessage.assistant('Unsupported action: ${call.name}.'),
        );
    }
  }

  String buildAttachmentSummary() {
    if (attachments.isEmpty) {
      return 'No files attached.';
    }
    return attachments
        .map((attachment) =>
            '${attachment.name} (${attachmentSizeKb(attachment.bytes)} KB)')
        .join(', ');
  }
}
