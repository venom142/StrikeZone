extends CanvasLayer

var player: Node
var match_manager: Node
var labels: Dictionary = {}
var root: Control
var joystick_visual: Label
var sprint_button: Button
var jump_button: Button
var tag_button: Button
var touch_finger := -1
var look_finger := -1
var joystick_finger := -1
var joystick_center := Vector2.ZERO
var joystick_value := Vector2.ZERO
var sprint_rect := Rect2()
var jump_rect := Rect2()
var tag_rect := Rect2()

func _ready() -> void:
    root = Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)
    _build_info()
    _build_mobile_controls()
    get_viewport().size_changed.connect(_layout_controls)
    call_deferred("_layout_controls")

func _build_info() -> void:
    var top := Label.new()
    top.position = Vector2(24, 18)
    top.size = Vector2(760, 50)
    top.add_theme_font_size_override("font_size", 25)
    top.add_theme_color_override("font_color", Color.WHITE)
    top.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(top)
    labels["top"] = top

    var hp := Label.new()
    hp.position = Vector2(28, 650)
    hp.size = Vector2(300, 50)
    hp.add_theme_font_size_override("font_size", 26)
    hp.add_theme_color_override("font_color", Color.WHITE)
    hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(hp)
    labels["hp"] = hp

    var cross := Label.new()
    cross.text = "+"
    cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    cross.add_theme_font_size_override("font_size", 32)
    cross.add_theme_color_override("font_color", Color.WHITE)
    cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(cross)

func _build_mobile_controls() -> void:
    joystick_visual = Label.new()
    joystick_visual.text = "◯\n  MOVE"
    joystick_visual.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    joystick_visual.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    joystick_visual.add_theme_font_size_override("font_size", 25)
    joystick_visual.add_theme_color_override("font_color", Color.WHITE)
    joystick_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(joystick_visual)

    sprint_button = _make_button("SPRINT", 22)
    jump_button = _make_button("JUMP", 22)
    tag_button = _make_button("TAG", 30)

func _make_button(text_value: String, font_size: int) -> Button:
    var b := Button.new()
    b.text = text_value
    b.add_theme_font_size_override("font_size", font_size)
    b.add_theme_color_override("font_color", Color.WHITE)
    b.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(b)
    return b

func _layout_controls() -> void:
    if not root:
        return
    var size := get_viewport().get_visible_rect().size
    var w := size.x
    var h := size.y
    var s := clampf(minf(w / 1280.0, h / 720.0), 0.65, 1.25)

    var joy_size := 190.0 * s
    joystick_visual.position = Vector2(35.0 * s, h - joy_size - 28.0 * s)
    joystick_visual.size = Vector2(joy_size, joy_size)
    joystick_center = joystick_visual.position + joystick_visual.size * 0.5

    sprint_rect = Rect2(Vector2(245.0 * s, h - 115.0 * s), Vector2(145.0 * s, 82.0 * s))
    jump_rect = Rect2(Vector2(w - 185.0 * s, h - 115.0 * s), Vector2(145.0 * s, 82.0 * s))
    tag_rect = Rect2(Vector2(w - 195.0 * s, h - 225.0 * s), Vector2(155.0 * s, 92.0 * s))

    sprint_button.position = sprint_rect.position
    sprint_button.size = sprint_rect.size
    jump_button.position = jump_rect.position
    jump_button.size = jump_rect.size
    tag_button.position = tag_rect.position
    tag_button.size = tag_rect.size

func setup(p: Node, mm: Node) -> void:
    player = p
    match_manager = mm

func _input(event: InputEvent) -> void:
    if not player:
        return

    if event is InputEventScreenTouch:
        if event.pressed:
            var p := event.position
            if tag_rect.has_point(p):
                player.tag()
                return
            if jump_rect.has_point(p):
                player.jump()
                return
            if sprint_rect.has_point(p):
                player.set_sprint(true)
                touch_finger = event.index
                return
            if joystick_visual.get_rect().has_point(p):
                joystick_finger = event.index
                _update_joystick(p)
                return
            if p.x > get_viewport().get_visible_rect().size.x * 0.45:
                look_finger = event.index
                return
        else:
            if event.index == joystick_finger:
                joystick_finger = -1
                joystick_value = Vector2.ZERO
                player.set_move(Vector2.ZERO)
            if event.index == look_finger:
                look_finger = -1
            if event.index == touch_finger:
                touch_finger = -1
                player.set_sprint(false)

    elif event is InputEventScreenDrag:
        if event.index == joystick_finger:
            _update_joystick(event.position)
        elif event.index == look_finger:
            player.set_look(event.relative)

func _update_joystick(pos: Vector2) -> void:
    var radius := maxf(1.0, joystick_visual.size.x * 0.42)
    joystick_value = (pos - joystick_center) / radius
    joystick_value = joystick_value.limit_length(1.0)
    player.set_move(joystick_value)

func _process(_delta: float) -> void:
    if not labels.has("top"):
        return
    var round_no := int(match_manager.round_no) if match_manager else 1
    var time_left := int(match_manager.time_left) if match_manager else 60
    var score := int(player.tags) if player and "tags" in player else 0
    var hp_value := int(player.hp) if player and "hp" in player else 100
    labels["top"].text = "ROUND %d/5    TIME %02d    PLAYER %d    BOTS 4" % [round_no, max(0, time_left), score]
    labels["hp"].text = "HP %d" % max(0, hp_value)
