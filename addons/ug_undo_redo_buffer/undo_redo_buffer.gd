@tool
class_name UndoRedoBuffer


var has_captured: bool = false

var do_buffer: Array[Callable]

var undo_buffer: Array[Callable]


static var listening_buffer: UndoRedoBuffer


# HACK @sphynx-skillcap: ambiguate the type of undo_redo because we want to be able to pass either
# an UndoRedo reference or EditorUndoRedoManager reference.
static func create_and_run_buffered_action(undo_redo: Object, action_name: String, callable: Callable, ...args: Array) -> void:
	undo_redo.create_action(action_name, 0)
	
	var new_undo_redo_buffer: UndoRedoBuffer = UndoRedoBuffer.new()
	
	undo_redo.add_do_method.callv([new_undo_redo_buffer, "do", callable] + args)
	
	undo_redo.add_undo_method(new_undo_redo_buffer, "undo")
	
	undo_redo.commit_action()


static func add_do_method(callable: Callable, ...args: Array) -> void:
	if !listening_buffer:
		return
	
	listening_buffer.do_buffer.append(callable)


static func add_undo_method(callable: Callable, ...args: Array) -> void:
	if !listening_buffer:
		return
	
	listening_buffer.undo_buffer.append(callable)


static func add_do_property(object: Object, property: StringName, value: Variant) -> void:
	if !listening_buffer:
		return
	
	listening_buffer.do_buffer.append(object.set.bind(property, value))


static func add_undo_property(object: Object, property: StringName, value: Variant) -> void:
	if !listening_buffer:
		return
	
	listening_buffer.undo_buffer.append(object.set.bind(property, value))


func _do(callable: Callable, ...args: Array) -> void:
	if !has_captured:
		has_captured = true
		
		_begin_listening()
		
		callable.bindv(args).call()
		
		_stop_listening()
		
	else:
		_do_captured()


func _undo() -> void:
	if !has_captured:
		push_error("cannot undo, has not captured yet")
		return
	
	_undo_captured()


func _begin_listening() -> void:
	if listening_buffer:
		push_error("listening buffer already occupied, cannot add another listener")
		return
	
	listening_buffer = self


func _stop_listening() -> void:
	if !listening_buffer == self:
		push_error("cannot stop listening, this is not the currently listening buffer")
		return
	
	listening_buffer = null


func _do_captured() -> void:
	for callable in do_buffer:
		callable.call()


# We call undo methods in reverse order.
func _undo_captured() -> void:
	for i in range(undo_buffer.size() - 1, -1, -1):
		undo_buffer[i].call()
