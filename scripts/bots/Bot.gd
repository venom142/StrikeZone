extends CharacterBody3D
class_name StrikeBot

signal tag_landed(target: Node)
signal eliminated

var target: StrikePlayer
var difficulty := "NORMAL"
var hp := 100
var active := true
var cooldown := 0.0
var reaction := 0.62
var speed := 3.8
var think_time := 0.0
var desired := Vector3.ZERO
var cover_points: Array[Vector3] = []
var rng := RandomNumberGenerator.new()
var state := "REPOSITION"

func _ready() -> void:
    add_to_group("bots")
    collision_layer = 4
    collision_mask = 1 | 2
    _build_body()

func setup(player: StrikePlayer, diff: String, covers: Array[Vector3]) -> void:
    target = player
    difficulty = diff
    cover_points = covers
    rng.randomize()
    _set_difficulty(diff)

func reset_for_round(player: StrikePlayer, diff: String, covers: Array[Vector3]) -> void:
    target = player
    difficulty = diff
    cover_points = covers
    hp = 100
    active = true
    collision_layer = 4
    collision_mask = 1 | 2
    cooldown = 0.0
    think_time = 0.0
    state = "REPOSITION"
    _set_difficulty(diff)
    show()

func _set_difficulty(diff: String) -> void:
    match diff:
        "EASY":
            reaction = 1.1
            speed = 3.0
        "HARD":
            reaction = 0.28
            speed = 4.7
        _:
            reaction = 0.62
            speed = 3.8

func _build_body() -> void:
    var cs := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.42
    shape.height = 1.7
    cs.shape = shape
    cs.position.y = 0.85
    add_child(cs)
    var mesh := MeshInstance3D.new()
    var cm := CapsuleMesh.new()
    cm.radius = 0.42
    cm.height = 1.7
    mesh.mesh = cm
    mesh.material_override = StrikeVFX.material(Color("#ff4bd8"), 0.28)
    mesh.position.y = 0.85
    add_child(mesh)

func _physics_process(delta: float) -> void:
    if not active or not is_instance_valid(target) or not target.active:
        velocity = Vector3.ZERO
        return
    cooldown = maxf(0.0, cooldown - delta)
    think_time -= delta
    if think_time <= 0.0:
        think_time = reaction
        _think()
    var dir := desired - global_position
    dir.y = 0.0
    if dir.length_squared() > 1.21:
        dir = dir.normalized()
        velocity.x = move_toward(velocity.x, dir.x * speed, 10.0 * delta)
        velocity.z = move_toward(velocity.z, dir.z * speed, 10.0 * delta)
        look_at(global_position + dir, Vector3.UP)
    else:
        velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
    if not is_on_floor():
        velocity.y -= 14.0 * delta
    move_and_slide()
    if _has_line_of_sight() and cooldown <= 0.0 and global_position.distance_to(target.global_position) < 26.0:
        _tag_target()

func _think() -> void:
    var distance := global_position.distance_to(target.global_position)
    var visible := _has_line_of_sight()
    if not visible:
        state = "COVER"
        desired = _pick_cover()
    elif distance > 14.0:
        state = "CHASE"
        desired = target.global_position
    elif difficulty == "EASY" and rng.randf() < 0.65:
        state = "RETREAT"
        desired = _retreat_point()
    else:
        state = "REPOSITION"
        desired = _reposition_point()

func _pick_cover() -> Vector3:
    if cover_points.is_empty(): return target.global_position
    return cover_points[rng.randi_range(0, cover_points.size() - 1)] + Vector3(rng.randf_range(-1.5, 1.5), 0, rng.randf_range(-1.5, 1.5))

func _retreat_point() -> Vector3:
    var away := global_position - target.global_position
    away.y = 0
    if away.length_squared() < 0.01: away = Vector3.FORWARD
    return global_position + away.normalized() * 6.0

func _reposition_point() -> Vector3:
    return target.global_position + Vector3(rng.randf_range(-6.0, 6.0), 0, rng.randf_range(-6.0, 6.0))

func _has_line_of_sight() -> bool:
    if not is_instance_valid(target): return false
    var from := global_position + Vector3.UP * 1.25
    var to := target.global_position + Vector3.UP * 1.25
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.collision_mask = 1 | 2
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    return not hit.has("collider") or hit.collider == target

func _tag_target() -> void:
    cooldown = 1.1 if difficulty == "EASY" else (0.7 if difficulty == "NORMAL" else 0.48)
    target.receive_tag(12, self)
    tag_landed.emit(target)

func receive_tag(damage: int, source: Node) -> void:
    if not active: return
    hp = maxi(0, hp - damage)
    AudioManager.play_hit()
    StrikeVFX.energy_burst(get_tree().current_scene, global_position + Vector3.UP * 0.7, Color("#45f5ff"), 0.75)
    if hp <= 0:
        active = false
        collision_layer = 0
        collision_mask = 0
        hide()
        eliminated.emit(self)
