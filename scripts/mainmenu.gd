extends Control

func _ready() -> void:
	$Menu/SingleplayerBtn.pressed.connect(_on_singleplayer)
	$Menu/MultiplayerBtn.pressed.connect(_on_multiplayer)
	$Menu/CharacterBtn.pressed.connect(_on_character)
	$Menu/ModsBtn.pressed.connect(_on_mods)
	$Menu/DetailsContainer/OptionsBtn.pressed.connect(_on_options)
	$Menu/DetailsContainer/QuitBtn.pressed.connect(_on_quit)

func _on_singleplayer() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_multiplayer() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_character() -> void:
	$CustomizeCharacter.visible = true

func _on_mods() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_options() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_quit() -> void:
	get_tree().quit()
