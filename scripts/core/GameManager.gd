extends Node

var current_state := "MENU"
var difficulty := "NORMAL"

func start_match(diff: String = "NORMAL") -> void:
    difficulty = diff
    current_state = "MATCH"
    get_tree().change_scene_to_file("res://Main.tscn")

func to_menu() -> void:
    current_state = "MENU"
    get_tree().change_scene_to_file("res://Main.tscn")

func quit_game() -> void:
    get_tree().quit()
