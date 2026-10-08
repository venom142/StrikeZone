extends Control
signal look_delta(delta: Vector2)
var last_position := Vector2.ZERO
var active := false
func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        active = event.pressed
        last_position = event.position
    elif event is InputEventScreenDrag and active:
        look_delta.emit(event.relative)
