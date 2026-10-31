extends Node2D

var regions := {} # Имя региона -> его прямоугольник
var base_colors := {} # Имя региона -> исходный цвет
var neighbors := {
	"Север": ["Восток", "Юг"],
	"Восток": ["Север", "Юг"],
	"Юг": ["Север", "Восток"],
}
var info_label: Label


func _ready() -> void:
	# Панель с информацией сверху экрана
	var ui := CanvasLayer.new()
	add_child(ui)
	info_label = Label.new()
	info_label.position = Vector2(20, 10)
	info_label.text = "Кликни по региону"
	ui.add_child(info_label)
	
	make_region("Север", Vector2(100, 100), Color.STEEL_BLUE)
	make_region("Восток", Vector2(310, 100), Color.INDIAN_RED)
	make_region("Юг", Vector2(100, 260), Color.SEA_GREEN)

func make_region(region_name: String, pos: Vector2, col: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = Vector2(200, 150)
	r.color = col
	var label := Label.new()
	label.text = region_name
	r.add_child(label)
	r.gui_input.connect(_on_region_input.bind(region_name))
	add_child(r)
	regions[region_name] = r
	base_colors[region_name] = col
	
func _on_region_input(event, region_name: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_region(region_name)

func select_region(region_name: String) -> void:
	# Сначала вернём всем исходный цвет
	for n in regions:
		regions[n].color = base_colors[n]
	# Выбранный регион светлее всех, соседи чуть светлее
	regions[region_name].color = base_colors[region_name].lightened(0.35)
	for n in neighbors[region_name]:
		regions[n].color = base_colors[n].lightened(0.12)
	var list := ", ".join(PackedStringArray(neighbors[region_name]))
	info_label.text = "Регион: %s\nСоседи: %s" % [region_name, list]
