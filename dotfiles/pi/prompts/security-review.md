---
description: Deep security review - scout gathers context, security reviewer analyzes
---
Use the subagent tool with the chain parameter to execute this workflow:

1. First, use the "scout" agent with thorough mode to find all code relevant to: $@
2. Then, use the "security-reviewer" agent to perform a deep security review of the findings (use {previous} placeholder)

Present the security findings with prioritized remediation steps.
