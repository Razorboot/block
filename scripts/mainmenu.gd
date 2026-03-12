extends Control

func _ready() -> void:
	$NewGameBtn.pressed.connect(_on_new_game_pressed)

func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
