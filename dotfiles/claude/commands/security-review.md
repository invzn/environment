---
description: Deep security review - repo-expert gathers context, security reviewer analyzes
argument-hint: <scope (feature, area, or topic)>
---
Execute this chain sequentially:

1. Use Task with `subagent_type: "repo-expert"` and instruct it to use thorough mode to find all code relevant to: $ARGUMENTS
2. Use Task with `subagent_type: "security-reviewer"` to perform a deep security review — include the repo-expert's findings in the prompt

Present the security findings with prioritized remediation steps.
