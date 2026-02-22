import os
import uuid

target_dir = r"c:\work\AIDLC\iPhone-weather-diff-app\swift\WeatherDiffApp"
pbxproj_path = r"c:\work\AIDLC\iPhone-weather-diff-app\swift\WeatherDiffApp.xcodeproj\project.pbxproj"

new_files = [("WeatherModels.swift", "Models"), ("WeatherService.swift", "Logic")]


# Quick way to generate fake UUID for pbxproj format (24 hex chars uppercase)
def generate_pbx_uuid():
    return uuid.uuid4().hex[:24].upper()


try:
    with open(pbxproj_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Find the sections and insert
    # This is a bit fragile but works for our simple project copy
    for fname, group in new_files:
        if fname in content:
            continue  # Already added

        file_ref_id = generate_pbx_uuid()
        build_file_id = generate_pbx_uuid()

        # 1. PBXBuildFile
        build_str = f"/* Begin PBXBuildFile section */\n\t\t{build_file_id} /* {group}/{fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {fname} */; }};"
        content = content.replace("/* Begin PBXBuildFile section */", build_str)

        # 2. PBXFileReference
        ref_str = f'/* Begin PBXFileReference section */\n\t\t{file_ref_id} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {fname}; sourceTree = "<group>"; }};'
        content = content.replace("/* Begin PBXFileReference section */", ref_str)

        # 3. PBXGroup
        group_search = f"/* {group} */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = ("
        group_insert = f"{group_search}\n\t\t\t\t{file_ref_id} /* {fname} */,"
        content = content.replace(group_search, group_insert)

        # 4. PBXSourcesBuildPhase
        sources_search = "/* Sources */ = {\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = ("
        sources_insert = f"{sources_search}\n\t\t\t\t{build_file_id} /* {group}/{fname} in Sources */,"
        content = content.replace(sources_search, sources_insert)

    with open(pbxproj_path, "w", encoding="utf-8") as f:
        f.write(content)

    print("Successfully patched pbxproj!")
except Exception as e:
    print(f"Failed to patch pbxproj: {e}")
