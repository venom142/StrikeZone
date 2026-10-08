extends Control
signal input_vector(value: Vector2)
var finger := -1
var center := Vector2.ZERO
func _ready() -> void:
    center = size * 0.5
func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            finger = event.index
            _emit(event.position)
        elif event.index == finger:
            finger = -1
            input_vector.emit(Vector2.ZERO)
    elif event is InputEventScreenDrag and event.index == finger:
        _emit(event.position)
func _emit(pos: Vector2) -> void:
    var v := (pos - center) / max(1.0, min(size.x, size.y) * 0.5)
    input_vector.emit(v.limit_length(1.0))
