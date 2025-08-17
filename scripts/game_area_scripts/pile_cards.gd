extends Control

# Track cards in the pile
var piled_cards: Array[String] = []
var piled_number_cards: Array[String] = []  # Track only number cards
var card_stack_count: int = 0

func _ready() -> void:
	# Make pile cards responsive while maintaining design
	setup_responsive_layout()

func initialize_pile_with_starting_card():
	# Draw one random card from CardManager to start the pile (like UNO)
	if CardManager:
		var starting_card = CardManager.draw_starting_pile_card()
		if starting_card != "":
			print("=== INITIALIZING PILE WITH STARTING CARD ===")
			print("Starting card: ", starting_card)
			
			# Add the starting card to pile
			add_card_to_pile(starting_card)
			
			print("Pile initialized with starting card: ", starting_card)
			print("===========================================")
		else:
			print("ERROR: Could not draw starting card for pile!")
	else:
		print("ERROR: CardManager not available for pile initialization!")

func add_card_to_pile(card_id: String):
	print("=== ADDING CARD TO PILE ===")
	print("Card ID: ", card_id)
	
	# Add card to general pile tracking
	piled_cards.append(card_id)
	card_stack_count += 1
	
	# Check if it's a number card and add to number cards tracking
	if CardManager:
		var card_type = CardManager.get_card_type(card_id)
		if card_type == CardManager.CardType.NUMBER:
			piled_number_cards.append(card_id)
			print("Added NUMBER card to pile: ", card_id)
		else:
			print("Added OPERATOR card to pile: ", card_id)
	
	# Safety check for CardManager
	if not CardManager:
		print("Error: CardManager not found!")
		return
	
	# Create new card instance for the pile
	var card_scene = preload("res://scenes/card_node.tscn")
	var card_instance = card_scene.instantiate()
	
	# Setup the card with its ID and texture
	var texture_path = CardManager.get_card_texture_path(card_id)
	card_instance.setup_card(card_id, texture_path)
	
	# MAKE THE CARD IMMOVABLE using the dedicated method
	if card_instance.has_method("mark_as_pile_card"):
		card_instance.mark_as_pile_card()
	else:
		# Fallback method if mark_as_pile_card doesn't exist
		card_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_instance.set_process_input(false)
		card_instance.set_process_unhandled_input(false)
	
	# Disconnect any existing drag signals to prevent dragging
	if card_instance.has_signal("drag_started"):
		# Disconnect all connections for drag signals
		for connection in card_instance.drag_started.get_connections():
			card_instance.drag_started.disconnect(connection.callable)
		for connection in card_instance.drag_ended.get_connections():
			card_instance.drag_ended.disconnect(connection.callable)
	
	# Add to the card container
	var card_container = $VBoxContainer/Control
	if card_container:
		card_container.add_child(card_instance)
		
		# Position the card at the center of the container
		# The container is 150x220, so center is at 75x110
		var container_center = Vector2(75, 110)  # Half of 150x220
		card_instance.position = container_center - Vector2(50, 70)  # Offset by half card size (100x140)
		
		# Apply stacking effects AFTER positioning
		apply_stacking_effects(card_instance, card_stack_count)
		
		print("SUCCESS: Added immovable card ", card_id, " to pile center.")
		print("Card positioned at: ", card_instance.position)
		print("Total cards in pile: ", count_actual_total_cards_in_pile())
		print("Number cards in pile: ", count_actual_number_cards_in_pile())
		print("Operator cards in pile: ", get_pile_operator_card_count())
		print("Stack position: ", card_stack_count)
		print("Card is now immovable and cannot be dragged.")
		
		# Update pile counter display
		update_pile_counter()
	else:
		print("ERROR: Could not find card container in pile!")

func apply_stacking_effects(card_instance: Control, stack_position: int):
	# Apply random rotation (±15 degrees for more variety)
	var random_rotation = randf_range(-15.0, 15.0)
	card_instance.rotation_degrees = random_rotation
	
	# Apply small random offset for stacking effect (from the centered position)
	var random_offset_x = randf_range(-8.0, 8.0)
	var random_offset_y = randf_range(-5.0, 5.0)
	
	# Add the offset to the current centered position
	card_instance.position += Vector2(random_offset_x, random_offset_y)
	
	# Set z-index so newer cards appear on top
	card_instance.z_index = stack_position
	
	# Add a slight scale variation for more realistic stacking
	var scale_variation = randf_range(0.95, 1.05)
	card_instance.scale = Vector2(scale_variation, scale_variation)
	
	print("Applied stacking effects:")
	print("  - Position: ", stack_position)
	print("  - Final position: ", card_instance.position)
	print("  - Rotation: ", random_rotation, "°")
	print("  - Offset: ", Vector2(random_offset_x, random_offset_y))
	print("  - Scale: ", scale_variation)
	print("  - Z-index: ", stack_position)

func update_pile_counter():
	# Always count actual number cards in the pile for accuracy
	var counter_label = $VBoxContainer/Label
	if counter_label:
		var actual_number_cards = count_actual_number_cards_in_pile()
		
		if CardManager:
			# Get total number cards available in the deck
			var deck_status = CardManager.get_deck_status()
			var total_number_cards = deck_status.get("total_number_cards", 100)  # Default to 100 if not available
			
			# If CardManager doesn't provide total_number_cards, calculate from available cards 1-100
			if total_number_cards == 100 and deck_status.has("available_cards"):
				# Assume cards 1-100 are number cards if no specific info available
				total_number_cards = 100
			
			# Show count of actual number cards in pile vs total number cards
			counter_label.text = str(actual_number_cards) + " / " + str(total_number_cards)
			print("=== PILE COUNTER UPDATED ===")
			print("Actual number cards in pile: ", actual_number_cards)
			print("Total number cards available: ", total_number_cards)
			print("Display text: ", counter_label.text)
			print("===========================")
		else:
			counter_label.text = str(actual_number_cards) + " / ?"

func count_actual_number_cards_in_pile() -> int:
	# Count actual number card nodes in the pile container
	var card_container = $VBoxContainer/Control
	if card_container:
		var number_card_count = 0
		for child in card_container.get_children():
			# Only count children that are card nodes with number card IDs
			if child.has_method("get_card_id") and CardManager:
				var card_id = child.get_card_id()
				var card_type = CardManager.get_card_type(card_id)
				if card_type == CardManager.CardType.NUMBER:
					number_card_count += 1
		return number_card_count
	return 0

func count_actual_total_cards_in_pile() -> int:
	# Count all actual card nodes in the pile container
	var card_container = $VBoxContainer/Control
	if card_container:
		var total_card_count = 0
		for child in card_container.get_children():
			# Only count children that are card nodes
			if child.has_method("get_card_id"):
				total_card_count += 1
		return total_card_count
	return 0

func is_drop_zone_for_position(global_pos: Vector2) -> bool:
	# Check if the given global position is within Panel3 (outermost circle) bounds
	var panel3 = $Panel3
	if panel3:
		var panel3_rect = panel3.get_global_rect()
		var panel3_center = panel3_rect.get_center()
		
		# Calculate radius from the panel size (it's circular, so use smaller dimension)
		var radius = min(panel3_rect.size.x, panel3_rect.size.y) / 2.0
		
		# Check if the position is within the circular area
		var distance_from_center = global_pos.distance_to(panel3_center)
		var is_in_zone = distance_from_center <= radius
		
		print("=== DROP ZONE DETECTION ===")
		print("Position: ", global_pos)
		print("Panel3 center: ", panel3_center)
		print("Panel3 rect: ", panel3_rect)
		print("Panel3 radius: ", radius)
		print("Distance from center: ", distance_from_center)
		print("In pile zone: ", is_in_zone)
		print("========================")
		return is_in_zone
	else:
		print("ERROR: Panel3 not found in pile cards!")
		return false

func get_pile_card_count() -> int:
	return count_actual_total_cards_in_pile()

func get_pile_number_card_count() -> int:
	return count_actual_number_cards_in_pile()

func get_pile_operator_card_count() -> int:
	return count_actual_total_cards_in_pile() - count_actual_number_cards_in_pile()

func setup_responsive_layout():
	var screen_size = get_viewport().get_visible_rect().size
	var scale_factor = min(screen_size.x / 720.0, screen_size.y / 1280.0)
	
	# Since we're now using center anchoring instead of full rect,
	# we need to scale the overall container size
	scale_container_size(scale_factor)
	
	# Scale the layered circular backgrounds
	scale_background_circles(scale_factor)
	
	# Scale the card node size
	scale_card_container(scale_factor)
	
	# Scale text elements (counter and description)
	scale_text_elements(scale_factor)

func scale_container_size(scale_factor: float):
	# Scale the main container size since we're using center anchoring
	var base_size = 400.0  # Our offset range is -200 to +200 = 400px
	var new_size = max(300.0, base_size * scale_factor)  # Minimum 300px
	var half_size = new_size / 2.0
	
	# Update the container offsets
	offset_left = -half_size
	offset_right = half_size
	offset_top = -half_size
	offset_bottom = half_size

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
	# Update counter every few frames to ensure accuracy
	if Engine.get_process_frames() % 30 == 0:  # Update every 30 frames (about every 0.5 seconds)
		update_pile_counter()
