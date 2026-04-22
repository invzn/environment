import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";

// Read-only git subcommands that are safe
const ALLOWED_GIT_SUBCOMMANDS = new Set([
  "status", "log", "diff", "show", "branch", "tag",
  "ls-files", "ls-tree", "ls-remote",
  "blame", "shortlog", "describe",
  "rev-parse", "rev-list", "cat-file",
  "config", "remote",
]);

/**
 * Normalize a bash command to detect git invocations regardless of how
 * they are called (direct, via env/command, full path, subshells, etc.)
 *
 * Returns all git subcommands found in the command string.
 */
function extractGitSubcommands(command: string): string[] {
  const subcommands: string[] = [];

  // Match git invocations including:
  //   git <subcmd>
  //   /usr/bin/git <subcmd>
  //   /usr/local/bin/git <subcmd>
  //   command git <subcmd>
  //   env git <subcmd>
  //   builtin git <subcmd>
  //   \git <subcmd>  (backslash to bypass aliases)
  const pattern = /(?:(?:command|env|builtin)\s+)?(?:\\)?(?:[\w/.-]*\/)?git\s+([a-z][\w-]*)/g;
  let match;
  while ((match = pattern.exec(command)) !== null) {
    subcommands.push(match[1]);
  }

  return subcommands;
}

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event, _ctx) => {
    if (!isToolCallEventType("bash", event)) return;

    const command = event.input.command?.trim() ?? "";
    const subcommands = extractGitSubcommands(command);

    if (subcommands.length === 0) return;

    for (const sub of subcommands) {
      if (!ALLOWED_GIT_SUBCOMMANDS.has(sub)) {
        return {
          block: true,
          reason: `Blocked: "git ${sub}" is not allowed. Only read-only git commands are permitted: ${[...ALLOWED_GIT_SUBCOMMANDS].join(", ")}.`,
        };
      }
    }
  });
}
