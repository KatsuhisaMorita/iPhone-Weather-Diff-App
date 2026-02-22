import os

target_dir = r"c:\work\AIDLC\iPhone-weather-diff-app\swift"
old_name = "MahjongScoreApp"
new_name = "WeatherDiffApp"
old_app_name = "majong.scorememo"
new_app_name = "aiteam.weatherdiff"

# 1. Rename files and folders
for root, dirs, files in os.walk(target_dir, topdown=False):
    for name in files:
        if old_name in name:
            os.rename(os.path.join(root, name), os.path.join(root, name.replace(old_name, new_name)))
    for name in dirs:
        if old_name in name:
            os.rename(os.path.join(root, name), os.path.join(root, name.replace(old_name, new_name)))

# 2. String replacement in files
for root, dirs, files in os.walk(target_dir):
    for name in files:
        file_path = os.path.join(root, name)
        # only process text files, skip binary like .xcassets
        if not name.endswith((".swift", ".pbxproj", ".plist", ".md")): continue
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
            # replace name and bundle id
            content = content.replace(old_name, new_name)
            content = content.replace(old_app_name, new_app_name)
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(content)
        except Exception as e:
            print(f"Failed to process {file_path}: {e}")

# 3. Clean up Mahjong specific files
to_remove = [
    "Models/Player.swift",
    "Models/GameRecord.swift",
    "Models/DailySession.swift",
    "Models/RuleSettings.swift",
    "Logic/ScoreCalculator.swift",
    "Views/DailySessionView.swift",
    "Views/GameInputView.swift",
    "Views/PlayersListView.swift",
    "Views/SettingsView.swift",
    "Views/SessionStartView.swift",
    "Views/SessionChipInputView.swift"
]

for rel_path in to_remove:
    path = os.path.join(target_dir, new_name, rel_path.replace("/", "\\"))
    if os.path.exists(path):
        os.remove(path)
        print(f"Removed {path}")

# Now we need to remove the references from the pbxproj file
pbxproj_path = os.path.join(target_dir, f"{new_name}.xcodeproj", "project.pbxproj")
try:
    with open(pbxproj_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    
    with open(pbxproj_path, "w", encoding="utf-8") as f:
        for line in lines:
            # If the line mentions any of the removed files, skip it
            skip = False
            for rm in to_remove:
                if rm.split("/")[-1] in line:
                    skip = True
                    break
            if not skip:
                f.write(line)
except Exception as e:
    print(f"Failed to update pbxproj: {e}")
