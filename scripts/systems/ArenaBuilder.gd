extends Node3D

var material_cache: Dictionary = {}
var spawn_points: Array[Vector3] = []
var cover_points: Array[Vector3] = []

func _ready() -> void: build()

func mat(color: Color, emission := Color.BLACK) -> StandardMaterial3D:
    var key := "%s|%s" % [color, emission]
    if material_cache.has(key): return material_cache[key]
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = 0.25
    m.roughness = 0.7
    if emission != Color.BLACK:
        m.emission_enabled = true
        m.emission = emission
        m.emission_energy_multiplier = 1.4
    material_cache[key] = m
    return m

func box(pos: Vector3, size: Vector3, color: Color, collision := true, glow := Color.BLACK) -> Node3D:
    var body: Node3D = StaticBody3D.new() if collision else Node3D.new()
    body.position = pos
    var mesh := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = size
    mesh.mesh = bm
    mesh.material_override = mat(color, glow)
    body.add_child(mesh)
    if collision:
        var cs := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        cs.shape = shape
        body.add_child(cs)
    add_child(body)
    return body

func build() -> void:
    var low := SettingsManager.data.graphics == "LOW"
    box(Vector3(0,-0.5,0), Vector3(80,1,80), Color("#11182a"))
    for x in [-40.0,40.0]: box(Vector3(x,4,0),Vector3(1,8,80),Color("#1d2941"))
    for z in [-40.0,40.0]: box(Vector3(0,4,z),Vector3(80,8,1),Color("#1d2941"))
    var base := Color("#263653")
    var glow := Color("#45f5ff")
    box(Vector3(0,0.7,0),Vector3(18,1.4,18),base)
    box(Vector3(0,1.45,0),Vector3(12,0.18,12),glow,false,glow)
    for p in [Vector3(-24,1.5,-18),Vector3(24,1.5,-18),Vector3(-24,1.5,18),Vector3(24,1.5,18)]:
        box(p,Vector3(8,3,5),base.lightened(0.06))
        cover_points.append(Vector3(p.x,0,p.z))
    for x in [-22.0,22.0]:
        box(Vector3(x,2,0),Vector3(5,4,16),base)
        cover_points.append(Vector3(x + (6 if x < 0 else -6),0,0))
    for z in [-22.0,22.0]:
        box(Vector3(0,2,z),Vector3(16,4,5),base)
        cover_points.append(Vector3(0,0,z + (6 if z < 0 else -6)))
    spawn_points = [Vector3(-30,0,-10),Vector3(30,0,10),Vector3(-10,0,30),Vector3(10,0,-30),Vector3(-30,0,10),Vector3(30,0,-10)]
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50,-25,0)
    sun.light_energy = 0.9 if low else 1.0
    sun.shadow_enabled = not low
    add_child(sun)
    if not low:
        var light := OmniLight3D.new()
        light.position = Vector3(0,6,0)
        light.omni_range = 22
        light.light_energy = 2.0
        light.light_color = glow
        add_child(light)

func get_spawn_points() -> Array[Vector3]: return spawn_points
func get_cover_points() -> Array[Vector3]: return cover_points
