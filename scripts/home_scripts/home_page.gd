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
	# TODO: Navigate to game scene with the selected mode
	# For now, just print the mode
	match selected_mode:
		0: # Normal Mode
			print("Starting Normal Mode game...")
		1: # Rank Mode  
			print("Starting Rank Mode game...")
		2: # Club Mode
			print("Starting Club Mode game...")
		3: # Competition Mode
			print("Starting Competition Mode game...")
