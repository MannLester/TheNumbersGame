extends Control

# Tab configuration
var tab_buttons: Array[Button] = []
var tab_margin_containers: Array[MarginContainer] = []
var selected_tab_index: int = 2  # Default to Battle tab (middle/index 2)

# Scale configuration
var normal_scale: Vector2 = Vector2(1.0, 1.0)
var selected_scale: Vector2 = Vector2(1.2, 1.2)
var animation_duration: float = 0.25

# Responsive configuration
var base_tab_size: Vector2 = Vector2(144, 120)
var base_icon_size: Vector2 = Vector2(84, 80)  # Average icon size

signal tab_changed(tab_index: int, tab_name: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_tabs()
	setup_responsive_layout()
	# Set Battle tab as default selected
	select_tab(2, false)  # Don't emit signal on initial setup

func setup_tabs():
	var hbox = $MarginContainer/HBoxContainer
	
	# Clear existing arrays
	tab_buttons.clear()
	tab_margin_containers.clear()
	
	# Get all tab components
	for i in range(hbox.get_child_count()):
		var margin_container = hbox.get_child(i)
		var button = margin_container.get_child(0)
		
		# Store references
		tab_margin_containers.append(margin_container)
		tab_buttons.append(button)
		
		# Setup button properties
		button.flat = true
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		
		# Connect button signal
		button.pressed.connect(_on_tab_pressed.bind(i))
		
		# Setup initial scale
		button.scale = normal_scale
		
		# Setup ColorRect for visual feedback
		var color_rect = button.get_child(0)
		if color_rect:
			color_rect.color = Color.TRANSPARENT  # Start transparent
			color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_tab_pressed(tab_index: int):
	if tab_index != selected_tab_index:
		select_tab(tab_index, true)

func select_tab(tab_index: int, should_emit_signal: bool = true):
	if tab_index < 0 or tab_index >= tab_buttons.size():
		return
	
	var previous_index = selected_tab_index
	selected_tab_index = tab_index
	
	# Animate tab changes
	animate_tab_selection(previous_index, selected_tab_index)
	
	# Emit signal if requested
	if should_emit_signal:
		var tab_name = get_tab_name(tab_index)
		tab_changed.emit(tab_index, tab_name)
		print("Tab changed to: ", tab_name, " (index: ", tab_index, ")")

func get_tab_name(tab_index: int) -> String:
	var tab_names = ["Shop", "Cards", "Battle", "Club", "Leaderboard"]
	if tab_index >= 0 and tab_index < tab_names.size():
		return tab_names[tab_index]
	return "Unknown"

func animate_tab_selection(_previous_index: int, new_index: int):
	var tween = create_tween()
	tween.set_parallel(true)  # Allow multiple animations simultaneously
	
	# Animate all tabs
	for i in range(tab_buttons.size()):
		var button = tab_buttons[i]
		var color_rect = button.get_child(0)
		var is_selected = (i == new_index)
		
		if is_selected:
			# Scale up selected tab
			tween.tween_property(button, "scale", selected_scale, animation_duration)
			tween.tween_property(button, "position:y", -10, animation_duration)  # Slight upward movement
			
			# Add subtle background highlight
			if color_rect:
				tween.tween_property(color_rect, "color", Color(1, 1, 1, 0.1), animation_duration)
		else:
			# Scale down unselected tabs
			tween.tween_property(button, "scale", normal_scale, animation_duration)
			tween.tween_property(button, "position:y", 0, animation_duration)
			
			# Remove background highlight
			if color_rect:
				tween.tween_property(color_rect, "color", Color.TRANSPARENT, animation_duration)

func setup_responsive_layout():
	# Connect to screen size changes
	get_viewport().size_changed.connect(_on_screen_size_changed)
	
	# Initial responsive setup
	_on_screen_size_changed()

func _on_screen_size_changed():
	var screen_size = get_viewport().get_visible_rect().size
	var scale_factor = calculate_scale_factor(screen_size)
	
	apply_responsive_scaling(scale_factor)

func calculate_scale_factor(screen_size: Vector2) -> float:
	# Base design resolution (typical mobile portrait)
	var base_width = 720.0
	var base_height = 1280.0
	
	# Calculate scale factor based on screen width primarily
	var width_scale = screen_size.x / base_width
	var height_scale = screen_size.y / base_height
	
	# Use the smaller scale to ensure UI fits on screen
	var scale_factor = min(width_scale, height_scale)
	
	# Clamp to reasonable limits
	scale_factor = clamp(scale_factor, 0.5, 2.0)
	
	return scale_factor

func apply_responsive_scaling(scale_factor: float):
	print("Applying responsive scaling with factor: ", scale_factor)
	
	# Scale overall container height
	var new_height = max(80, base_tab_size.y * scale_factor)
	self.custom_minimum_size = Vector2(0, new_height)
	
	# Scale HBoxContainer
	var hbox = $MarginContainer/HBoxContainer
	if hbox:
		var new_tab_width = max(80, base_tab_size.x * scale_factor)
		hbox.custom_minimum_size = Vector2(new_tab_width, new_height)
	
	# Scale individual tabs
	for i in range(tab_buttons.size()):
		var button = tab_buttons[i]
		var texture_rect = button.get_child(1)  # TextureRect is second child after ColorRect
		
		# Scale button minimum size
		var new_button_size = Vector2(
			max(60, base_tab_size.x * scale_factor),
			max(60, base_tab_size.y * scale_factor)
		)
		button.custom_minimum_size = new_button_size
		
		# Scale icon size within the button
		if texture_rect and texture_rect is TextureRect:
			var new_icon_size = Vector2(
				max(32, base_icon_size.x * scale_factor),
				max(32, base_icon_size.y * scale_factor)
			)
			
			# Update TextureRect offsets to center the scaled icon
			var half_width = new_icon_size.x / 2
			var half_height = new_icon_size.y / 2
			
			texture_rect.offset_left = -half_width
			texture_rect.offset_right = half_width
			texture_rect.offset_top = -half_height
			texture_rect.offset_bottom = half_height
	
	# Update scale values for responsive design
	var base_selected_scale = 1.2
	selected_scale = Vector2(
		base_selected_scale * scale_factor,
		base_selected_scale * scale_factor
	)
	
	# Ensure selected tab maintains its scaled appearance
	if selected_tab_index >= 0 and selected_tab_index < tab_buttons.size():
		tab_buttons[selected_tab_index].scale = selected_scale

# Public methods for external control
func get_selected_tab_index() -> int:
	return selected_tab_index

func get_selected_tab_name() -> String:
	return get_tab_name(selected_tab_index)

# Handle screen orientation changes
func _notification(what):
	if what == NOTIFICATION_RESIZED:
		# Small delay to ensure viewport size is updated
		await get_tree().process_frame
		_on_screen_size_changed()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
