import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'company_policy_controller.dart';
import 'company_policy_knowledge.dart';
import 'company_policy_models.dart';
import 'firestore_policy_knowledge_repository.dart';

class CompanyPolicyApp extends StatefulWidget {
  const CompanyPolicyApp({super.key});

  @override
  State<CompanyPolicyApp> createState() => _CompanyPolicyAppState();
}

class _CompanyPolicyAppState extends State<CompanyPolicyApp> {
  late final CompanyPolicyController controller;

  @override
  void initState() {
    super.initState();
    controller = CompanyPolicyController(
      knowledgeRepository: HybridPolicyKnowledgeRepository(
        remote: FirestorePolicyKnowledgeRepository(),
        fallback: InMemoryPolicyKnowledgeRepository(),
      ),
    );
    unawaited(controller.initializeKnowledge());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompanyPolicyScope(
      controller: controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Company Policy AI',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF174EA6),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if(controller.assistantOpen) {
              controller.toggleAssistant();
              return;
            }

            if(controller.currentTabIndex != 0){
              controller.openTab(0);
              return;
            }
            SystemNavigator.pop();
          },
          child: const CompanyPolicyShell()
        ),
      ),
    );
  }
}

class CompanyPolicyScope extends InheritedNotifier<CompanyPolicyController> {
  const CompanyPolicyScope({
    super.key,
    required CompanyPolicyController controller,
    required super.child,
  }) : super(notifier: controller);

  static CompanyPolicyController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<CompanyPolicyScope>();
    assert(scope != null, 'CompanyPolicyScope not found in widget tree.');
    return scope!.notifier!;
  }
}

class CompanyPolicyShell extends StatelessWidget {
  const CompanyPolicyShell({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CompanyPolicyScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          body: Stack(
            children: [
              IndexedStack(
                index: controller.currentTabIndex,
                children: const [
                  DashboardPage(),
                  PolicyPage(),
                  LeaveFormPage(),
                  KnowledgePage(),
                ],
              ),
              Positioned(
                right: kFloatingActionButtonMargin,
                bottom: kFloatingActionButtonMargin,
                child: CompanyPolicyAssistantLauncher(),
              ),
              if (controller.assistantOpen)
                Positioned.fill(
                  child: CompanyPolicyAssistantPanel(
                    onClose: controller.toggleAssistant,
                  ),
                ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: controller.currentTabIndex,
            onDestinationSelected: controller.openTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.space_dashboard_outlined),
                selectedIcon: Icon(Icons.space_dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.policy_outlined),
                selectedIcon: Icon(Icons.policy),
                label: 'Policy',
              ),
              NavigationDestination(
                icon: Icon(Icons.edit_document),
                selectedIcon: Icon(Icons.edit_document),
                label: 'Leave Form',
              ),
              NavigationDestination(
                icon: Icon(Icons.science_outlined),
                selectedIcon: Icon(Icons.science),
                label: 'Knowledge',
              ),
            ],
          ),
        );
      },
    );
  }
}

class CompanyPolicyAssistantLauncher extends StatelessWidget {
  const CompanyPolicyAssistantLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CompanyPolicyScope.of(context);
    return FloatingActionButton.extended(
      heroTag: 'company-policy-ai-launcher',
      onPressed: controller.toggleAssistant,
      icon: const Icon(Icons.auto_awesome),
      label: const Text('AI'),
    );
  }
}

class CompanyPolicyAssistantPanel extends StatefulWidget {
  const CompanyPolicyAssistantPanel({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  State<CompanyPolicyAssistantPanel> createState() =>
      _CompanyPolicyAssistantPanelState();
}

class _CompanyPolicyAssistantPanelState extends State<CompanyPolicyAssistantPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = CompanyPolicyScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });

        return IgnorePointer(
          ignoring: false,
          child: Container(
            color: Colors.black.withValues(alpha: 0.16),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final panelWidth = constraints.maxWidth < 640
                      ? constraints.maxWidth - 24
                      : 420.0;
                  final panelHeight = constraints.maxHeight < 720
                      ? constraints.maxHeight - 24
                      : 640.0;

                  return Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: panelWidth,
                          maxHeight: panelHeight,
                          minWidth: 320,
                        ),
                        child: Material(
                          elevation: 18,
                          borderRadius: BorderRadius.circular(28),
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  const Color(0xFFF6F9FF),
                                ],
                              ),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Column(
                              children: [
                                _AssistantHeader(onClose: widget.onClose),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: AssistantMode.values
                                        .map(
                                          (mode) => ChoiceChip(
                                            label: Text(
                                              switch (mode) {
                                                AssistantMode.general =>
                                                  'General',
                                                AssistantMode.policy => 'Policy',
                                                AssistantMode.knowledge =>
                                                  'Knowledge',
                                                AssistantMode.tools => 'Tools',
                                              },
                                            ),
                                            selected:
                                                controller.assistantMode == mode,
                                            onSelected: (_) => controller.setMode(mode),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _AttachmentSummary(
                                          text: controller.buildAttachmentSummary(),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton.filledTonal(
                                        onPressed: controller.pickAttachments,
                                        icon: const Icon(Icons.attach_file),
                                        tooltip: 'Attach files',
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton.filledTonal(
                                        onPressed: controller.clearAttachments,
                                        icon: const Icon(Icons.delete_outline),
                                        tooltip: 'Clear attachments',
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ListView.separated(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    itemBuilder: (context, index) {
                                      final message =
                                          controller.assistantMessages[index];
                                      return _AssistantBubble(message: message);
                                    },
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 10),
                                    itemCount: controller.assistantMessages.length,
                                  ),
                                ),
                                if (controller.attachments.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (var i = 0;
                                            i < controller.attachments.length;
                                            i++)
                                          InputChip(
                                            label: Text(
                                              controller.attachments[i].name,
                                            ),
                                            onDeleted: () =>
                                                controller.removeAttachmentAt(i),
                                          ),
                                      ],
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Column(
                                    children: [
                                      TextField(
                                        controller: controller
                                            .assistantPromptController,
                                        minLines: 2,
                                        maxLines: 5,
                                        textInputAction: TextInputAction.send,
                                        onSubmitted: (_) =>
                                            controller.sendAssistantPrompt(),
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Ask about policy, documents, or actions...',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          FilledButton.icon(
                                            onPressed: controller.isSending
                                                ? null
                                                : controller.sendAssistantPrompt,
                                            icon: controller.isSending
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Icon(Icons.send),
                                            label: const Text('Send'),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton(
                                            onPressed: controller.clearAssistantMessages,
                                            child: const Text('Clear chat'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AssistantHeader extends StatelessWidget {
  const _AssistantHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        border: const Border(
          bottom: BorderSide(color: Colors.black12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Policy Assistant',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Floating across every screen',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}

class _AttachmentSummary extends StatelessWidget {
  const _AttachmentSummary({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.message});

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = message.isUser
        ? theme.colorScheme.primary
        : const Color(0xFFF1F5FB);
    final foreground = message.isUser ? Colors.white : theme.colorScheme.onSurface;

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
              ),
              if (message.details != null) ...[
                const SizedBox(height: 6),
                Text(
                  message.details!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foreground.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CompanyPolicyScope.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _HeroCard(
            title: 'Company Policy AI',
            subtitle:
                'A research playground for restricted context, multi-file prompts, vector-ready knowledge, and function calling.',
            primaryActionLabel: 'Open Assistant',
            primaryAction: () => controller.openAssistant(true),
            secondaryActionLabel: 'Go to Policy',
            secondaryAction: () => controller.openTab(1),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricCard(
                title: 'Restricted Context',
                value: 'Policy only',
                icon: Icons.lock_outline,
              ),
              _MetricCard(
                title: 'Attachments',
                value: 'Docs + Images',
                icon: Icons.attach_file,
              ),
              _MetricCard(
                title: 'Actions',
                value: 'Tool calling',
                icon: Icons.route_rounded,
              ),
              _MetricCard(
                title: 'Knowledge',
                value: 'Vector ready',
                icon: Icons.psychology_alt,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Suggested demo flows',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _DemoTile(
            title: 'Policy-only Q&A',
            subtitle:
                'Ask whether 4 sick days require a doctor note and answer only from the policy context.',
            icon: Icons.policy,
            onTap: () {
              controller.openAssistant(true);
              controller.setMode(AssistantMode.policy);
              controller.assistantPromptController.text =
                  "I have been sick for 4 days. Do I need a doctor's note?";
            },
          ),
          _DemoTile(
            title: 'Upload file and ask',
            subtitle:
                'Attach a PDF or image, then ask the assistant to summarize or extract rules.',
            icon: Icons.upload_file,
            onTap: () {
              controller.openAssistant(true);
              controller.setMode(AssistantMode.policy);
            },
          ),
          _DemoTile(
            title: 'Tool calling',
            subtitle: 'Ask the assistant to open the leave form and prefill fields.',
            icon: Icons.touch_app,
            onTap: () {
              controller.openAssistant(true);
              controller.setMode(AssistantMode.tools);
              controller.assistantPromptController.text =
                  'Open the leave form and prefill name Rina, department HR, days 4, reason sick leave.';
            },
          ),
        ],
      ),
    );
  }
}

class PolicyPage extends StatelessWidget {
  const PolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CompanyPolicyScope.of(context);
    final theme = Theme.of(context);
    final chunks = controller.knowledgeChunks;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Policy Knowledge',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'This page is the restricted-context demo. The assistant should answer only from these rules.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (controller.isLoadingKnowledge)
            const Center(child: CircularProgressIndicator())
          else if (controller.knowledgeLoadError != null)
            Text(
              'Failed to load knowledge from Firestore. Using fallback knowledge locally.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            )
          else
            for (final chunk in chunks) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chunk.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(chunk.text),
                      if (chunk.tags.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final tag in chunk.tags)
                              Chip(label: Text(tag)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              controller.openAssistant(true);
              controller.setMode(AssistantMode.policy);
              controller.assistantPromptController.text =
                  "I have been sick for 4 days. Do I need a doctor's note?";
            },
            icon: const Icon(Icons.question_answer),
            label: const Text('Ask policy question'),
          ),
        ],
      ),
    );
  }
}

class LeaveFormPage extends StatelessWidget {
  const LeaveFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CompanyPolicyScope.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Leave Request Form',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Use AI tools to prefill or submit this form from the floating assistant.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: controller.leaveNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.leaveDepartmentController,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.leaveDaysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Requested days',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.leaveReasonController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: controller.submitLeaveForm,
                        child: const Text('Submit request'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => controller.prefillLeaveForm(
                          name: 'Rina',
                          department: 'HR',
                          days: '4',
                          reason: 'Sick leave',
                        ),
                        child: const Text('Prefill example'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Submitted requests',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (controller.leaveRequests.isEmpty)
            const Text('No leave requests yet.')
          else
            for (final request in controller.leaveRequests) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event_note),
                  title: Text('${request.name} - ${request.days} day(s)'),
                  subtitle: Text(
                    '${request.department} • ${request.reason}\n${request.createdAt}',
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class KnowledgePage extends StatelessWidget {
  const KnowledgePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CompanyPolicyScope.of(context);
    final theme = Theme.of(context);
    final chunks = controller.lastRetrievedChunks.isNotEmpty
        ? controller.lastRetrievedChunks
        : controller.knowledgeChunks;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Knowledge Base',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'This page is the vector-search-ready area. We are using local retrieval for now and can swap to Firestore vector search later.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (controller.isLoadingKnowledge)
            const Center(child: CircularProgressIndicator())
          else ...[
          TextField(
            controller: controller.knowledgeQueryController,
            decoration: const InputDecoration(
              labelText: 'Search query',
              border: OutlineInputBorder(),
            ),
            onSubmitted: controller.searchKnowledge,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => controller.searchKnowledge(
              controller.knowledgeQueryController.text,
            ),
            icon: const Icon(Icons.search),
            label: const Text('Search knowledge'),
          ),
          const SizedBox(height: 20),
          Text(
            'Retrieved chunks',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (final chunk in chunks) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chunk.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(chunk.text),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          ],
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.primaryActionLabel,
    required this.primaryAction,
    required this.secondaryActionLabel,
    required this.secondaryAction,
  });

  final String title;
  final String subtitle;
  final String primaryActionLabel;
  final VoidCallback primaryAction;
  final String secondaryActionLabel;
  final VoidCallback secondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A73E8), Color(0xFF174EA6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: primaryAction,
                style: FilledButton.styleFrom(backgroundColor: Colors.white),
                child: Text(
                  primaryActionLabel,
                  style: const TextStyle(color: Color(0xFF174EA6)),
                ),
              ),
              OutlinedButton(
                onPressed: secondaryAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                ),
                child: Text(secondaryActionLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 168,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
