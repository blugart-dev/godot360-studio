@tool
extends AcceptDialog
## Small, offline task guides. Detailed reference documents remain bundled.
signal setup_requested

const TOPICS = ["start", "setup", "quality", "files"]
const TITLES = ["Your first export", "Install and check tools", "Quality and renderer support", "Files, storage and recovery"]
const GUIDES = ["QUICKSTART.md", "PLATFORMS.md", "SUPPORT.md", "STORAGE.md"]
const PAGES = [
"""[b]1. Choose a scene and camera[/b]
In Current recipe, use [b]Use current scene[/b] or [b]Choose scene…[/b], then pick a camera. Use current scene saves a named scene; save a new scene in Godot first. Save other edited assets too.

[b]2. Choose the film settings[/b]
Start with [b]Draft · 2K[/b], set the full duration and FPS, choose scene audio or a soundtrack, and pick an output folder. Library has Calibration and Motion lab examples.

[b]3. Check and test[/b]
[b]Check setup[/b] checks tools and output access. [b]Test 1 second[/b] makes a real sample and estimates the full export's time and storage. It keeps your chosen full duration.

[b]4. Render and review[/b]
Choose [b]Render 360 video[/b]. Drag the preview to look around, or focus it and use arrow keys; Home resets the view. Play video prepares a review copy capped at 2K / 30 FPS. Use [b]Open delivery MP4[/b] for final resolution in a 360° player.

[b]Your next recipe stays separate[/b]
Opened export describes the job you are reviewing. Editing the current recipe changes the next render. Each export gets a new folder.""",
"""[b]Two external tools, installed once[/b]
FFmpeg creates the video and playback copy. FFprobe verifies the output. The addon does not download executables.

[b]On Windows[/b]
Use [b]FFmpeg download page[/b] below. Choose a release essentials ZIP on the Windows build page, then extract it. In [b]Tools → Tool setup[/b], select [b]FFmpeg…[/b] and choose [b]bin/ffmpeg.exe[/b] inside the extracted folder. FFprobe is filled from the same folder unless you selected it yourself. Keep the tools in a permanent location.

[b]Already installed?[/b]
[b]Find missing tools[/b] searches installed command paths. It preserves your selected paths, even if they are unavailable. To replace one, use its file picker; clear its field to allow discovery again.

[b]Check setup[/b]
Run this after choosing tools. If a tool cannot launch, select the executable for your operating system and CPU. Select the extracted executable, not the ZIP or its folder. Linux/macOS files also need execute permission.

[b]Export and playback have separate requirements[/b]
Delivery needs H.264 (libx264) and AAC encoding. In-editor playback additionally needs Theora and Vorbis. Missing playback codecs do not prevent delivery exports. A corrupt playback copy can be retried with another FFmpeg build without rendering the scene again.

[b]More details[/b]
The bundled platform guide has download links and Linux/macOS instructions. [b]Open setup logs[/b] provides the tool-check results.""",
"""[b]Choose a preset first[/b]
Draft · 2K is a quick test. Production · 4K captures more detail. Detail · 8K needs more time, memory and storage. These dimensions cover the entire sphere, so a viewer sees only part of those pixels at once.

[b]Capture detail and compression[/b]
Cube face size controls the detail captured by each of the six cameras. Increasing output width alone cannot recover detail that was never captured. H.264 quality (CRF) controls final compression: lower numbers retain more detail and make larger videos. Presets choose both values for you.

[b]Keep the project renderer by default[/b]
Overrides apply only to new captures. The support note below the graphics controls describes the selected combination. The Windows 1.0 target is Godot 4.5.1 / 4.6.3 / 4.7.2 Compatibility with OpenGL 3, plus 4.7.2 Forward+ / Mobile with Vulkan. Linux/macOS remain experimental. Other combinations are outside that launch matrix.

[b]Brightness and face edges[/b]
Fixed exposure preserves authored brightness values and animation while disabling automatic metering. Capture borders render extra context around each face and blend overlaps; they can soften some glow cuts, with extra rendering cost. Neither option fixes every view-dependent effect.

[b]Run another sample after changes[/b]
Check moving effects, edges and camera cuts in your actual scene. A passing setup check or supported combination does not guarantee seamless imagery or enough memory for every film.""",
"""[b]Keep the final film[/b]
[b]video-360.mp4[/b] is the verified delivery to share or watch. Keep its job folder and reports to reopen it in Godot; job.json identifies the export and report.json retains its technical checks.

[b]Keep source frames when you may revise the film[/b]
The original capture's [b]frames/[/b] folder contains lossless PNGs and its source WAV. Together with the capture records, these allow new compression or audio without rendering again. Re-encoded jobs still depend on that original capture for another re-encode. Attached soundtracks remain separate files; keep them available too.

[b]Before freeing space[/b]
Finish or cancel active jobs and stop playback preparation. Back up anything you may need. Removing source frames ends recovery and re-encoding from that capture. Partial captures cannot resume. Avoid moving original captures while dependent re-encodes still refer to their old paths.

[b]Playback copies can be rebuilt[/b]
The project's [b].godot360/playback/[/b] folder holds review copies and logs. With playback and preparation stopped, its contents can be removed manually; the original MP4 is needed to rebuild them. Other .godot360 files contain settings, history and diagnostics.

[b]History does not delete files[/b]
[b]Forget[/b] removes only a Recent exports entry. [b]Open saved job…[/b] locates an older or moved export. Each new render and re-encode uses a fresh folder.

[b]Plan enough working space[/b]
The sample estimates retained storage. Encoding, metadata copying and playback also need working space; the estimate is not a reservation. [b]Save diagnostics…[/b] makes a local report ZIP if you need help. Review it before sharing."""
]

var topics: OptionButton
var body: RichTextLabel
var setup_button: Button
var download_button: Button
var guide_button: Button
var guide_error: Label


func _ready() -> void:
	title = "Godot360 · Help"
	min_size = Vector2i(400, 280)
	get_ok_button().text = "Close"
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	topics = OptionButton.new()
	topics.fit_to_longest_item = false
	for heading in TITLES:
		topics.add_item(heading)
	column.add_child(topics)
	topics.item_selected.connect(_select_topic)
	body = RichTextLabel.new()
	body.bbcode_enabled = true
	body.selection_enabled = true
	body.focus_mode = Control.FOCUS_ALL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size = Vector2(0, 160)
	column.add_child(body)
	var actions := HFlowContainer.new()
	column.add_child(actions)
	setup_button = Button.new()
	setup_button.text = "Go to Tool setup"
	actions.add_child(setup_button)
	setup_button.pressed.connect(func():
		hide()
		setup_requested.emit())
	download_button = Button.new()
	download_button.text = "FFmpeg download page"
	download_button.tooltip_text = "Open installation choices in your browser. No file is downloaded by the addon."
	actions.add_child(download_button)
	download_button.pressed.connect(func():
		var url := "https://www.gyan.dev/ffmpeg/builds/" if OS.get_name() == "Windows" else "https://ffmpeg.org/download.html"
		if OS.shell_open(url) != OK:
			guide_error.text = "Could not open your browser. Open this address to find installation options: " + url
			guide_error.show())
	guide_button = Button.new()
	guide_button.text = "Open detailed guide externally"
	guide_button.tooltip_text = "Open the bundled Markdown reference in your default application."
	actions.add_child(guide_button)
	guide_button.pressed.connect(_open_guide)
	guide_error = Label.new()
	guide_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(guide_error)
	guide_error.hide()


func show_topic(topic: String) -> void:
	var index := TOPICS.find(topic)
	if index < 0:
		index = 0
	topics.select(index)
	_select_topic(index)
	popup_centered_clamped(Vector2i(720, 540), 0.9)
	topics.grab_focus()


func _select_topic(index: int) -> void:
	body.text = PAGES[index]
	body.scroll_to_line(0)
	setup_button.visible = TOPICS[index] == "setup"
	download_button.visible = setup_button.visible
	guide_error.hide()


func _open_guide() -> void:
	var path := ProjectSettings.globalize_path("res://addons/godot360/" + GUIDES[topics.selected])
	if OS.shell_open(path) != OK:
		guide_error.text = "Could not open the detailed guide. The instructions above work offline; the reference is at " + path
		guide_error.show()
