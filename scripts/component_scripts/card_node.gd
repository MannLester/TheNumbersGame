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
var card_number: int = 0
var card_texture_path: String = ""

var dragging := false
var drag_offset := Vector2.ZERO
var original_parent = null
var original_position := Vector2.ZERO

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
	dragging = true
	drag_offset = mouse_pos - global_position
	original_parent = get_parent()
	original_position = position
	
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
		
		# Emit signal for player hand to handle drop logic
		drag_ended.emit(self)

func return_to_original_position():
	if original_parent:
		reparent(original_parent)
		position = original_position
		z_index = 0
		print("Card returned to original position: ", name)

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

func setup_card(number: int, texture_path: String):
	# Setup card with specific number and texture
	card_number = number
	card_texture_path = texture_path
	
	# Load and set the texture
	var texture = load(texture_path) as Texture2D
	if texture:
		$TextureRect.texture = texture
		print("Card ", number, " setup with texture: ", texture_path)
	else:
		print("Warning: Could not load texture for card ", number, " at path: ", texture_path)
	
	# Update the card name for easier identification
	name = "Card" + str(number)
