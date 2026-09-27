extends StaticBody3D

@export var prompt := "Listen"
@export var speaker := "Uncle"
@export_file("*.txt") var text_file := "res://time_paradoxes_10_hours.txt"

var _paragraphs: Array[String] = []
var _index := 0
var _sentence_re := RegEx.new()


func _ready() -> void:
	_sentence_re.compile("[^.!?]+[.!?]+|[^.!?]+$")
	_load_paragraphs()


func _load_paragraphs() -> void:
	_paragraphs.clear()
	if not FileAccess.file_exists(text_file):
		push_warning("Dialogue text file not found: %s" % text_file)
		return
	var file := FileAccess.open(text_file, FileAccess.READ)
	if file == null:
		return
	var content := file.get_as_text()
	for block in content.split("\n\n", false):
		var paragraph := block.strip_edges()
		if not paragraph.is_empty():
			_paragraphs.append(paragraph)


func interact(player: Node) -> void:
	var dialogue := get_tree().get_first_node_in_group("dialogue")
	if not dialogue or not dialogue.has_method("show_lines"):
		return

	if player and player.has_method("lock_movement"):
		player.lock_movement()
		if not dialogue.dialogue_finished.is_connected(player.unlock_movement):
			dialogue.dialogue_finished.connect(player.unlock_movement)

	if _paragraphs.is_empty():
		return
	dialogue.show_lines(_split_sentences(_paragraphs[_index]))
	_index = (_index + 1) % _paragraphs.size()


func _split_sentences(paragraph: String) -> Array:
	var lines: Array = []
	for found in _sentence_re.search_all(paragraph):
		var sentence := found.get_string().strip_edges()
		if not sentence.is_empty():
			lines.append({"text": sentence, "speaker": speaker})
	return lines
