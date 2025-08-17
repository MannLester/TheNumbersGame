extends Node

# Global card deck manager for multiplayer games

# Available cards (numbers + operators)
var available_cards: Array[String] = []
var used_cards: Array[String] = []

# Card texture paths mapping
var card_texture_paths: Dictionary = {}

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
