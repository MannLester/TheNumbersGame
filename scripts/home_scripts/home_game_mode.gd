extends Control

# Signal to notify when mode changes
signal mode_changed(mode_index: int, mode_name: String)
signal play_button_pressed(mode_index: int)

# Game modes configuration
var game_modes = [
	{
		"name": "Normal Mode",
		"icon": "res://assets/icons/normal_mode.png",
		"background": "res://assets/images/backgrounds/blue_background.jpg"
	},
	{
		"name": "Rank Mode", 
		"icon": "res://assets/icons/rank_mode.png",
		"background": "res://assets/images/backgrounds/red_background.png"
	},
	{
		"name": "Club Wars",
		"icon": "res://assets/icons/club_mode.png", 
		"background": "res://assets/images/backgrounds/green_background.png"
	},
	{
		"name": "Competition",
		"icon": "res://assets/icons/competition_mode.png",
		"background": "res://assets/images/backgrounds/orange_background.png"
	}
]

var current_mode_index = 0

# References to UI elements
@onready var mode_icon = $"MarginContainer/HBoxContainer/VBoxContainer/TextureRect"
@onready var mode_label = $"MarginContainer/HBoxContainer/VBoxContainer/TextureRect/Label"
@onready var play_button = $"MarginContainer/HBoxContainer/VBoxContainer/TextureButton"
@onready var left_button = $"MarginContainer/HBoxContainer/Control/Button"
@onready var right_button = $"MarginContainer/HBoxContainer/Control2/Button"

func _ready():
	# Connect button signals
	left_button.pressed.connect(_on_left_button_pressed)
	right_button.pressed.connect(_on_right_button_pressed)
	play_button.pressed.connect(_on_play_button_pressed)
	
	# Initialize with the first mode
	update_mode_display()
	print("Game mode selector initialized")

func _on_left_button_pressed():
	current_mode_index = (current_mode_index - 1) % game_modes.size()
	if current_mode_index < 0:
		current_mode_index = game_modes.size() - 1
	update_mode_display()
	print("Left button pressed, switched to mode: ", game_modes[current_mode_index]["name"])

func _on_right_button_pressed():
	current_mode_index = (current_mode_index + 1) % game_modes.size()
	update_mode_display()
	print("Right button pressed, switched to mode: ", game_modes[current_mode_index]["name"])

func _on_play_button_pressed():
	play_button_pressed.emit(current_mode_index)
	print("Play button pressed for mode: ", game_modes[current_mode_index]["name"])

func update_mode_display():
	var current_mode = game_modes[current_mode_index]
	
	# Update the icon
	var icon_texture = load(current_mode["icon"])
	if icon_texture:
		mode_icon.texture = icon_texture
	else:
		print("Warning: Could not load icon: ", current_mode["icon"])
	
	# Update the label
	mode_label.text = current_mode["name"]
	
	# Emit signal for background change
	mode_changed.emit(current_mode_index, current_mode["name"])
	
	print("Updated mode display to: ", current_mode["name"])

func get_current_mode():
	return game_modes[current_mode_index]

func get_current_background():
	return game_modes[current_mode_index]["background"]
