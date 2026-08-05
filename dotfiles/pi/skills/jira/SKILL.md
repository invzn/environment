---
name: jira
description: Fetch Jira tickets by key or search with JQL via the Jira Cloud REST API. Use when the user mentions a Jira ticket key (e.g. ABC-123), asks to look up or fetch a Jira issue, or wants to find tickets (their open tickets, a sprint's tickets, recently updated ones).
---

# Jira Tickets (read-only)

Fetch and search Jira Cloud tickets with `curl` against the REST API. This skill is read-only: never create, edit, transition, or comment on tickets.

## Prerequisites

Connection details live in a JSON file at `${XDG_CONFIG_HOME:-$HOME/.config}/jira/config.json`:

```json
{
  "site": "https://yourcompany.atlassian.net",
  "email": "you@example.com",
  "api_token": "..."
}
```

`site` is the base URL with no trailing slash. Load it before the first request:

```bash
JIRA_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/jira/config.json"
JIRA_SITE=$(jq -re .site "$JIRA_CONFIG")
JIRA_EMAIL=$(jq -re .email "$JIRA_CONFIG")
JIRA_API_TOKEN=$(jq -re .api_token "$JIRA_CONFIG")
```

If the file is missing or any key is empty, stop and tell the user to:

1. Create an API token at https://id.atlassian.com/manage-profile/security/api-tokens
2. Create the JSON file above with all three keys (and never commit it to a repo)

Never echo `api_token` or include it in output shown to the user — don't `cat` the config file.

## Fetch a ticket by key

Use API **v2** for single issues — it returns the description and comments as plain text / wiki markup instead of ADF JSON, which is far easier to read:

```bash
curl -sf -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  "$JIRA_SITE/rest/api/2/issue/KEY-123?fields=summary,issuetype,status,priority,assignee,reporter,created,updated,labels,fixVersions,parent,description,comment"
```

Format the result with jq before presenting it:

```bash
... | jq -r '
  "\(.key): \(.fields.summary)",
  "Type: \(.fields.issuetype.name) | Status: \(.fields.status.name) | Priority: \(.fields.priority.name // "-")",
  "Assignee: \(.fields.assignee.displayName // "Unassigned") | Reporter: \(.fields.reporter.displayName // "-")",
  "Created: \(.fields.created) | Updated: \(.fields.updated)",
  "",
  "Description:",
  (.fields.description // "(none)"),
  "",
  "Comments:",
  (.fields.comment.comments[]? | "--- \(.author.displayName) (\(.created)):\n\(.body)")
'
```

## Search with JQL

Use `/rest/api/3/search/jql` — the legacy `/rest/api/2/search` and `/rest/api/3/search` endpoints were removed from Jira Cloud in 2025. JQL must be URL-encoded; pass it with `--data-urlencode` and `-G`:

```bash
curl -sf -G -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  "$JIRA_SITE/rest/api/3/search/jql" \
  --data-urlencode 'jql=assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC' \
  --data-urlencode 'fields=summary,status,issuetype,priority,updated' \
  --data-urlencode 'maxResults=50'
```

Present results as a compact list:

```bash
... | jq -r '.issues[] | "\(.key)\t\(.fields.status.name)\t\(.fields.summary)"'
```

Useful JQL patterns:

- My open tickets: `assignee = currentUser() AND statusCategory != Done`
- Current sprint for a project: `project = ABC AND sprint in openSprints()`
- Recently updated: `project = ABC AND updated >= -7d ORDER BY updated DESC`
- Free-text: `text ~ "payment timeout"`

If the response contains a `nextPageToken`, there are more results — pass it back via `--data-urlencode "nextPageToken=..."` to fetch the next page. Only paginate if the user needs more than the first page.

## Errors

- **401** — token or email is wrong; ask the user to regenerate the API token.
- **404 on an issue** — the key doesn't exist *or* the account lacks permission to see it; report both possibilities.
- **400 on search** — invalid JQL; show the `errorMessages` field from the response body (drop `-f` and inspect the body when debugging).
- **Could not resolve host** — `JIRA_SITE` is likely malformed; it must include the scheme, e.g. `https://yourcompany.atlassian.net`.
