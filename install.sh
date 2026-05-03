#!/usr/bin/env bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/vipulgupta2048/unlock-pdf-mac/main"
SERVICES_DIR="$HOME/Library/Services"
WORKFLOW_NAME="Unlock PDF.workflow"
WORKFLOW_DIR="$SERVICES_DIR/$WORKFLOW_NAME"

echo "==> Installing Unlock PDF for macOS"

if [[ "$(uname)" != "Darwin" ]]; then
  echo "Error: this installer only runs on macOS." >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Error: Homebrew is required. Install from https://brew.sh and re-run." >&2
  exit 1
fi

if ! command -v qpdf >/dev/null 2>&1; then
  echo "==> Installing qpdf via Homebrew"
  brew install qpdf
else
  echo "==> qpdf already installed: $(qpdf --version | head -1)"
fi

mkdir -p "$SERVICES_DIR"

if [ -d "$WORKFLOW_DIR" ]; then
  echo "==> Removing previous installation"
  rm -rf "$WORKFLOW_DIR"
fi

mkdir -p "$WORKFLOW_DIR/Contents"

cat > "$WORKFLOW_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSServices</key>
  <array>
    <dict>
      <key>NSMenuItem</key>
      <dict>
        <key>default</key>
        <string>Unlock PDF</string>
      </dict>
      <key>NSMessage</key>
      <string>runWorkflowAsService</string>
      <key>NSRequiredContext</key>
      <dict>
        <key>NSApplicationIdentifier</key>
        <string>com.apple.finder</string>
      </dict>
      <key>NSSendFileTypes</key>
      <array>
        <string>com.adobe.pdf</string>
      </array>
    </dict>
  </array>
</dict>
</plist>
PLIST

cat > "$WORKFLOW_DIR/Contents/document.wflow" <<'WFLOW'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>AMApplicationBuild</key>
  <string>523</string>
  <key>AMApplicationVersion</key>
  <string>2.10</string>
  <key>AMDocumentVersion</key>
  <string>2</string>
  <key>actions</key>
  <array>
    <dict>
      <key>action</key>
      <dict>
        <key>AMActionVersion</key>
        <string>2.0.3</string>
        <key>AMApplication</key>
        <array>
          <string>Automator</string>
        </array>
        <key>AMParameterProperties</key>
        <dict>
          <key>COMMAND_STRING</key>
          <dict/>
          <key>CheckedForUserDefaultShell</key>
          <dict/>
          <key>inputMethod</key>
          <dict/>
          <key>shell</key>
          <dict/>
          <key>source</key>
          <dict/>
        </dict>
        <key>AMProvides</key>
        <dict>
          <key>Container</key>
          <string>List</string>
          <key>Types</key>
          <array>
            <string>com.apple.cocoa.string</string>
          </array>
        </dict>
        <key>ActionBundlePath</key>
        <string>/System/Library/Automator/Run Shell Script.action</string>
        <key>ActionName</key>
        <string>Run Shell Script</string>
        <key>ActionParameters</key>
        <dict>
          <key>COMMAND_STRING</key>
          <string>export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
for f in "$@"; do
  dir=$(dirname "$f")
  base=$(basename "$f" .pdf)
  out="$dir/$base-unlocked.pdf"

  if qpdf --decrypt "$f" "$out" 2>/dev/null; then
    continue
  fi

  pw=$(osascript -e "display dialog \"Password for $base.pdf:\" default answer \"\" with hidden answer buttons {\"Cancel\", \"Unlock\"} default button \"Unlock\"" -e "text returned of result" 2>/dev/null) || continue

  if qpdf --password="$pw" --decrypt "$f" "$out" 2>/dev/null; then
    continue
  fi

  osascript -e "display dialog \"Could not unlock $base.pdf — wrong password or unsupported encryption.\" buttons {\"OK\"} default button 1 with icon caution" >/dev/null 2>&1
done</string>
          <key>CheckedForUserDefaultShell</key>
          <true/>
          <key>inputMethod</key>
          <integer>1</integer>
          <key>shell</key>
          <string>/bin/bash</string>
          <key>source</key>
          <string></string>
        </dict>
        <key>BundleIdentifier</key>
        <string>com.apple.RunShellScript</string>
        <key>CFBundleVersion</key>
        <string>2.0.3</string>
        <key>CanShowSelectedItemsWhenRun</key>
        <false/>
        <key>CanShowWhenRun</key>
        <true/>
        <key>Category</key>
        <array>
          <string>AMCategoryUtilities</string>
        </array>
        <key>Class Name</key>
        <string>RunShellScriptAction</string>
        <key>InputUUID</key>
        <string>00000000-0000-0000-0000-000000000001</string>
        <key>Keywords</key>
        <array>
          <string>Shell</string>
          <string>Script</string>
        </array>
        <key>OutputUUID</key>
        <string>00000000-0000-0000-0000-000000000002</string>
        <key>UUID</key>
        <string>00000000-0000-0000-0000-000000000003</string>
        <key>UnlocalizedApplications</key>
        <array>
          <string>Automator</string>
        </array>
        <key>arguments</key>
        <dict/>
        <key>conversionLabel</key>
        <integer>0</integer>
        <key>isViewVisible</key>
        <integer>1</integer>
        <key>location</key>
        <string>309.500000:316.000000</string>
        <key>nibPath</key>
        <string>/System/Library/Automator/Run Shell Script.action/Contents/Resources/Base.lproj/main.nib</string>
      </dict>
      <key>isViewVisible</key>
      <integer>1</integer>
    </dict>
  </array>
  <key>connectors</key>
  <dict/>
  <key>workflowMetaData</key>
  <dict>
    <key>serviceApplicationBundleID</key>
    <string>com.apple.finder</string>
    <key>serviceApplicationPath</key>
    <string>/System/Library/CoreServices/Finder.app</string>
    <key>serviceInputType</key>
    <string>0</string>
    <key>serviceInputTypeIdentifier</key>
    <string>com.apple.Automator.fileSystemObject.image</string>
    <key>serviceOutputType</key>
    <string>0</string>
    <key>serviceProcessesInput</key>
    <integer>0</integer>
    <key>workflowTypeIdentifier</key>
    <string>com.apple.Automator.servicesMenu</string>
  </dict>
</dict>
</plist>
WFLOW

/System/Library/CoreServices/pbs -flush 2>/dev/null || true

echo ""
echo "Installed: $WORKFLOW_DIR"
echo ""
echo "Right-click any PDF in Finder. You'll see 'Unlock PDF' under the menu"
echo "(possibly nested under 'Quick Actions' on newer macOS versions)."
echo ""
echo "If the menu item doesn't appear:"
echo "  killall Finder"
