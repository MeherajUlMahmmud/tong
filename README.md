# টং (Tong) - Expense Tracking App

A modern, feature-rich expense tracking application built with Flutter and Firebase. Track your daily expenses, manage categories, analyze spending patterns, and stay within budget.

## 🚀 Features

### Core Features
- **Daily Expense Tracking**: Easily track expenses by category with increment/decrement counters
- **Category Management**: Create, edit, and delete expense categories with custom prices
- **User Authentication**: Secure Google Sign-in integration
- **Data Persistence**: Cloud Firestore for data storage with offline support

### New & Improved Features

#### 🎨 Enhanced User Experience
- **Modern UI/UX**: Material Design 3 with beautiful animations and smooth transitions
- **Dark/Light Theme**: Toggle between dark and light themes with persistent settings
- **Responsive Design**: Optimized for various screen sizes and orientations
- **Loading States**: Shimmer loading effects and proper error handling
- **Pull-to-Refresh**: Refresh data with smooth animations

#### 📊 Analytics & Insights
- **Spending Analytics**: Visual charts showing spending patterns
- **Pie Charts**: Category-wise spending breakdown
- **Bar Charts**: Weekly spending trends
- **Summary Cards**: Key metrics at a glance
- **Period Filtering**: Analyze data for different time periods

#### 💰 Budget Management
- **Budget Tracker**: Set spending limits for each category
- **Progress Indicators**: Visual progress bars showing budget usage
- **Over-budget Alerts**: Notifications when exceeding budget limits
- **Budget Overview**: Total budget, spent, and remaining amounts

#### 📱 Offline Support
- **Local Database**: SQLite for offline data storage
- **Sync Queue**: Automatic data synchronization when online
- **Connectivity Monitoring**: Real-time network status detection
- **Offline Indicators**: Clear indication when working offline

#### 📤 Data Export
- **Multiple Formats**: Export data in CSV and JSON formats
- **Date Range Selection**: Export data for specific time periods
- **Share Functionality**: Share exported files via other apps
- **Detailed Reports**: Comprehensive expense reports

#### 🔧 Advanced Features
- **State Management**: Provider pattern for efficient state management
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Performance Optimization**: Efficient data fetching and caching
- **Accessibility**: Support for accessibility features

## 🛠 Technical Stack

- **Frontend**: Flutter 3.2+
- **Backend**: Firebase (Authentication, Firestore)
- **State Management**: Provider
- **Local Storage**: SQLite, SharedPreferences
- **Charts**: FL Chart
- **Animations**: Flutter Animate
- **UI Components**: Material Design 3, Shimmer

## 📱 Screenshots

### Home Screen
- Modern card-based layout
- Category-wise expense tracking
- Real-time total calculation
- Smooth animations and transitions

### Analytics Screen
- Interactive pie charts
- Weekly spending trends
- Summary statistics
- Period-based filtering

### Budget Screen
- Category-wise budget setting
- Progress indicators
- Over-budget alerts
- Visual budget overview

### Profile Screen
- User statistics
- Theme toggle
- Data export options
- Settings management

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.2.0 or higher
- Dart SDK 3.2.0 or higher
- Firebase project setup
- Google Sign-in configuration

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/tong.git
   cd tong
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project
   - Enable Authentication (Google Sign-in)
   - Enable Firestore Database
   - Download and add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

4. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── providers/               # State management
│   └── theme_provider.dart
├── services/                # Business logic services
│   ├── connectivity_service.dart
│   ├── local_database_service.dart
│   └── export_service.dart
├── repository/              # Data layer
│   ├── auth_service.dart
│   └── firestore_service.dart
├── screens/                 # UI screens
│   ├── auth/
│   │   └── login_screen.dart
│   ├── main/
│   │   ├── home_screen.dart
│   │   ├── analytics/
│   │   │   └── analytics_screen.dart
│   │   ├── budget/
│   │   │   └── budget_screen.dart
│   │   ├── history/
│   │   │   └── HistoryScreen.dart
│   │   ├── user/
│   │   │   └── profile_screen.dart
│   │   └── category/
│   │       ├── list_category_screen.dart
│   │       └── add_edit_category_screen.dart
│   └── utility/
│       ├── splash_screen.dart
│       └── not_found_screen.dart
└── utils/                   # Utilities
    ├── constants.dart
    ├── theme.dart
    ├── utils.dart
    ├── logger.dart
    └── routes_handler.dart
```

## 🔧 Configuration

### Firebase Configuration
1. Create a Firebase project
2. Enable Google Sign-in in Authentication
3. Set up Firestore Database
4. Configure security rules for Firestore

### Environment Variables
- No additional environment variables required
- All configuration is handled through Firebase console

## 📊 Data Model

### Categories
```dart
{
  id: String,
  title: String,
  price: double,
  userId: String,
  createdAt: DateTime,
  updatedAt: DateTime
}
```

### Daily Data
```dart
{
  userId: String,
  date: String (YYYY-MM-DD),
  categoryId: String,
  count: int,
  synced: bool
}
```

## 🎯 Key Improvements Made

### 1. User Experience
- **Before**: Basic UI with minimal styling
- **After**: Modern Material Design 3 with animations, gradients, and smooth transitions

### 2. Functionality
- **Before**: Basic expense tracking only
- **After**: Analytics, budget tracking, data export, offline support

### 3. Performance
- **Before**: No caching, inefficient data fetching
- **After**: Local database, optimized queries, offline-first approach

### 4. Error Handling
- **Before**: Basic error messages
- **After**: Comprehensive error handling with user-friendly messages and retry options

### 5. Accessibility
- **Before**: No accessibility features
- **After**: Dark mode, proper contrast, accessibility support

## 🚀 Future Enhancements

- [ ] Push notifications for budget alerts
- [ ] Multi-currency support
- [ ] Receipt scanning with OCR
- [ ] Expense sharing with family members
- [ ] Advanced analytics with machine learning
- [ ] Integration with banking APIs
- [ ] Widget support for quick expense entry

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- FL Chart for beautiful charts
- Flutter Animate for smooth animations

## 📞 Support

For support, email support@tong-app.com or create an issue in the repository.

---

**টং** - Making expense tracking simple and beautiful! 💰✨
