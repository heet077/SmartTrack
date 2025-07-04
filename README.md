# Smart Attendance System 📱✨

A modern, Flutter-powered attendance management system designed for educational institutions. This system leverages QR codes, location verification, and multiple authentication methods to provide a secure and efficient way to track student attendance.

## 🌟 Key Features

### Multi-Role System
- **👨‍🏫 Professors**
  - Secure authentication and dedicated dashboard
  - Generate time-sensitive QR codes for attendance
  - Real-time attendance tracking and analytics
  - Multiple attendance verification methods (QR, Passcode, Location)
  - Export detailed attendance reports
  - Course management and lecture scheduling

- **👨‍🎓 Students**
  - User-friendly mobile interface
  - Quick attendance marking through QR scanning
  - Location-based attendance verification
  - Personal attendance history and statistics
  - Course overview and schedule tracking
  - Passcode-based attendance backup

- **👨‍💼 Administrators**
  - Comprehensive system management
  - User management (professors & students)
  - Course assignment and scheduling
  - Advanced analytics dashboard
  - System-wide settings configuration
  - Attendance reports and statistics

## 🛠️ Technology Stack

- **Frontend**: Flutter 3.2+ with Material Design
- **Backend**: Supabase (Backend as a Service)
- **Database**: PostgreSQL with RLS policies
- **State Management**: GetX for efficient state handling
- **Authentication**: Supabase Auth
- **Location Services**: Geolocator
- **QR Features**: QR Flutter & Mobile Scanner
- **Analytics**: FL Chart for data visualization

## 🏗️ Architecture

The project follows a clean, modular architecture with:
- Separate modules for Admin, Professor, and Student roles
- GetX for state management and dependency injection
- Middleware for authentication and route protection
- Supabase RLS policies for data security
- Comprehensive database functions and migrations

## 🔐 Security Features

- Time-sensitive QR codes
- Location verification for attendance
- Role-based access control
- Secure password management
- Database-level security with RLS
- Multiple attendance verification methods

## 📊 Analytics & Reporting

- Course-wise attendance statistics
- Student performance metrics
- Program-level analytics
- Exportable reports (CSV, PDF)
- Real-time attendance tracking
- Detailed attendance history

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.2.3)
- Dart SDK
- Android Studio / VS Code
- Git
- Supabase Account

### Installation

1. Clone the repository:
   ```bash
   git clone [repository-url]
   cd [project-name]
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Supabase:
   - Create a new Supabase project
   - Set up the database using migrations in `/supabase/migrations`
   - Configure environment variables

4. Run the application:
   ```bash
   flutter run
   ```

## 📱 Supported Platforms

- Android
- iOS
- Web (Progressive Web App)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 💬 Support

For support:
- Open an issue in the repository
- Contact the development team
- Check the documentation

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the robust backend infrastructure
- All contributors who have helped shape this project

---
⭐ If you find this project helpful, please consider giving it a star!
