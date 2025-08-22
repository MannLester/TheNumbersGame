extends Control

# Base card dimensions for 720x1280 resolution
const BASE_WIDTH = 720.0
const BASE_HEIGHT = 1280.0
const BASE_CARD_WIDTH = 100.0
const BASE_CARD_HEIGHT = 140.0

# Minimum constraints
const MIN_CARD_WIDTH = 60.0
const MIN_CARD_HEIGHT = 84.0

# Card data
var card_id: String = ""
var card_number: int = 0
var card_operator: String = ""
var card_texture_path: String = ""

var dragging := false
var drag_offset := Vector2.ZERO
var original_parent = null
var original_position := Vector2.ZERO
var original_index := -1  # Track original position in parent container
var original_sibling_before = null  # Track the card that was before this one
var original_sibling_after = null   # Track the card that was after this one
var is_in_pile := false  # Track if card is in pile and should be immovable

# Signals for the player hand to listen to
signal drag_started(card)
signal drag_ended(card)

func _ready() -> void:
	# Connect to screen size changes for responsive updates
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# Setup initial responsive card
	setup_responsive_card()
	
	mouse_filter = MOUSE_FILTER_STOP
	
	# Note: gui_input signal is already connected in the scene file  

func _on_gui_input(event: InputEvent) -> void:
	# Don't process input if card is in pile
	if is_in_pile:
		print("Card ", card_id, " is in pile - ignoring input")
		return
		
	# Handle both touch and mouse input for testing
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_drag(event.global_position)
			else:
				end_drag()
	elif event is InputEventMouseMotion and dragging:
		update_drag_position(event.global_position)
	# Keep original touch handling for mobile
	elif event is InputEventScreenTouch and event.is_pressed():
		start_drag(event.global_position)
	elif event is InputEventScreenTouch and not event.is_pressed():
		end_drag()
	elif event is InputEventScreenDrag and dragging:
		update_drag_position(event.global_position)

func start_drag(mouse_pos: Vector2):
	# Don't allow dragging if card is in pile
	if is_in_pile:
		print("Card ", card_id, " is in pile - cannot be dragged")
		return
		
	dragging = true
	drag_offset = mouse_pos - global_position
	
	# Make sure we save the immediate parent (the cards container)
	original_parent = get_parent()
	original_position = position
	
	# Store the original index position in the parent container
	if original_parent:
		original_index = get_index()
		
		# Store sibling references for more reliable positioning
		var current_index = get_index()
		if current_index > 0:
			original_sibling_before = original_parent.get_child(current_index - 1)
		else:
			original_sibling_before = null
			
		if current_index < original_parent.get_child_count() - 1:
			original_sibling_after = original_parent.get_child(current_index + 1)
		else:
			original_sibling_after = null
	
	print("Starting drag - Immediate parent: ", original_parent.name if original_parent else "none")
	print("Starting drag - Parent path: ", original_parent.get_path() if original_parent else "none")
	print("Starting drag - Original position: ", original_position)
	print("Starting drag - Original index: ", original_index)
	print("Starting drag - Sibling before: ", original_sibling_before.get_card_id() if original_sibling_before and original_sibling_before.has_method("get_card_id") else "none")
	print("Starting drag - Sibling after: ", original_sibling_after.get_card_id() if original_sibling_after and original_sibling_after.has_method("get_card_id") else "none")
	
	# Move to top level for proper rendering
	reparent(get_tree().current_scene)
	z_index = 1000
	
	# Emit signal for player hand to handle
	drag_started.emit(self)
	
	print("Card started dragging: ", name)
	
	var tex = $TextureRect.texture
	if tex:
		print("Texture path: ", tex.resource_path)

func update_drag_position(mouse_pos: Vector2):
	if dragging:
		global_position = mouse_pos - drag_offset

func end_drag():
	if dragging:
		dragging = false
		print("Card ended dragging: ", name)
		print("About to emit drag_ended signal")
		
		# Emit signal for player hand to handle drop logic
		drag_ended.emit(self)
		print("drag_ended signal emitted")

func return_to_original_position():
	print("=== RETURNING CARD TO HAND ===")
	print("Card ID: ", card_id)
	if get_parent():
		print("Current parent: ", get_parent().name)
	else:
		print("Current parent: null")
	if original_parent:
		print("Original parent: ", original_parent.name)
	else:
		print("Original parent: null")
	print("Original position: ", original_position)
	
	# Method 1: Try to find player hand by group
	var player_hand = get_tree().get_first_node_in_group("player_hand")
	if player_hand:
		print("Found player hand by group: ", player_hand.name)
	else:
		print("Found player hand by group: null")
	
	# Method 2: Try to find by scene tree search if group failed
	if not player_hand:
		var scene_root = get_tree().current_scene
		player_hand = scene_root.get_node_or_null("Player Hand")
		if player_hand:
			print("Found player hand by scene search: ", player_hand.name)
		else:
			print("Found player hand by scene search: null")
	
	# Method 3: Try to find by searching for any node with "Hand" in the name
	if not player_hand:
		var scene_root = get_tree().current_scene
		for child in scene_root.get_children():
			if "Hand" in child.name and "Player" in child.name:
				player_hand = child
				print("Found player hand by name search: ", player_hand.name)
				break
	
	if player_hand:
		var cards_container = player_hand.get_node_or_null("MarginContainer/VBoxContainer/MarginContainer2/ScrollContainer/MarginContainer/HBoxContainer")
		if cards_container:
			print("Cards container found: ", cards_container.get_path())
			print("Current children count: ", cards_container.get_child_count())
			print("Original index to restore: ", original_index)
		else:
			print("Cards container not found")
		
		if cards_container:
			print("SUCCESS: Returning card to player hand cards container")
			
			# Remove from current parent first
			if get_parent():
				get_parent().remove_child(self)
			
			# Add to cards container at the original index position
			cards_container.add_child(self)
			print("=== CARD POSITIONING DEBUG ===")
			print("Added card as child, container now has: ", cards_container.get_child_count(), " children")
			print("Card is currently at index: ", get_index())
			print("Original index was: ", original_index)
			print("Sibling before valid: ", original_sibling_before != null and is_instance_valid(original_sibling_before))
			print("Sibling after valid: ", original_sibling_after != null and is_instance_valid(original_sibling_after))
			
			# List current children for debugging
			print("Current children in container:")
			for i in range(cards_container.get_child_count()):
				var child = cards_container.get_child(i)
				if child.has_method("get_card_id"):
					print("  Index ", i, ": ", child.get_card_id())
				else:
					print("  Index ", i, ": ", child.name)
			
			# Try to restore to original index
			var target_index = -1
			
			# Method 1: Use original index if valid
			if original_index >= 0 and original_index < cards_container.get_child_count():
				target_index = original_index
				print("Method 1: Using original index ", target_index)
			else:
				print("Method 1: Original index ", original_index, " is invalid (0 to ", cards_container.get_child_count()-1, ")")
				
				# Method 2: Try to position relative to siblings
				if original_sibling_before and is_instance_valid(original_sibling_before):
					# Find the sibling in the current container
					for i in range(cards_container.get_child_count()):
						if cards_container.get_child(i) == original_sibling_before:
							target_index = i + 1
							print("Method 2: Found sibling before at index ", i, ", positioning after at ", target_index)
							break
					if target_index == -1:
						print("Method 2: Sibling before not found in container")
				
				# Method 3: Try sibling after
				if target_index == -1 and original_sibling_after and is_instance_valid(original_sibling_after):
					for i in range(cards_container.get_child_count()):
						if cards_container.get_child(i) == original_sibling_after:
							target_index = i
							print("Method 3: Found sibling after at index ", i, ", positioning before at ", target_index)
							break
					if target_index == -1:
						print("Method 3: Sibling after not found in container")
			
			# Move to target index if valid
			if target_index >= 0 and target_index < cards_container.get_child_count():
				print("Moving card from index ", get_index(), " to target index: ", target_index)
				cards_container.move_child(self, target_index)
				print("Card successfully moved to index: ", get_index())
			else:
				print("No valid target index found (", target_index, "), card stays at end (index ", get_index(), ")")
			
			print("=== END POSITIONING DEBUG ===")
			
			# Reset transform properties
			position = Vector2.ZERO
			rotation = 0.0
			scale = Vector2.ONE
			z_index = 0
			
			print("Card ", card_id, " successfully returned to player hand")
			
			# Update the player hand counter
			if player_hand.has_method("update_card_counter"):
				player_hand.update_card_counter()
				print("Updated player hand counter after card return")
		else:
			print("ERROR: Could not find cards container in player hand!")
			use_fallback_return()
	else:
		print("ERROR: Could not find player hand at all!")
		use_fallback_return()
	
	print("=== RETURN COMPLETE ===")

func use_fallback_return():
	print("Using fallback return method...")
	# Fallback: try the original parent if everything else fails
	if original_parent and is_instance_valid(original_parent):
		print("Using original parent fallback: ", original_parent.name)
		
		# Remove from current parent first
		if get_parent():
			get_parent().remove_child(self)
		
		# Return to original parent at original index if possible
		if original_index >= 0 and original_index < original_parent.get_child_count():
			original_parent.add_child(self)
			original_parent.move_child(self, original_index)
			print("Restored to original parent at index: ", original_index)
		else:
			original_parent.add_child(self)
			print("Restored to original parent at end (index was invalid)")
		
		position = original_position
		rotation = 0.0
		scale = Vector2.ONE
		z_index = 0
		print("Returned to original parent")
	else:
		print("ERROR: Original parent is invalid or null")
		# Ultimate fallback: move to scene root and reset position
		var scene_root = get_tree().current_scene
		if get_parent() != scene_root:
			reparent(scene_root)
		position = Vector2(100, 100)  # Just put it somewhere visible
		rotation = 0.0
		scale = Vector2.ONE
		z_index = 0

func get_card_id() -> String:
	return card_id

func get_card_data() -> Dictionary:
	return {
		"card_id": card_id,
		"card_number": card_number,
		"card_operator": card_operator,
		"card_type": CardManager.get_card_type(card_id) if CardManager else -1
	}

func mark_as_pile_card():
	# Mark this card as being in the pile and make it immovable
	is_in_pile = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(false)
	set_process_unhandled_input(false)
	print("Card ", card_id, " marked as pile card - now immovable")

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

func setup_card(new_card_id: String, design_type: String = "blue"):
	# Setup card with specific ID and dynamic design
	card_id = new_card_id
	
	# Safety check for CardManager
	if not CardManager:
		print("Error: CardManager not found!")
		return
	
	# Get the correct asset path for the design using CardManager
	var background_path = CardManager.get_design_asset_path(design_type)
	var texture = load(background_path) as Texture2D
	if texture:
		$TextureRect.texture = texture
		print("Card ", card_id, " setup with design: ", design_type, " (theme: ", CardManager.get_current_theme(), ")")
	else:
		print("Warning: Could not load background design: ", background_path)
		# Fallback to classic design
		var fallback_path = "res://assets/cards/card_designs/classic_design/card_" + design_type + "_bg.png"
		var fallback_texture = load(fallback_path) as Texture2D
		if fallback_texture:
			$TextureRect.texture = fallback_texture
			print("Using fallback design: ", fallback_path)
		else:
			print("Error: Fallback design also failed: ", fallback_path)
			return
	
	# Determine card type and set appropriate text
	var card_type = CardManager.get_card_type(card_id)
	var label = $CardLabel
	
	if card_type == CardManager.CardType.NUMBER:
		card_number = CardManager.get_card_value(card_id)
		card_operator = ""
		name = "Card" + str(card_number)
		
		# Set number text
		label.text = str(card_number)
		
		# Adjust font size based on number of digits
		var font_size = 52
		if card_number >= 100:
			font_size = 42
		elif card_number >= 10:
			font_size = 48
		
		label.label_settings.font_size = font_size
		
	else:
		card_number = 0
		card_operator = CardManager.get_card_value(card_id)
		name = "Card" + card_operator
		
		# Set operator text with proper symbols
		var display_text = card_operator
		if card_operator == "±":
			display_text = "+/-"
		
		label.text = display_text
		
		# Operators use slightly smaller font
		label.label_settings.font_size = 45
	
	# Update neon color based on design type
	print("=== CARD SETUP DEBUG ===")
	print("Card ID: ", card_id)
	print("Design type: ", design_type)
	print("=========================")
	update_neon_effect(design_type)
	
	print("Card ", card_id, " neon effect applied for design: ", design_type)

func update_neon_effect(design_type: String):
	var label = $CardLabel
	if not label:
		return
	
	# Get current theme for enhanced neon effects
	var current_theme = CardManager.get_current_theme() if CardManager else "classic"
	
	# Base colors for different design types
	var neon_colors = get_neon_colors_for_design(design_type, current_theme)
	
	# Create a new LabelSettings resource to avoid modifying shared resources
	var new_label_settings = LabelSettings.new()
	
	# Copy font settings from the original
	if label.label_settings:
		new_label_settings.font = label.label_settings.font
		new_label_settings.font_size = label.label_settings.font_size
	else:
		# Fallback font settings
		var poppins_black = load("res://assets/fonts/poppins/Poppins-Black.ttf")
		new_label_settings.font = poppins_black
		new_label_settings.font_size = 52
	
	# Apply neon colors
	new_label_settings.font_color = neon_colors["font_color"]
	new_label_settings.outline_color = neon_colors["outline"]
	new_label_settings.shadow_color = neon_colors["shadow"]
	
	# Set shadow offset
	new_label_settings.shadow_offset = Vector2(0, 0)
	
	# Adjust intensity based on theme - 100% neon effect
	match current_theme:
		"neon":
			# Extra bright neon effect
			new_label_settings.outline_size = 4
			new_label_settings.shadow_size = 12
		"royal":
			# Golden glow effect
			new_label_settings.outline_size = 3
			new_label_settings.shadow_size = 10
		"seasonal_winter":
			# Icy glow effect
			new_label_settings.outline_size = 2
			new_label_settings.shadow_size = 6
		_: # classic - 100% neon effect
			# Maximum neon effect
			new_label_settings.outline_size = 4
			new_label_settings.shadow_size = 12
	
	# Apply the new label settings
	label.label_settings = new_label_settings
	
	print("=== APPLIED COLORS ===")
	print("Font color: ", new_label_settings.font_color)
	print("Outline color: ", new_label_settings.outline_color)
	print("Shadow color: ", new_label_settings.shadow_color)
	print("Outline size: ", new_label_settings.outline_size)
	print("======================")

func get_neon_colors_for_design(design_type: String, theme_name: String) -> Dictionary:
	# Return appropriate neon colors based on design and theme
	var colors = {}
	
	# Determine base color family from design type
	var color_family = get_color_family_from_design(design_type)
	
	print("=== NEON COLOR DEBUG ===")
	print("Design type: ", design_type)
	print("Color family: ", color_family)
	print("Current theme: ", theme_name)
	print("========================")
	print("========================")
	
	match theme_name:
		"neon":
			colors = get_enhanced_neon_colors(color_family)
		"royal":
			colors = get_royal_glow_colors(color_family)
		"seasonal_winter":
			colors = get_winter_glow_colors(color_family)
		_: # classic
			colors = get_classic_neon_colors(color_family)
	
	return colors

func get_color_family_from_design(design_type: String) -> String:
	# Extract color family from design name
	var design_lower = design_type.to_lower()
	
	print("=== COLOR FAMILY DEBUG ===")
	print("Input design_type: ", design_type)
	print("Lowercase: ", design_lower)
	
	if "yellow" in design_lower or "gold" in design_lower:
		print("Detected: YELLOW")
		return "yellow"
	elif "green" in design_lower or "silver" in design_lower:
		print("Detected: GREEN")
		return "green"
	elif "red" in design_lower or "bronze" in design_lower:
		print("Detected: RED")
		return "red"
	elif "blue" in design_lower or "platinum" in design_lower or "cyan" in design_lower:
		print("Detected: BLUE")
		return "blue"
	elif "white" in design_lower or "ice" in design_lower:
		print("Detected: WHITE")
		return "white"
	elif "purple" in design_lower:
		print("Detected: PURPLE")
		return "purple"
	else:
		# Fallback: check exact matches for basic colors
		match design_type:
			"yellow":
				print("Exact match: YELLOW")
				return "yellow"
			"green":
				print("Exact match: GREEN")
				return "green"
			"red":
				print("Exact match: RED")
				return "red"
			"blue":
				print("Exact match: BLUE")
				return "blue"
			_:
				print("Warning: Unknown design type '", design_type, "', defaulting to blue")
				print("=========================")
				return "blue"

func get_classic_neon_colors(color_family: String) -> Dictionary:
	match color_family:
		"yellow":
			return {
				"font_color": Color(1, 0.95, 0.85, 1),       # White with yellow hint
				"outline": Color(1, 0.788, 0.2, 1),          # #ffc933 border
				"shadow": Color(1, 0.788, 0.2, 0.6)          # Subtle yellow shadow
			}
		"green":
			return {
				"font_color": Color(0.9, 1, 0.95, 1),        # White with green hint
				"outline": Color(0.216, 0.49, 0.451, 1),     # #377d73 border
				"shadow": Color(0.216, 0.49, 0.451, 0.6)     # Subtle green shadow
			}
		"red":
			return {
				"font_color": Color(1, 0.92, 0.9, 1),        # White with red hint
				"outline": Color(0.545, 0.267, 0.243, 1),    # #8b443e border
				"shadow": Color(0.545, 0.267, 0.243, 0.6)    # Subtle red shadow
			}
		"blue":
			return {
				"font_color": Color(0.9, 0.96, 1, 1),        # White with blue hint
				"outline": Color(0.447, 0.671, 0.741, 1),    # #72abbd border
				"shadow": Color(0.447, 0.671, 0.741, 0.6)    # Subtle blue shadow
			}
		_:
			return {
				"font_color": Color(1, 1, 1, 1),             # Pure white
				"outline": Color(0.8, 0.8, 0.8, 1),          # Light gray border
				"shadow": Color(0.8, 0.8, 0.8, 0.6)          # Subtle gray shadow
			}

func get_enhanced_neon_colors(color_family: String) -> Dictionary:
	# More intense neon colors for neon theme - still using the new white+hint approach
	match color_family:
		"yellow":
			return {
				"font_color": Color(1, 0.98, 0.9, 1),       # Brighter white with yellow hint
				"outline": Color(1, 1, 0, 1),               # Pure yellow border
				"shadow": Color(1, 1, 0, 0.8)               # Intense yellow glow
			}
		"green":
			return {
				"font_color": Color(0.95, 1, 0.98, 1),      # Brighter white with green hint
				"outline": Color(0, 1, 0, 1),               # Pure green border
				"shadow": Color(0, 1, 0, 0.8)               # Intense green glow
			}
		"red":
			return {
				"font_color": Color(1, 0.95, 0.95, 1),      # Brighter white with red hint
				"outline": Color(1, 0, 0.5, 1),             # Hot pink border
				"shadow": Color(1, 0, 0.5, 0.8)             # Intense pink glow
			}
		"blue":
			return {
				"font_color": Color(0.95, 0.98, 1, 1),      # Brighter white with blue hint
				"outline": Color(0, 1, 1, 1),               # Pure cyan border
				"shadow": Color(0, 1, 1, 0.8)               # Intense cyan glow
			}
		_:
			return get_classic_neon_colors(color_family)

func get_royal_glow_colors(color_family: String) -> Dictionary:
	# Golden/premium glow colors
	match color_family:
		"yellow":
			return {
				"font_color": Color(1, 0.84, 0, 1),     # Pure gold
				"outline": Color(1, 0.84, 0, 1),        # Pure gold outline
				"shadow": Color(1, 0.84, 0, 0.9)        # Gold glow
			}
		"green":
			return {
				"font_color": Color(0.75, 0.75, 0.75, 1), # Silver
				"outline": Color(0.75, 0.75, 0.75, 1),    # Silver outline
				"shadow": Color(0.75, 0.75, 0.75, 0.9)    # Silver glow
			}
		"red":
			return {
				"font_color": Color(0.8, 0.5, 0.2, 1),  # Bronze
				"outline": Color(0.8, 0.5, 0.2, 1),     # Bronze outline
				"shadow": Color(0.8, 0.5, 0.2, 0.9)     # Bronze glow
			}
		"blue":
			return {
				"font_color": Color(0.9, 0.9, 1, 1),    # Platinum
				"outline": Color(0.9, 0.9, 1, 1),       # Platinum outline
				"shadow": Color(0.9, 0.9, 1, 0.9)       # Platinum glow
			}
		_:
			return get_classic_neon_colors(color_family)

func get_winter_glow_colors(color_family: String) -> Dictionary:
	# Icy/winter glow colors
	match color_family:
		"blue":
			return {
				"font_color": Color(0.7, 0.9, 1, 1),    # Ice blue
				"outline": Color(0.7, 0.9, 1, 1),       # Ice blue outline
				"shadow": Color(0.7, 0.9, 1, 0.8)       # Ice blue glow
			}
		"white":
			return {
				"font_color": Color(1, 1, 1, 1),        # Pure white
				"outline": Color(1, 1, 1, 1),           # Pure white outline
				"shadow": Color(0.9, 0.95, 1, 0.8)      # Frosty glow
			}
		"purple":
			return {
				"font_color": Color(0.8, 0.6, 1, 1),    # Winter purple
				"outline": Color(0.8, 0.6, 1, 1),       # Winter purple outline
				"shadow": Color(0.8, 0.6, 1, 0.8)       # Purple glow
			}
		_:
			# Use icy variants of other colors
			return {
				"font_color": Color(0.8, 0.9, 1, 1),    # Icy tint
				"outline": Color(0.8, 0.9, 1, 1),       # Icy outline
				"shadow": Color(0.8, 0.9, 1, 0.8)       # Icy glow
			}

# Legacy function for backward compatibility
func setup_card_legacy(new_card_id: String, texture_path: String):
	card_id = new_card_id
	card_texture_path = texture_path
	
	if not CardManager:
		print("Error: CardManager not found!")
		return
	
	var card_type = CardManager.get_card_type(card_id)
	if card_type == CardManager.CardType.NUMBER:
		card_number = CardManager.get_card_value(card_id)
		card_operator = ""
		name = "Card" + str(card_number)
	else:
		card_number = 0
		card_operator = CardManager.get_card_value(card_id)
		name = "Card" + card_operator
	
	var texture = load(texture_path) as Texture2D
	if texture:
		$TextureRect.texture = texture
		print("Card ", card_id, " setup with texture: ", texture_path)
	else:
		print("Warning: Could not load texture for card ", card_id, " at path: ", texture_path)
