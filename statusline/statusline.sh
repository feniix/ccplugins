#!/bin/bash
# Claude Code statusline with powerline style and git status
# Uses nerd fonts and ANSI colors for rainbow effect

input=$(cat)

# Validate JSON and extract fields safely
if ! echo "$input" | jq -e . >/dev/null 2>&1; then
    echo "⚠ invalid input"
    exit 0
fi

cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // empty' 2>/dev/null)
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // empty' 2>/dev/null)

# Get model - try id, then display_name, then fallback
model=$(echo "$input" | jq -r '.model.id // .model.display_name // .model // "claude"' 2>/dev/null)

# ANSI color codes - matching Starship palette
RESET=$'\033[0m'
BOLD=$'\033[1m'
BLINK=$'\033[5m'
FG_BLACK=$'\033[30m'
FG_WHITE=$'\033[97m'

# Starship colors (24-bit true color)
# Purple #8b5cf6 (username/hostname)
BG_PURPLE=$'\033[48;2;139;92;246m'
FG_PURPLE=$'\033[38;2;139;92;246m'

# Green #10b981 (directory)
BG_GREEN=$'\033[48;2;16;185;129m'
FG_GREEN=$'\033[38;2;16;185;129m'

# Blue #3b82f6 (git)
BG_BLUE=$'\033[48;2;59;130;246m'
FG_BLUE=$'\033[38;2;59;130;246m'

# Yellow #eab308 (warning/dirty)
BG_YELLOW=$'\033[48;2;234;179;8m'
FG_YELLOW=$'\033[38;2;234;179;8m'

# Dark gray (context bar)
BG_DARK=$'\033[48;2;55;65;81m'
FG_DARK=$'\033[38;2;55;65;81m'

# Legacy colors for progress bar
FG_RED=$'\033[38;5;196m'
FG_ORANGE=$'\033[38;5;208m'

# Powerline separator
SEP=''

# Git info - using Starship blue
git_segment=""
model_bg=$BG_PURPLE  # purple for model
model_fg=$FG_PURPLE
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
    [ -z "$branch" ] && branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)

    # Get status counts
    status=$(git -C "$cwd" status --porcelain 2>/dev/null)
    staged=$(echo "$status" | grep -c '^[MADRC]' || true)
    modified=$(echo "$status" | grep -c '^.[MD]' || true)

    # Ahead/behind
    ahead=$(git -C "$cwd" rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
    behind=$(git -C "$cwd" rev-list --count HEAD..@{u} 2>/dev/null || echo 0)

    # Build compact git status (starship style)
    git_status=""
    [ "$ahead" -gt 0 ] 2>/dev/null && git_status+="↑$ahead"
    [ "$behind" -gt 0 ] 2>/dev/null && git_status+="↓$behind"
    [ "$staged" -gt 0 ] && git_status+=" +$staged"
    [ "$modified" -gt 0 ] && git_status+=" M$modified"

    if [ -n "$git_status" ]; then
        git_content="  $branch $git_status "
    else
        git_content="  $branch "
    fi
    git_segment="${FG_GREEN}${BG_BLUE}${SEP}${FG_WHITE}${BOLD}${git_content}${RESET}"
    next_fg=$FG_BLUE
else
    next_fg=$FG_GREEN
fi

# CWD segment (always shown)
cwd_segment=""
if [ -n "$cwd" ]; then
    cwd_segment="${next_fg}${BG_DARK}${SEP}${FG_WHITE} $cwd ${RESET}"
    next_fg=$FG_DARK
fi

# Context progress bar
context_segment=""
usage=$(echo "$input" | jq '.context_window.current_usage // empty' 2>/dev/null)
if [ -n "$usage" ] && [ "$usage" != "null" ]; then
    current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens' 2>/dev/null)
    size=$(echo "$input" | jq '.context_window.context_window_size // 0' 2>/dev/null)
    if [ -n "$current" ] && [ "$current" != "null" ] && [ -n "$size" ] && [ "$size" != "null" ] && [ "$size" -gt 0 ] 2>/dev/null; then
        pct=$((current * 100 / size))

        # Build progress bar (10 chars wide)
        bar_width=10
        filled=$((pct * bar_width / 100))
        [ "$filled" -gt "$bar_width" ] && filled=$bar_width
        empty=$((bar_width - filled))

        # Colors for filled portion based on level
        if [ "$pct" -gt 95 ]; then
            fill_color=$'\033[38;2;239;68;68m'  # red #ef4444
            bar_blink=$BLINK
        elif [ "$pct" -gt 85 ]; then
            fill_color=$'\033[38;2;245;158;11m'  # orange #f59e0b
            bar_blink=""
        elif [ "$pct" -gt 70 ]; then
            fill_color=$FG_YELLOW  # yellow #eab308
            bar_blink=""
        else
            fill_color=$BG_GREEN  # green #10b981
            bar_blink=""
        fi
        empty_color=$'\033[38;2;148;163;184m'  # slate #94a3b8

        # Build the bar string
        filled_bar=""
        empty_bar=""
        for ((i=0; i<filled; i++)); do filled_bar+="█"; done
        for ((i=0; i<empty; i++)); do empty_bar+="░"; done

        context_segment="${next_fg}${BG_YELLOW}${SEP}${bar_blink}${fill_color}${filled_bar}${RESET}${BG_YELLOW}${empty_color}${empty_bar}${FG_WHITE} ${pct}%${RESET}"
    fi
fi

# Fallback if no context data
if [ -z "$context_segment" ]; then
    context_segment="${next_fg}${BG_YELLOW}${SEP}${FG_WHITE} --%${RESET}"
fi

# Build output: model -> project_dir -> git -> cwd -> context
echo -n "${BG_PURPLE}${FG_WHITE}${BOLD} $model ${RESET}"
echo -n "${FG_PURPLE}${BG_GREEN}${SEP}${FG_WHITE}${BOLD} $project_dir ${RESET}"
echo -n "$git_segment"
echo -n "$cwd_segment"
echo -n "$context_segment"
