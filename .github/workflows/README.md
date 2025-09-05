# GitHub Actions Workflows

This directory contains GitHub Actions workflows for the BuddyCount Flutter frontend.

## Available Workflows

### 1. `build_web_simple.yml` - Simple Web Build
**Recommended for most use cases**

- **Triggers**: Push to main, PRs to main, manual dispatch
- **Purpose**: Builds the Flutter web app in release mode
- **Features**:
  - Flutter dependency caching
  - Simple build process
  - Uploads build artifacts for 7 days

### 2. `build_web.yml` - Standard Web Build
**Good balance of features and simplicity**

- **Triggers**: Push to main/develop, PRs to main/develop, manual dispatch
- **Purpose**: Builds the Flutter web app with additional features
- **Features**:
  - Flutter dependency caching
  - Build verification and summary
  - Uploads build artifacts for 30 days
  - Detailed build information

### 3. `build_web_advanced.yml` - Advanced Web Build
**For complex deployment scenarios**

- **Triggers**: Push to main/develop, tags, PRs, manual dispatch with options
- **Purpose**: Comprehensive web build with testing and deployment packages
- **Features**:
  - Multiple build modes (release, profile, debug)
  - Multiple web renderers (html, canvaskit)
  - Flutter analyze and tests
  - Build validation
  - Deployment package creation
  - Uploads artifacts for 30 days

### 4. `flutter_tests.yml` - Testing
**Runs tests and analysis**

- **Triggers**: Push to main, PRs to main
- **Purpose**: Runs Flutter tests and code analysis
- **Features**:
  - Flutter tests
  - Code analysis
  - Format checking

## Usage

### Automatic Builds
- Push to `main` branch → Triggers web build
- Create PR to `main` → Triggers web build
- Push tags starting with `v` → Triggers advanced web build

### Manual Builds
1. Go to the "Actions" tab in your GitHub repository
2. Select the workflow you want to run
3. Click "Run workflow"
4. Choose the branch and options (for advanced workflow)
5. Click "Run workflow"

### Downloading Build Artifacts
1. Go to the "Actions" tab
2. Click on a completed workflow run
3. Scroll down to "Artifacts" section
4. Download the build artifacts
5. Extract and deploy to your web server

## Build Artifacts

### Simple/Standard Workflows
- `web-build` or `flutter-web-build`: Contains the built web app files
- Location: `build/web/` directory
- Files: `index.html`, `main.dart.js`, `flutter.js`, assets, etc.

### Advanced Workflow
- `flutter-web-build-*`: Raw build files
- `flutter-web-deployment-package`: Ready-to-deploy package with README

## Deployment

### Basic Deployment
1. Download the build artifacts
2. Upload all files to your web server
3. Configure your web server to serve `index.html` for all routes (SPA routing)

### Web Server Configuration
For proper SPA routing, configure your web server to:
- Serve `index.html` for all routes that don't match existing files
- Set proper MIME types for `.js` files
- Enable HTTPS for PWA functionality

### Example Nginx Configuration
```nginx
location / {
    try_files $uri $uri/ /index.html;
}

location ~* \.js$ {
    add_header Content-Type application/javascript;
}
```

## Troubleshooting

### Build Failures
- Check the workflow logs for specific error messages
- Ensure all dependencies are properly declared in `pubspec.yaml`
- Verify Flutter version compatibility

### Web App Issues
- Check browser console for JavaScript errors
- Verify web server configuration for SPA routing
- Ensure HTTPS is enabled for PWA features

### Performance
- Use the `html` web renderer for better compatibility
- Use the `canvaskit` web renderer for better performance
- Consider using the `profile` build mode for testing
