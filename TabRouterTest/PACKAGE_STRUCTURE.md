# UIRouter Swift Package Structure Guide

This guide documents the required file organization for the UIRouter Swift Package.

## ⚠️ Action Required

Your project currently has files in the root directory, but Swift Package Manager expects them in `Sources/UIRouter/`. Follow the instructions below to complete the package setup.

## Current Status

| Component | Status | Action Needed |
|-----------|--------|---------------|
| Package.swift | ✅ Fixed | None - now uses correct structure |
| README.md | ✅ Updated | None |
| Core Files | ⚠️ Wrong Location | Move to Sources/UIRouter/ |
| Test Files | ⚠️ Missing Directory | Create Tests/UIRouterTests/ |
| LICENSE | ⚠️ Missing | Add LICENSE file |
| .gitignore | ⚠️ Missing | Add .gitignore file |

## Target Directory Structure

```
UIRouter/
├── Package.swift                    # ✅ Fixed - Swift Package manifest
├── README.md                        # ✅ Updated - Package documentation
├── PACKAGE_README.md                # 📝 Archive file
├── PACKAGE_STRUCTURE.md             # 📝 This guide
├── LICENSE                          # ⚠️ ADD - License file
├── .gitignore                       # ⚠️ ADD - Git ignore rules
│
├── Sources/
│   └── UIRouter/                    # ⚠️ CREATE THIS DIRECTORY
│       ├── UIRouter.swift           # ⚠️ MOVE HERE from root
│       ├── UIRoute.swift            # ⚠️ MOVE HERE from root
│       ├── RouterView.swift         # ⚠️ MOVE HERE from root
│       └── TabRouterView.swift      # ⚠️ MOVE HERE from root
│
├── Tests/
│   └── UIRouterTests/               # ⚠️ CREATE THIS DIRECTORY
│       └── UIRouterTests.swift      # Add test file here
│
└── Examples/                        # ⚠️ CREATE (Optional)
    ├── AppRoute.swift               # Move example files here
    ├── TabExampleView.swift         # Move example files here
    └── (other example files)
```

## Quick Setup Commands

Run these commands in your project root directory:

```bash
# 1. Create required directories
mkdir -p Sources/UIRouter
mkdir -p Tests/UIRouterTests
mkdir -p Examples

# 2. Move core library files to Sources/UIRouter/
mv UIRouter.swift Sources/UIRouter/
mv UIRoute.swift Sources/UIRouter/
mv RouterView.swift Sources/UIRouter/
mv TabRouterView.swift Sources/UIRouter/

# 3. Move example files to Examples/ (optional)
mv AppRoute.swift Examples/ 2>/dev/null || true
mv TabExampleView.swift Examples/ 2>/dev/null || true
mv TabRouterTestApp.swift Examples/ 2>/dev/null || true
mv ContentView.swift Examples/ 2>/dev/null || true

# 4. Create .gitignore
cat > .gitignore << 'EOF'
# Swift Package Manager
.build/
.swiftpm/
Package.resolved

# Xcode
*.xcodeproj
*.xcworkspace
xcuserdata/
DerivedData/
*.xcuserdatad

# macOS
.DS_Store

# Swift
*.swiftmodule
*.swiftdoc
EOF

# 5. Verify structure
swift package describe

# 6. Build and test
swift build
swift test
```

## Understanding the Error

The error you saw:

```
error: No such module 'PackageDescription'
```

Was caused by an incorrect `path` parameter in Package.swift. The original configuration:

```swift
.target(
    name: "UIRouter",
    dependencies: [],
    path: "UIRouter"  // ❌ This was wrong
)
```

Swift Package Manager looks for `Sources/UIRouter/` by default. When you specify a custom path like `path: "UIRouter"`, it tries to find a directory called `UIRouter/` at the root, which doesn't exist in the standard Swift Package structure.

The fix (already applied):

```swift
.target(
    name: "UIRouter",
    dependencies: []  // ✅ No path parameter - uses default Sources/UIRouter/
)
```

## File Organization Details

### Core Package Files (Sources/UIRouter/)

These files comprise the distributable UIRouter library:

| File | Status | Description |
|------|--------|-------------|
| `UIRouter.swift` | ⚠️ Move | Core router class with navigation logic |
| `UIRoute.swift` | ⚠️ Move | Route protocol and type definitions |
| `RouterView.swift` | ⚠️ Move | Simple navigation container view |
| `TabRouterView.swift` | ⚠️ Move | Tab-based navigation container |

### Test Files (Tests/UIRouterTests/)

| File | Status | Description |
|------|--------|-------------|
| `UIRouterTests.swift` | ⚠️ Create | Unit tests for the package |

### Example Files (Examples/)

These files are for demonstration purposes and are **not** included in the distributed package:

| File | Purpose |
|------|---------|
| `AppRoute.swift` | Example route enum implementation |
| `TabExampleView.swift` | Example tab-based app |
| `TabRouterTestApp.swift` | Example app for testing |
| `ContentView.swift` | Example simple navigation |

### Package Configuration Files

| File | Status | Description |
|------|--------|-------------|
| `Package.swift` | ✅ Fixed | Swift Package Manager manifest |
| `README.md` | ✅ Updated | Main package documentation |
| `LICENSE` | ⚠️ Add | License file (MIT, Apache, etc.) |
| `.gitignore` | ⚠️ Add | Git ignore rules |

## Package Structure Rules

### ✅ Do Include in Sources/UIRouter/
- Core routing logic
- Public APIs and protocols
- SwiftUI views that are part of the API
- Type definitions used by consumers

### ❌ Do NOT Include in Sources/UIRouter/
- Example implementations
- Demo apps
- App-specific route definitions
- Test files (these go in Tests/)

### 📦 Package Distribution
When users add UIRouter as a dependency, they only get:
- The compiled module from `Sources/UIRouter/`
- Public APIs and types
- No example files or tests

## Required Files to Add

### .gitignore

Create a `.gitignore` file in the root directory (or use the command above):

```gitignore
# Swift Package Manager
.build/
.swiftpm/
Package.resolved

# Xcode
*.xcodeproj
*.xcworkspace
xcuserdata/
DerivedData/
*.xcuserdatad

# macOS
.DS_Store

# Swift
*.swiftmodule
*.swiftdoc
```

### LICENSE

Add a LICENSE file to specify how others can use your package. Common choices:

**MIT License** (permissive):
```
MIT License

Copyright (c) 2024 Joon Jang

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

**Apache License 2.0** (permissive with patent grant):
```
Apache License
Version 2.0, January 2004
http://www.apache.org/licenses/

[Full text available at: https://www.apache.org/licenses/LICENSE-2.0.txt]
```

Choose one and create a `LICENSE` file in the root directory.

## Verifying Package Structure

After organizing your files, verify the package is properly structured:

### Build and Test

```bash
# Build the package
swift build

# Run tests
swift test

# Build in release mode
swift build -c release
```

### Generate Xcode Project (Optional)

```bash
# For development in Xcode - opens Package.swift directly
open Package.swift

# Or generate an Xcode project (older method)
swift package generate-xcodeproj
```

### Validate Package

```bash
# Check package structure
swift package describe

# Show resolved dependencies
swift package show-dependencies

# Update dependencies
swift package update

# Clean build artifacts
swift package clean
```

## Publishing Your Package

### 1. Initialize Git Repository

```bash
git init
git add .
git commit -m "Initial commit - UIRouter v1.0.0"
```

### 2. Create Remote Repository

1. Create a new repository on GitHub/GitLab/Bitbucket
2. Do NOT initialize with README (you already have one)
3. Copy the repository URL

### 3. Push to Remote

```bash
git remote add origin https://github.com/yourusername/UIRouter.git
git branch -M main
git push -u origin main
```

### 4. Tag Version

```bash
# Create a semantic version tag
git tag 1.0.0
git push origin 1.0.0

# Or with annotation
git tag -a 1.0.0 -m "UIRouter v1.0.0 - Initial release"
git push origin 1.0.0
```

### 5. Update README with Repository URL

Update the repository URL in README.md to match your actual repository:
```swift
.package(url: "https://github.com/yourusername/UIRouter.git", from: "1.0.0")
```

## Using UIRouter in Other Projects

Once published, others can use UIRouter as a dependency:

### Adding to Package.swift

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    dependencies: [
        // Add UIRouter as a dependency
        .package(url: "https://github.com/yourusername/UIRouter.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: ["UIRouter"]
        )
    ]
)
```

### Adding to Xcode Project

1. Open your Xcode project
2. Select **File → Add Package Dependencies...**
3. Enter repository URL: `https://github.com/yourusername/UIRouter.git`
4. Choose dependency rule (e.g., "Up to Next Major Version" from 1.0.0)
5. Select the target(s) to add the package to
6. Click **Add Package**

### Using in Your Code

```swift
import UIRouter
import SwiftUI

// Define your routes
enum AppRoute: UIRoute {
    case home
    case detail(id: String)
    case settings
    
    func view() -> AnyView {
        switch self {
        case .home:
            return AnyView(HomeView())
        case .detail(let id):
            return AnyView(DetailView(id: id))
        case .settings:
            return AnyView(SettingsView())
        }
    }
}

// Use in your app
@main
struct YourApp: App {
    var body: some Scene {
        WindowGroup {
            RouterView {
                HomeView()
            }
        }
    }
}

// Navigate in your views
struct HomeView: View {
    @EnvironmentObject private var router: UIRouter
    
    var body: some View {
        Button("Go to Detail") {
            router.push(AppRoute.detail(id: "123"))
        }
    }
}
```

## Package Development Tips

### Local Package Development

Test your package locally before publishing:

```bash
# In the UIRouter directory
swift build
swift test

# Use it in another local project
# In your app's Package.swift:
dependencies: [
    .package(path: "../UIRouter")  // Relative path to local package
]
```

### Versioning Strategy

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** version (1.0.0 → 2.0.0): Breaking API changes
- **MINOR** version (1.0.0 → 1.1.0): New features, backward compatible
- **PATCH** version (1.0.0 → 1.0.1): Bug fixes, backward compatible

### Creating New Releases

```bash
# Make your changes
git add .
git commit -m "Add new feature"
git push

# Create a new version tag
git tag 1.1.0 -m "Version 1.1.0 - Add new navigation features"
git push origin 1.1.0
```

### Documentation

Keep your documentation up to date:
- Update README.md for any API changes
- Add inline documentation comments (`/// Description`)
- Consider adding DocC documentation
- Update CHANGELOG.md for each release

## Common Issues and Solutions

### Issue: "No such module 'PackageDescription'"

**Cause:** Incorrect path configuration in Package.swift

**Solution:** Remove custom `path` parameter from target definition. Swift Package Manager expects files in `Sources/ModuleName/` by default.

### Issue: "Module 'UIRouter' not found"

**Cause:** Files are not in the correct directory

**Solution:** Ensure all source files are in `Sources/UIRouter/`

### Issue: "Cannot find type 'UIRoute' in scope"

**Cause:** Files haven't been moved to Sources directory yet

**Solution:** Run the move commands listed in "Quick Setup Commands" above

### Issue: Build succeeds but tests fail

**Cause:** Test files are not in `Tests/UIRouterTests/`

**Solution:** Create the test directory and add test files

## Summary

### Key Points

✅ **Sources/UIRouter/** - Distributable library code (public API)  
✅ **Tests/UIRouterTests/** - Unit tests for the package  
✅ **Examples/** - Demo code (not distributed with package)  
✅ **Package.swift** - Package manifest (fixed to use standard structure)  
✅ **README.md** - Main documentation for users  
⚠️ **LICENSE** - Required for open source distribution  
⚠️ **.gitignore** - Recommended for version control  

### Publishing Checklist

Before publishing your package, ensure:

- [ ] All core files are moved to `Sources/UIRouter/`
- [ ] Tests are in `Tests/UIRouterTests/`
- [ ] `swift build` completes successfully
- [ ] `swift test` passes all tests
- [ ] README.md is complete and accurate
- [ ] LICENSE file is added
- [ ] .gitignore is configured
- [ ] Git repository is initialized
- [ ] Code is pushed to remote repository
- [ ] Version tag is created (e.g., 1.0.0)
- [ ] Repository URL is updated in documentation

## Next Steps

1. ⚠️ **Run the "Quick Setup Commands" from above** to organize files
2. ⚠️ Add LICENSE file
3. ⚠️ Add .gitignore file
4. ⚠️ Test with `swift build` and `swift test`
5. ⚠️ Create Git repository
6. ⚠️ Push to remote (GitHub/GitLab)
7. ⚠️ Tag version (e.g., v1.0.0)
8. ⚠️ Update repository URLs in documentation
9. ✅ Package is ready to share!

## Additional Resources

- [Swift Package Manager Documentation](https://swift.org/package-manager/)
- [Semantic Versioning](https://semver.org/)
- [Choosing a License](https://choosealicense.com/)
- [Swift Package Index](https://swiftpackageindex.com/) - Submit your package here
- [Apple's Swift Package Guide](https://developer.apple.com/documentation/xcode/creating_a_standalone_swift_package_with_xcode)

---

**UIRouter Package Structure Guide**  
Last Updated: December 2024  
For questions or issues, see README.md or open an issue on GitHub.
