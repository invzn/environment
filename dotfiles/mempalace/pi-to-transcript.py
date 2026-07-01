#!/usr/bin/env python3
"""Convert pi coding agent session JSONL to plain transcript format for MemPalace."""
import json
import sys
import os
from pathlib import Path

def extract_text(content):
    """Extract readable text from pi message content."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict):
                btype = block.get("type", "")
                if btype == "text":
                    text = block.get("text", "")
                    if text:
                        parts.append(text)
                elif btype == "thinking":
                    pass  # skip thinking blocks
                elif btype == "toolCall":
                    name = block.get("toolName", "unknown")
                    inp = block.get("input", {})
                    if name == "bash":
                        cmd = inp.get("command", "")
                        parts.append(f"[Tool: {name}] {cmd[:200]}")
                    elif name == "read":
                        parts.append(f"[Tool: {name}] {inp.get('path', '')}")
                    elif name in ("write", "edit"):
                        parts.append(f"[Tool: {name}] {inp.get('path', '')}")
                    else:
                        parts.append(f"[Tool: {name}]")
        return "\n".join(parts)
    return ""

def convert_session(jsonl_path):
    """Convert a pi session JSONL to transcript lines."""
    lines = []
    with open(jsonl_path) as f:
        for raw_line in f:
            raw_line = raw_line.strip()
            if not raw_line:
                continue
            try:
                entry = json.loads(raw_line)
            except json.JSONDecodeError:
                continue
            
            if entry.get("type") == "session":
                cwd = entry.get("cwd", "")
                ts = entry.get("timestamp", "")
                lines.append(f"# Pi Session — {cwd}")
                lines.append(f"# Started: {ts}")
                lines.append("")
            elif entry.get("type") == "message":
                msg = entry.get("message", {})
                role = msg.get("role", "")
                content = msg.get("content", "")
                text = extract_text(content)
                if not text:
                    continue
                if role == "user":
                    lines.append(f"Human: {text}")
                    lines.append("")
                elif role == "assistant":
                    lines.append(f"Assistant: {text}")
                    lines.append("")
                # skip toolResult — already captured in assistant tool calls
    return "\n".join(lines)

def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <sessions-dir> <output-dir>")
        sys.exit(1)
    
    sessions_dir = Path(sys.argv[1])
    output_dir = Path(sys.argv[2])
    output_dir.mkdir(parents=True, exist_ok=True)
    
    count = 0
    for project_dir in sessions_dir.iterdir():
        if not project_dir.is_dir() or project_dir.name.startswith("."):
            continue
        # Extract project name from dir name (pi encodes path with --)
        project_name = project_dir.name.strip("-").replace("-", "/")
        # Simplify to last meaningful segment
        parts = [p for p in project_name.split("/") if p]
        short_name = parts[-1] if parts else "unknown"
        
        for session_file in sorted(project_dir.glob("*.jsonl")):
            transcript = convert_session(session_file)
            if not transcript or transcript.count("Human:") < 1:
                continue
            
            out_name = f"{short_name}_{session_file.stem}.md"
            out_path = output_dir / out_name
            out_path.write_text(transcript)
            count += 1
    
    print(f"Converted {count} sessions to {output_dir}")

if __name__ == "__main__":
    main()
