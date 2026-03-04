# TopgradeX Assets

## App icon (Dock & Finder)

Add your TopgradeX logo to **AppIcon.appiconset** in these sizes:

| Size    | Scale | Filename (example) |
|---------|-------|--------------------|
| 16×16   | 1x, 2x | icon_16.png, icon_32.png |
| 32×32   | 1x, 2x | icon_32.png, icon_64.png |
| 128×128 | 1x, 2x | icon_128.png, icon_256.png |
| 256×256 | 1x, 2x | icon_256.png, icon_512.png |
| 512×512 | 1x, 2x | icon_512.png, icon_1024.png |

In Xcode: open **Assets.xcassets** → **AppIcon** → drag each image onto the correct slot, or add image files to the `AppIcon.appiconset` folder and reference them in `Contents.json`.

## Logo (in-app, e.g. onboarding)

Add the same (or a single) logo image to **Logo.imageset**:

- **Logo.imageset/**  
  - 1x: one image (e.g. logo.png)  
  - 2x: optional @2x version for retina  

Used in the onboarding welcome screen. If no image is added, that area will appear empty until you add one.

## Menu bar icon (later)

To use a custom template image in the menu bar instead of the system symbol, add a template image (e.g. **MenubarIcon.imageset**) and switch `TopgradeXApp.swift` from `systemImage: "arrow.triangle.2.circlepath"` to `image: Image("MenubarIcon")`. Use a single-color template image so it adapts to light/dark menu bar.
