extends Node
# Autoloaded as: ChallengeManager

var challenge_type: String = "density"
var chosen_barrel_id: int = -1
var goal_value: float = 0.0
var initialized: bool = false


func setup_challenge(barrels: Array) -> void:
	if barrels.is_empty():
		push_error("❌ [ChallengeManager] No barrels passed to setup_challenge()!")
		return

	print("\n🧠 [ChallengeManager] === Initializing Challenge ===")

	# 1️⃣ Pick random challenge type
	var types := ["density", "mass", "volume"]
	challenge_type = types[randi() % types.size()]
	print("🎯 Challenge Type Picked:", challenge_type)

	# 2️⃣ Pick random barrel
	var chosen_barrel = barrels[randi() % barrels.size()]
	chosen_barrel_id = chosen_barrel.barrel_id
	print("🍺 Chosen Barrel ID:", chosen_barrel_id)

	# 3️⃣ Compute goal value
	match challenge_type:
		"density": goal_value = chosen_barrel.density
		"mass": goal_value = chosen_barrel.density * chosen_barrel.volume
		"volume": goal_value = chosen_barrel.object_mass / max(chosen_barrel.density, 0.001)

	print("📈 Computed Goal Value:", goal_value)
	print("🧾 Formula Inputs → M:", chosen_barrel.object_mass, "| V:", chosen_barrel.volume, "| ρ:", chosen_barrel.density)

	# 4️⃣ Update goal label
	var goal_label = get_tree().get_first_node_in_group("GoalLabel")
	if goal_label:
		var formatted := "Goal %s: %.2f" % [challenge_type.capitalize(), goal_value]
		goal_label.text = formatted
		print("✅ GoalLabel Updated →", formatted)
	else:
		print("⚠️ No GoalLabel group found in scene.")

	initialized = true
	print("✅ [ChallengeManager] Challenge Ready\n")

func setup_bottle_challenge(bottles: Array) -> void:
	if bottles.is_empty():
		push_error("❌ [ChallengeManager] No bottles passed to setup_bottle_challenge()!")
		return

	print("\n🧠 [ChallengeManager] === Initializing Bottle Challenge ===")

	# 🎯 Pick one random bottle
	var chosen_bottle = bottles[randi() % bottles.size()]
	chosen_barrel_id = chosen_bottle.bottle_id
	challenge_type = "density"
	goal_value = chosen_bottle.density

	print("🍾 Chosen Bottle ID:", chosen_bottle.bottle_id, "→ Density:", chosen_bottle.density)

	# 🧾 Update UI
	var goal_label = get_tree().get_first_node_in_group("GoalLabel")
	if goal_label:
		var text = "Goal Density: %.2f" % goal_value
		goal_label.text = text
		print("✅ GoalLabel Updated →", text)
	else:
		print("⚠️ GoalLabel not found in scene.")

	initialized = true
	print("✅ [ChallengeManager] Bottle Challenge Ready\n")

func setup_item_challenge(items: Array) -> void:
	if items.is_empty():
		push_error("❌ [ChallengeManager] No items passed to setup_item_challenge()!")
		return

	print("\n🧠 [ChallengeManager] === Initializing Item Challenge ===")

	var chosen_item = items[randi() % items.size()]
	chosen_barrel_id = chosen_item.item_id
	challenge_type = "density"
	goal_value = chosen_item.density

	print("🧱 Chosen Item ID:", chosen_item.item_id, "→ Density:", chosen_item.density)

	var goal_label = get_tree().get_first_node_in_group("GoalLabel")
	if goal_label:
		var text = "Goal Density: %.2f" % goal_value
		goal_label.text = text
		print("✅ GoalLabel Updated →", text)
	else:
		print("⚠️ GoalLabel not found in scene.")

	initialized = true
	print("✅ [ChallengeManager] Item Challenge Ready\n")
