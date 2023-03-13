@tool
extends Node

var selected : Array[Node]
var selectedOut : Array[Node]

func Execute():
	pass##s

func QuickAddChild(parent, child):
	parent.add_child(child)
	child.owner = get_tree().edited_scene_root

func SelectByName(name, from: Node, extend = false, select = true):
	if !extend:
		selectedOut.clear()
	
	for node in from.get_children():
		if node.name.contains(name):
			selectedOut.append(node)
		SelectByName(name, node, true, false)
	
	if select:
		emit_signal("select", selectedOut)

func SelectByClass(type, from: Node, extend = false, select = true):
	if !extend:
		selectedOut.clear()
	
	for node in from.get_children():
		if node.get_class() == type:
			selectedOut.append(node)
		SelectByClass(type, node, true, false)
	
	if select:
		emit_signal("select", selectedOut)
