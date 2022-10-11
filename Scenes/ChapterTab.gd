extends VBoxContainer

@export var book:= "":
	set(v):
		book = v
		%BookTitle.text = "%s %d" % [book, chapter]
@export var chapter:= 1:
	set(v):
		chapter = v
		%BookTitle.text = "%s %d" % [book, chapter]
@export var font_size:= 16:
	set(v):
		font_size = v
		%BookTitle["theme_override_font_sizes/font_size"] = font_size * 2
		%BibleText["theme_override_font_sizes/normal_font_size"] = font_size
		%BibleText["theme_override_font_sizes/bold_font_size"] = font_size*.6
@export var text:= "":
	set(v):
		text = v
		%BibleText.text = text



func _on_text_scroll_velocity_started() -> void:
	Engine.target_fps = 30


func _on_text_scroll_velocity_stopped() -> void:
	Engine.target_fps = 5
