#!/bin/bash

sleep 2

export DISPLAY=:1
export XDG_RUNTIME_DIR=/tmp/runtime-vscode

mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

# Fix X11 socket issue (still needed sometimes)
sudo mkdir -p /tmp/.X11-unix
sudo chmod 1777 /tmp/.X11-unix

# Kill old sessions
pkill -9 kasmvncserver Xvfb openbox chrome 2>/dev/null || true

# Start KasmVNC server
kasmvncserver :1 \
  -geometry 1517x852 \
  -depth 16 \
  -websocketPort 6080 \
  -interface 0.0.0.0 \
  > /tmp/kasmvnc.log 2>&1 &

# Wait for KasmVNC to initialize
sleep 3

# Show the log to debug
cat /tmp/kasmvnc.log

# Wait until display is ready (with timeout)
for i in {1..30}; do
  if xdpyinfo -display :1 >/dev/null 2>&1; then
    echo "✅ Display ready"
    break
  fi
  echo "⏳ Waiting for display... ($i/30)"
  sleep 1
done

# If display still not ready after 30 seconds, continue anyway
if ! xdpyinfo -display :1 >/dev/null 2>&1; then
  echo "⚠️ Display timeout - continuing anyway"
fi

# Start window manager
dbus-launch openbox > /tmp/openbox.log 2>&1 &

# Launch Chrome
(
  sleep 3
  DISPLAY=:1 google-chrome-stable \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-gpu \
    --start-maximized \
    https://google.com
) &

echo "🚀 KasmVNC running on port 6080"