class_name RemoteRepoMetadata extends Object

var addon_file: String
var branch_last_commit: String
var download_url: String
var has_update: bool = false



func _to_string() -> String:
	return "RemoteRepoMetadata[addon_file: %s, branch_last_commit: %s, download_url: %s, has_update: %s]"  % [addon_file, branch_last_commit, download_url, has_update]