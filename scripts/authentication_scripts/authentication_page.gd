extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect button signals
	var local_button = $Control2/CenterContainer/VBoxContainer/TextureButton
	var online_button = $Control2/CenterContainer/VBoxContainer/TextureButton2
	
	if local_button:
		local_button.pressed.connect(_on_local_button_pressed)
	if online_button:
		online_button.pressed.connect(_on_online_button_pressed)
	
	# Make layout responsive while maintaining design
	setup_responsive_layout()

func setup_responsive_layout():
	var screen_size = get_viewport().get_visible_rect().size
	var scale_factor = min(screen_size.x / 720.0, screen_size.y / 1280.0)
	
	# Scale background circles while maintaining layered effect
	scale_background_circles(scale_factor)
	
	# Scale decorative math symbols
	scale_math_symbols(scale_factor, screen_size)
	
	# Scale main title fonts
	scale_title_fonts(scale_factor)
	
	# Scale game letters
	scale_game_letters(scale_factor)
	
	# Scale buttons while maintaining aspect ratio
	scale_buttons(scale_factor)
	
	# Scale copyright text
	scale_copyright(scale_factor)

func scale_background_circles(scale_factor: float):
	# Green circles (top-left area) - maintain layered effect
	var green_circles = [$GreenCircle1, $GreenCircle2, $GreenCircle3]
	var green_base_sizes = [203, 322, 419] # Original sizes from your design
	
	for i in range(green_circles.size()):
		var circle = green_circles[i]
		if circle:
			var new_size = max(100, green_base_sizes[i] * scale_factor)
			var radius = new_size / 2.0
			
			# Update size while maintaining position relationships
			circle.offset_right = circle.offset_left + new_size
			circle.offset_bottom = circle.offset_top + new_size
			
			# Update corner radius for perfect circles
			update_circle_radius(circle, radius)
	
	# Yellow circles (right-center area) - maintain layered effect
	var yellow_circles = [$YellowCircle1, $YellowCircle2, $YellowCircle3]
	var yellow_base_sizes = [179, 271, 349] # Original sizes from your design
	
	for i in range(yellow_circles.size()):
		var circle = yellow_circles[i]
		if circle:
			var new_size = max(80, yellow_base_sizes[i] * scale_factor)
			var radius = new_size / 2.0
			
			# Update size while maintaining anchor relationships
			var half_size = new_size / 2.0
			circle.offset_left = -half_size - (20 * scale_factor)
			circle.offset_right = half_size - (20 * scale_factor)
			circle.offset_top = -half_size
			circle.offset_bottom = half_size
			
			update_circle_radius(circle, radius)
	
	# Red circles (bottom-left area) - maintain layered effect
	var red_circles = [$RedCircle1, $RedCircle2, $RedCircle3]
	var red_base_sizes = [169, 259, 352] # Original sizes from your design
	
	for i in range(red_circles.size()):
		var circle = red_circles[i]
		if circle:
			var new_size = max(80, red_base_sizes[i] * scale_factor)
			var radius = new_size / 2.0
			
			# Update size while maintaining anchor relationships
			var half_size = new_size / 2.0
			circle.offset_left = -half_size - (30 * scale_factor)
			circle.offset_right = half_size + (30 * scale_factor)
			circle.offset_top = -half_size - (20 * scale_factor)
			circle.offset_bottom = half_size + (20 * scale_factor)
			
			update_circle_radius(circle, radius)

func update_circle_radius(circle: Panel, radius: float):
	var style = circle.get_theme_stylebox("panel")
	if style:
		var new_style = style.duplicate()
		new_style.corner_radius_top_left = radius
		new_style.corner_radius_top_right = radius
		new_style.corner_radius_bottom_left = radius
		new_style.corner_radius_bottom_right = radius
		circle.add_theme_stylebox_override("panel", new_style)

func scale_math_symbols(scale_factor: float, _screen_size: Vector2):
	# Scale decorative math symbols while maintaining positions
	var symbols = [$Label, $Label2, $Label3, $Label4] # /, -, x, +
	var base_font_sizes = [380, 180, 100, 320] # Your original font sizes
	
	for i in range(symbols.size()):
		var symbol = symbols[i]
		if symbol:
			var new_size = max(50, base_font_sizes[i] * scale_factor)
			symbol.add_theme_font_size_override("font_size", int(new_size))

func scale_title_fonts(scale_factor: float):
	# Scale "The" text
	var the_label = $Control/MarginContainer/VBoxContainer/Label
	if the_label:
		var base_size = 80
		var new_size = max(40, base_size * scale_factor)
		the_label.add_theme_font_size_override("font_size", int(new_size))
	
	# Scale "NUMBERS" - each letter individually
	var numbers_container = $Control/MarginContainer/VBoxContainer/HBoxContainer
	if numbers_container:
		var base_size = 140
		var new_size = max(80, base_size * scale_factor)
		
		for child in numbers_container.get_children():
			if child is Label:
				child.add_theme_font_size_override("font_size", int(new_size))

func scale_game_letters(scale_factor: float):
	# Scale "GAME" letters
	var game_container = $Control/MarginContainer/VBoxContainer/CenterContainer/HBoxContainer
	if game_container:
		var base_size = 40
		var new_size = max(24, base_size * scale_factor)
		
		for child in game_container.get_children():
			if child is Label:
				child.add_theme_font_size_override("font_size", int(new_size))

func scale_buttons(scale_factor: float):
	# Scale texture buttons while maintaining aspect ratio
	var buttons = [
		$Control2/CenterContainer/VBoxContainer/TextureButton,
		$Control2/CenterContainer/VBoxContainer/TextureButton2
	]
	
	for button in buttons:
		if button and button.texture_normal:
			var original_size = button.texture_normal.get_size()
			var new_width = max(150, original_size.x * scale_factor)
			var new_height = max(50, original_size.y * scale_factor)
			button.custom_minimum_size = Vector2(new_width, new_height)

func scale_copyright(scale_factor: float):
	# Scale copyright text
	var copyright = $CenterContainer/Label5
	if copyright:
		var base_size = 16  # Default Poppins size
		var new_size = max(12, base_size * scale_factor)
		copyright.add_theme_font_size_override("font_size", int(new_size))

func _on_local_button_pressed():
	print("Local game selected")
	# TODO: Navigate to local game setup
	get_tree().change_scene_to_file("res://scenes/game_area_page/game_area_page.tscn")

func _on_online_button_pressed():
	print("Online game selected")
	# TODO: Navigate to online game setup
	get_tree().change_scene_to_file("res://scenes/game_area_page/game_area_page.tscn")

# Handle screen size changes in real-time
func _notification(what):
	if what == NOTIFICATION_RESIZED:
		call_deferred("setup_responsive_layout")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
