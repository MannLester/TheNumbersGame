extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Make the main game area responsive while maintaining layout
	setup_responsive_layout()

func setup_responsive_layout():
	var screen_size = get_viewport().get_visible_rect().size
	var scale_factor = min(screen_size.x / 720.0, screen_size.y / 1280.0)
	
	# Scale the turn identifier text and positioning
	scale_turn_identifier(scale_factor)
	
	# Adjust component spacing and positioning for different screen sizes
	adjust_component_positioning(screen_size, scale_factor)

func scale_turn_identifier(scale_factor: float):
	# Scale the "Player X's Turn" text
	var turn_label = $"Turn Identifier/MarginContainer/Label"
	if turn_label:
		var base_font_size = 39  # Your original font size
		var new_font_size = max(24, base_font_size * scale_factor)  # Minimum 24px
		turn_label.add_theme_font_size_override("font_size", int(new_font_size))
		
		# Scale outline size proportionally
		var base_outline = 3
		var new_outline = max(1, base_outline * scale_factor)
		turn_label.add_theme_constant_override("outline_size", int(new_outline))

func adjust_component_positioning(screen_size: Vector2, scale_factor: float):
	# Adjust Turn Identifier positioning to maintain proper spacing
	var turn_identifier = $"Turn Identifier"
	if turn_identifier:
		# Keep it positioned below the header with responsive spacing
		var header_height = 120 * scale_factor  # Header scales with screen
		var spacing = max(10, 15 * scale_factor)  # Responsive spacing
		
		# Update anchor positioning to maintain relative position
		var new_anchor_top = (header_height + spacing) / screen_size.y
		turn_identifier.anchor_top = clamp(new_anchor_top, 0.1, 0.25)  # Keep it reasonable
		turn_identifier.anchor_bottom = turn_identifier.anchor_top
		
		# Adjust height based on scale
		var container_height = max(40, 60 * scale_factor)
		turn_identifier.custom_minimum_size.y = container_height
		turn_identifier.offset_top = -container_height / 2
		turn_identifier.offset_bottom = container_height / 2

# Handle screen size changes in real-time
func _notification(what):
	if what == NOTIFICATION_RESIZED:
		call_deferred("setup_responsive_layout")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
