class_name GitHubManager extends RemoteRepoManager

# "https://api.github.com/repos/OWNER/REPO/releases/latest"
const GITHUB_API_HEADERS: PackedStringArray = [
	"Accept: application/vnd.github+json",
]
const GITHUB_RELEASES_API_URL: String = "https://api.github.com/repos/%s/%s/releases/latest"
const GITHUB_BRANCH_API_URL: String = "https://api.github.com/repos/%s/%s/branches/%s"


func getAddonsFromRemoteRepo():
	var addons: Array[RemoteRepoObject] = _parseAddonFiles()

	for addon in addons:
		_setHTTPSignals(addon)
		AceLog.printLog(["Found Addon Config: %s Version: %s" % [addon.repo, addon.version]])
		var github_url: String = GITHUB_RELEASES_API_URL % [addon.owner, addon.repo] if addon.isRelease else GITHUB_BRANCH_API_URL % [addon.owner, addon.repo, addon.branch]

		var resp = http.request(github_url, GITHUB_API_HEADERS)
		AceLog.printLog(["Wating for GitHub API request %s" % github_url] )
		await http.request_completed
		if resp != OK:
			AceLog.printLog(["Failed to make HTTP request for addon: %s" % addon.repo], AceLog.LOG_LEVEL.ERROR)
			continue


	return addons



func _setHTTPSignals(addon: RemoteRepoObject) -> void:
	if http.request_completed.is_connected(_http_request_completed):
		http.request_completed.disconnect(_http_request_completed)
	
	http.request_completed.connect(_http_request_completed.bind(addon))


func _http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, addon: RemoteRepoObject) -> void:

	if result != HTTPRequest.RESULT_SUCCESS:
		AceLog.printLog(["HTTP Request Failed with result: %d, response code: %d" % [result, response_code]], AceLog.LOG_LEVEL.ERROR)
		return
	else :
		if response_code >= 400:
			var body_str: String = body.get_string_from_utf8()
			var json_data = JSON.parse_string(body_str)
			AceLog.printLog(["Error response from GitHub API for addon: %s - Response Code: %d - Error Message: %s." % [addon.repo, response_code, json_data["message"]]], AceLog.LOG_LEVEL.ERROR)
			_printAddonErrorMessage(addon)
			return
		else:
			var body_str: String = body.get_string_from_utf8()
			var json_data = JSON.parse_string(body_str)
			AceLog.printLog(["Successfully retrieved data from GitHub API for addon: %s - Response Code: %d." % [addon.repo, response_code]])
			AceLog.printLog(["Response Data: %s" % json_data], AceLog.LOG_LEVEL.DEBUG)
			# Process the
	

func _printAddonErrorMessage(addon: RemoteRepoObject) -> void:
	var github_url: String = GITHUB_RELEASES_API_URL % [addon.owner, addon.repo] if addon.isRelease else GITHUB_BRANCH_API_URL % [addon.owner, addon.repo, addon.branch]
	if addon.isRelease:
		AceLog.printLog(
			["Release version %s of addon %s is not available. Try a different release version or branch by changing the isRelease value to false in the addons.json file. Url: %s" % [addon.version, addon.repo, github_url]],
			AceLog.LOG_LEVEL.ERROR
		)
	else:
		AceLog.printLog(
			["Branch %s of addon %s is not available. Check that the branch exists or try a release version instead by setting isRelease to true in the addons.json file. Url: %s" % [addon.branch, addon.repo, github_url]],
			AceLog.LOG_LEVEL.ERROR
		)