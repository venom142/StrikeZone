extends CharacterBody3D

var speed := 6.0
var gravity := 18.0
var hp := 100
var camera:Camera3D
var look_touch := -1

func _ready():
    var capsule = CollisionShape3D.new()
    var cs = CapsuleShape3D.new()
    cs.height = 1.8
    cs.radius = 0.35
    capsule.shape = cs
    capsule.position.y = 0.9
    add_child(capsule)

    var mesh = MeshInstance3D.new()
    var cm = CapsuleMesh.new()
    cm.height = 1.8
    cm.radius = 0.35
    mesh.mesh = cm
    mesh.position.y = 0.9
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#40c4ff")
    mesh.material_override = mat
    add_child(mesh)

    camera = Camera3D.new()
    camera.position = Vector3(0,1.55,0)
    camera.current = true
    add_child(camera)

func _physics_process(delta):
    var input = Input.get_vector("move_left","move_right","move_forward","move_back")
    var dir = Vector3(input.x,0,input.y)
    velocity.x = dir.x * speed
    velocity.z = dir.z * speed
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = -0.2
    move_and_slide()

func _unhandled_input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            look_touch = event.index
        elif event.index == look_touch:
            look_touch = -1
    elif event is InputEventScreenDrag and event.index == look_touch:
        rotate_y(-event.relative.x * 0.006)

func tag_target():
    var from = camera.global_position
    var to = from + -camera.global_transform.basis.z * 35.0
    var q = PhysicsRayQueryParameters3D.create(from,to)
    q.exclude = [self]
    var hit = get_world_3d().direct_space_state.intersect_ray(q)
    if hit and hit.collider.has_method("tagged"):
        hit.collider.tagged()

func jump_now():
    if is_on_floor():
        velocity.y = 7.5

func respawn():
    hp = 100
    velocity = Vector3.ZERO
    global_position = Vector3(0,0.1,8)
