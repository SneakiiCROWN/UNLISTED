extends Logger
# Explicit isolated-QA instrument. Nothing is registered during ordinary play.
# No scene access from logger callbacks, which may run on any engine thread.
var output: String
var guard:=Mutex.new()
var captured:=false
var errors:=0
func _log_error(function: String,file: String,line: int,code: String,rationale: String,_editor_notify: bool,error_type: int,_backtraces: Array[ScriptBacktrace]) -> void:
	guard.lock()
	var hold:=false
	if errors<64:
		var path:=output.path_join("engine_errors_live.jsonl")
		var stream:=FileAccess.open(path,FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
		if stream:
			stream.seek_end();stream.store_line(JSON.stringify({"ticks_usec":Time.get_ticks_usec(),"thread":OS.get_thread_caller_id(),"function":function,"file":file,"line":line,"code":code,"rationale":rationale,"error_type":error_type}));stream.flush();stream.close()
		errors+=1
	if not captured and function=="particles_get_instance_buffer_motion_vectors_offsets" and file.ends_with("particles_storage.cpp"):
		captured=true;hold=true
		var signal_file:=FileAccess.open(output.path_join("native_hold.json"),FileAccess.WRITE)
		if signal_file:
			signal_file.store_string(JSON.stringify({"pid":OS.get_process_id(),"thread":OS.get_thread_caller_id(),"main_thread":OS.get_main_thread_id(),"ticks_usec":Time.get_ticks_usec(),"hold_msec":15000,"scope":"Deliberate diagnostic hold AFTER the real particle lookup error. Not an ordinary game freeze, crash or fix."}));signal_file.flush();signal_file.close()
	guard.unlock()
	# Keep the failing native caller on this stack for a bounded late attach.
	# Never log recursively, manipulate scene objects or hold our mutex here.
	if hold:OS.delay_msec(15000)
