extends Control

func _ready():
	# Connect to game mode selector signals if available
	var game_mode_selector = $"Game Modes"
	if game_mode_selector and game_mode_selector.has_signal("mode_changed"):
		game_mode_selector.mode_changed.connect(_on_mode_changed)
		print("Home page connected to game mode selector")
	
	if game_mode_selector and game_mode_selector.has_signal("play_button_pressed"):
		game_mode_selector.play_button_pressed.connect(_on_play_button_pressed)

func _on_mode_changed(_new_mode, mode_name: String):
	print("Home page received mode change: ", mode_name)
	# Here you could add additional logic like updating other UI elements

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
