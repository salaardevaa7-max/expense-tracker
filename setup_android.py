import re
import pathlib

def setup():
    # 1. Manifest permissions
    manifest_path = pathlib.Path('android/app/src/main/AndroidManifest.xml')
    if manifest_path.exists():
        xml = manifest_path.read_text(encoding='utf-8')
        perms = ['READ_SMS', 'RECEIVE_SMS', 'READ_CONTACTS', 'CAMERA', 'READ_MEDIA_IMAGES', 'VIBRATE']

        # Insert permissions safely after the <manifest> tag
        for p in perms:
            perm_tag = f'    <uses-permission android:name="android.permission.{p}"/>'
            if perm_tag not in xml:
                # Find the <manifest ...> tag and insert after it
                xml = re.sub(r'(<manifest\b[^>]*>)', r'\1\n' + perm_tag, xml)

        # Fix label
        xml = xml.replace('android:label="hisaab"', 'android:label="Hisaab"')

        manifest_path.write_text(xml, encoding='utf-8')
        print("Updated AndroidManifest.xml successfully")
    else:
        print("Error: AndroidManifest.xml not found")

if __name__ == '__main__':
    setup()
