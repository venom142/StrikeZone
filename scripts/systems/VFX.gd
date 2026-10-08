extends Node
class_name StrikeVFX

static func material(color: Color, glow: float = 1.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.emission_enabled = true
    m.emission = color
    m.emission_energy_multiplier = glow
    return m

static func energy_burst(parent: Node3D, position: Vector3, color: Color, scale_factor: float = 1.0) -> void:
    var root := Node3D.new()
    root.position = position
    parent.add_child(root)
    var mesh := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.14 * scale_factor
    sphere.height = 0.28 * scale_factor
    mesh.mesh = sphere
    mesh.material_override = material(color, 1.5)
    root.add_child(mesh)
    var tween := root.create_tween()
    tween.tween_property(mesh, "scale", Vector3.ONE * (3.5 * scale_factor), 0.18)
    tween.tween_callback(root.queue_free)

static func spawn_burst(parent: Node3D, position: Vector3, color: Color) -> void:
    energy_burst(parent, position + Vector3.UP * 0.5, color, 1.0)

static func floating_number(parent: Node3D, position: Vector3, value: int, color: Color) -> void:
    var label := Label3D.new()
    label.text = "-%d" % value
    label.modulate = color
    label.position = position + Vector3.UP * 1.7
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    parent.add_child(label)
    var tween := parent.create_tween()
    tween.tween_property(label, "position:y", label.position.y + 0.7, 0.5)
    tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
    tween.tween_callback(label.queue_free)

static func spawn_trail(parent: Node3D, owner: Node3D, color: Color) -> GPUParticles3D:
    var particles := GPUParticles3D.new()
    particles.amount = 10
    particles.lifetime = 0.45
    particles.process_material = ParticleProcessMaterial.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.035
    sphere.height = 0.07
    sphere.material = material(color, 1.5)
    particles.draw_pass_1 = sphere
    owner.add_child(particles)
    particles.emitting = true
    return particles
