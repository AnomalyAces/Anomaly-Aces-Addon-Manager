@tool
class_name GitHubManager extends RemoteRepoManager

# "https://api.github.com/repos/OWNER/REPO/releases/latest"
const GITHUB_API_HEADERS: PackedStringArray = [
	"Accept: application/vnd.github+json",
]
const GITHUB_RELEASES_API_URL: String = "https://api.github.com/repos/%s/%s/releases/tags/%s"
const GITHUB_BRANCH_API_URL: String = "https://api.github.com/repos/%s/%s/branches/%s"

const GITHUB_BRANCH_ZIP_URL: String = "https://api.github.com/repos/%s/%s/zipball/%s"

const GITHUB_TEMP_DOWNLOAD_PATH: String = "res://addons/anomalyAcesAddonManager/temp/github/"

signal addons_processed
signal addons_downloaded

var _addons: Array[RemoteRepoObject] = []
var _num_requests: int = 0
var _requests_completed: int = 0
var _num_download_requests: int = 0
var _download_requests_completed: int = 0

func getAddonsFromRemoteRepo():
	_addons = _parseAddonFiles()
	#Intialize counters
	_num_requests = _get_num_requests(_addons)
	_num_download_requests = 0
	_requests_completed = 0
	_download_requests_completed = 0
	
	for addon in _addons:
		_getAddonFromRemoteRepo(addon)

	await addons_processed
	AceLog.printLog(["Addons Processed from Remote Repo "])

	_num_download_requests = _get_num_download_requests(_addons, _num_download_requests)

	AceLog.printLog(["Total Download Requests to complete: %d" % _num_download_requests])

	for addon in _addons:
		_downloadAddonFromRemoteRepo(addon)
	
	await addons_downloaded

	AceLog.printLog(["All Addons Processed and Downloaded from Remote Repo: ", _addons])

	return _addons

func _get_num_requests(addons: Array[RemoteRepoObject]) -> int:
	_num_requests = 0
	for addon in addons:
		_num_requests += addon.dependencies.size() + 1
	return _num_requests

func _get_num_download_requests(addons: Array[RemoteRepoObject], num_download_req: int ) -> int:

	for addon in addons:
		if addon.metadata.download_url != null && !addon.metadata.download_url.is_empty():
			AceLog.printLog(["Download URL found for addon: %s download url: %s" % [addon.repo, addon.metadata.download_url]])
			num_download_req += 1
		if addon.dependencies.size() > 0:
			num_download_req = _get_num_download_requests(addon.dependencies, num_download_req)
	return num_download_req


func _getAddonFromRemoteRepo(addon: RemoteRepoObject) -> void:
	if addon.dependencies.size() > 0:
		for dependency in addon.dependencies:
			_getAddonFromRemoteRepo(dependency)
			

	var http: HTTPRequest = HTTPRequest.new()
	parent_node.add_child(http)
	_setHTTPAddonInfoSignal(http, addon)
	AceLog.printLog(["Found Addon Config: %s Version: %s" % [addon.repo, addon.version]])
	var github_url: String = GITHUB_RELEASES_API_URL % [addon.owner, addon.repo, addon.version] if addon.isRelease else GITHUB_BRANCH_API_URL % [addon.owner, addon.repo, addon.branch]

	var resp = http.request(github_url, GITHUB_API_HEADERS)
	AceLog.printLog(["Wating for GitHub API request %s" % github_url] )
	await http.request_completed
	if resp != OK:
		AceLog.printLog(["Failed to make HTTP request for addon: %s" % addon.repo], AceLog.LOG_LEVEL.ERROR)
	
	_requests_completed += 1
	AceLog.printLog(["Requests Completed: %d / %d" % [_requests_completed, _num_requests]])

	if _requests_completed >= _num_requests:
		addons_processed.emit()


func _setHTTPAddonInfoSignal(http: HTTPRequest, addon: RemoteRepoObject) -> void:
	if http.request_completed.is_connected(_http_addon_info_request_completed):
		http.request_completed.disconnect(_http_addon_info_request_completed)
	
	http.request_completed.connect(_http_addon_info_request_completed.bind(addon, http))


func _http_addon_info_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, addon: RemoteRepoObject, http: HTTPRequest) -> void:

	if result != HTTPRequest.RESULT_SUCCESS:
		AceLog.printLog(["HTTP Request Failed (url: %s) with result: %d, response code: %d" % [addon.metadata.download_url, result, response_code]], AceLog.LOG_LEVEL.ERROR)
		return
	else :
		if response_code >= 400:
			var body_str: String = body.get_string_from_utf8()
			var json_data = JSON.parse_string(body_str)
			AceLog.printLog(["Error response from GitHub API for addon: %s - Response Code: %d - Error Message: %s." % [addon.repo, response_code, json_data["message"]]], AceLog.LOG_LEVEL.ERROR)
			_printAddonInfoErrorMessage(addon)
			return
		else:
			var body_str: String = body.get_string_from_utf8()
			var json_data = JSON.parse_string(body_str)
			AceLog.printLog(["Successfully retrieved data from GitHub API for addon: %s - Response Code: %d." % [addon.repo, response_code]])
			AceLog.printLog(["Response Data: %s" % json_data], AceLog.LOG_LEVEL.DEBUG)
			# Process the json_data
			if addon.isRelease:
				if json_data.has("zipball_url"):
					addon.metadata.download_url = json_data["zipball_url"]
			else:
				if json_data.has("commit") && json_data["commit"].has("commit"):
					addon.metadata.branch_last_commit = json_data["commit"]["commit"]["author"]["date"]
					AceLog.printLog(["Addon: %s - Branch Last Commit Date: %s" % [addon.repo, addon.metadata.branch_last_commit]])
					addon.metadata.download_url = GITHUB_BRANCH_ZIP_URL % [addon.owner, addon.repo, addon.branch]

			
			if addon.metadata.download_url == null || addon.metadata.download_url.is_empty():
				AceLog.printLog(["Download URL not found for addon: %s" % addon.repo], AceLog.LOG_LEVEL.ERROR)
				return

			parent_node.remove_child(http)
			http.queue_free()

	

func _printAddonInfoErrorMessage(addon: RemoteRepoObject) -> void:
	var github_url: String = GITHUB_RELEASES_API_URL % [addon.owner, addon.repo, addon.version] if addon.isRelease else GITHUB_BRANCH_API_URL % [addon.owner, addon.repo, addon.branch]
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

func _downloadAddonFromRemoteRepo(addon: RemoteRepoObject) -> void:
	if addon.dependencies.size() > 0:
		for dependency in addon.dependencies:
			_downloadAddonFromRemoteRepo(dependency)

	if addon.metadata.download_url == null || addon.metadata.download_url.is_empty():
		AceLog.printLog(["No download URL for addon: %s, skipping download." % addon.repo], AceLog.LOG_LEVEL.WARN)
		return
	
	var http: HTTPRequest = HTTPRequest.new()
	parent_node.add_child(http)
	_setHTTPAddonDownloadSignal(http, addon)
	AceLog.printLog(["Starting download for Addon: %s" % [addon.repo]])
	var github_url: String = addon.metadata.download_url

	# Create temp directory if it doesn't exist
	if !DirAccess.dir_exists_absolute(GITHUB_TEMP_DOWNLOAD_PATH):
		DirAccess.make_dir_recursive_absolute(GITHUB_TEMP_DOWNLOAD_PATH)

	#Set Download File Path
	http.download_file = GITHUB_TEMP_DOWNLOAD_PATH + "%s.zip" % addon.repo

	var resp = http.request(github_url, GITHUB_API_HEADERS)
	AceLog.printLog(["Wating for GitHub API download request %s" % github_url] )
	await http.request_completed
	if resp != OK:
		AceLog.printLog(["Failed to make HTTP download request for addon: %s" % addon.repo], AceLog.LOG_LEVEL.ERROR)
	
	AceLog.printLog(["Download request completed for Addon: %s" % [addon.repo]])
	_download_requests_completed += 1
	AceLog.printLog(["Download Requests Completed: %d / %d" % [_download_requests_completed, _num_download_requests]])
	if _download_requests_completed >= _num_download_requests:
		addons_downloaded.emit()

func _setHTTPAddonDownloadSignal(http: HTTPRequest, addon: RemoteRepoObject) -> void: 
	if http.request_completed.is_connected(_http_addon_download_request_completed):
		http.request_completed.disconnect(_http_addon_download_request_completed)
	http.request_completed.connect(_http_addon_download_request_completed.bind(addon, http))

func _http_addon_download_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, addon: RemoteRepoObject, http: HTTPRequest) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		AceLog.printLog(["HTTP Download Request Failed with result: %d, response code: %d" % [result, response_code]], AceLog.LOG_LEVEL.ERROR)
		return
	else :
		if response_code >= 400:
			var body_str: String = body.get_string_from_utf8()
			var json_data = JSON.parse_string(body_str)
			AceLog.printLog(["Error response from GitHub API for addon download: %s - Response Code: %d - Error Message: %s." % [addon.repo, response_code, json_data["message"]]], AceLog.LOG_LEVEL.ERROR)
			_printAddonDownloadErrorMessage(addon)
			return
		else:
			if FileAccess.file_exists(http.download_file):
				AceLog.printLog(["Successfully downloaded addon: %s to path: %s" % [addon.repo, http.download_file]])
				AceFileUtil.Zip.extract_all_from_zip(http.download_file, http.download_file.get_base_dir(), addon.subfolder)
			else:
				AceLog.printLog(["Failed to download addon: %s to path: %s" % [addon.repo, http.download_file]], AceLog.LOG_LEVEL.ERROR)
			
			parent_node.remove_child(http)
			http.queue_free()

func _printAddonDownloadErrorMessage(addon: RemoteRepoObject) -> void:
	if addon.isRelease:
		AceLog.printLog(
			["Failed to download release version %s of addon %s. Try a different release version or branch by changing the isRelease value to false in the addons.json file." % [addon.version, addon.repo]],
			AceLog.LOG_LEVEL.ERROR
		)
	else:
		AceLog.printLog(
			["Failed to download branch %s of addon %s. Check that the branch exists or try a release version instead by setting isRelease to true in the addons.json file." % [addon.branch, addon.repo]],
			AceLog.LOG_LEVEL.ERROR
		)