
@tool
extends RichTextEffect

var bbcode = "woj"

func _process_custom_fx(char_fx:CharFXTransform) -> bool:
	char_fx.color = Color("ff7777")
	return true
