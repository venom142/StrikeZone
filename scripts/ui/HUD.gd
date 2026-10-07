extends CanvasLayer

var player: Node
var match_manager: Node
var labels: Dictionary = {}

func _ready() -> void:
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(root)
    var top := Label.new()
    top.position = Vector2(24, 20)
    top.add_theme_font_size_override("font_size", 24)
    root.add_child(top)
    labels["top"] = top
    var hp := Label.new()
    hp.position = Vector2(24, 650)
    hp.add_theme_font_size_override("font_size", 22)
    root.add_child(hp)
    labels["hp"] = hp
    var cross := Label.new()
    cross.text = "+"
    cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    cross.add_theme_font_size_override("font_size", 28)
    root.add_child(cross)

func setup(p: Node, mm: Node) -> void:
    player = p
    match_manager = mm

func _process(_delta: float) -> void:
    if not labels.has("top"):
        return
    var round_no := int(match_manager.round_no) if match_manager else 1
    var time_left := int(match_manager.time_left) if match_manager else 60
    var score := int(player.tags) if player and "tags" in player else 0
    var hp_value := int(player.hp) if player and "hp" in player else 100
    labels["top"].text = "ROUND %d/5    TIME %02d    PLAYER %d    BOTS 4" % [round_no, max(0, time_left), score]
    labels["hp"].text = "HP %d" % max(0, hp_value)
