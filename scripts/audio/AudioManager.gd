extends Node
var active_players: Array[AudioStreamPlayer] = []

func _ready() -> void:
    _ensure_buses()
    SettingsManager.settings_changed.connect(_on_settings_changed)
    SettingsManager.apply()

func _ensure_buses() -> void:
    if AudioServer.get_bus_index("Music") < 0:
        AudioServer.add_bus()
        AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
    if AudioServer.get_bus_index("Effects") < 0:
        AudioServer.add_bus()
        AudioServer.set_bus_name(AudioServer.bus_count - 1, "Effects")

func _on_settings_changed() -> void: _ensure_buses()

func _tone(frequency: float, duration: float, bus := "Effects", amplitude := 17000.0) -> void:
    var player := AudioStreamPlayer.new()
    var stream := AudioStreamWAV.new()
    stream.mix_rate = 22050
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    var count := maxi(1, int(22050.0 * duration))
    var bytes := PackedByteArray()
    bytes.resize(count * 2)
    for i in range(count):
        bytes.encode_s16(i * 2, int(sin(TAU * frequency * i / 22050.0) * amplitude * (1.0 - float(i)/count)))
    stream.data = bytes
    player.stream = stream
    player.bus = bus
    add_child(player)
    active_players.append(player)
    player.finished.connect(func(): active_players.erase(player); player.queue_free())
    player.play()

func play_ui(kind: String) -> void: _tone(520.0 if kind == "click" else 760.0, 0.055)
func play_menu() -> void: _tone(260.0, 0.22, "Music", 9000.0)
func play_match_start() -> void: _tone(420.0, 0.12); _tone(840.0, 0.18)
func play_tag() -> void: _tone(920.0, 0.09, "Effects", 15000.0)
func play_hit() -> void: _tone(180.0, 0.08)
func play_round() -> void: _tone(640.0, 0.16)
func play_victory() -> void: _tone(1040.0, 0.22); _tone(1320.0, 0.28)
func play_defeat() -> void: _tone(180.0, 0.25)
