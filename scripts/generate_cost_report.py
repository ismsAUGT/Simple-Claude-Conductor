#!/usr/bin/env python3
"""
Cost Report Generator for Simple Claude Conductor
Parses Claude Code session logs and generates a cost report.
"""

import json
import os
import sys
from datetime import datetime
from pathlib import Path

# API Pricing (per 1M tokens)
PRICING = {
    'claude-opus-4-5-20251101': {'input': 15.00, 'output': 75.00, 'cache_read': 1.875, 'cache_write': 18.75},
    'claude-sonnet-4-20250514': {'input': 3.00, 'output': 15.00, 'cache_read': 0.30, 'cache_write': 3.75},
    'claude-haiku-3-5-20241022': {'input': 0.80, 'output': 4.00, 'cache_read': 0.08, 'cache_write': 1.00},
    'default': {'input': 3.00, 'output': 15.00, 'cache_read': 0.30, 'cache_write': 3.75}
}

def get_pricing(model):
    """Get pricing for a model."""
    for key in PRICING:
        if key in str(model):
            return PRICING[key]
    return PRICING['default']

def parse_session(filepath):
    """Parse a session log file and extract token usage."""
    stats = {
        'input_tokens': 0,
        'output_tokens': 0,
        'cache_read': 0,
        'cache_write': 0,
        'model': 'unknown',
        'messages': 0,
        'start_time': None,
        'end_time': None
    }

    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                try:
                    entry = json.loads(line)
                    usage = entry.get('message', {}).get('usage', {})
                    model = entry.get('message', {}).get('model', '')
                    timestamp = entry.get('timestamp', '')

                    if model:
                        stats['model'] = model
                    if timestamp:
                        if not stats['start_time']:
                            stats['start_time'] = timestamp
                        stats['end_time'] = timestamp

                    stats['input_tokens'] += usage.get('input_tokens', 0)
                    stats['output_tokens'] += usage.get('output_tokens', 0)
                    stats['cache_read'] += usage.get('cache_read_input_tokens', 0)
                    stats['cache_write'] += usage.get('cache_creation_input_tokens', 0)

                    if entry.get('type') == 'assistant':
                        stats['messages'] += 1
                except json.JSONDecodeError:
                    pass
    except FileNotFoundError:
        pass

    return stats

def find_latest_session(project_path):
    """Find the most recent session for a project."""
    claude_projects = Path.home() / '.claude' / 'projects'

    # Look for project directory - Claude uses a specific naming format
    # e.g., c--NEOGOV-AIPM for C:\NEOGOV\AIPM
    session_dir = None

    if claude_projects.exists():
        dirs = list(claude_projects.iterdir())
        # Sort by modification time to get most recently used first
        dirs.sort(key=lambda x: x.stat().st_mtime if x.is_dir() else 0, reverse=True)

        for d in dirs:
            if d.is_dir():
                # Check if directory name contains project path components
                d_lower = d.name.lower()
                if 'aipm' in d_lower or 'neogov' in d_lower:
                    session_dir = d
                    break

    if not session_dir or not session_dir.exists():
        return None, None

    # Find the most recent session file
    session_files = list(session_dir.glob('*.jsonl'))
    session_files = [f for f in session_files if not f.name.startswith('agent-')]

    if not session_files:
        return None, None

    # Sort by modification time
    session_files.sort(key=lambda x: x.stat().st_mtime, reverse=True)
    latest = session_files[0]

    return latest, session_dir / latest.stem / 'subagents'

def generate_report(project_name, session_file, subagent_dir, output_path):
    """Generate a cost report."""

    # Parse main session
    main_stats = parse_session(session_file)
    session_id = session_file.stem if session_file else 'unknown'

    # Parse subagents
    subagent_stats = []
    if subagent_dir and subagent_dir.exists():
        for f in subagent_dir.glob('*.jsonl'):
            stats = parse_session(f)
            stats['id'] = f.stem.replace('agent-', '')
            subagent_stats.append(stats)

    # Calculate delegation metrics
    total_subagent_output = sum(sa['output_tokens'] for sa in subagent_stats)
    total_all_output = main_stats['output_tokens'] + total_subagent_output
    delegation_ratio = (total_subagent_output / total_all_output * 100) if total_all_output > 0 else 0

    # Identify "heavy work" subagents (>1000 output tokens = did real implementation)
    heavy_work_agents = [sa for sa in subagent_stats if sa['output_tokens'] > 1000]
    exploration_only_agents = [sa for sa in subagent_stats if sa['output_tokens'] <= 200]

    # Delegation health check (v3: warn on OVER-delegation, not under-delegation)
    # Healthy range: 0-50% delegation. Over 50% may indicate unnecessary agent spawning
    over_delegated = delegation_ratio > 50
    too_many_agents = len(subagent_stats) > 5
    main_session_bloated = main_stats['output_tokens'] > 50000
    delegation_healthy = not over_delegated and not too_many_agents

    # Calculate costs
    pricing = get_pricing(main_stats['model'])

    main_cost = (
        (main_stats['input_tokens'] / 1_000_000) * pricing['input'] +
        (main_stats['output_tokens'] / 1_000_000) * pricing['output'] +
        (main_stats['cache_read'] / 1_000_000) * pricing['cache_read'] +
        (main_stats['cache_write'] / 1_000_000) * pricing['cache_write']
    )

    total_input = main_stats['input_tokens']
    total_output = main_stats['output_tokens']
    total_cache_read = main_stats['cache_read']
    total_cache_write = main_stats['cache_write']

    subagent_cost = 0
    for sa in subagent_stats:
        sa_pricing = get_pricing(sa['model'])
        sa_cost = (
            (sa['input_tokens'] / 1_000_000) * sa_pricing['input'] +
            (sa['output_tokens'] / 1_000_000) * sa_pricing['output'] +
            (sa['cache_read'] / 1_000_000) * sa_pricing['cache_read'] +
            (sa['cache_write'] / 1_000_000) * sa_pricing['cache_write']
        )
        subagent_cost += sa_cost
        total_input += sa['input_tokens']
        total_output += sa['output_tokens']
        total_cache_read += sa['cache_read']
        total_cache_write += sa['cache_write']

    total_cost = main_cost + subagent_cost

    # Calculate efficiency
    total_tokens = total_input + total_output + total_cache_read + total_cache_write
    cache_efficiency = (total_cache_read / total_tokens * 100) if total_tokens > 0 else 0

    # Format timestamps
    start_time = main_stats['start_time'][:19] if main_stats['start_time'] else 'N/A'
    end_time = main_stats['end_time'][:19] if main_stats['end_time'] else 'N/A'

    # Generate report
    report = f"""# Cost Report: {project_name}

Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
Session ID: {session_id}

## Summary

| Metric | Value |
|--------|-------|
| Total Estimated Cost | **${total_cost:.2f}** |
| Session Duration | {start_time} to {end_time} |
| Model Used | {main_stats['model']} |
| Subagents Spawned | {len(subagent_stats)} |
| Delegation Ratio | {delegation_ratio:.1f}% |
| Cache Efficiency | {cache_efficiency:.1f}% |

## Token Usage

| Category | Tokens | Cost |
|----------|--------|------|
| Input Tokens | {total_input:,} | ${(total_input / 1_000_000) * pricing['input']:.4f} |
| Output Tokens | {total_output:,} | ${(total_output / 1_000_000) * pricing['output']:.4f} |
| Cache Read | {total_cache_read:,} | ${(total_cache_read / 1_000_000) * pricing['cache_read']:.4f} |
| Cache Write | {total_cache_write:,} | ${(total_cache_write / 1_000_000) * pricing['cache_write']:.4f} |
| **Total** | **{total_input + total_output + total_cache_read + total_cache_write:,}** | **${total_cost:.2f}** |

## Main Session

| Metric | Value |
|--------|-------|
| Input Tokens | {main_stats['input_tokens']:,} |
| Output Tokens | {main_stats['output_tokens']:,} |
| Cache Read | {main_stats['cache_read']:,} |
| Cache Write | {main_stats['cache_write']:,} |
| Messages | {main_stats['messages']} |
| Cost | ${main_cost:.2f} |

## Subagents

| Agent ID | Model | Output | Messages | Cost | Work Type |
|----------|-------|--------|----------|------|-----------|
"""

    for sa in subagent_stats:
        sa_pricing = get_pricing(sa['model'])
        sa_cost = (
            (sa['input_tokens'] / 1_000_000) * sa_pricing['input'] +
            (sa['output_tokens'] / 1_000_000) * sa_pricing['output'] +
            (sa['cache_read'] / 1_000_000) * sa_pricing['cache_read'] +
            (sa['cache_write'] / 1_000_000) * sa_pricing['cache_write']
        )
        # Determine work type based on output tokens
        if sa['output_tokens'] > 1000:
            work_type = "Heavy Work"
        elif sa['output_tokens'] > 200:
            work_type = "Light Work"
        else:
            work_type = "Exploration"

        # Extract model short name
        model_short = 'unknown'
        if 'opus' in sa['model'].lower():
            model_short = 'Opus'
        elif 'sonnet' in sa['model'].lower():
            model_short = 'Sonnet'
        elif 'haiku' in sa['model'].lower():
            model_short = 'Haiku'

        report += f"| {sa['id'][:20]}... | {model_short} | {sa['output_tokens']:,} | {sa['messages']} | ${sa_cost:.4f} | {work_type} |\n"

    if not subagent_stats:
        report += "| (none) | - | - | - | - | - |\n"

    # Add Delegation Analysis section
    delegation_status = "HEALTHY" if delegation_healthy else "WARNING"

    # Determine delegation ratio status
    if delegation_ratio > 50:
        ratio_status = "Over-delegated"
    elif delegation_ratio > 0:
        ratio_status = "OK"
    else:
        ratio_status = "Single-session"

    # Determine agent count status
    if len(subagent_stats) > 5:
        agent_status = "Too many"
    elif len(subagent_stats) > 3:
        agent_status = "High"
    else:
        agent_status = "OK"

    # Determine main session status
    if main_stats['output_tokens'] > 50000:
        main_status = "Bloated - consider compaction"
    elif main_stats['output_tokens'] > 20000:
        main_status = "High"
    else:
        main_status = "OK"

    report += f"""
## Delegation Health

| Metric | Value | Status |
|--------|-------|--------|
| Delegation Ratio | {delegation_ratio:.1f}% | {ratio_status} (healthy: 0-50%) |
| Subagents Spawned | {len(subagent_stats)} | {agent_status} (healthy: 0-3) |
| Main Session Output | {main_stats['output_tokens']:,} tokens | {main_status} |
| Subagent Output | {total_subagent_output:,} tokens | |
| Heavy Work Agents | {len(heavy_work_agents)} | |
| Exploration-Only | {len(exploration_only_agents)} | |

"""

    if over_delegated:
        report += """### Over-Delegation Warning

Delegation ratio exceeds 50%. This may indicate:
- Too many subagents spawned (each breaks KV-cache sharing)
- Subagents re-reading the same large files repeatedly
- Consider single-session mode for tasks with shared context

**Recommendation**: For implementation tasks with shared reference files (>50K tokens),
stay in the main session to benefit from cache reuse.

"""

    if too_many_agents:
        report += f"""### Too Many Subagents Warning

{len(subagent_stats)} subagents spawned (recommended: 0-3).
Each subagent re-reads files, breaking cache efficiency.

**Recommendation**: Break tasks into larger chunks or use single-session mode.

"""

    if main_session_bloated:
        report += """### Main Session Bloat Warning

Main session output exceeds 50K tokens. Consider:
- Using compaction (replace file contents with paths)
- Summarizing old tool outputs
- Starting fresh session for next phase

"""

    if heavy_work_agents:
        report += "### Heavy Work Agents (>1000 output tokens)\n\n"
        for agent in heavy_work_agents:
            report += f"- **{agent['id']}**: {agent['output_tokens']:,} output tokens, {agent['messages']} messages\n"
        report += "\n"

    savings = (total_cache_read / 1_000_000) * (pricing['input'] - pricing['cache_read'])

    report += f"""
## Pricing Reference (per 1M tokens)

| Model | Input | Output | Cache Read | Cache Write |
|-------|-------|--------|------------|-------------|
| Opus 4.5 | $15.00 | $75.00 | $1.875 | $18.75 |
| Sonnet 4 | $3.00 | $15.00 | $0.30 | $3.75 |
| Haiku 3.5 | $0.80 | $4.00 | $0.08 | $1.00 |

## Efficiency Analysis

- **Cache Efficiency: {cache_efficiency:.1f}%** - Percentage of tokens served from cache
- **Fresh Processing: {100 - cache_efficiency:.1f}%** - Tokens requiring new computation
- **Context Reuse Savings: ~${savings:.2f}** - Saved by using cache vs fresh input

> Note: This report uses API pricing for reference. Subscription users pay a flat monthly fee regardless of usage.
"""

    # Save report
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(report)

    return report, total_cost

def list_sessions(project_path):
    """List all available sessions for a project."""
    claude_projects = Path.home() / '.claude' / 'projects'

    session_dir = None
    if claude_projects.exists():
        for d in claude_projects.iterdir():
            if d.is_dir():
                d_lower = d.name.lower()
                if 'aipm' in d_lower or 'neogov' in d_lower:
                    session_dir = d
                    break

    if not session_dir:
        return []

    sessions = []
    for f in session_dir.glob('*.jsonl'):
        if not f.name.startswith('agent-'):
            stats = parse_session(f)
            sessions.append({
                'id': f.stem,
                'file': f,
                'start': stats['start_time'],
                'end': stats['end_time'],
                'messages': stats['messages'],
                'model': stats['model']
            })

    # Sort by start time
    sessions.sort(key=lambda x: x['start'] or '', reverse=True)
    return sessions, session_dir

def main():
    # Parse arguments
    import argparse
    parser = argparse.ArgumentParser(description='Generate cost report for Claude sessions')
    parser.add_argument('project_path', nargs='?', default='.', help='Project directory')
    parser.add_argument('--session', '-s', help='Specific session ID to analyze')
    parser.add_argument('--list', '-l', action='store_true', help='List available sessions')
    args = parser.parse_args()

    project_path = Path(args.project_path).resolve()

    # Try to get project name from project.yaml
    project_name = "Unknown Project"
    yaml_path = project_path / 'project.yaml'
    if yaml_path.exists():
        with open(yaml_path, 'r') as f:
            for line in f:
                if 'name:' in line:
                    project_name = line.split(':', 1)[1].strip().strip('"\'')
                    break

    # List sessions if requested
    if args.list:
        sessions, _ = list_sessions(project_path)
        print(f"Available sessions for {project_name}:\n")
        print(f"{'Session ID':<40} {'Start Time':<22} {'Messages':<10} {'Model'}")
        print("-" * 100)
        for s in sessions:
            start = s['start'][:19] if s['start'] else 'N/A'
            print(f"{s['id']:<40} {start:<22} {s['messages']:<10} {s['model']}")
        return

    # Find session
    if args.session:
        # Use specified session
        sessions, session_dir = list_sessions(project_path)
        session_file = None
        for s in sessions:
            if s['id'] == args.session or s['id'].startswith(args.session):
                session_file = s['file']
                break

        if not session_file:
            print(f"Error: Session '{args.session}' not found.")
            print("Use --list to see available sessions.")
            sys.exit(1)

        subagent_dir = session_dir / session_file.stem / 'subagents'
    else:
        # Find latest session
        session_file, subagent_dir = find_latest_session(project_path)

    if not session_file:
        print("Error: Could not find session logs.")
        print("Make sure you've run a Claude session in this project.")
        sys.exit(1)

    print(f"Found session: {session_file.name}")

    # Generate report
    output_path = project_path / 'output' / 'cost_report.md'
    report, total_cost = generate_report(project_name, session_file, subagent_dir, output_path)

    print(report)
    print(f"\n---\nReport saved to: {output_path}")

if __name__ == '__main__':
    main()
