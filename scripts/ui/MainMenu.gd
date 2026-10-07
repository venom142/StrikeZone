extends CanvasLayer

func _ready() -> void:
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(root)
    var title := Label.new()
    title.text = "STRIKEZONE MOBILE ARENA"
    title.position = Vector2(0, 90)
    title.size = Vector2(1280, 60)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 36)
    root.add_child(title)
    var box := VBoxContainer.new()
    box.position = Vector2(460, 210)
    box.size = Vector2(360, 330)
    root.add_child(box)
    _button(box, "PLAY", _play)
    _button(box, "PRACTICE", _practice)
    _button(box, "SETTINGS", _settings)
    _button(box, "HOW TO PLAY", _how_to_play)
    _button(box, "EXIT", _exit)

func _button(parent: VBoxContainer, text_value: String, action: Callable) -> void:
    var b := Button.new()
    b.text = text_value
    b.custom_minimum_size = Vector2(360, 52)
    b.pressed.connect(action)
    parent.add_child(b)

func _play() -> void:
    GameManager.start_match()

func _practice() -> void:
    GameManager.start_practice()

func _settings() -> void:
    pass

func _how_to_play() -> void:
    pass

func _exit() -> void:
    get_tree().quit()
