# Platform setup

The same `addons/godot360` folder works across desktop platforms; there are no
platform-specific addon binaries. Keep your scene's renderer and start
with [Godot 4.7.2 Standard](https://godotengine.org/download/archive/4.7.2-stable/).
You need native **FFmpeg and FFprobe** on each computer. A Windows `.exe` cannot
serve as a Linux or macOS tool. No Python, compiler, .NET runtime or Godot export
templates are required by the addon itself.

## Support status

| Platform | Status |
| --- | --- |
| Windows x86_64 | Compatibility baseline on 4.5.1/4.6.3/4.7.2; current Forward+/Mobile evidence and backend-specific limits are in [Renderers](RENDERERS.md). |
| Linux x86_64 | Ubuntu 26.04 under WSL2/WSLg, Godot 4.7.2, Mesa llvmpipe OpenGL/Vulkan and FFmpeg 8.0.1. See [current evidence](BETA.md) and [renderer limits](RENDERERS.md). |
| macOS, Apple Silicon and Intel | Prepared for testing: native paths, Homebrew discovery and installation guide. Native Mac export validation is pending. |

Validation on one machine does not cover every GPU or desktop environment.
Forward+ and Mobile have Windows Vulkan/D3D12 and Linux software-Vulkan visual
evidence; see [renderers and scene appearance](RENDERERS.md) for exact limits.
This is a desktop editor addon; web, mobile
and sandboxed editor distributions are outside this support scope.

## Windows

1. Download **Windows → Standard → x86_64** from the Godot archive above. Extract
   the ZIP and run the editor. No installer is needed for this Godot download.
2. Open [gyan.dev's Windows FFmpeg builds](https://www.gyan.dev/ffmpeg/builds/),
   a provider linked by [FFmpeg's official download page](https://ffmpeg.org/download.html).
   Choose **release builds → ffmpeg-release-essentials.zip**, then **Extract All**.
3. Keep the extracted folder somewhere permanent, such as your user folder's
   `Tools` directory. Its `bin` folder contains both `ffmpeg.exe` and `ffprobe.exe`.
4. In **Godot360 → Tool setup**, select **FFmpeg…** and choose `bin/ffmpeg.exe`.
   FFprobe is filled in when beside it; otherwise select `bin/ffprobe.exe` yourself.

Selecting the files is enough. Optionally add the extracted **bin directory** to
your user `Path`, restart Godot, and click **Find installed tools**. In a new
PowerShell window, `ffmpeg -version` and `ffprobe -version` should print versions.
The recorded Windows tests use FFmpeg/FFprobe **9.0.1 essentials**.

## Linux

1. Download **Linux → Standard → x86_64** from the Godot archive and extract it.
   On an ARM machine, choose arm64 instead; Linux ARM has not been validated here.
   Use the official standalone editor for the first test, so it can launch host
   tools and access your output folder.
2. If your file manager will not launch Godot, enable **Allow executing file as
   program** in its file properties, or run the following from the extracted folder:

   ```sh
   chmod +x ./Godot_v4.7.2-stable_linux.x86_64
   ./Godot_v4.7.2-stable_linux.x86_64 --editor
   ```

3. On Ubuntu or Debian, install FFmpeg and FFprobe together:

   ```sh
   sudo apt update
   sudo apt install ffmpeg
   ffmpeg -version
   ffprobe -version
   ```

   See the [Ubuntu FFmpeg package](https://packages.ubuntu.com/noble/ffmpeg) or
   [Debian FFmpeg package](https://packages.debian.org/stable/ffmpeg). On other
   distributions, use your distribution's package manager or a native build linked
   by [FFmpeg](https://ffmpeg.org/download.html). Codec availability can differ;
   **Check setup** tells you what your installed build is missing.
4. Reopen Godot, choose **Find installed tools**, then **Check setup**. Standard
   package installs normally resolve to `/usr/bin/ffmpeg` and `/usr/bin/ffprobe`.
   Use `command -v ffmpeg` and `command -v ffprobe` to locate custom installs, then
   select their absolute paths in the panel if needed.

Capture needs a working graphical session with OpenGL support. The coordinator is
headless, but its capture worker renders through a display. A headless-only server
cannot capture scenes without a suitable display/rendering setup. Linux filename
case matters: scene, script and asset references must match their filenames exactly.
Flatpak/Snap confinement can block host executables; use the official standalone
editor for this workflow instead of changing sandbox permissions blindly.

## macOS

1. Download **macOS → Standard → Universal** from the Godot archive. Extract the
   ZIP, drag `Godot.app` into **Applications**, and open it. The universal app
   includes Apple Silicon and Intel executables.
2. Install [Homebrew using its official guide](https://docs.brew.sh/Installation)
   if you do not already have it. Complete the installer's **Next steps** so a new
   Terminal window recognizes `brew`. Homebrew lists its own system requirements
   and Command Line Tools requirement; those belong to the package manager.
3. Install [Homebrew's FFmpeg package](https://formulae.brew.sh/formula/ffmpeg):

   ```sh
   brew install ffmpeg
   ffmpeg -version
   ffprobe -version
   ```

4. Open **Godot360 → Tool setup → Find installed tools**. Discovery checks PATH
   first, then the usual Homebrew locations: `/opt/homebrew/bin` on Apple Silicon
   and `/usr/local/bin` on Intel. This also works when Godot is opened from Finder
   with a different PATH from Terminal. Existing MacPorts installs in
   `/opt/local/bin` are searched too.
5. If discovery fails, run `command -v ffmpeg` and `command -v ffprobe` in Terminal
   and paste those full paths into the panel. Select the executables, not a folder
   or `.app` bundle. Choose a writable output folder and run **Check setup**.

Use **Cmd+S** to save scenes. For command-line review scripts, Godot's executable
is `/Applications/Godot.app/Contents/MacOS/Godot`; see the
[Godot command-line guide](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html).
If macOS blocks a downloaded application, verify its source and follow
[Apple's instructions for opening trusted apps](https://support.apple.com/en-us/102445).
The addon does not remove quarantine attributes or change system security settings.

## Finish setup on any platform

1. Import your `project.godot`, or create a project with **Compatibility**. To try
   this repository without Git, use **Code → Download ZIP**, extract it, and import
   its `project.godot`.
2. Copy `addons/godot360` into your project and enable **Godot360 Studio** under
   **Project > Project Settings > Plugins**. Open the **Godot360** bottom panel.
3. Locate FFmpeg/FFprobe as above. Paths are saved per project in the local
   `.godot360/settings.cfg`; reselect them after moving to another computer.
4. Choose an output folder and click **Check setup**. It checks tools and write
   access. FFmpeg must have **libx264**, **AAC**, `scale`, `colorspace`, and the
   selected audio filters. **Fast PNG** also needs the PNG encoder; use **Compact
   PNG** when it is unavailable. Execute bits alone do not prove a binary can run;
   this check also launches it.
5. Follow the [quick start](QUICKSTART.md), beginning with **Test 1 second**. Repeat
   setup and the short test after changing Godot, FFmpeg, GPU drivers or machines.

For full-video review, [download VLC for your platform](https://www.videolan.org/vlc/)
and follow VideoLAN's [360° playback guide](https://docs.videolan.me/vlc-user/desktop/3.0/en/advanced/player/360_video.html).
Open the final `video-360.mp4` through VLC's **File/Media → Open File** menu, then
drag with the left mouse button to look around. The editor preview is a still image.

## Troubleshooting

| Symptom | What to do |
| --- | --- |
| FFmpeg or FFprobe cannot be found | Select each executable by its absolute path. Both must be installed on this computer. |
| Linux/macOS reports permission denied | Check file properties and execute permission. Use a trusted native build; a binary on a `noexec` filesystem must be moved to an executable location. |
| Wrong executable format or CPU architecture | Replace the Windows/Linux/macOS or Intel/ARM binary with one for this machine. Run it in a terminal to see the system error. |
| A tool works in Terminal but not Godot | Restart Godot and choose **Find installed tools**, or paste the absolute path reported by `command -v`. |
| Missing encoders or filters | Select a build containing the capabilities named by **Check setup**. FFmpeg's source archive is not an executable package. |
| Output folder is not writable | Select a local folder you can write to and check free space. On macOS, check any system folder-access prompt. |
| Capture cannot open a display | Use a desktop session with a working native driver for the requested renderer. Inspect requested/actual selection and `capture.log`; see [renderer troubleshooting](RENDERERS.md#estimates-retained-captures-and-troubleshooting). |

Keep the failed job folder. **Save diagnostics…** produces a local ZIP for review;
the [beta report](BETA-REPORT.md) asks for OS, architecture, graphics and tool versions.
