# Company Policy AI Exploration Knowledge

This document is the working knowledge base for the Flutter app in this repository.
It records the product direction, implementation strategy, guardrails, and the current
research plan for the Firebase AI exploration.

## Product Goal

Build a company policy assistant app that can:

1. Control response generation with system instructions and prompt design.
2. Accept multiple documents and images as prompt input.
3. Restrict answers to approved company knowledge only.
4. Retrieve relevant knowledge chunks through vector-search-ready architecture.
5. Use function calling to open pages, fill forms, and trigger safe app actions.
6. Expose a floating chat window that is available from every page in the app.

The app is not only a chat demo. It is a small research playground for AI-assisted
application workflows.

## Current App Concept

The app follows a company policy assistant scenario with four screens:

- Dashboard
- Policy knowledge
- Leave request form
- Knowledge search

The floating assistant sits above the shell so it can be accessed from every page.
It can:

- answer company policy questions,
- accept multiple document/image attachments,
- run in restricted policy mode,
- run knowledge retrieval mode,
- and execute whitelisted tool calls.

## Design Principles

- Keep the AI as a reasoning layer, not the source of truth for business rules.
- Execute navigation, form filling, and API calls in Flutter code only after validation.
- Use allowlists for tools, destinations, and supported actions.
- Prefer grounded responses over open-ended generated answers.
- If context is missing, the assistant should say so instead of guessing.
- Keep the app modular so we can later swap local retrieval with Firestore vector search.

## Current Knowledge Domain

The first knowledge set is a fictional company policy pack:

- Annual leave: 20 days per calendar year.
- Sick leave: 10 days per calendar year.
- A medical certificate is required for 3 consecutive sick days or more.
- Public holidays follow the official national holiday calendar.
- Reimbursement requests must be submitted within 14 days after the expense date.
- Remote work requests must be approved by the direct manager before the workday starts.

Example question:

- "I have been sick for 4 days. Do I need a doctor's note?"

Expected behavior:

- The assistant should answer only from the provided policy knowledge.
- It should not use outside knowledge when policy mode is active.
- It should explain when the policy does or does not confirm the answer.

## Current Implementation Surface

The implementation is organized into these files:

- `lib/main.dart`
- `lib/company_policy_app.dart`
- `lib/company_policy_controller.dart`
- `lib/company_policy_knowledge.dart`
- `lib/company_policy_models.dart`
- `lib/policy_assistant_service.dart`
- `lib/app_bootstrap.dart`

The current shell already includes:

- a bottom navigation scaffold,
- a persistent floating AI launcher,
- an overlay assistant panel,
- a policy page,
- a leave form page,
- and a knowledge page.

## Research Targets

### 1. Prompt Input With Multiple Files

Goal:

- Allow the user to attach multiple documents or images before sending a prompt.

Why this matters:

- It allows policy extraction from PDFs.
- It allows screenshot or image interpretation.
- It mirrors real support and operations workflows.

Expected flow:

1. User writes a prompt.
2. User attaches one or more files.
3. Flutter converts them into model parts.
4. Firebase AI receives text plus attachments.
5. The response is rendered in the assistant panel.

Implementation notes:

- Keep attachment validation in Flutter.
- Show attachment chips in the assistant panel.
- Support common content types such as PDF, PNG, JPG, WEBP, TXT, and CSV.

### 2. Restricted Context Assistant

Goal:

- Force the assistant to answer only from approved knowledge.

Why this matters:

- Policy answers must be consistent and auditable.
- The assistant should not invent company rules.

Expected flow:

1. The app loads the policy context.
2. The system instruction states that only this context is allowed.
3. The user asks a question.
4. The model answers only from the policy block or retrieved chunks.
5. If the answer is not supported, the assistant says it cannot confirm.

Recommended product behavior:

- If the question is about policy, do not answer from general world knowledge.
- If the answer is not present in the current context, show a safe fallback.
- Keep the context versioned so policy changes are easy to track later.

### 3. Vector Search Knowledge Base

Goal:

- Store policy knowledge as chunks.
- Retrieve the best chunks for a query.
- Feed only those chunks into the model.

Planned pipeline:

1. Chunk policy documents into semantically meaningful passages.
2. Generate embeddings for each chunk.
3. Store chunk text, source metadata, and embedding vectors.
4. Embed the user query.
5. Retrieve the top matching chunks.
6. Ask the model to answer only from the retrieved context.

Implementation stance for now:

- Use a local retrieval layer first.
- Keep the code structure ready for Firestore vector search later.
- Do not bind the product to a vector backend too early.

### 4. Function Calling

Goal:

- Let the model return structured actions that the app can execute safely.

Primary use cases:

- Open a screen.
- Prefill a form.
- Submit a draft request.
- Search the knowledge base.
- Trigger a backend action later.

Guardrails:

- Define a small allowlist of functions.
- Validate the function name and arguments in Flutter.
- Execute only safe actions.
- Never let the model mutate app state directly.

## Floating Chat Window

The assistant should feel available everywhere in the app.

Desired behavior:

- A floating launcher stays visible on every screen.
- The assistant opens as an overlay panel.
- The user can move between pages without losing the app state.
- The assistant can open policy, form, and knowledge pages through tools.

This design is useful because it lets us test whether AI can act as a cross-screen
control layer, not only as a single-page chatbot.

## App Flow

### Dashboard

- Shows the app purpose and the main research targets.
- Offers quick actions to open the assistant and jump to policy pages.

### Policy Page

- Displays the policy knowledge directly.
- Serves as the source of truth for restricted-context answers.

### Leave Form Page

- Hosts a real form that can be filled or submitted through tool calling.
- Gives a safe target for function-calling experiments.

### Knowledge Page

- Demonstrates retrieval and the vector-search-ready architecture.
- Shows which chunks were retrieved for a query.

### Floating Assistant

- Accepts prompts and attachments.
- Supports mode switching between general, policy, knowledge, and tools.
- Returns model output and handles function calls.

## Phase Plan

### Phase 1

- Prompt input with multiple document and image attachments.
- Floating assistant shell across all pages.

### Phase 2

- Strict policy-mode answers using only company knowledge.
- Safe fallback behavior when the answer is not in context.

### Phase 3

- Retrieval pipeline with chunked knowledge and vector-ready storage.
- Replace local search with Firestore vector search later.

### Phase 4

- Function calling for navigation and form actions.
- Add backend-triggered actions when needed.

### Phase 5

- Expand the demo with richer document handling, citations, and production guards.

## Working Rules

- Keep each change small and traceable.
- Preserve the app shell and floating assistant once they are stable.
- Store strategic decisions in this document before implementing them.
- Prefer readable code over clever abstractions.
- If a feature is experimental, isolate it behind a narrow surface area.

## Open Questions

- Should attachments be stored locally first or uploaded to Firebase Storage later?
- Should the restricted assistant show citations in the UI?
- Should knowledge retrieval run on every question or only in knowledge mode?
- Should function calling stay in one shared router or split by screen domain?

## Next Step

The next implementation step should focus on tightening the company policy demo:

1. Polish the prompt composer and attachment flow.
2. Keep the restricted policy mode strict and predictable.
3. Prepare the knowledge retrieval layer for Firestore vector search.
4. Expand function calling with safer form and navigation actions.
