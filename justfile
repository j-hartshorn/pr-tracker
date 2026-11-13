swift_format_config := '{"version":1,"indentation":{"spaces":4},"lineLength":120}'
swift_paths := "Sources Tests Package.swift"
app_bundle := "build/gh-tracker.app"
install_app := "/Applications/PR Tracker.app"

default:
    @just --list

# Format Swift source files in place
format:
    swift format format --in-place --parallel --configuration '{{ swift_format_config }}' --recursive {{ swift_paths }}

# Lint Swift source files
lint *args:
    swift format lint --parallel --configuration '{{ swift_format_config }}' --recursive {{ args }} {{ swift_paths }}

# Run unit tests
test *args:
    ./scripts/check.sh {{ args }}

# Run unit and live GitHub API tests
test-live *args:
    GH_TRACKER_LIVE=1 ./scripts/check.sh {{ args }}

# Build the signed app bundle (release by default, or debug)
build config="release":
    ./scripts/bundle.sh {{ config }}

# Build and launch the local app bundle (replaces any running local instance)
run config="release": (build config)
    -pkill -f "gh-tracker.app/Contents/MacOS/GHTracker"
    open "{{ app_bundle }}"

# Bring the local app window to the front
open:
    open "{{ app_bundle }}"

# Build release bundle and install to /Applications
install: (build "release")
    -pkill -f "Contents/MacOS/GHTracker"
    rm -rf "{{ install_app }}"
    ditto "{{ app_bundle }}" "{{ install_app }}"

# Render all preview views to build/previews
previews:
    swift run Previews

# Show recent app logs
logs last="5m":
    log show --last {{ last }} --info --predicate 'subsystem == "local.gh-tracker"'

# Remove build artefacts
clean:
    swift package clean
    rm -rf build
