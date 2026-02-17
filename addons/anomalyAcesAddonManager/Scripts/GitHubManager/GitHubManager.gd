@tool
class_name GitHubManager extends RemoteRepoManager

# "https://api.github.com/repos/OWNER/REPO/releases/latest"
const GITHUB_API_HEADERS: PackedStringArray = [
	"Accept: application/vnd.github+json",
]
const GITHUB_RELEASES_API_URL: String = "https://api.github.com/repos/%s/%s/releases/tags/%s"
const GITHUB_RELEASES_LATEST_API_URL: String = "https://api.github.com/repos/%s/%s/releases/latest"

const GITHUB_BRANCH_API_URL: String = "https://api.github.com/repos/%s/%s/branches/%s"
const GITHUB_BRANCH_ZIP_URL: String = "https://api.github.com/repos/%s/%s/zipball/%s"

const GITHUB_TEMP_DOWNLOAD_PATH: String = "res://addons/anomalyAcesAddonManager/temp/github/"

## Signals ##
signal addons_processed
signal addon_updates_processed
signal addons_downloaded(addons: Array[RemoteRepoObject], is_update: bool)
signal conflicts_found(conflicting_addons: Array[RemoteRepoConflict])

var _addons: Array[RemoteRepoObject] = []
var _num_requests: int = 0
var _requests_completed: int = 0
var _num_download_requests: int = 0
var _download_requests_completed: int = 0
var _num_update_requests: int = 0
var _update_requests_completed: int = 0

func getAddonsFromRemoteRepo():
	_addons = _parseAddonFiles()

	#Check for conflicts
	var conflicting_addons: Array[RemoteRepoConflict] = _checkForConflicts(_addons)
	if conflicting_addons.size() > 0:
		conflicts_found.emit(conflicting_addons)
		AceLog.printLog(["Conflicts found in addons from remote repos."], AceLog.LOG_LEVEL.ERROR)
		return

	#Intialize counters
	_initialize_counters()
	
	for addon in _addons:
		_getAddonFromRemoteRepo(addon)

	await addons_processed
	AceLog.printLog(["Addons Processed from Remote Repo "])

	_num_download_requests = _get_num_download_requests(_addons, _num_download_requests)

	AceLog.printLog(["Total Download Requests to complete: %d" % _num_download_requests])

	if isAutoDownloadEnabled():
		for addon in _addons:
			_downloadAddonFromRemoteRepo(addon)
	else:
		AceLog.printLog(["Auto Download Addons is disabled. Skipping addon downloads. Should draw attention to download button", AceLog.LOG_LEVEL.INFO])
	
	await addons_downloaded

	# AceLog.printLog(["All Addons Processed and Downloaded from Remote Repo: ", _addons ])

	# return _addons

func getAddonUpdatesFromRemoteRepo(addons: Array[RemoteRepoObject]):
	# Similar to getAddonsFromRemoteRepo but checks for updates based on version or branch commit date and emits a different signal for addons that have updates available
	_initialize_counters()

	for addon in addons:
		_getAddonUpdatesFromRemoteRepo(addon)
	
	await addon_updates_processed
	AceLog.printLog(["Addon Updates Processed from Remote Repo "])

	_num_download_requests = _get_num_download_requests(_addons, _num_download_requests)

	AceLog.printLog(["Total Update Download Requests to complete: %d" % _num_download_requests])

	if isAutoDownloadEnabled():
		for addon in _addons:
			_downloadAddonFromRemoteRepo(addon, true)
	else:
		AceLog.printLog(["Auto Download Addons is disabled. Skipping addon downloads. Should draw attention to download button", AceLog.LOG_LEVEL.INFO])
	
	await addons_downloaded

	# Check addonInstalls.cfg and compare versions aand last commit dates to determine if there are updates available.
	var _addon_installs_cfg: ConfigFile = AceFileUtil.Config.load_config("%s/addonInstalls.cfg" % ADDON_DIR)

	if _addon_installs_cfg != null:
		# Process the existing addons
		pass

	if isAutoInstallDownloadsEnabled(): 
		AceLog.printLog(["Auto Install Downloads is enabled. Emitting signal to install addons."])
		addons_downloaded.emit(_addons, true)
	else:
		AceLog.printLog(["Auto Install Downloads is disabled. Skipping addon installation. Should draw attention to install button", AceLog.LOG_LEVEL.INFO])






func _initialize_counters():
	#Intialize counters
	_num_requests = _get_num_requests(_addons)
	_num_download_requests = 0
	_requests_completed = 0
	_download_requests_completed = 0

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

	var resp = http.request(github_url, _get_headers())
	AceLog.printLog(["Wating for GitHub API request %s" % github_url] )
	await http.request_completed
	if resp != OK:
		AceLog.printLog(["Failed to make HTTP request for addon: %s" % addon.repo], AceLog.LOG_LEVEL.ERROR)
		addon.metadata.status = RemoteRepoConstants.STATUS.NOT_AVAILABLE
	
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

func _downloadAddonFromRemoteRepo(addon: RemoteRepoObject, isUpdate: bool = false) -> void:
	if addon.dependencies.size() > 0:
		for dependency in addon.dependencies:
			_downloadAddonFromRemoteRepo(dependency, isUpdate)

	if addon.metadata.download_url == null || addon.metadata.download_url.is_empty():
		AceLog.printLog(["No download URL for addon: %s, skipping download." % addon.repo], AceLog.LOG_LEVEL.WARN)
		addon.metadata.status = RemoteRepoConstants.STATUS.NOT_AVAILABLE
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

	var resp = http.request(github_url, _get_headers())
	AceLog.printLog(["Wating for GitHub API download request %s" % github_url] )
	await http.request_completed
	if resp != OK:
		AceLog.printLog(["Failed to make HTTP download request for addon: %s" % addon.repo], AceLog.LOG_LEVEL.ERROR)
	
	AceLog.printLog(["Download request completed for Addon: %s" % [addon.repo]])
	_download_requests_completed += 1
	AceLog.printLog(["Download Requests Completed: %d / %d" % [_download_requests_completed, _num_download_requests]])
	if _download_requests_completed >= _num_download_requests:
		addons_downloaded.emit(_addons, isUpdate)

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
				AceFileUtil.Zip.extract_all_from_zip(http.download_file, http.download_file.get_base_dir(), addon.subfolder)
				addon.metadata.status = RemoteRepoConstants.STATUS.DOWNLOADED
				AceLog.printLog(["Successfully downloaded addon: %s to path: %s" % [addon.repo, http.download_file]])
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

func _get_headers() -> PackedStringArray:
	var headers: PackedStringArray = GITHUB_API_HEADERS.duplicate()
	var token: String = getGithubPersonalAccessToken()
	if token != null && !token.is_empty():
		headers.append("Authorization: Bearer %s" % token)
		AceLog.printLog(["Using GitHub Personal Access Token for API requests."], AceLog.LOG_LEVEL.INFO)
	return headers


func _getAddonUpdatesFromRemoteRepo(update: RemoteRepoObject) -> void:
	# Similar to _getAddonFromRemoteRepo but checks for updates based on version or branch commit date and emits a different signal for addons that have updates available
	if update.dependencies.size() > 0:
		for dependency in update.dependencies:
			_getAddonUpdatesFromRemoteRepo(dependency)
			

	var http: HTTPRequest = HTTPRequest.new()
	parent_node.add_child(http)
	_setHTTPAddonInfoSignal(http, update)
	AceLog.printLog(["Checking for updates for Addon: %s" % update.repo])
	# If this is a release, check for updates based on version number. If it's a branch, check for updates based on the date of the last commit to the branch
	var github_latest_url: String = GITHUB_RELEASES_LATEST_API_URL % [update.owner, update.repo] if update.isRelease else GITHUB_BRANCH_API_URL % [update.owner, update.repo, update.branch]

	var resp = http.request(github_latest_url, _get_headers())
	AceLog.printLog(["Wating for GitHub API request %s" % github_latest_url] )
	await http.request_completed
	if resp != OK:
		AceLog.printLog(["Failed to make HTTP request for addon: %s" % update.repo], AceLog.LOG_LEVEL.ERROR)
		update.metadata.status = RemoteRepoConstants.STATUS.NOT_AVAILABLE
	
	_requests_completed += 1
	AceLog.printLog(["Requests Completed: %d / %d" % [_requests_completed, _num_requests]])

	if _requests_completed >= _num_requests:
		addon_updates_processed.emit()


func _compareDownloadsToInstalls(addons: Array[RemoteRepoObject], addon_install_cfg: ConfigFile) -> void:
	# Check addonInstalls.cfg and compare versions aand last commit dates to determine if there are updates available.
	if addon_install_cfg != null:
		# Each config section is a naemd after a addon repo name. The fields it has are version, last_commit_date, install_date
		for addon in addons:
			if addon_install_cfg.has_section(addon.repo):
				var installed_version: String = addon_install_cfg.get_value(addon.repo, "version", "")
				var installed_commit_date: String = addon_install_cfg.get_value(addon.repo, "last_commit_date", "")
				if addon.isRelease:
					if _is_version_newer(addon.version, installed_version):
						addon.metadata.status = RemoteRepoConstants.STATUS.UPDATE_AVAILABLE
						AceLog.printLog(["Update available for addon: %s - Installed Version: %s, Latest Version: %s" % [addon.repo, installed_version, addon.version]])
					else:
						addon.metadata.status = RemoteRepoConstants.STATUS.UP_TO_DATE
						AceLog.printLog(["Addon: %s is up to date. Installed Version: %s, Latest Version: %s" % [addon.repo, installed_version, addon.version]])
				else:
					if _is_date_newer(addon.metadata.branch_last_commit, installed_commit_date):
						addon.metadata.status = RemoteRepoConstants.STATUS.UPDATE_AVAILABLE
						AceLog.printLog(["Update available for addon: %s - Installed Last Commit Date: %s, Latest Last Commit Date: %s" % [addon.repo, installed_commit_date, addon.metadata.branch_last_commit]])
					else:
						addon.metadata.status = RemoteRepoConstants.STATUS.UP_TO_DATE
						AceLog.printLog(["Addon: %s is up to date. Installed Last Commit Date: %s, Latest Last Commit Date: %s" % [addon.repo, installed_commit_date, addon.metadata.branch_last_commit]])


func _is_version_newer(latest_version: String, installed_version: String) -> bool:
	# Strip the non numeric characters from the version strings
	var numeric_latest_version = _strip_non_numeric(latest_version)
	var numeric_installed_version = _strip_non_numeric(installed_version)
	# Simple version comparison function that splits the version strings by . and compares each part as an integer. Returns true if the latest version is newer than the installed version.
	var latest_parts: Array = numeric_latest_version.split(".")
	var installed_parts: Array = numeric_installed_version.split(".")
	var max_parts: int = max(latest_parts.size(), installed_parts.size())
	for i in range(max_parts):
		var latest_part: int =  int(latest_parts[i]) if i < latest_parts.size() else 0
		var installed_part: int = int(installed_parts[i]) if i < installed_parts.size() else 0
		if latest_part > installed_part:
			return true
		elif latest_part < installed_part:
			return false
	return false

func _strip_non_numeric(version: String) -> String:
	# Helper function to strip non-numeric characters from a version string for comparison. This is useful for versions that have suffixes like -beta or -rc1.
	var regex = RegEx.new()
	regex.compile("[^0-9]") # Matches any character that is NOT a digit
	return regex.sub(version, "", true)

func _is_date_newer(latest_date: String, installed_date: String) -> bool:
	# Remove the Z from the date strings
	var sanitized_latest_date: String = latest_date.replace("Z", "")
	var sanitized_installed_date: String = installed_date.replace("Z", "")
	# Simple date comparison function that converts the date strings to DateTime objects and compares them. Returns true if the latest date is newer than the installed date.
	var latest_dt: int  = Time.get_unix_time_from_datetime_string(sanitized_latest_date)
	var installed_dt: int = Time.get_unix_time_from_datetime_string(sanitized_installed_date)
	return latest_dt > installed_dt