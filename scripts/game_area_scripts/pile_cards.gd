extends Control

func _ready() -> void:
	# Make pile cards responsive while maintaining design
	setup_responsive_layout()

func setup_responsive_layout():
	var screen_size = get_viewport().get_visible_rect().size
	var scale_factor = min(screen_size.x / 720.0, screen_size.y / 1280.0)
	
	# Scale the layered circular backgrounds
	scale_background_circles(scale_factor)
	
	# Scale the card node size
	scale_card_container(scale_factor)
	
	# Scale text elements (counter and description)
	scale_text_elements(scale_factor)

func scale_background_circles(scale_factor: float):
	# Scale the 3 layered yellow circles while maintaining the layered effect
	var circles = [$Panel, $Panel2, $Panel3]  # Inner, middle, outer
	var base_sizes = [
		Vector2(202, 177),   # Panel (inner) - calculated from your offsets
		Vector2(272, 270),   # Panel2 (middle)  
		Vector2(376, 348)    # Panel3 (outer)
	]
	
	for i in range(circles.size()):
		var circle = circles[i]
		if circle:
			var base_size = base_sizes[i]
			var new_width = max(100, base_size.x * scale_factor)   # Minimum 100px width
			var new_height = max(100, base_size.y * scale_factor)  # Minimum 100px height
			
			# Update circle size while maintaining center positioning
			var half_width = new_width / 2
			var half_height = new_height / 2
			
			circle.offset_left = -half_width
			circle.offset_right = half_width
			circle.offset_top = -half_height
			circle.offset_bottom = half_height
			
			# Update corner radius for perfect circles
			update_circle_radius(circle, min(half_width, half_height))

func update_circle_radius(circle: Panel, radius: float):
	var style = circle.get_theme_stylebox("panel")
	if style:
		var new_style = style.duplicate()
		new_style.corner_radius_top_left = radius
		new_style.corner_radius_top_right = radius
		new_style.corner_radius_bottom_left = radius
		new_style.corner_radius_bottom_right = radius
		circle.add_theme_stylebox_override("panel", new_style)

func scale_card_container(scale_factor: float):
	# Scale the card container based on your custom minimum size (150x220)
	var card_control = $VBoxContainer/Control
	if card_control:
		var base_width = 150   # Your original custom_minimum_size.x
		var base_height = 220  # Your original custom_minimum_size.y
		
		var new_width = max(100, base_width * scale_factor)   # Minimum 100px
		var new_height = max(140, base_height * scale_factor) # Minimum 140px (maintain card ratio)
		
		card_control.custom_minimum_size = Vector2(new_width, new_height)
	
	# Scale the main VBoxContainer to accommodate the scaled card
	var vbox = $VBoxContainer
	if vbox:
		var base_width = 150   # Your original width
		var base_height = 220  # Your original height
		
		var new_width = max(100, base_width * scale_factor)
		var new_height = max(180, base_height * scale_factor)  # Extra space for labels
		
		var half_width = new_width / 2
		var half_height = new_height / 2
		
		vbox.offset_left = -half_width
		vbox.offset_right = half_width
		vbox.offset_top = -half_height
		vbox.offset_bottom = half_height

func scale_text_elements(scale_factor: float):
	# Scale the card counter text ("36 / 100")
	var counter_label = $VBoxContainer/Label
	if counter_label:
		var base_font_size = 20  # Your original font size
		var new_font_size = max(12, base_font_size * scale_factor)  # Minimum 12px
		counter_label.add_theme_font_size_override("font_size", int(new_font_size))
	
	# Scale the description text ("number cards")
	var description_label = $VBoxContainer/Label2
	if description_label:
		var base_font_size = 20  # Your original font size
		var new_font_size = max(12, base_font_size * scale_factor)  # Minimum 12px
		description_label.add_theme_font_size_override("font_size", int(new_font_size))

# Handle screen size changes in real-time
func _notification(what):
	if what == NOTIFICATION_RESIZED:
		call_deferred("setup_responsive_layout")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
