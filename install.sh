#!/usr/bin/env bash
set -euo pipefail

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
				<key>AMAccepts</key>
				<dict>
					<key>Container</key>
					<string>List</string>
					<key>Optional</key>
					<true/>
					<key>Types</key>
					<array>
						<string>com.apple.cocoa.string</string>
					</array>
				</dict>
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

  if qpdf --warning-exit-0 --decrypt "$f" "$out" 2&gt;/dev/null; then
    continue
  fi
  rm -f "$out"

  attempts=0
  while [ $attempts -lt 5 ]; do
    attempts=$((attempts + 1))
    if [ $attempts -eq 1 ]; then
      prompt="Enter password to unlock $base.pdf"
    else
      prompt="Incorrect password. Try again - $base.pdf"
    fi

    pw=$(osascript -e "display dialog \"$prompt\" default answer \"\" with hidden answer buttons {\"Cancel\", \"Unlock\"} default button \"Unlock\"" -e "text returned of result" 2&gt;/dev/null) || break

    if err=$(qpdf --warning-exit-0 --password="$pw" --decrypt "$f" "$out" 2&gt;&amp;1); then
      break
    fi
    rm -f "$out"

    if printf '%s' "$err" | grep -qi "invalid password"; then
      continue
    fi

    reason=$(printf '%s' "$err" | tail -1 | sed -E 's|^qpdf: [^:]*: *||' | sed 's/"/\\"/g')
    osascript -e "display dialog \"Could not unlock $base.pdf\n\n$reason\" buttons {\"OK\"} default button 1 with icon caution" &gt;/dev/null 2&gt;&amp;1
    break
  done
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
				<string>AE15A104-3BEE-4138-9182-C8C638FC20D9</string>
				<key>Keywords</key>
				<array>
					<string>Shell</string>
					<string>Script</string>
					<string>Command</string>
					<string>Run</string>
					<string>Unix</string>
				</array>
				<key>OutputUUID</key>
				<string>BCFC1B93-6F69-4B2B-A0E5-69D4A437E32B</string>
				<key>UUID</key>
				<string>E58C2CB1-0317-4098-8B95-5130DC14459B</string>
				<key>UnlocalizedApplications</key>
				<array>
					<string>Automator</string>
				</array>
				<key>arguments</key>
				<dict>
					<key>0</key>
					<dict>
						<key>default value</key>
						<integer>0</integer>
						<key>name</key>
						<string>inputMethod</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>0</string>
					</dict>
					<key>1</key>
					<dict>
						<key>default value</key>
						<false/>
						<key>name</key>
						<string>CheckedForUserDefaultShell</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>1</string>
					</dict>
					<key>2</key>
					<dict>
						<key>default value</key>
						<string></string>
						<key>name</key>
						<string>source</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>2</string>
					</dict>
					<key>3</key>
					<dict>
						<key>default value</key>
						<string></string>
						<key>name</key>
						<string>COMMAND_STRING</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>3</string>
					</dict>
					<key>4</key>
					<dict>
						<key>default value</key>
						<string>/bin/sh</string>
						<key>name</key>
						<string>shell</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>4</string>
					</dict>
				</dict>
				<key>isViewVisible</key>
				<integer>1</integer>
				<key>location</key>
				<string>309.000000:305.000000</string>
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
		<key>applicationBundleID</key>
		<string>com.apple.finder</string>
		<key>applicationBundleIDsByPath</key>
		<dict>
			<key>/System/Library/CoreServices/Finder.app</key>
			<string>com.apple.finder</string>
		</dict>
		<key>applicationPath</key>
		<string>/System/Library/CoreServices/Finder.app</string>
		<key>applicationPaths</key>
		<array>
			<string>/System/Library/CoreServices/Finder.app</string>
		</array>
		<key>inputTypeIdentifier</key>
		<string>com.apple.Automator.fileSystemObject</string>
		<key>outputTypeIdentifier</key>
		<string>com.apple.Automator.nothing</string>
		<key>presentationMode</key>
		<integer>15</integer>
		<key>processesInput</key>
		<integer>0</integer>
		<key>serviceApplicationBundleID</key>
		<string>com.apple.finder</string>
		<key>serviceApplicationPath</key>
		<string>/System/Library/CoreServices/Finder.app</string>
		<key>serviceInputTypeIdentifier</key>
		<string>com.apple.Automator.fileSystemObject</string>
		<key>serviceOutputTypeIdentifier</key>
		<string>com.apple.Automator.nothing</string>
		<key>serviceProcessesInput</key>
		<integer>0</integer>
		<key>systemImageName</key>
		<string>NSTouchBarDocuments</string>
		<key>useAutomaticInputType</key>
		<integer>0</integer>
		<key>workflowTypeIdentifier</key>
		<string>com.apple.Automator.servicesMenu</string>
	</dict>
</dict>
</plist>
WFLOW

/System/Library/CoreServices/pbs -flush 2>/dev/null || true

echo ""
echo "Validating workflow plist..."
if plutil -lint "$WORKFLOW_DIR/Contents/document.wflow" >/dev/null && plutil -lint "$WORKFLOW_DIR/Contents/Info.plist" >/dev/null; then
  echo "==> plists OK"
else
  echo "Error: generated plist failed validation. Please open an issue." >&2
  exit 1
fi

echo ""
echo "Installed: $WORKFLOW_DIR"
echo ""
echo "Right-click any PDF in Finder. You'll see 'Unlock PDF' under the menu"
echo "(possibly nested under 'Quick Actions' on newer macOS versions)."
echo ""
echo "If the menu item doesn't appear:"
echo "  killall Finder"
