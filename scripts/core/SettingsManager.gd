extends Node

signal settings_changed

const PATH := "user://strikezone.cfg"
const DEFAULTS := {"graphics":"AUTO","fps":60,"vsync":true,"sensitivity":1.0,"master":0.8,"music":0.55,"effects":0.8,"cosmetic_color":0,"cosmetic_trail":0,"cosmetic_crosshair":0,"cosmetic_theme":0,"unlocked":[0,1,2,3],"wins":0,"losses":0,"tags":0}
var data: Dictionary = DEFAULTS.duplicate(true)

func _ready() -> void:
    load_data()
    _apply_auto_quality()
    apply()

func load_data() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(PATH) != OK: return
    for key in DEFAULTS.keys():
        if cfg.has_section_key("game", key): data[key] = cfg.get_value("game", key, DEFAULTS[key])

func save_data() -> void:
    var cfg := ConfigFile.new()
    for key in data.keys(): cfg.set_value("game", key, data[key])
    cfg.save(PATH)

func _apply_auto_quality() -> void:
    if str(data.graphics) != "AUTO": return
    data.graphics = "LOW" if OS.get_processor_count() <= 4 else "MEDIUM"
    save_data()

func apply() -> void:
    Engine.max_fps = 30 if int(data.fps) == 30 else 60
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(data.vsync) else DisplayServer.VSYNC_DISABLED)
    _set_bus_volume("Master", float(data.master))
    _set_bus_volume("Music", float(data.music))
    _set_bus_volume("Effects", float(data.effects))
    settings_changed.emit()

func _set_bus_volume(bus_name: String, value: float) -> void:
    var index := AudioServer.get_bus_index(bus_name)
    if index >= 0: AudioServer.set_bus_volume_db(index, linear_to_db(clampf(value, 0.001, 1.0)))

func set_value(key: String, value: Variant) -> void:
    if not data.has(key): return
    data[key] = value
    save_data()
    apply()

func record_match_result(won: bool) -> void:
    data.wins = int(data.wins) + int(won)
    data.losses = int(data.losses) + int(not won)
    save_data()
