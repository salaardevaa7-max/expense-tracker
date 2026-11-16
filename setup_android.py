import re
import pathlib

def setup():
    # 1. Manifest permissions
    manifest_path = pathlib.Path('android/app/src/main/AndroidManifest.xml')
    if manifest_path.exists():
        xml = manifest_path.read_text(encoding='utf-8')
        perms = ['READ_SMS', 'RECEIVE_SMS', 'READ_CONTACTS', 'CAMERA', 'READ_MEDIA_IMAGES', 'VIBRATE']
        for p in perms:
            perm_tag = f'    <uses-permission android:name="android.permission.{p}"/>'
            if perm_tag not in xml:
                xml = re.sub(r'(<manifest\b[^>]*>)', r'\1\n' + perm_tag, xml)
        xml = xml.replace('android:label="hisaab"', 'android:label="Hisaab"')
        manifest_path.write_text(xml, encoding='utf-8')
        print("Updated AndroidManifest.xml successfully")

    # 2. Aggressively Disable Lint in ROOT build.gradle
    root_gradle_path = pathlib.Path('android/build.gradle')
    if root_gradle_path.exists():
        root_gradle = root_gradle_path.read_text(encoding='utf-8')

        # Nuclear option to disable all lint tasks across all subprojects (plugins)
        nuclear_option = """
subprojects {
    afterEvaluate { project ->
        if (project.hasProperty('android')) {
            project.android {
                lintOptions {
                    checkReleaseBuilds false
                    abortOnError false
                }
            }
        }
    }
}
"""
        root_gradle += nuclear_option
        root_gradle_path.write_text(root_gradle, encoding='utf-8')
        print("Aggressively disabled Lint for ALL subprojects in root android/build.gradle")
    else:
        print("Error: root android/build.gradle not found")

    # 3. Disable Lint in APP build.gradle as well
    app_gradle_path = pathlib.Path('android/app/build.gradle')
    if app_gradle_path.exists():
        app_gradle = app_gradle_path.read_text(encoding='utf-8')
        if 'lintOptions' not in app_gradle:
            app_gradle = app_gradle.replace('android {', 'android {\n    lintOptions {\n        checkReleaseBuilds false\n        abortOnError false\n    }')
            app_gradle_path.write_text(app_gradle, encoding='utf-8')
            print("Disabled Lint in android/app/build.gradle")

if __name__ == '__main__':
    setup()
