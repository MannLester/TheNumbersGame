extends Control

# Base dimensions for 720x1280 resolution
const BASE_WIDTH = 720.0
const BASE_HEIGHT = 1280.0
const BASE_HAND_WIDTH = 300.0
const BASE_HAND_HEIGHT = 100.0
const BASE_VBOX_SEPARATION = 25.0
const BASE_HBOX_SEPARATION = -50.0

# Minimum constraints
const MIN_HAND_WIDTH = 200.0
const MIN_HAND_HEIGHT = 70.0

# Node references
@onready var margin_container = $MarginContainer
@onready var vbox_container = $MarginContainer/VBoxContainer
@onready var label_control = $MarginContainer/VBoxContainer/Control
@onready var player_label = $MarginContainer/VBoxContainer/Control/Label
@onready var hbox_container = $MarginContainer/VBoxContainer/HBoxContainer

func _ready() -> void:
	# Connect to screen size changes
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# Setup initial responsive layout
	setup_responsive_layout()

func _on_viewport_size_changed():
	setup_responsive_layout()

func setup_responsive_layout():
	var screen_size = get_viewport().get_visible_rect().size
	var scale_x = screen_size.x / BASE_WIDTH
	var scale_y = screen_size.y / BASE_HEIGHT
	var scale_factor = min(scale_x, scale_y)
	
	scale_hand_dimensions(scale_factor)
	scale_spacing_and_containers(scale_factor)
	scale_label(scale_factor)

func scale_hand_dimensions(scale_factor: float):
	# Scale the main hand control size
	var new_width = max(BASE_HAND_WIDTH * scale_factor, MIN_HAND_WIDTH)
	var new_height = max(BASE_HAND_HEIGHT * scale_factor, MIN_HAND_HEIGHT)
	
	custom_minimum_size = Vector2(new_width, new_height)
	
	# Update offsets to maintain centered top positioning
	offset_left = -new_width * 0.5
	offset_right = new_width * 0.5
	offset_bottom = offset_top + new_height

func scale_spacing_and_containers(scale_factor: float):
	# Scale VBox separation
	var new_vbox_separation = BASE_VBOX_SEPARATION * scale_factor
	vbox_container.add_theme_constant_override("separation", new_vbox_separation)
	
	# Scale HBox card overlap
	var new_hbox_separation = BASE_HBOX_SEPARATION * scale_factor
	hbox_container.add_theme_constant_override("separation", new_hbox_separation)
	
	# Scale container minimum sizes
	var container_width = 100.0 * scale_factor
	var container_height = 140.0 * scale_factor
	vbox_container.custom_minimum_size = Vector2(container_width, container_height)
	hbox_container.custom_minimum_size = Vector2(container_width, container_height)

func scale_label(scale_factor: float):
	# Scale the player label
	if player_label:
		var label_height = 23.0 * scale_factor
		player_label.size = Vector2(player_label.size.x, label_height)
		
		# Maintain centered alignment
		player_label.position = Vector2(-0.5 * scale_factor, 0)
		player_label.size = Vector2(1.0 * scale_factor, label_height)
