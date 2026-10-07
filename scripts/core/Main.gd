extends Node3D

const ArenaBuilderScene = preload("res://scenes/arena/Arena.tscn")
const PlayerScene = preload("res://scenes/player/Player.tscn")
const BotScene = preload("res://scenes/bots/Bot.tscn")
const HUDScene = preload("res://scenes/ui/HUD.tscn")
const MenuScene = preload("res://scenes/menus/MainMenu.tscn")
const SpawnManagerScript = preload("res://scripts/systems/SpawnManager.gd")
const MatchManagerScript = preload("res://scripts/systems/MatchManager.gd")

var debug_layer: CanvasLayer
var debug_label: Label
var debug_player: StrikePlayer
var debug_match: MatchManager

func _ready() -> void:
    if GameManager.current_state == "MATCH":
        await start_match_world()
    else:
        add_child(MenuScene.instantiate())
        AudioManager.play_menu()

func start_match_world() -> void:
    var arena := ArenaBuilderScene.instantiate()
    arena.name = "Arena"
    add_child(arena)
    await get_tree().process_frame

    var spawns: Node = SpawnManagerScript.new()
    spawns.name = "SpawnManager"
    add_child(spawns)
    spawns.setup(arena)

    var player: StrikePlayer = PlayerScene.instantiate()
    player.name = "Player"
    add_child(player)
    player.global_position = spawns.choose_spawn(Vector3.ZERO) + Vector3.UP * 0.2

    var bots: Array[StrikeBot] = []
    for i in range(4):
        var bot: StrikeBot = BotScene.instantiate()
        bot.name = "Bot_%d" % (i + 1)
        add_child(bot)
        bot.global_position = spawns.choose_spawn(player.global_position) + Vector3.UP * 0.2
        bot.setup(player, GameManager.difficulty, arena.get_cover_points())
        bots.append(bot)

    var mm: MatchManager = MatchManagerScript.new()
    mm.name = "MatchManager"
    add_child(mm)
    mm.setup(player, bots, spawns)
    for bot in bots:
        bot.eliminated.connect(mm.on_bot_eliminated)

    var hud: CanvasLayer = HUDScene.instantiate()
    add_child(hud)
    hud.setup(player, mm)

    debug_player = player
    debug_match = mm
    _build_debug_menu()
    AudioManager.play_match_start()

func _build_debug_menu() -> void:
    if not OS.is_debug_build():
        return
    debug_layer = CanvasLayer.new()
    debug_layer.name = "DebugLayer"
    add_child(debug_layer)
    var panel := PanelContainer.new()
    panel.name = "DebugMenu"
    panel.position = Vector2(12, 110)
    panel.size = Vector2(280, 330)
    debug_layer.add_child(panel)
    var box := VBoxContainer.new()
    panel.add_child(box)
    debug_label = Label.new()
    debug_label.name = "DebugStats"
    box.add_child(debug_label)
    _debug_button(box, "RESTART ROUND", _debug_restart_round)
    _debug_button(box, "RESTART MATCH", _debug_restart_match)
    _debug_button(box, "RESET BOTS", _debug_reset_bots)
    _debug_button(box, "KILL BOTS", _debug_kill_bots)
    _debug_button(box, "TELEPORT SPAWN", _debug_teleport)

func _debug_button(parent: VBoxContainer, title: String, callback: Callable) -> void:
    var button := Button.new()
    button.text = title
    button.pressed.connect(callback)
    parent.add_child(button)

func _debug_restart_round() -> void:
    if debug_match:
        debug_match.restart_round_debug()

func _debug_restart_match() -> void:
    if debug_match:
        debug_match.restart_match_debug()

func _debug_reset_bots() -> void:
    if debug_match:
        debug_match.reset_bots_debug()

func _debug_kill_bots() -> void:
    if debug_match:
        debug_match.kill_bots_debug()

func _debug_teleport() -> void:
    var spawner := get_node_or_null("SpawnManager")
    if spawner and debug_player:
        debug_player.global_position = spawner.choose_spawn(Vector3.ZERO) + Vector3.UP * 0.2

func _process(_delta: float) -> void:
    if not OS.is_debug_build() or not debug_label:
        return
    var bot_count := get_tree().get_nodes_in_group("bots").size()
    var active_bots := 0
    for bot in get_tree().get_nodes_in_group("bots"):
        if is_instance_valid(bot) and bot.active:
            active_bots += 1
    var round := debug_match.round_no if debug_match else 0
    var pos := debug_player.global_position if debug_player else Vector3.ZERO
    var physics := Engine.get_physics_frames_per_second()
    var cpu_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
    debug_label.text = "FPS %d\nCPU %.2fms\nPhysics %d\nBots %d/%d\nRound %d/5\nPos %.1f, %.1f, %.1f" % [Engine.get_frames_per_second(), cpu_ms, physics, active_bots, bot_count, round, pos.x, pos.y, pos.z]
