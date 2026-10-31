extends Node2D

func _ready() -> void:
	make_region("Север", Vector2(100, 100), Color.STEEL_BLUE)
	make_region("Восток", Vector2(310, 100), Color.INDIAN_RED)
	make_region("Юг", Vector2(100, 260), Color.SEA_GREEN)

func make_region(region_name, pos, col) :
	var r = ColorRect.new()
	r.position = pos
	r.size = Vector2(200, 150)
	r.color = col
	var label = Label.new()
	label.text = region_name
	r.add_child(label)
	r.gui_input.connect(_on_region_input.bind(r, region_name))
	add_child(r)
	
func _on_region_input(event, r, region_name):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Клик по: ", region_name)
		r.color = r.color.lightened(0.2)
