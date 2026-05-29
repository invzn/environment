---
description: Language expert implements, reviewer reviews, expert applies feedback
---
Use the subagent tool with the chain parameter to execute this workflow:

1. First, use the "repo-expert" agent to gather context for: $@
2. Then, use the appropriate language expert agent ("go-expert", "python-expert", or "language-expert") to implement based on the findings (use {previous} placeholder)
3. Then, use the "reviewer" agent to review the implementation (use {previous} placeholder)
4. Finally, use the same language expert agent to apply the feedback from the review (use {previous} placeholder)

Execute this as a chain, passing output between steps via {previous}.
