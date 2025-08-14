extends Control

# Base dimensions for 720x1280 resolution
const BASE_WIDTH = 720.0
const BASE_HEIGHT = 1280.0
const BASE_HAND_WIDTH = 140.0
const BASE_HAND_HEIGHT = 300.0
const BASE_MARGIN = 10.0
const BASE_SEPARATION = 25.0
const BASE_CARD_OVERLAP = -100.0

# Minimum constraints
const MIN_HAND_WIDTH = 100.0
const MIN_HAND_HEIGHT = 200.0
const MIN_MARGIN = 5.0

# Node references
@onready var margin_container = $MarginContainer
@onready var hbox_container = $MarginContainer/HBoxContainer
@onready var vbox_container = $MarginContainer/HBoxContainer/VBoxContainer
@onready var label_control = $MarginContainer/HBoxContainer/Control
@onready var player_label = $MarginContainer/HBoxContainer/Control/Label

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
	scale_margins_and_spacing(scale_factor)
	scale_label(scale_factor)

func scale_hand_dimensions(scale_factor: float):
	# Scale the main hand control size
	var new_width = max(BASE_HAND_WIDTH * scale_factor, MIN_HAND_WIDTH)
	var new_height = max(BASE_HAND_HEIGHT * scale_factor, MIN_HAND_HEIGHT)
	
	custom_minimum_size = Vector2(new_width, new_height)
	
	# Update the offset to maintain left-side positioning
	offset_right = new_width
	offset_top = -new_height * 0.5
	offset_bottom = new_height * 0.5

func scale_margins_and_spacing(scale_factor: float):
	# Scale margin container
	var new_margin = max(BASE_MARGIN * scale_factor, MIN_MARGIN)
	margin_container.add_theme_constant_override("margin_left", new_margin)
	
	# Scale HBox separation
	var new_separation = BASE_SEPARATION * scale_factor
	hbox_container.add_theme_constant_override("separation", new_separation)
	
	# Scale VBox card overlap
	var new_overlap = BASE_CARD_OVERLAP * scale_factor
	vbox_container.add_theme_constant_override("separation", new_overlap)
	
	# Scale container minimum size
	var container_width = 100.0 * scale_factor
	var container_height = 140.0 * scale_factor
	vbox_container.custom_minimum_size = Vector2(container_width, container_height)

func scale_label(scale_factor: float):
	# Scale the player label
	if player_label:
		# Calculate rotated label dimensions
		var label_width = 40.0 * scale_factor
		var label_height = 23.0 * scale_factor
		
		player_label.size = Vector2(label_width, label_height)
