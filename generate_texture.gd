@tool
class_name GenerateTexture
extends EditorScript

var texture_type: int = 0
var size: int = 128
var height: int = 128
var color: Color = Color(1, 1, 1, 1)
var save_path: String = "res://generated_texture.png"

# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	spawn_texture_creation_ui()


# set type, size, color and save path
func spawn_texture_creation_ui() -> void:
	var dialog := AcceptDialog.new()
	dialog.set_title("Generate Texture")
	dialog.set_exclusive(true)
	
	var vbox := VBoxContainer.new()
	
	var type_label := Label.new()
	type_label.text = "Texture Type:"
	vbox.add_child(type_label)
	
	var type_option := OptionButton.new()
	type_option.add_item("Circle", 0)
	type_option.add_item("Solid Rectangle", 1)
	type_option.add_item("Triangle", 2)
	type_option.item_selected.connect(
		func(index):
		texture_type = index
	)
	vbox.add_child(type_option)
	
	var size_label := Label.new()
	size_label.text = "Size (for circle) or Width (for rectangle/triangle):"
	vbox.add_child(size_label)
	
	var size_spin := SpinBox.new()
	size_spin.min_value = 1
	size_spin.max_value = 8192
	size_spin.value = size
	size_spin.value_changed.connect(
		func(value):
		size = int(value)
	)
	vbox.add_child(size_spin)
	
	var height_label := Label.new()
	height_label.text = "Height (for rectangle/triangle):"
	vbox.add_child(height_label)
	
	var height_spin := SpinBox.new()
	height_spin.min_value = 1
	height_spin.max_value = 8192
	height_spin.value = height
	height_spin.value_changed.connect(
		func(value):
		height = int(value)
	)
	vbox.add_child(height_spin)
	
	var color_label := Label.new()
	color_label.text = "Color (RGBA):"
	vbox.add_child(color_label)
	
	var color_picker := ColorPickerButton.new()
	color_picker.custom_minimum_size = Vector2(50, 50)
	color_picker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	color_picker.color = color
	color_picker.color_changed.connect(
		func(new_color):
		color = new_color
	)
	vbox.add_child(color_picker)
	
	var path_label := Label.new()
	path_label.text = "Save Path (including filename.png):"
	vbox.add_child(path_label)
	
	var path_line_edit := LineEdit.new()
	path_line_edit.text = "res://generated_texture.png"
	path_line_edit.text_changed.connect(
		func(new_path: String) ->void:
			save_path = new_path
	)
	vbox.add_child(path_line_edit)
	
	var browse_button := Button.new()
	browse_button.text = "Browse..."
	browse_button.pressed.connect(
		func():
		var file_dialog := FileDialog.new()
		file_dialog.access = FileDialog.ACCESS_RESOURCES
		file_dialog.filters = ["*.png"]
		file_dialog.connect("file_selected",
			func(selected_path):
			path_line_edit.text = selected_path
			save_path = selected_path
		)
		dialog.add_child(file_dialog)
		file_dialog.popup_centered()
	)

	vbox.add_child(browse_button)

	dialog.add_child(vbox)
	
	dialog.get_ok_button().text = "Generate"
	
	# Connect the confirmed signal to the handler
	dialog.confirmed.connect(
		func():
		_on_generate_texture_confirmed(texture_type, size, height, color, path_line_edit.text)
	)

	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered()
	
func _on_generate_texture_confirmed(texture_type: int, size: int, height: int, color: Color, save_path: String) -> void:

	match texture_type:
		0:
			print("circle: size=", size, ", color=", color)
		1:
			print("solid rectangle: width=", size, ", height=", height, ", color=", color)
		2:
			print("triangle: size=", size, ", height=", height, ", color=", color)

	var image: Image
	match texture_type:
		0:
			image = generate_circle_texture(size, color)
		1:
			image = generate_solid_rect_texture(size, height, color)
		2:
			image = generate_triangle_texture(size, height, color)
		_:
			push_error("Invalid texture type selected.")
			return

	save_texture_as_png(image, save_path)


# 生成圆形纹理
func generate_circle_texture(size: int, color: Color, bg_color: Color = Color(0, 0, 0, 0)) -> Image:
	var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
		
	var center := Vector2(size/2.0, size/2.0)
	var radius :float = size/2.0
	
	for x in range(size):
		for y in range(size):
			var distance = center.distance_to(Vector2(x, y))
			image.set_pixel(x, y, color if distance <= radius else bg_color)
	
	return image


# 生成纯色矩形纹理
func generate_solid_rect_texture(width: int, height: int, color: Color) -> Image:
	var image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	
	for x in range(width):
		for y in range(height):
			image.set_pixel(x, y, color)
	
	return image


# 生成三角形纹理
func generate_triangle_texture(width: int, height: int, color: Color, bg_color: Color = Color(0, 0, 0, 0)) -> Image:
	var image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	var p1 = Vector2(width / 2.0, 0)
	var p2 = Vector2(0, height)
	var p3 = Vector2(width, height)
	for x in range(width):
		for y in range(height):
			var p = Vector2(x, y)
			if is_point_in_triangle(p, p1, p2, p3):
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, bg_color)

	return image

# 检查点是否在三角形内
func is_point_in_triangle(p, p1, p2, p3):
	var alpha = ((p2.y - p3.y)*(p.x - p3.x) + (p3.x - p2.x)*(p.y - p3.y)) / \
				((p2.y - p3.y)*(p1.x - p3.x) + (p3.x - p2.x)*(p1.y - p3.y))
	var beta = ((p3.y - p1.y)*(p.x - p3.x) + (p1.x - p3.x)*(p.y - p3.y)) / \
			   ((p2.y - p3.y)*(p1.x - p3.x) + (p3.x - p2.x)*(p1.y - p3.y))
	var gamma = 1.0 - alpha - beta
	
	return alpha >= 0 and beta >= 0 and gamma >= 0

func save_texture_as_png(image:Image, file_path:String):
	image.save_png(file_path)
	EditorInterface.get_resource_filesystem().scan()
