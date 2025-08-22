extends Node

# Global card deck manager for multiplayer games

# Available cards (numbers + operators)
var available_cards: Array[String] = []
var used_cards: Array[String] = []

# Card texture paths mapping (legacy support)
var card_texture_paths: Dictionary = {}

# ===== CARD DESIGN SYSTEM =====
# Current active design theme
var current_design_theme: String = "classic"

# Available design themes
var available_design_themes: Dictionary = {
	"classic": {
		"name": "Classic",
		"description": "Original game design",
		"backgrounds": ["yellow", "green", "red", "blue"],
		"unlock_condition": "default"
	},
	"neon": {
		"name": "Neon Glow",
		"description": "Bright neon theme",
		"backgrounds": ["neon_yellow", "neon_green", "neon_red", "neon_blue"],
		"unlock_condition": "level_10"
	},
	"royal": {
		"name": "Royal Cards",
		"description": "Gold and premium design",
		"backgrounds": ["royal_gold", "royal_silver", "royal_bronze", "royal_platinum"],
		"unlock_condition": "premium"
	},
	"seasonal_winter": {
		"name": "Winter Theme",
		"description": "Ice and snow theme",
		"backgrounds": ["ice_blue", "snow_white", "frost_cyan", "winter_purple"],
		"unlock_condition": "seasonal"
	}
}

# Design assignment rules for number ranges
var number_range_designs: Dictionary = {
	"1-25": 0,    # Index 0 in backgrounds array (yellow/neon_yellow/royal_gold/ice_blue)
	"26-50": 1,   # Index 1 in backgrounds array (green/neon_green/royal_silver/snow_white)
	"51-75": 2,   # Index 2 in backgrounds array (red/neon_red/royal_bronze/frost_cyan)
	"76-100": 3   # Index 3 in backgrounds array (blue/neon_blue/royal_platinum/winter_purple)
}

# Operator design assignments
var operator_designs: Dictionary = {
	"+": 0,    # Yellow family (Addition = yellow)
	"*": 2,    # Red family (Multiplication = red)
	"-": 1,    # Green family (Subtraction = green)
	"/": 3,    # Blue family (Division = blue)
	"±": -1    # Special: use card-specific color
}

# Card types
enum CardType {
	NUMBER,
	ADDITION,
	SUBTRACTION,
	MULTIPLICATION,
	DIVISION,
	PLUS_MINUS
}

func _ready():
	initialize_deck()
	setup_card_texture_paths()

func initialize_deck():
	# Initialize deck with cards 1-100 + operator cards
	available_cards.clear()
	used_cards.clear()
	
	# Add number cards 1-100 (unique)
	for i in range(1, 101):
		available_cards.append("num_" + str(i))
	
	# Add operator cards (8 of each type)
	for i in range(8):
		available_cards.append("add_" + str(i + 1))    # Addition cards
		available_cards.append("sub_" + str(i + 1))    # Subtraction cards  
		available_cards.append("mul_" + str(i + 1))    # Multiplication cards
		available_cards.append("div_" + str(i + 1))    # Division cards
	
	# Add plus/minus cards (2 of each color = 8 total)
	for i in range(2):
		available_cards.append("plusminus_yellow_" + str(i + 1))  # Yellow plus/minus
		available_cards.append("plusminus_green_" + str(i + 1))   # Green plus/minus
		available_cards.append("plusminus_red_" + str(i + 1))     # Red plus/minus
		available_cards.append("plusminus_blue_" + str(i + 1))    # Blue plus/minus
	
	# Shuffle the deck
	available_cards.shuffle()
	print("Card deck initialized with ", available_cards.size(), " cards (100 numbers + 32 operators + 8 plus/minus)")

func setup_card_texture_paths():
	# Map card identifiers to their texture paths
	card_texture_paths.clear()
	
	# Number cards 1-25
	for i in range(1, 26):
		card_texture_paths["num_" + str(i)] = "res://assets/cards/card1-25/card" + str(i) + ".jpg"
	
	# Number cards 26-50
	for i in range(26, 51):
		card_texture_paths["num_" + str(i)] = "res://assets/cards/card26-50/card" + str(i) + ".jpg"
	
	# Number cards 51-75
	for i in range(51, 76):
		card_texture_paths["num_" + str(i)] = "res://assets/cards/card51-75/card" + str(i) + ".jpg"
	
	# Number cards 76-100
	for i in range(76, 101):
		card_texture_paths["num_" + str(i)] = "res://assets/cards/card76-100/card" + str(i) + ".jpg"
	
	# Operator cards (all instances use the same texture)
	for i in range(8):
		card_texture_paths["add_" + str(i + 1)] = "res://assets/cards/card_operators/card_addition.jpg"
		card_texture_paths["sub_" + str(i + 1)] = "res://assets/cards/card_operators/card_subtract.jpg"
		card_texture_paths["mul_" + str(i + 1)] = "res://assets/cards/card_operators/card_multiply.jpg"
		card_texture_paths["div_" + str(i + 1)] = "res://assets/cards/card_operators/card_division.jpg"
	
	# Plus/minus cards (different colors but same functionality)
	for i in range(2):
		card_texture_paths["plusminus_yellow_" + str(i + 1)] = "res://assets/cards/card_operators/yellow_plus_minus.png"
		card_texture_paths["plusminus_green_" + str(i + 1)] = "res://assets/cards/card_operators/green_plus_minus.png"
		card_texture_paths["plusminus_red_" + str(i + 1)] = "res://assets/cards/card_operators/red_plus_minus.png"
		card_texture_paths["plusminus_blue_" + str(i + 1)] = "res://assets/cards/card_operators/blue_plus_minus.png"
	
	print("Card texture paths mapped for ", card_texture_paths.size(), " cards (100 numbers + 32 operators + 8 plus/minus)")

func draw_cards(count: int) -> Array[String]:
	# Draw specified number of cards from the deck
	var drawn_cards: Array[String] = []
	
	if count > available_cards.size():
		print("Warning: Trying to draw ", count, " cards but only ", available_cards.size(), " available")
		count = available_cards.size()
	
	for i in range(count):
		if available_cards.size() > 0:
			var card_id = available_cards.pop_front()
			drawn_cards.append(card_id)
			used_cards.append(card_id)
	
	print("Drew ", drawn_cards.size(), " cards: ", drawn_cards)
	print("Remaining cards in deck: ", available_cards.size())
	
	return drawn_cards

func get_card_texture_path(card_id: String) -> String:
	if card_id in card_texture_paths:
		return card_texture_paths[card_id]
	else:
		print("Warning: No texture path found for card ", card_id)
		return ""

func get_card_type(card_id: String) -> CardType:
	# Determine card type from card ID
	if card_id.begins_with("num_"):
		return CardType.NUMBER
	elif card_id.begins_with("add_"):
		return CardType.ADDITION
	elif card_id.begins_with("sub_"):
		return CardType.SUBTRACTION
	elif card_id.begins_with("mul_"):
		return CardType.MULTIPLICATION
	elif card_id.begins_with("div_"):
		return CardType.DIVISION
	elif card_id.begins_with("plusminus_"):
		return CardType.PLUS_MINUS
	else:
		print("Warning: Unknown card type for ", card_id)
		return CardType.NUMBER

func get_card_value(card_id: String):
	# Get the actual value/operator from card ID
	if card_id.begins_with("num_"):
		return int(card_id.split("_")[1])  # Return number value
	elif card_id.begins_with("add_"):
		return "+"
	elif card_id.begins_with("sub_"):
		return "-"
	elif card_id.begins_with("mul_"):
		return "*"
	elif card_id.begins_with("div_"):
		return "/"
	elif card_id.begins_with("plusminus_"):
		return "±"  # Plus/minus symbol
	else:
		return ""

func return_card_to_deck(card_id: String):
	# Return a card back to the available deck (for testing/debugging)
	if card_id in used_cards:
		used_cards.erase(card_id)
		available_cards.append(card_id)
		available_cards.shuffle()
		print("Returned card ", card_id, " to deck")

func get_deck_status() -> Dictionary:
	return {
		"available_cards": available_cards.size(),
		"used_cards": used_cards.size(),
		"total_cards": available_cards.size() + used_cards.size()
	}

func draw_starting_pile_card() -> String:
	# Draw one random card to start the pile (like UNO)
	if available_cards.size() > 0:
		var card_id = available_cards.pop_front()
		used_cards.append(card_id)
		print("Drew starting pile card: ", card_id)
		print("Remaining cards in deck: ", available_cards.size())
		return card_id
	else:
		print("Warning: No cards available for starting pile!")
		return ""

func reset_deck():
	# Reset the entire deck (useful for new games)
	initialize_deck()
	print("Deck reset to full 100 cards")

func get_card_design_type(card_id: String) -> String:
	# Get design based on current theme and card type/value
	var card_type = get_card_type(card_id)
	var theme_data = available_design_themes.get(current_design_theme, available_design_themes["classic"])
	var backgrounds = theme_data["backgrounds"]
	
	print("=== DESIGN TYPE DEBUG ===")
	print("Card ID: ", card_id)
	print("Card type: ", card_type)
	print("Theme: ", current_design_theme)
	print("Backgrounds: ", backgrounds)
	
	if card_type == CardType.NUMBER:
		var value = get_card_value(card_id)
		var design_index: int
		
		print("Card value: ", value)
		
		# Determine design index based on number range
		if value >= 1 and value <= 25:
			design_index = number_range_designs["1-25"]    # Yellow family
			print("Range: 1-25, Index: ", design_index)
		elif value >= 26 and value <= 50:
			design_index = number_range_designs["26-50"]   # Green family
			print("Range: 26-50, Index: ", design_index)
		elif value >= 51 and value <= 75:
			design_index = number_range_designs["51-75"]   # Red family
			print("Range: 51-75, Index: ", design_index)
		else: # 76-100
			design_index = number_range_designs["76-100"]  # Blue family
			print("Range: 76-100, Index: ", design_index)
		
		var result = backgrounds[design_index]
		print("Final design: ", result)
		print("========================")
		return result
		
	else:
		# Operator cards
		var operator = get_card_value(card_id)
		var design_index = operator_designs.get(operator, 0)
		
		if design_index == -1:
			# Special case for plus/minus - use card-specific color
			if "yellow" in card_id:
				return backgrounds[0]  # Yellow family
			elif "green" in card_id:
				return backgrounds[1]  # Green family
			elif "red" in card_id:
				return backgrounds[2]  # Red family
			else:
				return backgrounds[3]  # Blue family
		else:
			return backgrounds[design_index]

# ===== DESIGN THEME MANAGEMENT =====
func set_design_theme(theme_name: String) -> bool:
	if theme_name in available_design_themes:
		current_design_theme = theme_name
		print("Design theme changed to: ", theme_name)
		return true
	else:
		print("Warning: Design theme '", theme_name, "' not found")
		return false

func get_current_theme() -> String:
	return current_design_theme

func get_available_themes() -> Array[String]:
	return available_design_themes.keys()

func is_theme_unlocked(theme_name: String) -> bool:
	# Placeholder for unlock logic - can be expanded based on game progression
	var theme_data = available_design_themes.get(theme_name, {})
	var unlock_condition = theme_data.get("unlock_condition", "locked")
	
	match unlock_condition:
		"default":
			return true
		"level_10":
			# TODO: Check player level >= 10
			return true  # For now, return true for testing
		"premium":
			# TODO: Check if player has premium/paid content
			return false
		"seasonal":
			# TODO: Check if current season/event is active
			return false
		_:
			return false

func get_theme_info(theme_name: String) -> Dictionary:
	return available_design_themes.get(theme_name, {})

func add_custom_theme(theme_name: String, theme_data: Dictionary) -> bool:
	# Allow adding custom themes dynamically
	if not theme_data.has("backgrounds") or not theme_data.has("name"):
		print("Error: Custom theme must have 'backgrounds' and 'name' properties")
		return false
	
	available_design_themes[theme_name] = theme_data
	print("Added custom theme: ", theme_name)
	return true

func get_available_designs() -> Array[String]:
	# Return list of available card designs for current theme
	var theme_data = available_design_themes.get(current_design_theme, available_design_themes["classic"])
	return theme_data["backgrounds"]

func get_design_asset_path(design_name: String) -> String:
	# Get the file path for a specific design background
	# This allows for different folder structures for different themes
	
	if current_design_theme == "classic":
		return "res://assets/cards/card_designs/classic_design/card_" + design_name + "_bg.png"
	elif current_design_theme == "neon":
		return "res://assets/cards/card_designs/neon/card_" + design_name + "_bg.png"
	elif current_design_theme == "royal":
		return "res://assets/cards/card_designs/royal/card_" + design_name + "_bg.png"
	elif current_design_theme == "seasonal_winter":
		return "res://assets/cards/card_designs/seasonal/winter/card_" + design_name + "_bg.png"
	else:
		# Fallback to classic for unknown themes
		return "res://assets/cards/card_designs/classic_design/card_" + design_name + "_bg.png"

func validate_design_assets() -> Dictionary:
	# Check if all design assets exist for current theme
	var theme_data = available_design_themes.get(current_design_theme, {})
	var backgrounds = theme_data.get("backgrounds", [])
	var validation_result = {
		"theme": current_design_theme,
		"valid": true,
		"missing_assets": [],
		"existing_assets": []
	}
	
	for design_name in backgrounds:
		var asset_path = get_design_asset_path(design_name)
		if ResourceLoader.exists(asset_path):
			validation_result["existing_assets"].append(asset_path)
		else:
			validation_result["missing_assets"].append(asset_path)
			validation_result["valid"] = false
	
	return validation_result

# ===== DESIGN PREVIEW AND TESTING =====
func preview_card_with_design(card_id: String, theme_name: String) -> String:
	# Preview what design a card would have with a specific theme
	var original_theme = current_design_theme
	set_design_theme(theme_name)
	var preview_design = get_card_design_type(card_id)
	set_design_theme(original_theme)  # Restore original theme
	return preview_design

func get_design_statistics() -> Dictionary:
	# Get statistics about design distribution
	var stats = {
		"current_theme": current_design_theme,
		"total_themes": available_design_themes.size(),
		"unlocked_themes": [],
		"locked_themes": [],
		"design_distribution": {}
	}
	
	# Check unlock status for all themes
	for theme_name in available_design_themes.keys():
		if is_theme_unlocked(theme_name):
			stats["unlocked_themes"].append(theme_name)
		else:
			stats["locked_themes"].append(theme_name)
	
	# Count how many cards use each design in current theme
	var theme_data = available_design_themes.get(current_design_theme, {})
	var backgrounds = theme_data.get("backgrounds", [])
	
	for design in backgrounds:
		stats["design_distribution"][design] = 0
	
	# Count number cards (1-100)
	for i in range(1, 101):
		var card_id = "num_" + str(i)
		var design = get_card_design_type(card_id)
		if design in stats["design_distribution"]:
			stats["design_distribution"][design] += 1
	
	return stats
