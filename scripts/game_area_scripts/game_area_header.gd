extends Control

func _ready() -> void:
	# Connect button signals
	var exit_button = $MarginHeader/HeaderContainer/ExitButton
	var info_button = $MarginHeader/HeaderContainer/InfoButton
	
	if exit_button:
		exit_button.pressed.connect(_on_exit_button_pressed)
	if info_button:
		info_button.pressed.connect(_on_info_button_pressed)
	
	# Make header responsive while maintaining design
	setup_responsive_layout()

func setup_responsive_layout():
	var screen_size = get_viewport().get_visible_rect().size
	var scale_factor = min(screen_size.x / 720.0, screen_size.y / 1280.0)
	
	# Scale header height while respecting your custom minimum size
	scale_header_dimensions(scale_factor)
	
	# Scale margins proportionally
	scale_margins(scale_factor)
	
	# Scale button sizes while maintaining aspect ratio
	scale_buttons(scale_factor)
	
	# Scale timer elements (font, icon, spacing)
	scale_timer_elements(scale_factor)
	
	# Scale container separation
	scale_container_spacing(scale_factor)

func scale_header_dimensions(scale_factor: float):
	# Scale the header height based on your custom minimum size (120px)
	var base_height = 120  # Your original custom_minimum_size
	var new_height = max(80, base_height * scale_factor)  # Minimum 80px for usability
	self.custom_minimum_size = Vector2(0, new_height)

func scale_margins(scale_factor: float):
	# Scale margins based on your original values (50px left/right, 15px top/bottom)
	var margin_container = $MarginHeader
	if margin_container:
		var base_margin_x = 50  # Your original left/right margins
		var base_margin_y = 15  # Your original top/bottom margins
		
		var new_margin_x = max(20, base_margin_x * scale_factor)  # Minimum 20px
		var new_margin_y = max(8, base_margin_y * scale_factor)   # Minimum 8px
		
		margin_container.add_theme_constant_override("margin_left", int(new_margin_x))
		margin_container.add_theme_constant_override("margin_right", int(new_margin_x))
		margin_container.add_theme_constant_override("margin_top", int(new_margin_y))
		margin_container.add_theme_constant_override("margin_bottom", int(new_margin_y))

func scale_buttons(scale_factor: float):
	# Scale texture buttons while maintaining aspect ratio
	var exit_button = $MarginHeader/HeaderContainer/ExitButton
	var info_button = $MarginHeader/HeaderContainer/InfoButton
	
	var buttons = [exit_button, info_button]
	
	for button in buttons:
		if button and button.texture_normal:
			var original_size = button.texture_normal.get_size()
			var new_width = max(40, original_size.x * scale_factor)   # Minimum 40px width
			var new_height = max(40, original_size.y * scale_factor)  # Minimum 40px height
			button.custom_minimum_size = Vector2(new_width, new_height)

func scale_timer_elements(scale_factor: float):
	# Scale timer font size based on your original 48px
	var timer_label = $MarginHeader/HeaderContainer/TimerContainer/TimerControl/TimerLabel
	if timer_label:
		var base_font_size = 48  # Your original font size
		var new_font_size = max(24, base_font_size * scale_factor)  # Minimum 24px
		timer_label.add_theme_font_size_override("font_size", int(new_font_size))
	
	# Scale timer icon while maintaining aspect ratio
	var timer_icon = $MarginHeader/HeaderContainer/TimerContainer/TimerControl/TimerIcon
	if timer_icon and timer_icon.texture:
		var original_size = timer_icon.texture.get_size()
		var new_width = max(32, original_size.x * scale_factor)   # Minimum 32px
		var new_height = max(32, original_size.y * scale_factor)  # Minimum 32px
		
		# Update icon size and position
		var half_height = new_height / 2
		timer_icon.offset_left = 13 * scale_factor
		timer_icon.offset_right = timer_icon.offset_left + new_width
		timer_icon.offset_top = -half_height
		timer_icon.offset_bottom = half_height
	
	# Scale timer container to accommodate scaled elements
	var timer_container = $MarginHeader/HeaderContainer/TimerContainer
	if timer_container:
		var base_width = 150  # Approximate original timer container width
		var new_width = max(100, base_width * scale_factor)
		timer_container.custom_minimum_size = Vector2(new_width, 0)

func scale_container_spacing(scale_factor: float):
	# Scale the separation between header elements based on your 75px setting
	var header_container = $MarginHeader/HeaderContainer
	if header_container:
		var base_separation = 75  # Your original separation
		var new_separation = max(30, base_separation * scale_factor)  # Minimum 30px
		header_container.add_theme_constant_override("separation", int(new_separation))

func _on_exit_button_pressed():
	print("Exit button pressed")
	# TODO: Show exit confirmation dialog or return to main menu
	get_tree().change_scene_to_file("res://scenes/authentication_page/authentication_page.tscn")

func _on_info_button_pressed():
	print("Info button pressed")
	# TODO: Show game info/rules dialog

# Handle screen size changes in real-time
func _notification(what):
	if what == NOTIFICATION_RESIZED:
		call_deferred("setup_responsive_layout")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
