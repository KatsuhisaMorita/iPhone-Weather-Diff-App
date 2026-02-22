# iPhone Weather Diff App

A Swift application that calculates and displays weather differences (temperature, precipitation, etc.) to help users decide what to wear.

## Features
- Displays current weather and forecast
- Highlights temperature and precipitation differences
- Provides clothing recommendations

## Setup
1. Clone the repository
2. Open `swift/WeatherDiffApp/WeatherDiffApp.xcodeproj` in Xcode
3. Build and run on your target device

## Fastlane & GitHub Actions
This project includes a `.github/workflows/ios-build.yml` file to automate builds and deployments.

## Troubleshooting Tips
- **AppIcon Build Errors**: Ensure the `AppIcon.appiconset` contains an image exactly `1024x1024` pixels.
- **GitHub Actions Node Modules Error**: If you have a separate Node.js project for API tests, ensure `node_modules/` is added to `.gitignore`. If already accidentally tracked by git, remove it with `git rm -r --cached node_modules/`.
