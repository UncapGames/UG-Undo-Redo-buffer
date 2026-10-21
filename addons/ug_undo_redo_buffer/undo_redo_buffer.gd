@tool
class_name UndoRedoBuffer


var has_captured: bool = false

var do_buffer: Array[Callable]

var undo_buffer: Array[Callable]


static var listening_buffer: UndoRedoBuffer


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


func begin_listening() -> void:
	if listening_buffer:
		push_error("listening buffer already occupied, cannot add another listener")
		return
	
	listening_buffer = self


func stop_listening() -> void:
	if !listening_buffer == self:
		push_error("cannot stop listening, this is not the currently listening buffer")
		return
	
	listening_buffer = null


func do(callable: Callable, ...args: Array) -> void:
	if !has_captured:
		has_captured = true
		
		begin_listening()
		
		callable.bindv(args).call()
		
		stop_listening()
		
	else:
		_do()


func undo() -> void:
	if !has_captured:
		push_error("cannot undo, has not captured yet")
		return
	
	_undo()


func _do() -> void:
	for callable in do_buffer:
		callable.call()


# We call undo methods in reverse order.
func _undo() -> void:
	for i in range(undo_buffer.size() - 1, -1, -1):
		undo_buffer[i].call()
