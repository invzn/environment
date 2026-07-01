import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { execSync } from "node:child_process";
import { writeFileSync, mkdirSync, existsSync, readFileSync } from "node:fs";
import { join, basename } from "node:path";
import { homedir } from "node:os";

const PALACE_DIR = join(homedir(), ".mempalace", "palace");
const PI_SESSIONS_DIR = join(homedir(), ".mempalace", "pi-sessions");
const CONVERTER_SCRIPT = join(homedir(), ".mempalace", "pi-to-transcript.py");
const SESSIONS_DIR = join(homedir(), ".pi", "agent", "sessions");

export default function (pi: ExtensionAPI) {
  // --- Search tool: let the LLM query past sessions ---
  pi.registerTool({
    name: "mempalace_search",
    label: "MemPalace Search",
    description:
      "Search past pi coding agent sessions across all projects using semantic search. Returns relevant conversation snippets from previous sessions.",
    promptSnippet:
      "Search past coding sessions for relevant context, decisions, and solutions",
    promptGuidelines: [
      "Use mempalace_search when the user references past work, previous sessions, or asks 'didn't we already...'",
      "Use mempalace_search to find context from other projects that might be relevant to the current task",
    ],
    parameters: Type.Object({
      query: Type.String({ description: "What to search for" }),
      wing: Type.Optional(
        Type.String({
          description: "Filter to a specific wing (project name)",
        })
      ),
      limit: Type.Optional(
        Type.Number({ description: "Max results (default 5)" })
      ),
    }),
    async execute(_toolCallId, params) {
      try {
        const args = ["search", JSON.stringify(params.query)];
        if (params.wing) args.push("--wing", params.wing);
        if (params.limit) args.push("--results", String(params.limit));

        const result = execSync(`mempalace ${args.join(" ")}`, {
          encoding: "utf-8",
          timeout: 15000,
        });

        return {
          content: [{ type: "text", text: result || "No results found." }],
          details: { query: params.query },
        };
      } catch (e: any) {
        return {
          content: [
            {
              type: "text",
              text: `Search failed: ${e.message || "unknown error"}`,
            },
          ],
          details: {},
          isError: true,
        };
      }
    },
  });

  // --- Sync command: manually sync current sessions to MemPalace ---
  pi.registerCommand("mempalace-sync", {
    description: "Sync pi sessions to MemPalace",
    handler: async (_args, ctx) => {
      try {
        // Convert pi sessions to transcripts
        execSync(`python3 "${CONVERTER_SCRIPT}" "${SESSIONS_DIR}" "${PI_SESSIONS_DIR}"`, {
          encoding: "utf-8",
          timeout: 30000,
        });

        // Mine new transcripts
        const result = execSync(
          `mempalace mine "${PI_SESSIONS_DIR}" --mode convos --wing pi-sessions 2>&1`,
          { encoding: "utf-8", timeout: 60000 }
        );

        // Extract stats
        const drawersMatch = result.match(/Drawers filed:\s+(\d+)/);
        const skippedMatch = result.match(/Files skipped.*:\s+(\d+)/);
        const drawers = drawersMatch ? drawersMatch[1] : "?";
        const skipped = skippedMatch ? skippedMatch[1] : "?";

        ctx.ui.notify(
          `MemPalace synced: ${drawers} drawers filed, ${skipped} skipped`,
          "success"
        );
      } catch (e: any) {
        ctx.ui.notify(`Sync failed: ${e.message}`, "error");
      }
    },
  });

  // --- Auto-sync on session shutdown ---
  pi.on("session_shutdown", async (_event, _ctx) => {
    try {
      // Convert and mine in background — don't block shutdown
      execSync(
        `python3 "${CONVERTER_SCRIPT}" "${SESSIONS_DIR}" "${PI_SESSIONS_DIR}" && mempalace mine "${PI_SESSIONS_DIR}" --mode convos --wing pi-sessions 2>/dev/null`,
        { encoding: "utf-8", timeout: 30000 }
      );
    } catch {
      // Silent fail — don't block pi shutdown
    }
  });

  // --- Wake-up context on session start ---
  pi.on("before_agent_start", async (event, ctx) => {
    // Only inject on first prompt of a session
    const entries = ctx.sessionManager.getEntries();
    const messageCount = entries.filter((e) => e.type === "message").length;
    if (messageCount > 1) return; // Not the first prompt

    try {
      const wakeup = execSync("mempalace wake-up --wing pi-sessions 2>/dev/null", {
        encoding: "utf-8",
        timeout: 10000,
      }).trim();

      if (wakeup && wakeup.length > 50) {
        return {
          message: {
            customType: "mempalace-context",
            content: `## Recent session context (from MemPalace)\n\n${wakeup}`,
            display: false,
          },
        };
      }
    } catch {
      // Silent — no context available
    }
  });
}
