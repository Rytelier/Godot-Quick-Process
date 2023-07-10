@tool
extends EditorPlugin

var baseScript : GDScript = preload("res://addons/QuickProcess/Resources/BaseScript.gd")

var selection
var codeEditorWindow : Window
var container : Control
var codeEditor : CodeEdit
var presets : OptionButton

var selectedNodes : Array[Node]

var popupId = 60

var docked = false

func _enter_tree():
	selection = get_editor_interface().get_selection()
	FindSceneTreePopup()
	
	pass


func _exit_tree():
	if codeEditorWindow != null:
		codeEditorWindow.queue_free()
	
	pass

func ShowCodeEditor(id):
	if id == popupId:
		var qp : PackedScene = load("res://addons/QuickProcess/Resources/QP window.tscn")
		codeEditorWindow = qp.instantiate()
		get_editor_interface().get_editor_main_screen().get_window().add_child(codeEditorWindow)
		
		codeEditorWindow.connect("close_requested", CloseCodeEditor.bind())
		container = codeEditorWindow.get_node("QuickProcess")
		codeEditor = container.get_node("CodeEdit")
		
		var executeButton = container.get_node("Panel/Execute")
		executeButton.connect("pressed", ExecuteCode.bind())
		
		var loadPresetButton = container.get_node("Panel/Load")
		presets = container.get_node("Panel/Presets")
		
		var dockButton = codeEditor.get_node("Dock")
		dockButton.pressed.connect(Dock.bind())
		
		var allPresets = DirAccess.open("res://addons/QuickProcess/Presets/").get_files()
		for preset in allPresets:
			if preset == "Default.txt": continue
			presets.add_item(preset.replace(".txt", ""))
		
		loadPresetButton.pressed.connect(LoadPreset.bind())
		presets.selected = 0
		LoadPreset()

func CloseCodeEditor():
	codeEditorWindow.queue_free()

func LoadPreset():
	if presets.selected == -1: return
	
	var preset = presets.get_item_text(presets.selected)
	var presetFile = FileAccess.open("res://addons/QuickProcess/Presets/" + preset + ".txt", FileAccess.READ)
	codeEditor.text = presetFile.get_as_text()
	
	presets.select(-1)

func ExecuteCode():
	selectedNodes = selection.get_selected_nodes()
	
	var codeFinal = ""
	var code = codeEditor.text.split("\n")
	for line in code:
		codeFinal += "\t" + line + "\n"
	
	var script = baseScript.duplicate()
	script.source_code = baseScript.source_code.replace("\tpass##s", codeFinal)
	script.reload()
	
	var tempNode = Node.new()
	get_editor_interface().get_edited_scene_root().add_child(tempNode)
	tempNode.set_script(script)
	tempNode.selected = selectedNodes
	tempNode.add_user_signal("select")
	tempNode.connect("select", Selected.bind())
	tempNode.Execute()
	
	tempNode.queue_free()

func Selected(nodes : Array[Node]):
	get_editor_interface().get_selection().clear()
	for node in nodes:
		get_editor_interface().get_selection().add_node(node)

func FindSceneTreePopup():
	var sceneTreeEditor : Array[Node]
	var popup
	FindByClass(get_editor_interface().get_editor_main_screen().get_window(), "SceneTreeDock", sceneTreeEditor)
	
	if sceneTreeEditor.size() > 0:
		for child in sceneTreeEditor[0].get_children():
			var pop:PopupMenu = child as PopupMenu

			if not pop: continue

			popup = pop
			popup.connect("about_to_popup", AddItemToPopup.bind(pop))
			popup.connect("id_pressed", ShowCodeEditor.bind())

func AddItemToPopup(popup : PopupMenu):
	var max = 0
	for i in range(popup.item_count):
		if popup.get_item_id(i) > max:
			max = popup.get_item_id(i)
	
	if max > 50:
		popupId = max + 1
	
	popup.add_separator()
	popup.add_icon_item(get_editor_interface().get_base_control().get_theme_icon('Script', 'EditorIcons'), "Quick process", popupId)

func FindByClass(node: Node, className : String, result : Array) -> void:
	if node.is_class(className) :
		result.push_back(node)
	for child in node.get_children():
		FindByClass(child, className, result)

func Dock():
	if !docked:
		codeEditorWindow.remove_child(container)
		add_control_to_bottom_panel(container, "Quick Process")
		codeEditorWindow.visible = false
		docked = true
	else:
		remove_control_from_bottom_panel(container)
		codeEditorWindow.visible = true
		container.visible = true
		codeEditorWindow.add_child(container)
		container.set_anchors_preset(Control.PRESET_FULL_RECT)
		container.size = codeEditorWindow.size
		docked = false
	
