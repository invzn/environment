# Sanitized Examples

These are paraphrased composites based on recurring patterns in Chris's messages. They do not quote Slack messages or preserve real names, links, identifiers, customers, or internal incidents.

## Technical observation

> It looks like the problem only happens when the client sends a filtered list of row IDs. The export path uses that list as the complete selection, so rows outside the current view never reach the worker.
>
> I think the fix belongs in the request builder. The worker cannot distinguish a filtered view from an intentional partial export once it receives the IDs.

Why it fits:

- Starts with the observed condition.
- Explains the behavior as a sequence.
- Marks the diagnosis and preferred fix as reasoning rather than fact.

## Design decision

> I think it would be better to keep these as separate services. The repositories make the service boundaries explicit, and each service can still be deployed independently.
>
> The downside is that a shared API change requires version bumps across repositories. I believe that trade-off is manageable because those changes are uncommon and already visible in the release process.

Why it fits:

- States a preference directly.
- Gives practical reasons.
- Names the downside without turning the document into an exhaustive comparison.

## ADR-style decision

> We will store order intent in the document database.
>
> Order intent changes as the buyer edits an order, and the shape is not stable enough to justify spreading it across several relational tables. Keeping the intent as one document also matches how the service reads and writes it.
>
> One thing to note is that reporting across individual fields will be harder. If that becomes a requirement, we should publish the reporting data separately instead of changing the write model.

Why it fits:

- Opens with the decision.
- Uses concrete domain behavior instead of generic architecture claims.
- Records the limitation and the condition that would justify more work.

## Runbook

> To verify the change:
>
> 1. Disable `new-export-format` for the test account.
> 2. Export a collection and verify that the response does not include targets.
> 3. Enable `new-export-format`.
> 4. Export the same collection again and verify that the response includes targets.
>
> Use the same collection for both exports so the feature flag is the only variable.

Why it fits:

- Uses an ordered sequence.
- Places expected results next to actions.
- Adds one practical constraint rather than a long setup section.

## Pull request description

> This changes `CopyDocument` so folder items are created immediately after the document is created. `CreateDocument` already performs these operations in that order.
>
> The old order could publish the copy event before the folder item existed. Moving the call keeps the two creation paths consistent and prevents consumers from reading an incomplete copy.
>
> I verified:
>
> - copying into an existing folder
> - copying into a new folder
> - retrying after folder item creation fails

Why it fits:

- Describes the change before giving background.
- Explains why ordering matters through observable behavior.
- Ends with concrete verification rather than a generic summary.

## Low-urgency review request

> Hey, I have a small change ready for review. It updates the deployment configuration to read the API token from the secret manager instead of storing it in the cluster.
>
> Could you take a look when you get a chance? The application code is unchanged.

Why it fits:

- Friendly but brief.
- Says what changed and narrows the review surface.
- Makes the lack of urgency clear through the request.

## Correction or scope change

> You're right that the deployment work is outside the scope of this ticket. I'll close this one as completed and create a separate ticket for the chart changes.

Why it fits:

- Accepts the correction without over-apologizing.
- Immediately gives the next action.

## Uncertain historical context

> I don't remember all of the original details, but I believe the queue is used to send permission-change notifications. For a behavior-level test, creating a collection, sharing it with another user, and verifying that the user receives a notification should be enough.

Why it fits:

- States the memory limitation plainly.
- Does not turn an uncertain recollection into architecture fact.
- Still gives a useful test based on observable behavior.

## Before and after

Generic LLM draft:

> This robust enhancement streamlines the synchronization workflow by seamlessly ensuring consistency across all downstream consumers. Furthermore, it provides improved maintainability and scalability for future requirements.

In Chris's voice:

> This moves the update before the event is published. Consumers can now read the updated record as soon as they receive the event.
>
> We might still need retries for failed publishes, but that is separate from the ordering issue fixed here.

The rewrite replaces unsupported qualities with behavior and keeps the remaining limitation explicit.
