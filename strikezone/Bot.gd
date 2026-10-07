extends CharacterBody3D
signal died

var target:Node3D
var hp := 100
var speed := 2.6
var alive := true

func _ready():
    var capsule = CollisionShape3D.new()
    var cs = CapsuleShape3D.new()
    cs.height = 1.8
    cs.radius = 0.38
    capsule.shape = cs
    capsule.position.y = 0.9
    add_child(capsule)

    var mesh = MeshInstance3D.new()
    var cm = CapsuleMesh.new()
    cm.height = 1.8
    cm.radius = 0.38
    mesh.mesh = cm
    mesh.position.y = 0.9
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#ff6688")
    mesh.material_override = mat
    add_child(mesh)

func _physics_process(_delta):
    if not alive or target == null:
        return
    var flat = target.global_position
    flat.y = global_position.y
    var dist = global_position.distance_to(flat)
    if dist > 7:
        velocity = (flat-global_position).normalized() * speed
        move_and_slide()
    else:
        velocity = Vector3.ZERO

func tagged():
    if not alive:
        return
    hp -= 34
    if hp <= 0:
        alive = false
        hide()
        $CollisionShape3D.disabled = true
        died.emit()

func respawn(pos:Vector3):
    global_position = pos
    hp = 100
    alive = true
    show()
    $CollisionShape3D.disabled = false
