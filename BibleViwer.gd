extends Control

const SAVE_FORMAT_VERSION:= 0

@export var chapter_tab:PackedScene

var bible_version:= "nkjv"
## An [Array] of the books of the bible.
var books:= load_book_names() as Array
## The currently selected chater tab.
var current_tab:int = -1
var fuzzy_books:Array = []
var font_size:= 16:
	set(v):
		font_size = v
		for child in %ChapterTabs.get_children():
			child.font_size = font_size

var _tabs:Array:
	set(v):
		for i in v.size():
			var tab:Dictionary = v[i]
			var new_tab:CanvasItem = null
			if i >= %ChapterTabs.get_child_count():
				new_tab = add_tab(tab.book, tab.chapter)
			else:
				new_tab = %ChapterTabs.get_child(i)
				new_tab.book = tab.book
				new_tab.chapter = tab.chapter
			new_tab.text = get_chapter_text(tab.book, tab.chapter)
			new_tab.get_node(^"%TextScroll").scroll_vertical = tab.scroll
	get:
		var arr:= []
		for i in %ChapterTabBar.tab_count:
			var chapter_tab = %ChapterTabs.get_child(i)
			arr.append({
				&"book":chapter_tab.book,
				&"chapter":chapter_tab.chapter,
				&"scroll":chapter_tab.get_node(^"%TextScroll").scroll_vertical
			})
		return arr

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%SearchBook.text_changed.connect(_on_search_book_text_changed)
	%SearchBook.text_submitted.connect(_on_search_enter)
	%SearchChapter.value_changed.connect(_on_search_chapter_text_changed)
	%SearchChapter.changed.connect(_on_search_enter)
	%FuzzyBook1.pressed.connect(_on_fuzzy_book_pressed.bind(%FuzzyBook1))
	%FuzzyBook2.pressed.connect(_on_fuzzy_book_pressed.bind(%FuzzyBook2))
	%FuzzyBook3.pressed.connect(_on_fuzzy_book_pressed.bind(%FuzzyBook3))
	%FuzzyBook4.pressed.connect(_on_fuzzy_book_pressed.bind(%FuzzyBook4))
	
	get_node(^"/root/").size = Vector2i(
		%PageResolutionX.value,
		%PageResolutionY.value
	)
	
	load_settings()

	if %ChapterTabs.get_child_count() == 0:
		add_tab("Genesis", 1)


func add_tab(book:String, chapter:int) -> CanvasItem:
	var new_tab:Node = chapter_tab.instantiate()
	%ChapterTabs.add_child(new_tab)
	new_tab.book = book
	new_tab.chapter = chapter
	new_tab.text = get_chapter_text(book, chapter)
	new_tab.visible = false
	new_tab.font_size = font_size
	%ChapterTabBar.add_tab("%s %d" % [book, chapter])
	
	if current_tab >= %ChapterTabs.get_child_count() or current_tab == -1:
		current_tab = %ChapterTabs.get_child_count()-1
	
	save_settings()
	
	return new_tab


func book_fuzzy_search(search_by:String) -> Array:
	if search_by.strip_escapes().length() == 0:
		return []
		
	var closest_matches:Array = books.map(func(elm:String):
		return [
			elm,
			search_by.similarity(elm.substr(0, search_by.length()).to_lower())
		]
	)
	closest_matches.sort_custom(func(a:Array, b:Array):
		return a[1] > b[1]
	)
	return closest_matches


func load_book_names() -> Array:
	var file:= FileAccess.open("res://bibles.txt", FileAccess.READ)
	var arr:= file.get_as_text().split("\n") as Array
	arr.erase("")
	return arr


func get_chapter_text(book:String, chapter:int) -> String:
	var path:= "res://bibles/%s/%s_%s.txt" \
		% [bible_version, book.replace(" ", "_"), int(chapter)]
	if not DirAccess.dir_exists_absolute(path):
		path = "user://bibles/%s/%s_%s.txt" \
			% [bible_version, book.replace(" ", "_"), int(chapter)]
			
	var file:= FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func get_saving_properties() -> Dictionary:
	return {
		self: {&"name":&"Self", &"params":[&"_tabs"]},
		%PageResolutionX:  {&"name":&"PageResolutionX", &"params":[&"value"]},
		%PageResolutionY: {&"name":&"PageResolutionY", &"params":[&"value"]},
		%PageResiazable: {&"name":&"PageResiazable", &"params":[&"button_pressed"]},
		%FontSize: {&"name":&"FontSize", &"params":[&"value"]}
	}


func goto_chapter(book:String, chapter:int) -> void:
	var chapter_text:= get_chapter_text(book, chapter)
	if chapter_text == "":
		book = books[wrapi(books.find(book)+1, 0, books.size())]
		chapter = 1
		goto_chapter(book, chapter)
	
	%SearchBook.text = book
	%SearchChapter.value = chapter
	
	var curr_chapter_tab:= %ChapterTabs.get_child(current_tab)
	curr_chapter_tab.book = book
	curr_chapter_tab.chapter = chapter
	curr_chapter_tab.text = get_chapter_text(book, chapter)
	curr_chapter_tab.font_size = font_size
	%ChapterTabBar.set_tab_title(current_tab, "%s %d" % [book, chapter])
	
	
func load_settings() -> void:
	var config:= ConfigFile.new()
	config.load("user://data.save")
	
	if config.get_value("meta", "format") != SAVE_FORMAT_VERSION:
		return
	
	var to_save:= get_saving_properties()
	for obj in to_save:
		var obj_meta:Dictionary = to_save[obj]
		for prop in obj_meta.params:
			var config_property:= "%s.%s"%[obj_meta.name, prop]
			if config.has_section_key("data", config_property):
				var val = config.get_value("data", config_property)
				obj.set(prop, val)


func remove_tab(tab_index:int) -> void:
	%ChapterTabs.get_child(tab_index).queue_free()
	%ChapterTabBar.remove_tab(tab_index)
	
	if current_tab >= %ChapterTabs.get_child_count() or current_tab == -1:
		current_tab = %ChapterTabs.get_child_count()-1
		switch_tab(current_tab)
	save_settings()


func save_settings() -> void:
	var config:= ConfigFile.new()
	config.set_value("meta", "format", SAVE_FORMAT_VERSION)
	var to_save:= get_saving_properties()
	for obj in to_save:
		var obj_meta:Dictionary = to_save[obj]
		for prop in obj_meta.params:
			config.set_value("data", "%s.%s"%[obj_meta.name,prop], obj.get(prop))
	
	config.save("user://data.save")


func switch_tab(tab_index:int) -> void:
	if tab_index >= %ChapterTabs.get_child_count():
		push_warning(
			"Attempted to switch to tab by index %s, but only %s tabs exist."
				% [tab_index, %ChapterTabs.get_child_count()]
		)
		return
		
	for child in %ChapterTabs.get_children():
		if child is CanvasItem:
			child.hide()
			
	%ChapterTabs.get_child(tab_index).show()
	current_tab = tab_index


func _on_fuzzy_book_pressed(button:Button) -> void:
	_on_search_book_text_changed(button.text)
	%SearchBook.grab_focus()
	goto_chapter(button.text, %SearchChapter.value)


func _on_search_book_text_changed(new_text:String) -> void:
	fuzzy_books = book_fuzzy_search(new_text)
	if fuzzy_books.size() == 0:
		%FuzzyBooks.visible = false
		return
	if new_text in books:
		%FuzzyBooks.visible = false
		return
	
	%FuzzyBooks.visible = true
	%FuzzyBook1.text = str(fuzzy_books[0][0])
	%FuzzyBook2.text = str(fuzzy_books[1][0])
	%FuzzyBook3.text = str(fuzzy_books[2][0])
	%FuzzyBook4.text = str(fuzzy_books[3][0])


func _on_search_chapter_text_changed(value:int) -> void:
	goto_chapter(%SearchBook.text, value)


func _on_search_enter(_p=null) -> void:
	goto_chapter(%SearchBook.text, %SearchChapter.value)


func _on_tab_bar_tab_close_pressed(tab:int) -> void:
	remove_tab(tab)


func _on_new_tab_pressed() -> void:
	add_tab(%SearchBook.text, %SearchChapter.value)


func _on_chapter_tab_bar_tab_changed(tab: int) -> void:
	switch_tab(tab)
	
	
func _on_page_resolution_x_value_changed(value:float) -> void:
	get_viewport().size.x = %PageResolutionX.value
	save_settings()


func _on_page_resolution_y_value_changed(value:float) -> void:
	get_viewport().size.y = %PageResolutionY.value
	save_settings()


func _on_page_resiazable_toggled(button_pressed: bool) -> void:
	get_node(^"/root/").unresizable = not button_pressed
	save_settings()


func _on_font_size_value_changed(value: float) -> void:
	self.font_size = value
	save_settings()


func _on_scroll_value_changed(value: float) -> void:
	var scroll_cont:= %ChapterTabs.get_child(current_tab).get_node(^"%TextScroll")
	scroll_cont.scroll_vertical = value * scroll_cont.get_child(0).get_rect().size.y
