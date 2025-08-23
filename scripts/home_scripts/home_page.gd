extends Control

@onready var background_texture = $"TextureRect"

func _ready():
	# Connect to game mode selector signals if available
	var game_mode_selector = $"Game Modes"
	if game_mode_selector and game_mode_selector.has_signal("mode_changed"):
		game_mode_selector.mode_changed.connect(_on_mode_changed)
		print("Home page connected to game mode selector")
	
	if game_mode_selector and game_mode_selector.has_signal("play_button_pressed"):
		game_mode_selector.play_button_pressed.connect(_on_play_button_pressed)

func _on_mode_changed(_mode_index: int, mode_name: String):
	print("Home page received mode change: ", mode_name)
	# Update background based on mode
	var game_mode_selector = $"Game Modes"
	if game_mode_selector:
		var background_path = game_mode_selector.get_current_background()
		var background = load(background_path)
		if background and background_texture:
			background_texture.texture = background
			print("Background changed to: ", background_path)
		else:
			print("Warning: Could not load background: ", background_path)

func _on_play_button_pressed(selected_mode):
	print("Home page received play button press for mode: ", selected_mode)
	
	# Store selected mode for later use (all modes use same mechanics for now)
	var mode_names = ["Normal Mode", "Rank Mode", "Club Mode", "Competition Mode"]
	var selected_mode_name = mode_names[selected_mode] if selected_mode < mode_names.size() else "Unknown Mode"
	
	print("Starting ", selected_mode_name, " - Creating multiplayer lobby...")
	
	# Navigate to lobby/room creation for all modes
	get_tree().change_scene_to_file("res://scenes/lobby_page/lobby_page.tscn")
