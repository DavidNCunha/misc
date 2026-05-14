#!/bin/bash
outputs=($(xrandr | awk '/ connected/ {print $1}'))

# Detect laptop screen (usually eDP or LVDS)
laptop=$(xrandr | awk '/ connected/ && ($1 ~ /^eDP|^LVDS/) {print $1}')

# Detect external screens (anything that's not the laptop)
externals=()
for out in "${outputs[@]}"; do
    [[ "$out" != "$laptop" ]] && externals+=("$out")
done

# -------------------------
# Get preferred resolution
# -------------------------
get_preferred_mode() {
    xrandr | awk -v mon="$1" '
        $1 == mon {
            found=1
            next
        }

        found && /^[[:space:]]+[0-9]/ {

            # Preferred mode marked with +
            if ($0 ~ /\+/) {
                print $1
                exit
            }

            # Otherwise remember first mode
            if (!first_mode)
                first_mode=$1
        }

        # Stop when next monitor block begins
        found && /^[^[:space:]]/ {
            if (first_mode)
                print first_mode
            exit
        }

        END {
            if (first_mode)
                print first_mode
        }
    '
}
#    xrandr | awk -v monitor="$1" '
#        $1 == monitor { found=1; next }
#        found && /^\s+[0-9]/ {
#            if ($0 ~ /\+/) {
#                print $1
#                exit
#            }
#        }
#        found && /^[^ ]/ { exit }
#    '
#}

# Case 1: No external monitors connected
# Enable laptop monitor and exit.
if [ ${#externals[@]} -eq 0 ]; then
    mode=$(get_preferred_mode "$laptop")

    xrandr \
        --output "$laptop" \
        --mode "$mode" \
        --primary

    exit 0
fi

#if [ ${#externals[@]} -eq 0 ]; then
#    #echo "No external monitors detected. Enabling laptop screen ($laptop)..."
#    xrandr --output "$laptop" --auto --primary
##    for out in "${outputs[@]}"; do
##        [ "$out" != "$laptop" ] && xrandr --output "$out" --off
##    done
#    exit 0
#fi

# Main action menu 
action=$(printf "Single\nExtend\nMirror" | dmenu -p "Display mode:")

[ -z "$action" ] && exit

#Case 2: If external monitors connected, select which monitor to display.
if [ "$action" = "Single" ]; then
	keep=$(xrandr | awk '/ connected/ {print $1}' | dmenu -p "Select display to keep:")
#echo "You selected output: $keep" 

# Exit if user canceled or made no selection
	[ -z "$keep" ] && exit

#Fetch chosen monitor's preferred display mode
keep_mode=$(get_preferred_mode "$keep")
echo $keep_mode

# Turn off all others, keep the selected one on (auto mode)
	for out in "${outputs[@]}"; do
	    if [ "$out" != "$keep" ]; then
	        xrandr --output "$out" --off
	    else
	    	xrandr \
       		        --output "$out" \
      	        	--mode "$keep_mode" \
       		        --primary
	    fi
	done
fi

# -------------------------
# EXTEND MODE
# -------------------------
if [ "$action" = "Extend" ]; then
    primary=$(printf "%s\n" "${outputs[@]}" | dmenu -p "Primary display:")

    [ -z "$primary" ] && exit

    secondary=$(printf "%s\n" "${outputs[@]}" \
        | grep -v "^$primary$" \
        | dmenu -p "Extend to:")

    [ -z "$secondary" ] && exit

    position=$(printf "right-of\nleft-of\nabove\nbelow" \
        | dmenu -p "Position:")

    [ -z "$position" ] && exit

#Fetch chosen monitor's preferred display mode
    primary_mode=$(get_preferred_mode "$primary") 
    secondary_mode=$(get_preferred_mode "$secondary")

    # Turn everything on first
    xrandr --output "$primary" \
	   --mode "$primary_mode" \
	   --primary \
           --output "$secondary" \
	   --mode "$secondary_mode" \
	   "--$position" "$primary"

    # Turn off unused outputs
    for out in "${outputs[@]}"; do
        if [ "$out" != "$primary" ] && [ "$out" != "$secondary" ]; then
            xrandr --output "$out" --off
        fi
    done
fi
# -------------------------
# MIRROR MODE
# -------------------------
if [ "$action" = "Mirror" ]; then
    primary=$(printf "%s\n" "${outputs[@]}" | dmenu -p "Primary display:")
    [ -z "$primary" ] && exit

    secondary=$(printf "%s\n" "${outputs[@]}" | grep -v "^$primary$" | dmenu -p "Mirror to:")
    [ -z "$secondary" ] && exit

#Fetch chosen monitor's preferred display mode
    primary_mode=$(get_preferred_mode "$primary") 
    secondary_mode=$(get_preferred_mode "$secondary")

    xrandr \
        --output "$primary" --mode "$primary_mode" --primary \
        --output "$secondary" --mode "$secondary_mode" 

    for out in "${outputs[@]}"; do
        if [ "$out" != "$primary" ] && [ "$out" != "$secondary" ]; then
            xrandr --output "$out" --off
        fi
    done
fi
