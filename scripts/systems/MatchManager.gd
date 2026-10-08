extends Node
class_name MatchManager

signal hud_update(round_no: int, time_left: int, player_tags: int, bots_left: int)
signal round_finished(won: bool)
signal match_finished(won: bool)
signal round_transition(round_no: int)

const MAX_ROUNDS := 5
const ROUND_TIME := 60.0
const TARGET_TAGS := 4

var round_no := 1
var time_left := ROUND_TIME
var player_tags := 0
var bots_left := 4
var player: StrikePlayer
var bots: Array[StrikeBot] = []
var spawn_manager: Node
var active := false
var round_over := false
var finish_lock := false

func setup(p: StrikePlayer, b: Array[StrikeBot], spawner: Node) -> void:
    player = p
    bots = b
    spawn_manager = spawner
    active = true
    _start_round()

func _process(delta: float) -> void:
    if not active or round_over: return
    time_left = maxf(0.0, time_left - delta)
    hud_update.emit(round_no, ceili(time_left), player_tags, bots_left)
    if player_tags >= TARGET_TAGS: _finish_round(true)
    elif time_left <= 0.0 or not player.active: _finish_round(false)

func _start_round() -> void:
    round_over = false
    finish_lock = false
    time_left = ROUND_TIME
    player_tags = 0
    bots_left = bots.size()
    _reset_positions()
    player.reset_health()
    for bot in bots:
        bot.reset_for_round(player, GameManager.difficulty, _get_cover_points())
    round_transition.emit(round_no)
    hud_update.emit(round_no, int(ROUND_TIME), 0, bots_left)
    AudioManager.play_round()

func _reset_positions() -> void:
    if not is_instance_valid(spawn_manager): return
    player.global_position = spawn_manager.choose_spawn(Vector3.ZERO) + Vector3.UP * 0.2
    for bot in bots:
        if is_instance_valid(bot): bot.global_position = spawn_manager.choose_spawn(player.global_position) + Vector3.UP * 0.2

func _get_cover_points() -> Array[Vector3]:
    var arena := get_parent().get_node_or_null("Arena")
    if arena and arena.has_method("get_cover_points"): return arena.get_cover_points()
    return []

func on_bot_eliminated(_bot: Node) -> void:
    if round_over: return
    bots_left = maxi(0, bots_left - 1)
    player_tags = mini(TARGET_TAGS, player_tags + 1)
    SettingsManager.data.tags = int(SettingsManager.data.tags) + 1
    SettingsManager.save_data()

func _finish_round(won: bool) -> void:
    if finish_lock: return
    finish_lock = true
    round_over = true
    for bot in bots:
        if is_instance_valid(bot): bot.active = false
    round_finished.emit(won)
    if won: AudioManager.play_victory()
    else: AudioManager.play_defeat()
    await get_tree().create_timer(1.0).timeout
    if round_no >= MAX_ROUNDS:
        active = false
        SettingsManager.record_match_result(won)
        match_finished.emit(won)
    else:
        round_no += 1
        _start_round()

func restart_round_debug() -> void:
    if OS.is_debug_build(): _start_round()
func restart_match_debug() -> void:
    if OS.is_debug_build(): round_no = 1; _start_round()
func reset_bots_debug() -> void:
    if OS.is_debug_build():
        for bot in bots: bot.reset_for_round(player, GameManager.difficulty, _get_cover_points())
func kill_bots_debug() -> void:
    if OS.is_debug_build():
        for bot in bots:
            if bot.active: bot.receive_tag(999, player)
