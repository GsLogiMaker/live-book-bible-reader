extends CodeEdit

var books:= []
		

func _on_code_edit_code_completion_requested() -> void:
	pass # Replace with function body.


func _on_code_edit_text_changed() -> void:
	for book in books:
		add_code_completion_option(KIND_CLASS, book, book)
	update_code_completion_options(false)
