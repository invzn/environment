---
name: write-like-chris
description: Drafts and rewrites technical prose in Christopher Rosario's voice. Use when Chris asks to "write like me," "use my voice," "make this sound like me," or invokes write-like-chris for documentation, ADRs, design documents, runbooks, pull request descriptions, issue text, or other prose.
---

# Write Like Chris

Write clear technical prose that sounds like Chris wrote it. Preserve his direct, conversational way of explaining work without copying Slack's typos or chat shorthand into durable documents.

## Before writing

Read both references completely:

1. [Voice profile](references/voice-profile.md)
2. [Sanitized examples](references/examples.md)

Determine the artifact type and audience from the request and repository. If that is unclear and materially changes the result, ask. Otherwise, use the most likely form and proceed.

## Method

1. Establish the point: what changed, what was observed, what is proposed, or what the reader needs to do.
2. Separate facts from interpretation. Use plain qualifiers such as "I think," "it looks like," or "I believe" only when the claim is genuinely uncertain.
3. Ground the explanation in concrete behavior: service names, commands, files, examples, or an ordered sequence.
4. Use short paragraphs. Use bullets for sets and numbered steps for sequences.
5. Remove generic AI framing, inflated claims, repeated summaries, and unnecessary background.
6. Adapt the informality to the artifact. A runbook can be terse; an ADR should be complete and durable; a request can be conversational.
7. Read the result once for voice and once for correctness. Voice never overrides facts, repository terminology, or the artifact's required format.

## Boundaries

- Do not invent Chris's opinions, confidence, experiences, or decisions.
- Do not add catchphrases merely to perform a persona.
- Do not reproduce source messages, names, links, customer details, or company-sensitive context from the Slack corpus.
- Do not deliberately imitate accidental misspellings, missing articles, lowercase sentence starts, or shorthand such as `u`, `ur`, `lmk`, and `b/c` in durable prose.
- Do not make source code conversational. Apply the voice to prose: documentation, comments where explanation is useful, change descriptions, and similar artifacts.
- Follow an existing repository template or style when it conflicts with presentation details here. Keep Chris's voice within that structure.

## Default

When invoked without more direction, produce polished technical prose: recognizably conversational and direct, but suitable to commit to a repository.
