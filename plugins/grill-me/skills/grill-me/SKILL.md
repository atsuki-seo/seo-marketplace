---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
---

Interview the user relentlessly about every aspect of their plan until you reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one at a time — upstream choices before downstream ones, since a downstream answer can become moot when the upstream decision flips.

## Core rhythm

Ask **one question at a time**. Wait for the answer before moving on. This keeps the user's attention on a single decision and prevents shallow batch-answers.

If a question can be answered by exploring the codebase, explore the codebase instead of asking. The goal is to surface decisions that genuinely need the user's judgment, not to quiz them on facts you can look up.

## How to ask each question

For every question, provide a **recommended answer** alongside it. A recommendation forces you to take a position, which makes the conversation faster and sharper than open-ended prompting — the user can confirm, adjust, or push back against a concrete proposal.

Each recommendation must include three things, kept brief (1–2 sentences each):

1. **The recommended answer** — what you'd choose.
2. **Why** — the reasoning behind it.
3. **Trade-off** — what is given up by choosing this over the alternatives.

The trade-off line matters most. Without it, the user tends to rubber-stamp recommendations (yes-man mode) because the downside is invisible. Naming what is sacrificed gives them a concrete hook to disagree with: "no, I can't give that up."

Keep it tight. Don't add confidence scores, fully fleshed-out counter-proposals, or long justifications — that bloats each round and breaks the one-question rhythm.

## Choosing the question format

Use **AskUserQuestion** only when the answer space naturally collapses to 3–5 roughly mutually exclusive options. In that case, the picker UI is faster than typing a reply.

Otherwise, ask in **free text**. This applies to:

- Open-ended questions about intent, motivation, or constraints.
- Questions where you can't confidently enumerate the full option space.
- Questions where the interesting answer is likely *outside* the options you'd generate.

The risk of over-using AskUserQuestion is that you pre-decide the answer space, and the user picks from your frame instead of articulating theirs. grill-me exists to pull thinking out of the user — don't cage it with premature multiple choice.

When in doubt, free text. A free-text question with a recommended answer captures most of the speed benefit of a picker without foreclosing options.

## When to stop

Continue until every branch of the decision tree has been resolved. Don't impose a question-count or time limit — the right number of questions depends on the complexity of the plan, and capping it risks stopping mid-tree with unresolved dependencies.

When all branches are resolved, produce a **summary** with this structure:

```
## 決定事項
- <decision 1>
- <decision 2>
- ...

## 未解決/保留
- <item 1>
- <item 2>
- ...
```

One line per item. The decision list is the artifact the user carries forward into a plan or spec, so it should be terse and paste-ready — no restated reasoning, no narrative recap. The未解決/保留 section exists as a safety valve: if a branch was deferred, left ambiguous, or surfaced but not resolved, list it here rather than pretending it was settled. If nothing is pending, write "なし" (or omit the section only if truly empty and you want to signal completeness).
