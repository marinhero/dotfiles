#!/bin/sh

# Terminate already running bar instances
polybar-msg cmd quit 2>/dev/null

# Wait until the processes have been shut down
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.5; done

# Launch polybar on each monitor
if command -v xrandr >/dev/null && [ "$(xrandr --query | grep -c ' connected')" -gt 1 ]; then
  for m in $(xrandr --query | grep ' connected' | cut -d' ' -f1); do
    MONITOR=$m polybar main 2>&1 | tee -a /tmp/polybar-"$m".log &
  done
else
  polybar main 2>&1 | tee -a /tmp/polybar.log &
fi
