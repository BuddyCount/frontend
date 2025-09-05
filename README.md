# BuddyCount Frontend

A modern, offline-first Flutter application for managing shared expenses and budgets within groups. Built with a focus on user experience, data persistence, and offline functionality.

## 🚀 Features

### Core Functionality
- **Group Management**: Create, join, and manage expense groups
- **Expense Tracking**: Add, edit, and delete expenses with detailed information
- **Balance Calculation**: Automatic calculation of balances and splits
- **Multi-Currency Support**: Support for USD, EUR, and CHF
- **Offline-First**: Works seamlessly without internet connection
- **Data Persistence**: Local storage using Hive database

### User Experience
- **Intuitive Interface**: Clean, Material Design 3 UI
- **Responsive Design**: Optimized for both mobile and tablet
- **Swipe Gestures**: Swipe to delete expenses
- **Real-time Updates**: Instant UI updates with Provider state management
- **Confirmation Dialogs**: Safe deletion with user confirmation

### Technical Features
- **State Management**: Provider pattern for efficient state handling
- **Local Storage**: Hive database for offline data persistence
- **Async Operations**: Proper handling of asynchronous storage operations
- **Error Handling**: Comprehensive error handling and user feedback
- **Hot Reload Support**: Full support for Flutter hot reload and restart

## 🛠️ Tech Stack

- **Framework**: Flutter 3.35.2
- **Language**: Dart
- **State Management**: Provider
- **Local Database**: Hive
- **UI Framework**: Material Design 3
- **Platforms**: iOS, Android, Web (planned)


## 📋 Prerequisites

- Flutter SDK (3.35.2 or higher)
- Dart SDK (3.0.0 or higher)
- iOS Simulator (for iOS development)
- Android Emulator or device (for Android development)
- CocoaPods (for iOS development)

## 🚀 Installation

1. **Clone the repository**
   ```bash
   git clone git@github.com:BuddyCount/frontend.git
   cd buddycount-frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters** (if models change)
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   # iOS Simulator (must be on Macos with Xcode installed)
   flutter emulators --launch apple_ios_simulator
   flutter run -d "iPhone 16 Plus"
   
   # Android Emulator
   flutter run -d android
   
   # Web
   flutter run -d chrome
   ```

## 🚀 CI/CD & Automation

### GitHub Actions Workflows

The project uses GitHub Actions for continuous integration and deployment:

#### **Flutter Tests** (`.github/workflows/flutter_tests.yml`)
- **Triggers**: Push to main/CI-integration branches, pull requests
- **Actions**:
  - Code formatting with `dart format`
  - Static analysis with `flutter analyze`
  - Unit tests with `flutter test`
  - Generates test reports

#### **Badge Generation** (`.github/workflows/simple_badges.yml`)
- **Triggers**: After Flutter Tests workflow completes
- **Actions**:
  - Generates SVG badges for test/build status
  - Commits badges to repository
  - Updates automatically on each workflow run

### Badge Generation

Badges are automatically generated and committed to the `badges/` directory:
- `test-status.svg` - Current test status
- `build-status.svg` - Current build status

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── group.dart           # Group entity
│   ├── expense.dart         # Expense entity
│   ├── person.dart          # Person entity
│   └── *.g.dart            # Generated Hive adapters
├── providers/               # State management
│   └── group_provider.dart  # Main app state provider
├── screens/                 # UI screens
│   ├── groups_overview_screen.dart    # Groups list
│   ├── group_detail_screen.dart       # Group details
│   ├── add_expense_screen.dart        # Add expense form
│   └── home_screen.dart               # Legacy home screen
│   └── expense_detail_screen.dart      # Expense detail screen
├── services/                # Business logic
│   ├── local_storage_service.dart     # Hive database operations
│   ├── api_service.dart               # Backend API communication
│   └── sync_service.dart              # Offline sync logic
│   ├── auth_service.dart              # Authentication service
│   ├── image_service.dart             # Image upload service
│   ├── device_id_service.dart         # Device ID service
│   └── api_service.dart               # Backend API communication
└── widgets/                 # Reusable UI components
    └── group_dialog.dart    # Group creation/join dialog

## 🎯 Usage

### Creating a Group
1. Tap the "+" button on the groups overview screen
2. Choose "Create Group"
3. Enter group name and add members
4. Confirm creation

### Adding Expenses
1. Navigate to a group's detail screen
2. Tap the "+" floating action button
3. Fill in expense details (name, amount, currency, payer, split)
4. Save the expense

### Managing Groups
- **View Groups**: See all your groups on the overview screen
- **Group Details**: Tap a group to see expenses and balances
- **Delete Groups**: Use the delete button (🗑️) on group cards
- **Delete Expenses**: Swipe left on expense tiles to delete

### Offline Usage
- The app works completely offline
- All data is stored locally using Hive
- Changes sync automatically when online
- Manual refresh available via refresh button

## 🔧 Development

### Adding New Features
1. Create new issue and corresponding feature branch
2. Implement changes
3. Test thoroughly
4. Commit changes and push to feature branch
5. Create pull request to `main`

### Code Style
- Follow Flutter/Dart conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Ensure proper error handling

### Testing
- Test on iOS, Android and Web
- Verify offline functionality
- Check data persistence
- Test edge cases and error scenarios

## 📊 Data Models

### Group
- `id`: Unique identifier
- `name`: Group name
- `members`: List of Person objects
- `expenses`: List of Expense objects
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp

### Expense
- `id`: Unique identifier
- `name`: Expense description
- `amount`: Cost amount
- `currency`: Currency code (USD/EUR/CHF)
- `paidBy`: Person ID who paid
- `splitBetween`: List of Person IDs to split with
- `date`: Expense date
- `groupId`: Associated group ID

### Person
- `id`: Unique identifier
- `name`: Person's name
- `balance`: Current balance in the group

## 🚨 Known Issues

- Hot restart may occasionally lose data (mitigated with refresh button)
- Some deprecated Flutter APIs are used (will be updated in future versions)

## 🔮 Future Enhancements


- [ ] Real-time collaboration
- [ ] Export functionality
- [ ] Advanced analytics
- [ ] Push notifications


## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is part of the HEIG-VD BA5 PDG course. All rights reserved.

## 👥 Team

- **Frontend Development**: [Sergey Komarov]
- **Backend Development**: [Aude Laydu, Arthur Jacobs]


## 📞 Support

For questions or issues:
- Create an issue in the repository
- Contact the development team
- Check the project documentation

