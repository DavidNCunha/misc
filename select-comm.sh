#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)" 
COMMANDS_FILE="$SCRIPT_DIR/commands" 

#cat commands | dmenu -p "Select command"
mapfile -t cmds < $COMMANDS_FILE
#
PS3="Choose a command: "
select cmd in "${cmds[@]}"; do
	if [[ -n "$cmd" ]]; then
		echo "Selected: $cmd"
		eval "$cmd"   # uncomment to execute automatically
		break
	elif [[ "$REPLY" == "q" ]]; then
		exit 0
	else
		echo "Invalid choice"
	fi
done

