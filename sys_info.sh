#!/bin/bash

clear

echo "=========================================="
echo "         REPLIT LINUX DASHBOARD          "
echo "=========================================="
echo ""

# Display OS Info
echo "--- Operating System ---"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "OS: $PRETTY_NAME"
else
    echo "OS: $(uname -s -r)"
fi
echo "Kernel: $(uname -r)"
echo ""

# Display CPU Specs
echo "--- CPU Resources ---"
CPU_MODEL=$(grep -m 1 "model name" /proc/cpuinfo | awk -F: '{print $2}' | sed -e 's/^[ \t]*//')
CPU_CORES=$(nproc)
echo "Model: $CPU_MODEL"
echo "Available Cores: $CPU_CORES"
echo ""

# Display Memory Metrics
echo "--- RAM Usage ---"
free -h | awk '/Mem:/ {print "Total: " $2 " | Used: " $3 " | Free: " $4 " | Available: " $7}'
echo ""

# Display Workspace Storage
echo "--- Storage (/home/runner/workspace) ---"
df -h /home/runner/workspace | awk 'NR==2 {print "Total: " $2 " | Used: " $3 " | Available: " $4 " | Usage: " $5}'
echo ""

echo "=========================================="
echo ""

read -n 1 -s -r -p "Press any key to launch the desktop environment..."
echo -e "\nLaunching Desktop Environment..."

# 1. Clean up stale background processes
pkill -9 -f Xvfb >/dev/null 2>&1
pkill -9 -f x11vnc >/dev/null 2>&1
pkill -9 -f websockify >/dev/null 2>&1
pkill -9 -f openbox >/dev/null 2>&1
pkill -9 -f xterm >/dev/null 2>&1
pkill -9 -f tint2 >/dev/null 2>&1
rm -rf /tmp/.X*-lock /tmp/.X11-unix/X* ~/.vnc/*.pid ~/.vnc/*.log >/dev/null 2>&1
sleep 1

# 2. Set display environment
export DISPLAY=:99
export XDG_RUNTIME_DIR="/tmp/runtime-$USER"
mkdir -p "$XDG_RUNTIME_DIR" ~/.config ~/.cache ~/.local
chmod 700 "$XDG_RUNTIME_DIR"

# 3. Start Virtual Display Server
Xvfb :99 -ac -screen 0 1280x720x24 -noreset > /dev/null 2>&1 &
sleep 2

# 4. Set slate background color
xsetroot -solid "#1e1e2e" >/dev/null 2>&1 || true

# 5. Start Window Manager & Desktop Components
openbox &
sleep 1

# Launch taskbar panel & file manager
tint2 >/dev/null 2>&1 &

# Launch styled xterm with scalable TrueType font
xterm -fa "DejaVu Sans Mono" -fs 11 -geometry 105x32+60+60 -bg "#11111b" -fg "#cdd6f4" -cr "#f5e0dc" &

# 6. Start VNC Server
x11vnc -display :99 -rfbport 5901 -nopw -forever -shared -bg -noxdamage -noxrecord > /dev/null 2>&1
sleep 2

# 7. Setup noVNC web client
if [ ! -d "$HOME/.novnc" ]; then
    echo "Downloading noVNC web interface..."
    git clone --depth 1 https://github.com/novnc/noVNC.git ~/.novnc >/dev/null 2>&1
fi

if [ ! -d "$HOME/.websockify" ]; then
    echo "Downloading websockify proxy..."
    git clone --depth 1 https://github.com/novnc/websockify.git ~/.websockify >/dev/null 2>&1
fi

chmod +x "$HOME/.websockify/run"

cat << 'EOF' > "$HOME/.novnc/index.html"
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="refresh" content="0; url=vnc.html?autoconnect=true&reconnect=true" />
</head>
<body>
    <p>Connecting to Linux Desktop...</p>
</body>
</html>
EOF

echo ""
echo "Desktop ready! Click 'Port :8080 opened on {...}.replit.dev' at the bottom left."

# 8. Serve Web VNC Proxy
PYTHONWARNINGS="ignore" "$HOME/.websockify/run" --web="$HOME/.novnc" 0.0.0.0:8080 127.0.0.1:5901
