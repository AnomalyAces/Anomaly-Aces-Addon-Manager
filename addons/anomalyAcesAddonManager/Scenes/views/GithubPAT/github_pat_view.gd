@tool
class_name GithubPATView extends Control

@onready var http: HTTPRequest = $HTTPRequest
@onready var checkButton: Button = %CheckButton

var personal_access_token: String = ""



func _ready() -> void:
	pass




func _on_check_button_pressed() -> void:
	AceLog.printLog(["Check Button Pressed"], AceLog.LOG_LEVEL.DEBUG) # Replace with function body.
	_check_github_pat()

func _on_line_edit_text_submitted(new_text: String) -> void:
	personal_access_token = new_text
	AceLog.printLog(["New Personal Access Token Submitted: ", personal_access_token], AceLog.LOG_LEVEL.DEBUG)


func _check_github_pat() -> void:
	if personal_access_token.is_empty():
		AceLog.printLog(["Personal Access Token is empty. Please enter a valid token."], AceLog.LOG_LEVEL.WARN)
		return
	
	var url: String = "https://api.github.com/user"
	
	# Set up the headers
	var headers: PackedStringArray = [
		"Authorization: Bearer " + personal_access_token,
		"User-Agent: GodotEngine" # GitHub API requires a User-Agent
	]

	http.request_completed.connect(_on_github_pat_check_completed)
	
	var result: int = http.request(url, headers)


func _on_github_pat_check_completed(result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		AceLog.printLog(["Network request failed with error code: ", result], AceLog.LOG_LEVEL.ERROR)
		return
	
	# 1. Check if token is expired/invalid based on status code
	if response_code == 401:
		AceLog.printLog(["Token is EXPIRED or INVALID."], AceLog.LOG_LEVEL.DEBUG)
		return
	elif response_code != 200:
		AceLog.printLog(["Unexpected server response: ", response_code], AceLog.LOG_LEVEL.DEBUG)
		return
	
	# 2. Extract expiration date from headers
	var expiration_date: String = "No expiration date found (Likely set to 'No Expiration')"

	
	for header in headers:
		if header.to_lower().begins_with("github-authentication-token-expiration:"):
			# Split the header name from its value
			var parts = header.split(":", true, 1)
			if parts.size() > 1:
				expiration_date = parts[1].strip_edges()
			break

	AceLog.printLog(["Token is VALID."], AceLog.LOG_LEVEL.INFO)
	AceLog.printLog(["Expires on: ", expiration_date], AceLog.LOG_LEVEL.INFO)
	AceLog.printLog(["Expires on (local time): ", AceDateTimeUtil.DateTime.utc_string_to_local_formatted_string(expiration_date)], AceLog.LOG_LEVEL.INFO)
	
