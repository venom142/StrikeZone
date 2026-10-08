extends CharacterBody3D
class_name StrikePlayer

signal tag_landed(target: Node)
signal hp_changed(value: int)
signal eliminated
signal tag_missed
signal tag_hit_confirmed(target: Node, damage: int)

const MAX_HP := 100
const TAG_DAMAGE := 25
const TAG_RANGE := 42.0
const TAG_COOLDOWN := 0.55

var speed := 6.2
var sprint_speed := 9.2
var jump_velocity := 5.2
var gravity := 14.0
var hp := MAX_HP
var tag_cooldown := 0.0
var camera: Camera3D
var pitch := -8.0
var yaw := 0.0
var mobile_move := Vector2.ZERO
var touch_look := Vector2.ZERO
var sprinting := false
var active := true
var pulse_color := Color("#45f5ff")
var trail: GPUParticles3D

func _ready() -> void:
    collision_layer = 2
    collision_mask = 1
    _build_body()
    _apply_cosmetics()

func _build_body() -> void:
    var shape := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.42
    capsule.height = 1.7
    shape.shape = capsule
    shape.position.y = 0.85
    add_child(shape)
    var mesh := MeshInstance3D.new()
    var cm := CapsuleMesh.new()
    cm.radius = 0.42
    cm.height = 1.7
    mesh.mesh = cm
    mesh.material_override = StrikeVFX.material(pulse_color, 0.35)
    mesh.position.y = 0.85
    mesh.name = "PlayerBody"
    add_child(mesh)
    camera = Camera3D.new()
    camera.name = "PlayerCamera"
    camera.position = Vector3(0, 1.58, 0)
    camera.current = true
    camera.fov = 78.0
    add_child(camera)

func _apply_cosmetics() -> void:
    var palette := [Color("#45f5ff"), Color("#ff4bd8"), Color("#ffe45e"), Color("#7cff8a")]
    pulse_color = palette[clampi(int(SettingsManager.data.cosmetic_color), 0, palette.size() - 1)]
    var mesh := get_node_or_null("PlayerBody") as MeshInstance3D
    if mesh: mesh.material_override = StrikeVFX.material(pulse_color, 0.35)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT): set_look(event.relative)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed: tag()

func _physics_process(delta: float) -> void:
    if not active:
        velocity = Vector3.ZERO
        return
    tag_cooldown = maxf(0.0, tag_cooldown - delta)
    var input_vec := mobile_move
    var keyboard := Vector2(float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)), float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
    if keyboard.length_squared() > 0.01: input_vec = keyboard.normalized()
    var local := Vector3(input_vec.x, 0, input_vec.y)
    var basis_dir := global_transform.basis * local
    basis_dir.y = 0.0
    if basis_dir.length_squared() > 1.0: basis_dir = basis_dir.normalized()
    var target_speed := sprint_speed if sprinting or Input.is_key_pressed(KEY_SHIFT) else speed
    velocity.x = move_toward(velocity.x, basis_dir.x * target_speed, 24.0 * delta)
    velocity.z = move_toward(velocity.z, basis_dir.z * target_speed, 24.0 * delta)
    if not is_on_floor(): velocity.y -= gravity * delta
    elif Input.is_key_pressed(KEY_SPACE): velocity.y = jump_velocity
    move_and_slide()
    _look(delta)

func _look(delta: float) -> void:
    yaw -= touch_look.x * 0.65 * float(SettingsManager.data.sensitivity)
    pitch = clampf(pitch - touch_look.y * 0.65 * float(SettingsManager.data.sensitivity), -78.0, 70.0)
    rotation.y = yaw
    camera.rotation.x = deg_to_rad(pitch)
    touch_look = touch_look.lerp(Vector2.ZERO, minf(1.0, delta * 12.0))

func set_look(delta_vec: Vector2) -> void: touch_look += delta_vec * 0.7
func set_move(value: Vector2) -> void: mobile_move = value
func set_sprint(value: bool) -> void: sprinting = value
func jump() -> void:
    if active and is_on_floor(): velocity.y = jump_velocity

func tag() -> void:
    if tag_cooldown > 0.0 or not active: return
    tag_cooldown = TAG_COOLDOWN
    var direction := -camera.global_transform.basis.z
    var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position + direction * TAG_RANGE)
    query.collision_mask = 4
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    var hit_position := camera.global_position + direction * 8.0
    if hit.has("position"): hit_position = hit.position
    StrikeVFX.energy_burst(get_tree().current_scene, hit_position, pulse_color, 0.8)
    AudioManager.play_tag()
    if hit.has("collider") and hit.collider.has_method("receive_tag"):
        hit.collider.receive_tag(TAG_DAMAGE, self)
        tag_landed.emit(hit.collider)
        tag_hit_confirmed.emit(hit.collider, TAG_DAMAGE)
    else: tag_missed.emit()

func receive_tag(damage: int, source: Node) -> void:
    if not active: return
    hp = maxi(0, hp - damage)
    hp_changed.emit(hp)
    AudioManager.play_hit()
    if hp <= 0:
        active = false
        eliminated.emit()

func reset_health() -> void:
    hp = MAX_HP
    hp_changed.emit(hp)
    active = true
    _apply_cosmetics()
