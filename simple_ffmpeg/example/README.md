

## `ffmpeg_kit_flutter` Platform Support

The following table shows Android API level, iOS deployment target and macOS deployment target requirements in
`ffmpeg_kit_flutter` releases.

<table>
<thead>
<tr>
<th align="center" colspan="3">Main Release</th>
<th align="center" colspan="3">LTS Release</th>
</tr>
<tr>
<th align="center">Android<br>API Level</th>
<th align="center">iOS Minimum<br>Deployment Target</th>
<th align="center">macOS Minimum<br>Deployment Target</th>
<th align="center">Android<br>API Level</th>
<th align="center">iOS Minimum<br>Deployment Target</th>
<th align="center">macOS Minimum<br>Deployment Target</th>
</tr>
</thead>
<tbody>
<tr>
<td align="center">24</td>
<td align="center">12.1</td>
<td align="center">10.15</td>
<td align="center">16</td>
<td align="center">10</td>
<td align="center">10.12</td>
</tr>
</tbody>
</table>

```
┌─ Flutter Fix ───────────────────────────────────────────────────────────────────────────────────────────────────┐
│ The plugin ffmpeg_kit_flutter requires a higher Android SDK version.                                            │
│ Fix this issue by adding the following to the file                                                              │
│ /Users/mac/repo/twosun/packages/simple_ffmpeg/example/android/app/build.gradle:                                 │
│ android {                                                                                                       │
│   defaultConfig {                                                                                               │
│     minSdkVersion 24                                                                                            │
│   }                                                                                                             │
│ }                                                                                                               │
│                                                                                                                 │
│                                                                                                                 │
│ Following this change, your app will not be available to users running Android SDKs below 24.                   │
│ Consider searching for a version of this plugin that supports these lower versions of the Android SDK instead.  │
│ For more information, see: https://docs.flutter.dev/deployment/android#reviewing-the-gradle-build-configuration │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```


## ./example `image_gallery_saver` Platform Support

```yaml
dependencies:
  image_gallery_saver: '^2.0.3'
```

## iOS
Your project need create with swift.
Add the following keys to your Info.plist file, located in <project root>/ios/Runner/Info.plist:
 * NSPhotoLibraryAddUsageDescription - describe why your app needs permission for the photo library. This is called Privacy - Photo Library Additions Usage Description in the visual editor
 
 ##  Android
 You need to ask for storage permission to save an image to the gallery. You can handle the storage permission using [flutter_permission_handler](https://github.com/BaseflowIT/flutter-permission-handler).
 In Android version 10, Open the manifest file and add this line to your application tag
 ```
 <application android:requestLegacyExternalStorage="true" .....>
 ```