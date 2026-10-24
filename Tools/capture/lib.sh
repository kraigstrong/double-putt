# Shared by the capture scripts (footage.sh, screenshots.sh, trailer.sh): the capture simulator, the build, and
# playing a clip from clips.json. Sourced, not run.
#
# The app's capture mode (MiniGolf/Game/StoreCapture.swift) stages a fresh saved state each launch, so it runs on a
# simulator of its own, "DP Capture iPhone 17 Pro Max" (made the first time; CAPTURE_DEVICE picks another by name or
# UDID): your usual simulator keeps its progress. Its screen is 1320x2868, the App Store's 6.9" size.

cd "$(dirname "${BASH_SOURCE[0]}")/../.."
ROOT="$PWD"
OUT="$ROOT/build/capture"
DERIVED="$OUT/DerivedData"
CLIPS="$ROOT/Tools/capture/clips.json"
BUNDLE=com.kraigstrong.doubleputt
DEVICE_NAME="${CAPTURE_DEVICE:-DP Capture iPhone 17 Pro Max}"
DEVICE_TYPE=com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max

# The capture simulator's UDID, made if it isn't there yet.
capture_device() {
    if [[ $DEVICE_NAME =~ ^[0-9A-Fa-f-]{36}$ ]]; then echo "$DEVICE_NAME"; return; fi
    local udid
    udid=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
name = sys.argv[1]
for devices in json.load(sys.stdin)["devices"].values():
    for d in devices:
        if d["name"] == name:
            print(d["udid"]); sys.exit()' "$DEVICE_NAME")
    if [ -z "$udid" ]; then
        udid=$(xcrun simctl create "$DEVICE_NAME" "$DEVICE_TYPE")
        echo "made the capture simulator, $DEVICE_NAME" >&2
    fi
    echo "$udid"
}

# Builds Debug for the capture simulator and installs it (CAPTURE_NO_BUILD=1 reuses the last build, if installed).
build_and_install() {
    UDID=$(capture_device)
    xcrun simctl boot "$UDID" 2>/dev/null || true
    xcrun simctl bootstatus "$UDID" -b >/dev/null
    if [ "${CAPTURE_NO_BUILD:-0}" = 1 ] && xcrun simctl get_app_container "$UDID" "$BUNDLE" >/dev/null 2>&1; then return; fi
    xcodebuild build -quiet -project MiniGolf.xcodeproj -scheme MiniGolf -configuration Debug \
        -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$DERIVED"
    xcrun simctl install "$UDID" "$DERIVED/Build/Products/Debug-iphonesimulator/MiniGolf.app"
}

# The clip's entry in clips.json, as one line of JSON.
clip_json() {
    python3 - "$CLIPS" "$1" <<'EOF'
import json, sys
clips, name = sys.argv[1:3]
for clip in json.load(open(clips))["clips"]:
    if clip["name"] == name:
        print(json.dumps(clip, separators=(",", ":"))); sys.exit()
sys.exit(f"no clip called {name} in {clips}")
EOF
}

# Every clip's name, in clips.json's order.
clip_names() {
    python3 -c 'import json, sys; print(" ".join(c["name"] for c in json.load(open(sys.argv[1]))["clips"]))' "$CLIPS"
}

# Plays clip $1 with the capture's arguments after it ($2...), waits for it to finish, and leaves its frames in
# $FRAMES (the app's Documents/StoreCapture).
play_clip() {
    local name="$1"; shift
    local json
    json=$(clip_json "$name") || return 1
    FRAMES="$(xcrun simctl get_app_container "$UDID" "$BUNDLE" data)/Documents/StoreCapture"
    xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
    rm -rf "$FRAMES"
    SIMCTL_CHILD_DP_CAPTURE_CLIP="$json" xcrun simctl launch "$UDID" "$BUNDLE" -storeCapture "$name" "$@" >/dev/null
    local waited=0
    until [ -f "$FRAMES/done.txt" ] || [ -f "$FRAMES/failed.txt" ]; do
        [ $waited -gt 18000 ] && { echo "$name: not done after half an hour" >&2; return 1; }
        perl -e 'select(undef, undef, undef, 0.1)'
        waited=$((waited + 1))
    done
    xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
    if [ -f "$FRAMES/failed.txt" ]; then
        echo "$name failed: $(cat "$FRAMES/failed.txt")" >&2
        return 1
    fi
}
