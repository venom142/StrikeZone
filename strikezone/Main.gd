extends Node3D

var player
var bots:Array[Node] = []
var round_no := 1
var player_score := 0
var bot_score := 0
var round_active := false
var round_time := 45.0
var time_left := 45.0
var hud:CanvasLayer
var status_label:Label
var score_label:Label
var timer_label:Label
var menu:Control

func _ready():
    build_world()
    build_hud()
    show_menu()

func build_world():
    var env = WorldEnvironment.new()
    var e = Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color("#101827")
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color("#8aa0c8")
    e.ambient_light_energy = 0.65
    env.environment = e
    add_child(env)

    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55,-25,0)
    sun.light_energy = 1.1
    add_child(sun)

    make_box(Vector3(0,-1,0), Vector3(34,2,24), Color("#253149"))
    make_box(Vector3(0,4,-12), Vector3(34,8,1), Color("#33415e"))
    make_box(Vector3(0,4,12), Vector3(34,8,1), Color("#33415e"))
    make_box(Vector3(-17,4,0), Vector3(1,8,24), Color("#33415e"))
    make_box(Vector3(17,4,0), Vector3(1,8,24), Color("#33415e"))

    for p in [Vector3(-7,0,0),Vector3(7,0,0),Vector3(0,0,5),Vector3(0,0,-5)]:
        make_box(p + Vector3(0,1,0), Vector3(3,2,2), Color("#40516f"))

    player = preload("res://Player.gd").new()
    player.position = Vector3(0,0.1,8)
    player.name = "Player"
    add_child(player)

    for i in 4:
        var b = preload("res://Bot.gd").new()
        b.position = [Vector3(-9,0,-7),Vector3(9,0,-7),Vector3(-9,0,7),Vector3(9,0,7)][i]
        b.target = player
        b.name = "Bot_%d" % i
        b.died.connect(_on_bot_died)
        add_child(b)
        bots.append(b)

func make_box(pos:Vector3, size:Vector3, color:Color):
    var body = StaticBody3D.new()
    body.position = pos
    var shape = CollisionShape3D.new()
    var box = BoxShape3D.new()
    box.size = size
    shape.shape = box
    body.add_child(shape)
    var mesh = MeshInstance3D.new()
    var bm = BoxMesh.new()
    bm.size = size
    mesh.mesh = bm
    var mat = StandardMaterial3D.new()
    mat.albedo_color = color
    mesh.material_override = mat
    body.add_child(mesh)
    add_child(body)

func build_hud():
    hud = CanvasLayer.new()
    add_child(hud)

    status_label = Label.new()
    status_label.position = Vector2(24,20)
    status_label.add_theme_font_size_override("font_size",28)
    hud.add_child(status_label)

    score_label = Label.new()
    score_label.position = Vector2(24,58)
    score_label.add_theme_font_size_override("font_size",22)
    hud.add_child(score_label)

    timer_label = Label.new()
    timer_label.position = Vector2(1080,20)
    timer_label.add_theme_font_size_override("font_size",28)
    hud.add_child(timer_label)

    var fire = Button.new()
    fire.text = "TAG"
    fire.position = Vector2(1080,560)
    fire.size = Vector2(150,110)
    fire.add_theme_font_size_override("font_size",30)
    fire.pressed.connect(_fire_pressed)
    hud.add_child(fire)

    var jump = Button.new()
    jump.text = "JUMP"
    jump.position = Vector2(900,600)
    jump.size = Vector2(130,70)
    jump.pressed.connect(_jump_pressed)
    hud.add_child(jump)

    var hint = Label.new()
    hint.text = "MOVE: WASD / TOUCH    LOOK: SWIPE    TAG: BUTTON"
    hint.position = Vector2(330,665)
    hint.add_theme_font_size_override("font_size",16)
    hud.add_child(hint)

func show_menu():
    menu = Control.new()
    menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu.mouse_filter = Control.MOUSE_FILTER_STOP
    hud.add_child(menu)

    var bg = ColorRect.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.color = Color("#0b1020e8")
    menu.add_child(bg)

    var title = Label.new()
    title.text = "STRIKEZONE"
    title.position = Vector2(0,120)
    title.size = Vector2(1280,70)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size",54)
    menu.add_child(title)

    var sub = Label.new()
    sub.text = "MOBILE ARENA"
    sub.position = Vector2(0,185)
    sub.size = Vector2(1280,40)
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sub.add_theme_font_size_override("font_size",20)
    menu.add_child(sub)

    var play = Button.new()
    play.text = "PLAY"
    play.position = Vector2(480,300)
    play.size = Vector2(320,90)
    play.add_theme_font_size_override("font_size",34)
    play.pressed.connect(start_match)
    menu.add_child(play)

    var info = Label.new()
    info.text = "5 rounds • arena • bots • touch controls"
    info.position = Vector2(0,420)
    info.size = Vector2(1280,40)
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    menu.add_child(info)

func start_match():
    menu.queue_free()
    round_no = 1
    player_score = 0
    bot_score = 0
    start_round()

func start_round():
    round_active = true
    time_left = round_time
    player.respawn()
    for i in bots.size():
        bots[i].respawn([Vector3(-9,0,-7),Vector3(9,0,-7),Vector3(-9,0,7),Vector3(9,0,7)][i])
    status_label.text = "ROUND %d/5" % round_no
    update_hud()

func _process(delta):
    if not round_active:
        return
    time_left -= delta
    timer_label.text = "%02d" % max(0,ceil(time_left))
    if time_left <= 0:
        finish_round()

func _fire_pressed():
    if round_active:
        player.tag_target()

func _jump_pressed():
    if round_active:
        player.jump_now()

func _on_bot_died():
    player_score += 1
    update_hud()
    if player_score >= 3:
        finish_round(true)

func finish_round(player_won=false):
    if not round_active:
        return
    round_active = false
    if not player_won:
        bot_score += 1
    if round_no >= 5:
        status_label.text = "MATCH COMPLETE"
        timer_label.text = ""
        await get_tree().create_timer(2.0).timeout
        show_menu()
    else:
        round_no += 1
        await get_tree().create_timer(1.5).timeout
        start_round()

func update_hud():
    score_label.text = "YOU %d   :   BOTS %d" % [player_score,bot_score]
