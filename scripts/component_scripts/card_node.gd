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
	
	# Connect the gui_input signal
	gui_input.connect(_on_gui_input)  

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
	
	print("Starting drag - Immediate parent: ", original_parent.name if original_parent else "none")
	print("Starting drag - Parent path: ", original_parent.get_path() if original_parent else "none")
	print("Starting drag - Original position: ", original_position)
	
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
		else:
			print("Cards container not found")
		
		if cards_container:
			print("SUCCESS: Returning card to player hand cards container")
			
			# Remove from current parent first
			if get_parent():
				get_parent().remove_child(self)
			
			# Add to cards container
			cards_container.add_child(self)
			
			# Reset transform properties
			position = Vector2.ZERO
			rotation = 0.0
			scale = Vector2.ONE
			z_index = 0
			
			print("Card ", card_id, " successfully returned to player hand")
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
		
		# Return to original parent
		original_parent.add_child(self)
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

func setup_card(new_card_id: String, texture_path: String):
	# Setup card with specific ID and texture
	card_id = new_card_id
	card_texture_path = texture_path
	
	# Safety check for CardManager
	if not CardManager:
		print("Error: CardManager not found!")
		return
	
	# Determine card type and set appropriate data
	var card_type = CardManager.get_card_type(card_id)
	if card_type == CardManager.CardType.NUMBER:
		card_number = CardManager.get_card_value(card_id)
		card_operator = ""
		name = "Card" + str(card_number)
	else:
		card_number = 0
		card_operator = CardManager.get_card_value(card_id)
		name = "Card" + card_operator
	
	# Load and set the texture
	var texture = load(texture_path) as Texture2D
	if texture:
		$TextureRect.texture = texture
		print("Card ", card_id, " setup with texture: ", texture_path)
	else:
		print("Warning: Could not load texture for card ", card_id, " at path: ", texture_path)
