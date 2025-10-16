#!/bin/sh
outputs=($(xrandr | awk '/ connected/ {print $1}'))

# Detect laptop screen (usually eDP or LVDS)
laptop=$(xrandr | awk '/ connected/ && ($1 ~ /^eDP|^LVDS/) {print $1}')

# Detect external screens (anything that's not the laptop)
externals=()
for out in "${outputs[@]}"; do
    [[ "$out" != "$laptop" ]] && externals+=("$out")
done

# Case 1: No external monitors connected
# Enable laptop monitor and exit.
if [ ${#externals[@]} -eq 0 ]; then
    #echo "No external monitors detected. Enabling laptop screen ($laptop)..."
    xrandr --output "$laptop" --auto --primary
#    for out in "${outputs[@]}"; do
#        [ "$out" != "$laptop" ] && xrandr --output "$out" --off
#    done
    exit 0
fi

#Case 2: If external monitors connected, select which monitor to display.
keep=$(xrandr | awk '/ connected/ {print $1}' | dmenu -p "Select display to keep:")
#echo "You selected output: $keep" 

# Exit if user canceled or made no selection
[ -z "$keep" ] && exit

# Turn off all others, keep the selected one on (auto mode)
for out in "${outputs[@]}"; do
    if [ "$out" != "$keep" ]; then
        xrandr --output "$out" --off
    else
        xrandr --output "$out" --auto
    fi
done
