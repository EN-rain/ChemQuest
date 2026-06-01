extends Area2D

func check_shot() -> int:
	# Enable just for this check
	monitoring = true
	var areas = get_overlapping_areas()
	monitoring = false   # turn off immediately

	for area in areas:
		if area.has_meta("score"):
			var score = area.get_meta("score")
			print("Hit:", area.name, " Score:", score)
			return score

	print("Missed! 0 points")
	return 0
