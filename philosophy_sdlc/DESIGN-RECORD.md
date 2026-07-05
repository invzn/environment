# Design Record Format

One markdown file per change, committed to the repo (default
`docs/design/<slug>.md`, slug in kebab-case). The record **accumulates through
the six stages** of the [complexity-first SDLC](./PHILOSOPHY_SDLC.md): each
stage fills exactly one section, each gate verdict is written into it, and
backtracking revises it in place. It is the change's design memory — the
artifact a stage agent reads as its input contract and writes as its output.

Three standing rules:

1. **Gates are recorded, never assumed.** Every gated section ends with an
   explicit `Gate:` line naming the verdict, who gave it, and when
   (non-negotiable 2). A missing gate line means the stage has not passed —
   later stages must not proceed past it.
2. **Revise in place; git history is the changelog.** Backtracking edits the
   earlier section directly and re-gates it. No "v2" sections. The one
   exception: §2 runners-up are never deleted — they are the evidence that
   design-it-twice happened, and the first place to return on backtrack.
3. **Decision log, not essay.** Every sentence records a decision, a reason, a
   finding, or a verdict. A healthy record for a typical change runs 60–150
   lines. If §3 dwarfs §2, the abstraction is fuzzy — that is a design signal,
   not a formatting problem.

## Skeleton

```markdown
# <slug> — design record

Status: stage <n> — <stage name>
Owner: <human> · Lead: <agent> · Started: <date>

## 1. Strategic intent

Owned knowledge:
- <what this change knows that nothing else may — 1–3 bullets>

Axis of change: <one sentence — what is likely to change behind the boundary>

Complexity budget:
- Allowed to get harder: <module/interface — and who pays>
- Must stay simple: <module/interface — and who would otherwise pay>

Gate (hard): approved by <human>, <date>

## 2. Designs considered

### Design A — <name>
- Abstraction: <one sentence>
- Interface sketch: <≤5 signatures, no bodies>
- Hides: <the decisions that stay encapsulated>
- Depth: <interface size vs functionality provided>

### Design B — <name>
- …

Verdict: <chosen design>. Deeper than <each runner-up, by name> because
<reason grounded in depth and information hiding>.

Gate (hard): approved by <human>, <date>

## 3. Interface contract

<the interface comment, verbatim, in a fenced code block — every public
signature, full behavioural contract, target language>

Errors defined out of existence: <which, and how — clamp / default / idempotent>
Errors that remain: <each with one sentence justifying its existence>

Critique screen: shallow module — <clean/finding> · information leakage — <…>
· overexposure — <…> · special-general mixture — <…> · pass-through — <…>

Gate (critique): passed, <date>  <or: backtracked to §2, <date>>

## 4. Implementation

Code: <module path> · Tests: <test path>
Locked behaviours:
- <one bullet per contract behaviour a test pins>
Complexity pulled down: <configuration, defaults, edge cases absorbed inside>
Interface delta: none

## 5. Red-flag audit

| Flag | Where | Finding | Verdict | Reasoning |
|---|---|---|---|---|
| classitis | | | | |
| pass-through method | | | | |
| repetition | | | | |
| comment repeats code | | | | |

Gate (block): all rows verdicted, <date>

## 6. Integration

Surrounding refactors: <what was redesigned so the change fits without
patching — or "none needed" plus why the seam was already clean>
Smallest-change proposals rejected: <the minimal patch the model offered and
why it was refused — or "none offered">
Budget settlement: <did anything outside §1's allowed-harder list get harder?>

Verdict (human): system complexity <down / flat / up>
Gate (human): merged by <human>, <date>  <or: blocked>
```

## Header

Title is the slug. `Status:` names the stage the record is currently in and is
updated at every transition, including backtracks — a stale status line is a
stale record.

## Section 1 — Strategic intent

Three fields, nothing else. No code, no design sketches — if a solution has
crept in, delete it; it belongs in §2 as one of the alternatives.

- **Owned knowledge** bullets are noun phrases naming knowledge, not verbs
  naming work: "retry policy for upstream fetches," not "handle retries
  better."
- Each **budget** entry names a module or interface *and who pays*: "the
  pricing module's internals may get harder (its one developer pays); the
  quoting call-sites must not (they are many)."

## Section 2 — Designs considered

- Two designs minimum, each named. A design you can't name is the
  *hard-to-pick-name* red flag showing up before a line of code — replace it.
- The radical-difference test: if two designs expose the same interface shape,
  they are variations, not alternatives. One of them doesn't count; generate
  another.
- Interface sketch: at most 5 signatures, no bodies. Depth is judged from
  here — how much behaviour hides behind how little surface.
- The **verdict** must beat each runner-up *by name*, on depth and information
  hiding. "Easier to build" may be recorded; it may not decide.

## Section 3 — Interface contract

- The contract is the code artifact, quoted verbatim — the interface comment
  exactly as it will ship, in the target language. Writing it here, before §4
  exists, is the point: there is no implementation yet to rationalize it.
- Backtrack triggers (to §2, before the gate): the contract needs a paragraph
  of special cases; the module can't be summarized in one sentence; a name
  refuses to settle.
- Every error that remains gets one sentence justifying why it could not be
  defined out of existence. No sentence, no error.
- The critique screen covers exactly the five interface-altitude flags, each
  marked `clean` or with a finding — screened, never assumed.

## Section 4 — Implementation

The shortest section: stage 4's real output is the code; the record keeps only
the accountability trail.

- **Locked behaviours** are phrased as contract semantics ("unset of an absent
  key succeeds idempotently"), never as test names.
- `Interface delta: none` is a required literal. Any delta means the interface
  was not settled: backtrack to §3, revise the contract, re-gate, return.

## Section 5 — Red-flag audit

- Written by the reviewing agent, prompted to *find* flaws, not bless the code.
- The four LLM-characteristic flags (classitis, pass-through method,
  repetition, comment repeats code) always get a row — `clean` entries include
  one line saying what was checked. The rest of the
  [full flag list](./GLOSSARY.md#design-red-flags) appears only as findings.
- Verdict is `repaired` or `refuted`. A refutation must engage the flag's
  definition; "acceptable for now" and "out of scope" are not refutations —
  they are unpaid findings, and they block.
- An empty verdict cell blocks stage 6. That is the merge rule, made visible.

## Section 6 — Integration

- "None needed" under surrounding refactors is a claim; record the reason the
  seam was already clean.
- **Budget settlement** closes the loop opened in §1 — the budget was set so it
  could be audited, so audit it.
- The human verdict is the workflow's exit condition. `up` means not merged:
  the record stays open and work returns to whichever stage the excess
  complexity came from.

## Backtracking

Update `Status:`, revise the target section in place, strike its gate line and
re-issue it (`Gate (hard): re-approved by <human>, <date>`). Mark every
downstream section the revision invalidates with a single line —
`> stale — revise before proceeding` — rather than deleting it; the marker is
what stops a later agent from reading a superseded contract as settled.

## Tone

Vocabulary from [`GLOSSARY.md`](./GLOSSARY.md) — *deep, shallow, hides, pulls
complexity down, defines errors out of existence, information hiding*. Numbers
over adjectives: "3 public functions hiding parsing, retries, and pagination"
earns its place; "a clean, simple interface" does not.

Phrasings to avoid: "robust," "scalable," "clean," "elegant," "best
practices," "leverages." None of them record a decision. Cut them.
