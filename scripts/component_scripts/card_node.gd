extends Control

# Base card dimensions for 720x1280 resolution
const BASE_WIDTH = 720.0
const BASE_HEIGHT = 1280.0
const BASE_CARD_WIDTH = 100.0
const BASE_CARD_HEIGHT = 140.0

# Minimum constraints
const MIN_CARD_WIDTH = 60.0
const MIN_CARD_HEIGHT = 84.0

func _ready() -> void:
	# Connect to screen size changes for responsive updates
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# Setup initial responsive card
	setup_responsive_card()

func _on_viewport_size_changed():
	setup_responsive_card()

func setup_responsive_card():
	var screen_size = get_viewport().get_visible_rect().size
	var scale_x = screen_size.x / BASE_WIDTH
	var scale_y = screen_size.y / BASE_HEIGHT
	var scale_factor = min(scale_x, scale_y)
	
	# Scale card minimum size with constraints
	var new_width = max(BASE_CARD_WIDTH * scale_factor, MIN_CARD_WIDTH)
	var new_height = max(BASE_CARD_HEIGHT * scale_factor, MIN_CARD_HEIGHT)
	
	custom_minimum_size = Vector2(new_width, new_height)
