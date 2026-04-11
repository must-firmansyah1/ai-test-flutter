# Company Policy Knowledge Seed

This document defines the first approved knowledge set for the company policy assistant.
It is intended to be the source material for future Firestore storage, chunking, and
vector search retrieval.

## Purpose

Use this knowledge set to answer policy questions only from approved company rules.
The assistant must not guess or use outside knowledge when policy mode is active.

## Source Policy Statements

### 1. Annual Leave

- Annual leave entitlement is 20 days per calendar year.
- Annual leave usage must follow the company approval workflow.

### 2. Sick Leave

- Sick leave entitlement is 10 days per calendar year.
- A medical certificate is required for 3 consecutive sick days or more.
- The assistant should not invent exceptions that are not written in the policy.

### 3. National Holidays

- Company holidays follow the official national holiday calendar.
- If a day is listed as a national holiday, it is treated as a company holiday unless a separate notice says otherwise.

### 4. Reimbursement

- Reimbursement requests must be submitted within 14 days after the expense date.
- Valid receipts must be attached to the reimbursement request.
- Late submissions require manual review.

### 5. Remote Work

- Remote work requests must be approved by the direct manager before the workday starts.
- Remote work approval is required even if the employee has used remote work before.

## Chunk-Ready Knowledge Records

These records are formatted so they can later be moved into Firestore as document chunks.

```text
id: annual_leave
title: Annual Leave
text: Annual leave entitlement is 20 days per calendar year. Annual leave usage must follow the company approval workflow.
tags: leave, annual, vacation, approval
source: company_policy_handbook
section: leave_policy

id: sick_leave
title: Sick Leave
text: Sick leave entitlement is 10 days per calendar year. A medical certificate is required for 3 consecutive sick days or more.
tags: leave, sick, medical, certificate, doctor
source: company_policy_handbook
section: leave_policy

id: national_holidays
title: National Holidays
text: Company holidays follow the official national holiday calendar. If a day is listed as a national holiday, it is treated as a company holiday unless a separate notice says otherwise.
tags: holiday, calendar, national, company holiday
source: company_policy_handbook
section: holiday_policy

id: reimbursement
title: Reimbursement
text: Reimbursement requests must be submitted within 14 days after the expense date. Valid receipts must be attached to the reimbursement request. Late submissions require manual review.
tags: reimbursement, expense, receipt, finance
source: company_policy_handbook
section: reimbursement_policy

id: remote_work
title: Remote Work
text: Remote work requests must be approved by the direct manager before the workday starts. Remote work approval is required even if the employee has used remote work before.
tags: remote work, wfh, manager, approval
source: company_policy_handbook
section: remote_work_policy
```

## Expected Answer Rules

The assistant should answer only from the policy text above.

Examples:

- If the user asks, "I have been sick for 4 days. Do I need a doctor's note?"
  - The correct answer is yes, because the policy requires a medical certificate for 3 consecutive sick days or more.

- If the user asks, "How many annual leave days do I get?"
  - The correct answer is 20 days per calendar year.

- If the user asks, "Can I submit reimbursement after 20 days?"
  - The correct answer is that the request is late and requires manual review.

## Firestore Usage Plan

When this knowledge set moves into Firestore, each record should store:

- `id`
- `title`
- `text`
- `tags`
- `source`
- `section`
- `version`
- `embedding_vector`
- `created_at`
- `updated_at`

The app should:

1. chunk the source policy into records like the ones above,
2. generate embeddings for each chunk,
3. store the chunk in Firestore,
4. retrieve the most relevant chunks by query,
5. pass only retrieved chunks into the model prompt.

## Notes For Future Expansion

- Keep each policy rule short and specific.
- Do not mix multiple policy domains in one chunk unless they are tightly related.
- Add a new chunk when a policy section changes, instead of silently overwriting the rule text.
- If a policy is deleted, keep the old version archived for traceability.
