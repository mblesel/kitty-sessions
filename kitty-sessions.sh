#!/usr/bin/env bash

# Set your Project paths here
# Currently only a depth of 1 is supported
KS_PATHS=(~/Projects ~/Documents)

# Check if all requirements are installed
sanity_check() {
    if ! command -v fzf &>/dev/null; then
        echo "fzf is not installed. Please install it first."
        exit 1
    fi
    if ! command -v fd &>/dev/null; then
        echo "fd is not installed. Please install it first."
        exit 1
    fi
}

usage() {
    echo "Usage: $0 [start|save]"
}

# Load an existing session or create a new one if the project does not already have one
start_session() {
    # Get all directories that already contain a kitty session file
    SESSION_FILES=$(fd --glob '*.kitty-session' "${KS_PATHS[@]}")
    SESSION_DIRS=$(echo "$SESSION_FILES" | while read -r session; do
        session_name=${session%/*.kitty-session}
        echo "$session_name"
    done)

    # Get all subdirectories from the given paths in KS_PATHS
    DIRS=$(fd . -t d --max-depth=1 "${KS_PATHS[@]}")
    # Remove all paths that already contain a kitty session file
    if [[ -n "$SESSION_DIRS" ]]; then
        FILTERED_DIRS=$(echo "$DIRS" | grep -v -F -f <(echo "$SESSION_DIRS"))
        # Tell the user about existing sessions by adding the [KITTY] prefix to them
        DISPLAY_SESSIONS=$(echo "$SESSION_DIRS" | while read -r session; do
            echo "[KITTY] $session"
        done)
    else
        FILTERED_DIRS="$DIRS"
        DISPLAY_SESSIONS=""
    fi

    SELECTED=$({
        echo "${DISPLAY_SESSIONS}"
        echo "${FILTERED_DIRS}"
    } | fzf)

    if [[ -n "$SELECTED" ]]; then
        # If an already exsiting session file was selected this session is loaded
        # KS_CURRENT_SESSION is set to the path of the selected session file
        # This is required for the kitty-save-session.sh script to work
        if [[ "$SELECTED" == "[KITTY] "* ]]; then
            ORIGINAL_PATH="${SELECTED#\[KITTY\] }"
            PROJECT_NAME="${SELECTED##*/}"
            ORIGINAL_PATH="${ORIGINAL_PATH}/${PROJECT_NAME}.kitty-session"
            kitten @ env KS_CURRENT_SESSION="$ORIGINAL_PATH"
            kitten @ action goto_session "$ORIGINAL_PATH"
        else
            SESSION_FILE_PATH="${SELECTED%/}"
            PROJECT_NAME="${SESSION_FILE_PATH##*/}"
            SESSION_FILE_PATH="${SESSION_FILE_PATH}/${PROJECT_NAME}.kitty-session"
            kitten @ env KS_CURRENT_SESSION="${SESSION_FILE_PATH}"
            kitten @ action launch --title="${PROJECT_NAME}" --type=tab --tab-title="${PROJECT_NAME}" --cwd="${SELECTED}"
            kitten @ action save_as_session --relocatable --match=session:^$ --save-only "${SESSION_FILE_PATH}"
            cp "${SESSION_FILE_PATH}" "${SESSION_FILE_PATH}.tmp"
            sed -n "/new_tab ${PROJECT_NAME}/,/focus/p" "${SESSION_FILE_PATH}.tmp" >"${SESSION_FILE_PATH}"
            rm "${SESSION_FILE_PATH}.tmp"
            kitten @ close-tab --match=title:"${PROJECT_NAME}"
            kitten @ action goto_session "${SESSION_FILE_PATH}"
        fi
    fi
}

# save the session of the currently active tab
save_session() {
    if [ -n "${KS_CURRENT_SESSION}" ]; then
        kitten @ action save_as_session --relocatable --save-only --match=session:. "${KS_CURRENT_SESSION}"
        # This workaround uses a new tab to run the script which has the name KS_TAB
        # This tab is then removed from the session file again
        sed -i '/new_tab KS_TAB/,/focus/d' "${KS_CURRENT_SESSION}"
    fi
}

sanity_check

if [ $# -gt 0 ]; then
    case "$1" in
    start)
        start_session
        ;;
    save)
        save_session
        ;;
    -h)
        usage
        ;;
    *)
        echo "Unknown argument: $1"
        exit 1
        ;;
    esac
else
    usage
fi

## TODOS
# Add config file where you can set the project directories being searched
# Look into automatic session saving
