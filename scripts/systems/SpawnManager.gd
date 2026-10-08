extends Node

var points: Array[Vector3] = []
var rng := RandomNumberGenerator.new()

func setup(source: Node) -> void:
    points = source.get_spawn_points()
    rng.randomize()

func choose_spawn(avoid: Vector3 = Vector3.ZERO) -> Vector3:
    if points.is_empty(): return Vector3.ZERO
    var candidates: Array[Vector3] = []
    for p in points:
        if p.distance_to(avoid) > 9.0: candidates.append(p)
    if candidates.is_empty(): candidates = points.duplicate()
    return candidates[rng.randi_range(0, candidates.size() - 1)]
