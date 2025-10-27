#!/usr/bin/env bash
set -euo pipefail

# This script installs a desktop launcher for Gemini CLI on Linux systems

# Determine the project directory
PROJECT_DIR=$(cd "$(dirname "$0")/.." && pwd)

# Desktop file locations
DESKTOP_FILE="${PROJECT_DIR}/gemini-cli.desktop"
USER_APPLICATIONS_DIR="${HOME}/.local/share/applications"
DESKTOP_DIR="${HOME}/Desktop"

# Icon file
ICON_SOURCE="${PROJECT_DIR}/packages/vscode-ide-companion/assets/icon.png"
ICON_DIR="${HOME}/.local/share/icons/hicolor/256x256/apps"
ICON_DEST="${ICON_DIR}/gemini-cli.png"

echo "=========================================="
echo "Gemini CLI Desktop Launcher Installation"
echo "=========================================="
echo ""
echo "This script will install a desktop launcher for Gemini CLI."
echo "Installation locations:"
echo "  - Applications menu: ${USER_APPLICATIONS_DIR}"
echo "  - Desktop shortcut: ${DESKTOP_DIR} (optional)"
echo "  - Icon: ${ICON_DEST}"
echo ""

# Check if desktop file exists
if [[ ! -f "${DESKTOP_FILE}" ]]; then
    echo "Error: Desktop file not found at ${DESKTOP_FILE}"
    exit 1
fi

# Check if icon exists
if [[ ! -f "${ICON_SOURCE}" ]]; then
    echo "Warning: Icon file not found at ${ICON_SOURCE}"
    echo "The launcher will still work but may not have an icon."
fi

# Create directories if they don't exist
mkdir -p "${USER_APPLICATIONS_DIR}"
mkdir -p "${ICON_DIR}"

# Copy and install icon
if [[ -f "${ICON_SOURCE}" ]]; then
    echo "Installing icon..."
    cp "${ICON_SOURCE}" "${ICON_DEST}"
    echo "✓ Icon installed to ${ICON_DEST}"
fi

# Create the desktop file with correct paths
echo "Creating desktop launcher..."
DESKTOP_CONTENT=$(cat "${DESKTOP_FILE}" | sed "s|%INSTALL_DIR%|${PROJECT_DIR}|g")

# Install to applications directory
echo "${DESKTOP_CONTENT}" > "${USER_APPLICATIONS_DIR}/gemini-cli.desktop"
chmod +x "${USER_APPLICATIONS_DIR}/gemini-cli.desktop"
echo "✓ Launcher installed to applications menu"

# Ask if user wants desktop shortcut
read -p "Do you want to create a desktop shortcut? (y/n) " -n 1 -r
echo ""
if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
    if [[ -d "${DESKTOP_DIR}" ]]; then
        echo "${DESKTOP_CONTENT}" > "${DESKTOP_DIR}/gemini-cli.desktop"
        chmod +x "${DESKTOP_DIR}/gemini-cli.desktop"

        # Mark as trusted on Ubuntu/GNOME
        if command -v gio >/dev/null 2>&1; then
            gio set "${DESKTOP_DIR}/gemini-cli.desktop" metadata::trusted true 2>/dev/null || true
        fi

        echo "✓ Desktop shortcut created"
    else
        echo "Warning: Desktop directory not found at ${DESKTOP_DIR}"
    fi
fi

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    echo "Updating desktop database..."
    update-desktop-database "${USER_APPLICATIONS_DIR}" 2>/dev/null || true
    echo "✓ Desktop database updated"
fi

# Update icon cache
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    echo "Updating icon cache..."
    gtk-update-icon-cache "${HOME}/.local/share/icons/hicolor" 2>/dev/null || true
    echo "✓ Icon cache updated"
fi

echo ""
echo "=========================================="
echo "✓ Installation complete!"
echo "=========================================="
echo ""
echo "You should now see 'Gemini CLI' in your applications menu."
echo "You can also search for it by pressing the Super key and typing 'Gemini'."
echo ""
echo "To uninstall, run:"
echo "  rm ${USER_APPLICATIONS_DIR}/gemini-cli.desktop"
if [[ -f "${DESKTOP_DIR}/gemini-cli.desktop" ]]; then
    echo "  rm ${DESKTOP_DIR}/gemini-cli.desktop"
fi
echo "  rm ${ICON_DEST}"
echo ""
