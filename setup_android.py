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
                xml = xml.replace('<manifest', '<manifest\n' + perm_tag)
        xml = xml.replace('android:label="hisaab"', 'android:label="Hisaab"')
        manifest_path.write_text(xml, encoding='utf-8')
        print("Updated AndroidManifest.xml")

    # 2. Disable Lint in build.gradle
    gradle_path = pathlib.Path('android/app/build.gradle')
    if gradle_path.exists():
        gradle = gradle_path.read_text(encoding='utf-8')
        lint_config = """
    lintOptions {
        abortOnError false
        checkReleaseBuilds false
    }
"""
        if 'lintOptions' not in gradle and 'android {' in gradle:
            gradle = gradle.replace('android {', 'android {' + lint_config)
            gradle_path.write_text(gradle, encoding='utf-8')
            print("Disabled Lint in android/app/build.gradle")

if __name__ == '__main__':
    setup()
