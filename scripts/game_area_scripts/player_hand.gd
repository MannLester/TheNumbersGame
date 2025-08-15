extends Control

var dragging_card = null
var player_cards: Array[String] = []  # Track player's card IDs

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Wait for CardManager to be ready
	await get_tree().process_frame
	
	# Safety check for CardManager
	if not CardManager:
		print("Error: CardManager autoload not found! Check project settings.")
		return
	
	# Connect draw button signal
	var draw_button = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/TextureButton
	if draw_button:
		draw_button.pressed.connect(_on_draw_button_pressed)
	
	# Setup initial 10 random cards
	setup_initial_cards()
	
	# Setup card drag signals AFTER cards are created
	setup_card_dragging()
	
	# Make player hand responsive while maintaining design
	setup_responsive_layout()

func setup_card_dragging():
	print("=== SETTING UP CARD DRAGGING ===")
	# Connect drag signals for all existing cards
	var cards_container = $MarginContainer/VBoxContainer/MarginContainer2/ScrollContainer/MarginContainer/HBoxContainer
	if cards_container:
		print("Cards container found with ", cards_container.get_child_count(), " children")
		for child in cards_container.get_children():
			print("Checking child: ", child.name, " (", child.get_class(), ")")
			if child.has_signal("drag_started"):
				print("Connecting drag signals for: ", child.name)
				child.drag_started.connect(_on_card_drag_started)
				child.drag_ended.connect(_on_card_drag_ended)
				print("Successfully connected drag signals for: ", child.name)
			else:
				print("WARNING: Child ", child.name, " does not have drag_started signal")
	else:
		print("ERROR: Cards container not found!")
	print("=== CARD DRAGGING SETUP COMPLETE ===")
	print("")

func setup_initial_cards():
	# Remove existing placeholder cards
	var cards_container = $MarginContainer/VBoxContainer/MarginContainer2/ScrollContainer/MarginContainer/HBoxContainer
	if cards_container:
		# Remove all existing children
		for child in cards_container.get_children():
			child.queue_free()
		
		# Wait for children to be freed
		await get_tree().process_frame
		
		# Draw 10 random cards from CardManager
		player_cards = CardManager.draw_cards(10)
		
		# Create CardNode instances for each drawn card
		for card_id in player_cards:
			var card_scene = preload("res://scenes/card_node.tscn")
			var card_instance = card_scene.instantiate()
			
			# Add to container first
			cards_container.add_child(card_instance)
			
			# Wait for the node to be ready
			await get_tree().process_frame
			
			# Setup the card with its ID and texture
			var texture_path = CardManager.get_card_texture_path(card_id)
			card_instance.setup_card(card_id, texture_path)
			
			# Connect drag signals immediately after card setup
			if card_instance.has_signal("drag_started"):
				card_instance.drag_started.connect(_on_card_drag_started)
				card_instance.drag_ended.connect(_on_card_drag_ended)
				print("Connected drag signals for card: ", card_id)
			else:
				print("WARNING: Card ", card_id, " does not have drag signals!")
		
		# Update card counter after all cards are added
		update_card_counter()
		
		print("Setup ", player_cards.size(), " initial cards: ", player_cards)

func update_card_counter():
	# Update the card counter label to show actual number of cards
	var counter_label = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/Control2/TextureRect/Label
	if counter_label:
		var card_count = get_current_card_count()
		counter_label.text = str(card_count)
		print("Updated card counter to: ", card_count)

func get_current_card_count() -> int:
	# Count actual cards in the container
	var cards_container = $MarginContainer/VBoxContainer/MarginContainer2/ScrollContainer/MarginContainer/HBoxContainer
	if cards_container:
		return cards_container.get_child_count()
	return 0

func _on_card_drag_started(card: Control):
	dragging_card = card
	print("=== CARD DRAG STARTED ===")
	print("Card: ", card.name)
	print("Card ID: ", card.get_card_id() if card.has_method("get_card_id") else "unknown")
	print("Card position: ", card.global_position)
	print("=========================")

func _on_card_drag_ended(card: Control):
	if dragging_card == card:
		print("=== CARD DRAG ENDED ===")
		print("Card: ", card.name)
		print("Card global position: ", card.global_position)
		
		# Check if dropped on valid target
		var drop_target = get_drop_target()
		
		if drop_target:
			print("SUCCESS: Valid drop target found - moving card to pile")
			handle_successful_drop(card, drop_target)
		else:
			print("FAIL: No valid drop target - returning card to hand")
			# Return to original position
			card.return_to_original_position()
		
		dragging_card = null
		# Update counter after any card movement
		update_card_counter()
		print("=== DRAG END COMPLETE ===")
		print("")

func get_drop_target():
	print("=== CHECKING DROP TARGET ===")
	# Check if dropped on the pile cards area
	if dragging_card:
		print("Dragging card exists: ", dragging_card.name)
		print("Dragging card position: ", dragging_card.global_position)
		
		# Try multiple ways to find the pile cards
		var pile_cards = null
		
		# Method 1: Try group first
		pile_cards = get_tree().get_first_node_in_group("pile_cards")
		print("Method 1 (group): ", pile_cards.name if pile_cards else "not found")
		
		# Method 2: Try finding by parent relationship
		if not pile_cards:
			var parent = get_parent()  # Get parent of player hand
			print("Player hand parent: ", parent.name if parent else "not found")
			if parent:
				pile_cards = parent.get_node_or_null("Pile Card")
				print("Method 2 (parent relationship): ", pile_cards.name if pile_cards else "not found")
		
		# Method 3: Try finding by scene tree search
		if not pile_cards:
			var scene_root = get_tree().current_scene
			print("Scene root: ", scene_root.name if scene_root else "not found")
			pile_cards = scene_root.get_node_or_null("Pile Card")
			print("Method 3 (scene tree): ", pile_cards.name if pile_cards else "not found")
		
		# Check if we found pile cards and can drop
		if pile_cards and pile_cards.has_method("is_drop_zone_for_position"):
			var card_global_pos = dragging_card.global_position + dragging_card.size / 2  # Center of card
			print("Checking drop zone - Card center position: ", card_global_pos)
			if pile_cards.is_drop_zone_for_position(card_global_pos):
				print("SUCCESS: Card dropped on Panel3 pile area!")
				return pile_cards
			else:
				print("FAIL: Card not in Panel3 drop zone - returning to hand")
		else:
			print("ERROR: Pile cards not found or missing method")
			if pile_cards:
				print("Pile cards methods: ", pile_cards.get_method_list())
	else:
		print("ERROR: No dragging card found")
	
	print("=== DROP TARGET CHECK COMPLETE ===")
	print("")
	return null

func handle_successful_drop(card: Control, target):
	print("=== HANDLING SUCCESSFUL DROP ===")
	print("Card: ", card)
	print("Target: ", target)
	
	# If dropped on pile cards, add card to pile and remove from hand
	if target.has_method("add_card_to_pile") and card.has_method("get_card_id"):
		var card_id = card.get_card_id()
		print("Moving card ", card_id, " from hand to pile")
		
		# Add card to pile (this will create a new stacked card instance)
		target.add_card_to_pile(card_id)
		
		# Remove card from player's hand tracking
		if card_id in player_cards:
			player_cards.erase(card_id)
			print("Removed card ", card_id, " from player_cards array")
		
		# Remove the dragged card from the hand UI
		card.queue_free()
		print("Removed dragged card from hand UI")
		
		# Update hand counter
		update_card_counter()
		
		print("SUCCESS: Card ", card_id, " moved from hand to pile!")
		print("Remaining cards in hand: ", player_cards.size())
	else:
		print("ERROR: Could not move card to pile - missing methods or data")
		print("Target has add_card_to_pile: ", target.has_method("add_card_to_pile") if target else false)
		print("Card has get_card_id: ", card.has_method("get_card_id") if card else false)
		# Fallback: return card to hand
		card.return_to_original_position()
	print("=== DROP HANDLING COMPLETE ===")
	print("")

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
	
	# Draw one new card from the deck
	var drawn_cards = CardManager.draw_cards(1)
	if drawn_cards.size() > 0:
		var card_id = drawn_cards[0]
		player_cards.append(card_id)
		
		# Create new CardNode instance
		var card_scene = preload("res://scenes/card_node.tscn")
		var card_instance = card_scene.instantiate()
		
		# Setup the card with its ID and texture
		var texture_path = CardManager.get_card_texture_path(card_id)
		card_instance.setup_card(card_id, texture_path)
		
		# Add to container
		var cards_container = $MarginContainer/VBoxContainer/MarginContainer2/ScrollContainer/MarginContainer/HBoxContainer
		if cards_container:
			cards_container.add_child(card_instance)
		
		# Connect drag signals for the new card
		if card_instance.has_signal("drag_started"):
			card_instance.drag_started.connect(_on_card_drag_started)
			card_instance.drag_ended.connect(_on_card_drag_ended)
		
		# Update counter
		update_card_counter()
		
		print("Added card ", card_id, " to hand. Total cards: ", player_cards.size())
	else:
		print("No more cards available in deck!")

# Handle screen size changes in real-time
func _notification(what):
	if what == NOTIFICATION_RESIZED:
		call_deferred("setup_responsive_layout")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
