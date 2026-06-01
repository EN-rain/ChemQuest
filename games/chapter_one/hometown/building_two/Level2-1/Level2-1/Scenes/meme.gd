extends Area2D
@onready var meme: AudioStreamPlayer = $Meme


func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":  # ✅ Replace "Player" with the exact node name
		meme.play()
