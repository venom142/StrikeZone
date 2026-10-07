#!/usr/bin/env python3
from pathlib import Path
import configparser, sys

root = Path(__file__).resolve().parents[1]
required = [
    "project.godot",
    "Main.tscn",
    "export_presets.cfg",
    "scripts/core/Main.gd",
    "scripts/core/GameManager.gd",
    "scripts/core/SettingsManager.gd",
    "scripts/player/Player.gd",
    "scripts/bots/Bot.gd",
    "scripts/systems/ArenaBuilder.gd",
    "scripts/systems/MatchManager.gd",
    "scripts/systems/SpawnManager.gd",
    "scripts/systems/VFX.gd",
    "scripts/audio/AudioManager.gd",
    "scenes/arena/Arena.tscn",
    "scenes/bots/Bot.tscn",
    "scenes/player/Player.tscn",
    "scenes/menus/MainMenu.tscn",
    "scenes/ui/HUD.tscn",
]
missing = [p for p in required if not (root / p).is_file()]
if missing:
    print("Missing required files:")
    print("\n".join(" - " + p for p in missing))
    sys.exit(1)

project = (root / "project.godot").read_text(encoding="utf-8")
preset = (root / "export_presets.cfg").read_text(encoding="utf-8")
checks = [
    ("res://Main.tscn" in project, "main scene"),
    ("config/name="StrikeZone Mobile"" in project, "app name"),
    ("package/unique_name="com.venom142.strikezonemobile"" in preset, "Android package"),
    ("architectures/arm64-v8a=true" in preset, "ARM64"),
    ("name="Android"" in preset, "Android preset"),
]
failed = [name for ok, name in checks if not ok]
if failed:
    print("Configuration checks failed:")
    print("\n".join(" - " + x for x in failed))
    sys.exit(1)

print(f"Validation OK: {len(required)} required files and Android configuration verified.")
