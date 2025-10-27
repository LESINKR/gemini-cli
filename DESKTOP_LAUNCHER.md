# Desktop Launcher pro Gemini CLI

Tento návod ti ukáže, jak nainstalovat desktop launcher pro Gemini CLI na Linuxu.

## Rychlá instalace

Spusť tento příkaz v rootu projektu:

```bash
./scripts/install_desktop_launcher.sh
```

Skript provede:
- ✓ Instalaci launcheru do menu aplikací
- ✓ Volitelně vytvoří zástupce na ploše
- ✓ Nainstaluje ikonu
- ✓ Aktualizuje systémové databáze

## Co launcher dělá

Po instalaci můžeš spustit Gemini CLI několika způsoby:

1. **Z menu aplikací**: Hledej "Gemini CLI" v menu aplikací (Super klávesa + vyhledávání)
2. **Z plochy**: Pokud jsi vytvořil zástupce na ploše, dvojklik na ikonu
3. **Klávesová zkratka**: Můžeš si nastavit vlastní klávesovou zkratku v systémových nastaveních

Launcher automaticky:
- Otevře terminál
- Spustí Gemini CLI v interaktivním módu
- Použije globálně nainstalovanou verzi (pokud existuje) nebo vývojovou verzi z tohoto projektu

## Požadavky

- Linux s desktop prostředím (GNOME, KDE, XFCE, atd.)
- X-terminal emulator nebo jakýkoliv terminál
- Node.js 20+ (pro spuštění Gemini CLI)

## Manuální instalace

Pokud chceš launcher nainstalovat ručně:

1. Zkopíruj `gemini-cli.desktop` do `~/.local/share/applications/`
2. Nahraď `%INSTALL_DIR%` skutečnou cestou k projektu
3. Zkopíruj ikonu: `cp packages/vscode-ide-companion/assets/icon.png ~/.local/share/icons/hicolor/256x256/apps/gemini-cli.png`
4. Spusť: `update-desktop-database ~/.local/share/applications/`

## Odinstalace

Pro odstranění launcheru:

```bash
rm ~/.local/share/applications/gemini-cli.desktop
rm ~/Desktop/gemini-cli.desktop  # pokud existuje
rm ~/.local/share/icons/hicolor/256x256/apps/gemini-cli.png
update-desktop-database ~/.local/share/applications/
```

## Přizpůsobení

Můžeš upravit launcher podle svých potřeb:

- **Změnit terminál**: V `.desktop` souboru změň `x-terminal-emulator` na tvůj oblíbený terminál (např. `gnome-terminal`, `konsole`, `xfce4-terminal`)
- **Přidat argumenty**: Přidej parametry za `gemini` příkaz (např. `gemini --verbose`)
- **Změnit ikonu**: Nahraď ikonu jinou PNG/SVG ikonou

## Řešení problémů

### Launcher se nezobrazuje v menu
- Spusť: `update-desktop-database ~/.local/share/applications/`
- Odhlásit se a znovu přihlásit
- Zkontroluj, že soubor má správná práva: `chmod +x ~/.local/share/applications/gemini-cli.desktop`

### Ikona se nezobrazuje
- Zkontroluj cestu k ikoně v `.desktop` souboru
- Spusť: `gtk-update-icon-cache ~/.local/share/icons/hicolor`
- Zkopíruj ikonu do správného adresáře

### Terminál se otevře a hned zavře
- Zkontroluj, že máš nainstalovaný Node.js 20+
- Zkontroluj cestu k projektu v `.desktop` souboru
- Zkus spustit `gemini` příkaz ručně v terminálu

---

# Desktop Launcher for Gemini CLI (English)

This guide shows you how to install a desktop launcher for Gemini CLI on Linux.

## Quick Installation

Run this command in the project root:

```bash
./scripts/install_desktop_launcher.sh
```

The script will:
- ✓ Install the launcher to your applications menu
- ✓ Optionally create a desktop shortcut
- ✓ Install the icon
- ✓ Update system databases

## What the Launcher Does

After installation, you can launch Gemini CLI in several ways:

1. **From Applications Menu**: Search for "Gemini CLI" in your applications menu (Super key + search)
2. **From Desktop**: If you created a desktop shortcut, double-click the icon
3. **Keyboard Shortcut**: You can set up a custom keyboard shortcut in system settings

The launcher automatically:
- Opens a terminal
- Starts Gemini CLI in interactive mode
- Uses the globally installed version (if available) or the development version from this project

## Requirements

- Linux with desktop environment (GNOME, KDE, XFCE, etc.)
- X-terminal emulator or any terminal
- Node.js 20+ (to run Gemini CLI)

## Manual Installation

If you want to install the launcher manually:

1. Copy `gemini-cli.desktop` to `~/.local/share/applications/`
2. Replace `%INSTALL_DIR%` with the actual path to the project
3. Copy icon: `cp packages/vscode-ide-companion/assets/icon.png ~/.local/share/icons/hicolor/256x256/apps/gemini-cli.png`
4. Run: `update-desktop-database ~/.local/share/applications/`

## Uninstallation

To remove the launcher:

```bash
rm ~/.local/share/applications/gemini-cli.desktop
rm ~/Desktop/gemini-cli.desktop  # if exists
rm ~/.local/share/icons/hicolor/256x256/apps/gemini-cli.png
update-desktop-database ~/.local/share/applications/
```

## Customization

You can customize the launcher to your needs:

- **Change terminal**: In the `.desktop` file, change `x-terminal-emulator` to your favorite terminal (e.g., `gnome-terminal`, `konsole`, `xfce4-terminal`)
- **Add arguments**: Add parameters after the `gemini` command (e.g., `gemini --verbose`)
- **Change icon**: Replace the icon with another PNG/SVG icon

## Troubleshooting

### Launcher doesn't appear in menu
- Run: `update-desktop-database ~/.local/share/applications/`
- Log out and log back in
- Check that the file has correct permissions: `chmod +x ~/.local/share/applications/gemini-cli.desktop`

### Icon doesn't display
- Check the icon path in the `.desktop` file
- Run: `gtk-update-icon-cache ~/.local/share/icons/hicolor`
- Copy the icon to the correct directory

### Terminal opens and immediately closes
- Check that you have Node.js 20+ installed
- Check the project path in the `.desktop` file
- Try running the `gemini` command manually in a terminal
