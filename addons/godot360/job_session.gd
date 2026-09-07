extends RefCounted
## Fresh challenges prove that this coordinator still serves this job folder.
## Saved PIDs are diagnostic evidence, never authority to signal another process.
const IO = preload("job_io.gd")
const Planner = preload("job_planner.gd")
const TERMINAL = ["Complete", "Failed", "Cancelled"]
var identity: Dictionary = {}
var folder: String


static func token() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()


func start(path: String) -> bool:
	folder = path
	identity = {"protocol": 1, "session_id": token(), "pid": OS.get_process_id()}
	return DirAccess.make_dir_recursive_absolute(folder.path_join("control")) == OK and IO.write_json(folder.path_join("session.json"), identity)


func serve(state: Dictionary) -> void:
	var directory := folder.path_join("control")
	for name in DirAccess.get_files_at(directory):
		if not name.ends_with(".request.json"):
			continue
		var path := directory.path_join(name)
		var request := IO.read_json(path)
		var nonce := name.trim_suffix(".request.json")
		var valid: bool = nonce.length() == 32 and nonce.is_valid_hex_number() and request.get("nonce") == nonce
		valid = valid and request.get("session_id") == identity.session_id and request.get("action") in ["probe", "cancel"]
		var expires := float(request.get("expires", 0))
		valid = valid and expires >= Time.get_unix_time_from_system() and expires <= Time.get_unix_time_from_system() + 15.0
		if valid:
			var accepted := true
			if request.action == "cancel" and not state.get("stage") in TERMINAL:
				accepted = IO.write_text(folder.path_join("cancel.request"), "Cancel requested through the connected studio panel.")
			var reply := identity.duplicate()
			reply.merge({"nonce": nonce, "action": request.action, "accepted": accepted, "state": state})
			IO.write_json(directory.path_join(nonce + ".reply.json"), reply)
		DirAccess.remove_absolute(path)


static func request(path: String, owner: Dictionary, action: String = "probe") -> Dictionary:
	if owner.get("protocol") != 1 or str(owner.get("session_id", "")).length() != 32 or int(owner.get("pid", -1)) <= 0:
		return {}
	var pending := owner.duplicate()
	pending.merge({"nonce": token(), "action": action, "expires": Time.get_unix_time_from_system() + 10.0}, true)
	if not IO.write_json(path.path_join("control").path_join(str(pending.nonce) + ".request.json"), pending):
		return {}
	return pending


static func response(path: String, pending: Dictionary) -> Dictionary:
	if pending.is_empty():
		return {}
	var reply := IO.read_json(path.path_join("control").path_join(str(pending.nonce) + ".reply.json"))
	for key in ["protocol", "session_id", "pid", "nonce", "action"]:
		if reply.get(key) != pending.get(key):
			return {}
	return reply if reply.get("accepted", false) and Time.get_unix_time_from_system() <= float(pending.expires) else {}


static func clear_request(path: String, pending: Dictionary) -> void:
	if pending.is_empty():
		return
	for suffix in [".request.json", ".reply.json"]:
		var file := path.path_join("control").path_join(str(pending.nonce) + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


static func review(path: String) -> Dictionary:
	var job := IO.read_json(path.path_join("job.json"))
	if job.is_empty():
		return {"error": "Select an export folder containing job.json."}
	var state := IO.read_json(path.path_join("status.json"))
	var report := IO.read_json(path.path_join("report.json"))
	var delivered: bool = report.get("ok", false) and FileAccess.file_exists(path.path_join("video-360.mp4"))
	var source := str(job.get("source_dir", "")) if job.get("mode") == "reencode" else path
	var recovery := Planner.recovery(source) if source.is_absolute_path() else {"can_reencode": false, "next_step": "The original capture folder is missing from this job."}
	return {"job": job, "state": state, "delivered": delivered, "recovery": recovery,
		"owner": IO.read_json(path.path_join("session.json")), "terminal": state.get("stage") in TERMINAL}
