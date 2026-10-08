extends CanvasLayer

var player: Node
var match_manager: Node
var labels: Dictionary = {}
var root: Control
var joystick: Control
var look_area: Control
var sprint_button: Button
var jump_button: Button
var tag_button: Button

func _ready() -> void:
    root = Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)
    _build_info()
    _build_mobile_controls()

func _build_info() -> void:
    var top := Label.new()
    top.position = Vector2(24, 18)
    top.size = Vector2(700, 44)
    top.add_theme_font_size_override("font_size", 24)
    top.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(top)
    labels["top"] = top

    var hp := Label.new()
    hp.position = Vector2(28, 650)
    hp.size = Vector2(250, 44)
    hp.add_theme_font_size_override("font_size", 24)
    hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(hp)
    labels["hp"] = hp

    var cross := Label.new()
    cross.text = "+"
    cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    cross.add_theme_font_size_override("font_size", 30)
    cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(cross)

func _build_mobile_controls() -> void:
    joystick = preload("res://scripts/ui/VirtualJoystick.gd").new()
    joystick.name = "MoveJoystick"
    joystick.position = Vector2(36, 430)
    joystick.size = Vector2(220, 220)
    joystick.mouse_filter = Control.MOUSE_FILTER_STOP
    root.add_child(joystick)
    joystick.input_vector.connect(_on_move)

    look_area = preload("res://scripts/ui/TouchLook.gd").new()
    look_area.name = "LookArea"
    look_area.position = Vector2(610, 100)
    look_area.size = Vector2(610, 540)
    look_area.mouse_filter = Control.MOUSE_FILTER_STOP
    root.add_child(look_area)
    look_area.look_delta.connect(_on_look)

    sprint_button = _make_button("SPRINT", Vector2(260, 570), Vector2(150, 100))
    sprint_button.button_down.connect(func(): player.set_sprint(true) if player else null)
    sprint_button.button_up.connect(func(): player.set_sprint(false) if player else null)

    jump_button = _make_button("JUMP", Vector2(1050, 500), Vector2(150, 100))
    jump_button.pressed.connect(func(): player.jump() if player else null)

    tag_button = _make_button("TAG", Vector2(1040, 350), Vector2(170, 120))
    tag_button.add_theme_font_size_override("font_size", 28)
    tag_button.pressed.connect(func(): player.tag() if player else null)

func _make_button(text_value: String, pos: Vector2, button_size: Vector2) -> Button:
    var b := Button.new()
    b.text = text_value
    b.position = pos
    b.size = button_size
    b.mouse_filter = Control.MOUSE_FILTER_STOP
    b.add_theme_font_size_override("font_size", 22)
    root.add_child(b)
    return b

func setup(p: Node, mm: Node) -> void:
    player = p
    match_manager = mm

func _on_move(value: Vector2) -> void:
    if player:
        player.set_move(value)

func _on_look(delta: Vector2) -> void:
    if player:
        player.set_look(delta)

func _process(_delta: float) -> void:
    if not labels.has("top"):
        return
    var round_no := int(match_manager.round_no) if match_manager else 1
    var time_left := int(match_manager.time_left) if match_manager else 60
    var score := int(player.tags) if player and "tags" in player else 0
    var hp_value := int(player.hp) if player and "hp" in player else 100
    labels["top"].text = "ROUND %d/5    TIME %02d    PLAYER %d    BOTS 4" % [round_no, max(0, time_left), score]
    labels["hp"].text = "HP %d" % max(0, hp_value)
