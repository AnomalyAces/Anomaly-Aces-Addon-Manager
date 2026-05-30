@tool
class_name GithubPATView extends Control

@onready var http: HTTPRequest = $HTTPRequest
@onready var checkButton: Button = %CheckButton
@onready var tokenStatusRTL: RichTextLabel = %TokenStatus
@onready var tokenNotesRTL: RichTextLabel = %TokenNotes

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
	tokenStatusRTL.clear()
	tokenNotesRTL.clear()
	var isPATValid: bool = false
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

	isPATValid = true

	if isPATValid:
		AceLog.printLog(["Token is VALID."], AceLog.LOG_LEVEL.INFO)
		tokenStatusRTL.append_text("Token is [color=green]VALID[/color].")
		AceLog.printLog(["Expires on: ", expiration_date], AceLog.LOG_LEVEL.INFO)
		var local_time_expiration_iso: String = AceDateTimeUtil.DateTime.utc_string_to_local_formatted_string(expiration_date, AceDateTimeUtil.FORMAT_DATETIME_ISO_8601) 
		AceLog.printLog(["Expires on (local time [ISO 8601]): ", local_time_expiration_iso], AceLog.LOG_LEVEL.INFO)
		var local_time_expiration: String = AceDateTimeUtil.DateTime.utc_string_to_local_formatted_string(expiration_date, AceDateTimeUtil.FORMAT_DATETIME_WITH_TZ)
		AceLog.printLog(["Expires on (local time formatted): ", AceDateTimeUtil.DateTime.format_datetime_string(local_time_expiration, AceDateTimeUtil.FORMAT_DATETIME_WITH_TZ)], AceLog.LOG_LEVEL.INFO)
		# var local_time_expiration_iso: String = AceDateTimeUtil.DateTime.format_datetime_string(local_time_expiration, AceDateTimeUtil.FORMAT_DATE_ISO_8601)
		# AceLog.printLog(["Token expiration date (Local ISO): ", local_time_expiration_iso], AceLog.LOG_LEVEL.INFO)

		tokenNotesRTL.append_text("[font_size=36]Token Expires on: [b]" + local_time_expiration + "[/b][/font_size]")
		tokenNotesRTL.newline()
	else:
		tokenNotesRTL.append_text("[font_size=36][b]How to Update/Generate Your Token[/b][/font_size]")
		tokenNotesRTL.newline()
		tokenNotesRTL.newline()
		tokenNotesRTL.append_text("[b]Step 1: Generate a New Token on GitHub[/b][br]")
		tokenNotesRTL.push_list(1, RichTextLabel.ListType.LIST_DOTS,true) # Start a new numbered list with indentation and spacing.
		# tokenNotesRTL.append_text("[ul]")
		tokenNotesRTL.append_text("Go to your GitHub Settings and click on [b]Developer settings[/b] in the left sidebar.")
		tokenNotesRTL.newline()
		tokenNotesRTL.append_text("Click on [b]Personal access tokens[/b] and select [b]Fine-grained tokens[/b].")
		tokenNotesRTL.newline()
		tokenNotesRTL.append_text("Click [b]Generate new token[/b].")
		tokenNotesRTL.newline()
		tokenNotesRTL.append_text("Set the expiration and select your repositories.")
		tokenNotesRTL.newline()
		tokenNotesRTL.append_text("Under Permissions, set [b]Contents[/b] to [b]Read and write[/b].")
		tokenNotesRTL.newline()
		tokenNotesRTL.append_text("Click [b]Generate token[/b] and copy it.")
		tokenNotesRTL.newline()
		tokenNotesRTL.pop()
		tokenNotesRTL.newline()
		tokenNotesRTL.append_text("[b]Step 2: Update Godot 4 Github PAT[/b]")
		tokenNotesRTL.push_list(1, RichTextLabel.ListType.LIST_DOTS,true)
		tokenNotesRTL.append_text("Paste your new token into the input field above and click [b]Check Token[/b] to verify it's working.")
		tokenNotesRTL.newline()
		tokenNotesRTL.append_text("Your token will be saved automatically if valid.")
		# tokenNotesRTL.append_text("[*]Ensure [b]Username[/b] is your GitHub username.")
		# tokenNotesRTL.append_text("[*]Paste your PAT into the [b]Password[/b] field.")
		# tokenNotesRTL.append_text("[*]Click [b]OK[/b] to apply changes.")
		tokenNotesRTL.pop() # End the list.


	
