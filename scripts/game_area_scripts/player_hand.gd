extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect draw button signal
	var draw_button = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/TextureButton
	if draw_button:
		draw_button.pressed.connect(_on_draw_button_pressed)
	
	# Make player hand responsive while maintaining design
	setup_responsive_layout()

func setup_responsive_layout():
	var screen_size = get_viewport().get_visible_rect().size
	var scale_factor = min(screen_size.x / 720.0, screen_size.y / 1280.0)
	
	# Scale hand height based on your custom minimum size (300px)
	scale_hand_dimensions(scale_factor)
	
	# Scale margins proportionally
	scale_margins(scale_factor)
	
	# Scale top section elements (labels, buttons, icons)
	scale_top_section(scale_factor)
	
	# Scale card container and cards
	scale_card_section(scale_factor)
	
	# Scale spacing between elements
	scale_spacing(scale_factor)

func scale_hand_dimensions(scale_factor: float):
	# Scale the hand height based on your custom minimum size (300px)
	var base_height = 300  # Your original custom_minimum_size
	var new_height = max(200, base_height * scale_factor)  # Minimum 200px for usability
	self.custom_minimum_size = Vector2(0, new_height)

func scale_margins(scale_factor: float):
	# Scale main margins based on your original values (50px left/right)
	var main_margin = $MarginContainer
	if main_margin:
		var base_margin = 50  # Your original left/right margins
		var new_margin = max(20, base_margin * scale_factor)  # Minimum 20px
		
		main_margin.add_theme_constant_override("margin_left", int(new_margin))
		main_margin.add_theme_constant_override("margin_right", int(new_margin))
	
	# Scale internal margins
	var top_margin = $MarginContainer/VBoxContainer/MarginContainer
	if top_margin:
		var base_internal = 10  # Your original internal margins
		var new_internal = max(5, base_internal * scale_factor)  # Minimum 5px
		
		top_margin.add_theme_constant_override("margin_left", int(new_internal))
		top_margin.add_theme_constant_override("margin_right", int(new_internal))

func scale_top_section(scale_factor: float):
	# Scale the HBoxContainer separation (your original 230px)
	var top_hbox = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer
	if top_hbox:
		var base_separation = 230  # Your original separation
		var new_separation = max(100, base_separation * scale_factor)  # Minimum 100px
		top_hbox.add_theme_constant_override("separation", int(new_separation))
	
	# Scale operator and card count labels
	var operator_label = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/Control/Panel/MarginContainer/Label
	var cards_label = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/Control2/Panel/MarginContainer/Label
	
	var labels = [operator_label, cards_label]
	for label in labels:
		if label:
			var base_font_size = 16  # Default Poppins Regular size
			var new_font_size = max(12, base_font_size * scale_factor)  # Minimum 12px
			label.add_theme_font_size_override("font_size", int(new_font_size))
	
	# Scale card counter number (the "8" in the counter icon)
	var counter_label = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/Control2/TextureRect/Label
	if counter_label:
		var base_font_size = 20  # Your original font size
		var new_font_size = max(14, base_font_size * scale_factor)  # Minimum 14px
		counter_label.add_theme_font_size_override("font_size", int(new_font_size))
	
	# Scale icons (operator icon and counter icon)
	scale_icons(scale_factor)
	
	# Scale draw button
	scale_draw_button(scale_factor)

func scale_icons(scale_factor: float):
	# Scale operator icon (Add Icon)
	var operator_icon = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/Control/TextureRect
	if operator_icon and operator_icon.texture:
		var original_size = operator_icon.texture.get_size()
		var new_width = max(24, original_size.x * scale_factor)   # Minimum 24px
		var new_height = max(24, original_size.y * scale_factor)  # Minimum 24px
		operator_icon.custom_minimum_size = Vector2(new_width, new_height)
	
	# Scale counter icon
	var counter_icon = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/Control2/TextureRect
	if counter_icon and counter_icon.texture:
		var original_size = counter_icon.texture.get_size()
		var new_width = max(32, original_size.x * scale_factor)   # Minimum 32px
		var new_height = max(32, original_size.y * scale_factor)  # Minimum 32px
		counter_icon.custom_minimum_size = Vector2(new_width, new_height)

func scale_draw_button(scale_factor: float):
	# Scale draw button while maintaining aspect ratio
	var draw_button = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/TextureButton
	if draw_button and draw_button.texture_normal:
		var original_size = draw_button.texture_normal.get_size()
		var new_width = max(60, original_size.x * scale_factor)   # Minimum 60px
		var new_height = max(40, original_size.y * scale_factor)  # Minimum 40px
		draw_button.custom_minimum_size = Vector2(new_width, new_height)

func scale_card_section(scale_factor: float):
	# Scale card container height based on your custom minimum size (150px)
	var scroll_container = $MarginContainer/VBoxContainer/MarginContainer2/ScrollContainer
	if scroll_container:
		var base_height = 150  # Your original custom_minimum_size
		var new_height = max(100, base_height * scale_factor)  # Minimum 100px
		scroll_container.custom_minimum_size = Vector2(0, new_height)
	
	# Scale card HBoxContainer minimum size and separation
	var cards_hbox = $MarginContainer/VBoxContainer/MarginContainer2/ScrollContainer/MarginContainer/HBoxContainer
	if cards_hbox:
		# Scale the minimum size for cards container
		var base_width = 100   # Your original custom_minimum_size.x
		var base_height = 140  # Your original custom_minimum_size.y
		
		var new_width = max(80, base_width * scale_factor)   # Minimum 80px
		var new_height = max(100, base_height * scale_factor) # Minimum 100px
		cards_hbox.custom_minimum_size = Vector2(new_width, new_height)
		
		# Scale separation between cards (your original 10px)
		var base_separation = 10
		var new_separation = max(5, base_separation * scale_factor)  # Minimum 5px
		cards_hbox.add_theme_constant_override("separation", int(new_separation))

func scale_spacing(scale_factor: float):
	# Scale VBoxContainer separation (your original 10px)
	var main_vbox = $MarginContainer/VBoxContainer
	if main_vbox:
		var base_separation = 10  # Your original separation
		var new_separation = max(5, base_separation * scale_factor)  # Minimum 5px
		main_vbox.add_theme_constant_override("separation", int(new_separation))

func _on_draw_button_pressed():
	print("Draw button pressed")
	# TODO: Implement card drawing logic
	# This could involve:
	# - Drawing a card from the pile
	# - Adding it to the player's hand
	# - Updating the card counter
	# - Triggering any draw animations

# Handle screen size changes in real-time
func _notification(what):
	if what == NOTIFICATION_RESIZED:
		call_deferred("setup_responsive_layout")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
