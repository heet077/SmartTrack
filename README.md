# QR Code-Based Attendance System

A modern, Flutter-based attendance management system that uses QR codes for seamless attendance tracking in educational institutions.

## Features

### For Professors
- **Secure Authentication**: Dedicated login system for professors
- **Dashboard Overview**: 
  - View upcoming lectures
  - Quick access to course statistics
  - Real-time attendance tracking
- **QR Code Generation**: 
  - Generate time-sensitive QR codes for attendance
  - Configurable QR code expiration time
  - Automatic refresh functionality
- **Attendance Management**:
  - View attendance statistics by course
  - Track student attendance patterns
  - Export attendance reports

### For Students
- **Mobile-First Design**: User-friendly interface for students
- **QR Code Scanning**: Quick attendance marking through QR code scanning
- **Attendance History**: View personal attendance records
- **Course Overview**: Access enrolled courses and attendance statistics

### For Administrators
- **Comprehensive Management**:
  - Manage professors and students
  - Course assignment and scheduling
  - System-wide settings configuration
- **Analytics Dashboard**:
  - Overall attendance statistics
  - Course-wise reports
  - Student performance metrics

## Technology Stack

- **Frontend**: Flutter
- **Backend**: Supabase
- **Database**: PostgreSQL
- **Authentication**: Supabase Auth
- **State Management**: GetX
- **QR Integration**: Flutter QR packages

## Project Structure

```
lib/
├── modules/
│   ├── admin/
│   │   ├── controllers/
│   │   ├── models/
│   │   └── views/
│   ├── professor/
│   │   ├── controllers/
│   │   ├── models/
│   │   └── views/
│   └── student/
│       ├── controllers/
│       ├── models/
│       └── views/
├── shared/
│   ├── components/
│   ├── constants/
│   └── utils/
└── main.dart
```

## Setup Instructions

### Prerequisites
- Flutter SDK (latest version)
- Dart SDK
- Android Studio / VS Code
- Git
- Supabase Account

### Installation Steps

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
   - Copy your Supabase URL and anon key
   - Create a `.env` file in the project root
   - Add your Supabase credentials:
     ```
     SUPABASE_URL=your_supabase_url
     SUPABASE_ANON_KEY=your_anon_key
     ```

4. Run the application:
   ```bash
   flutter run
   ```

## Database Schema

The system uses the following main tables:
- `instructors`: Professor information
- `students`: Student records
- `courses`: Course details
- `course_assignments`: Course-professor assignments
- `attendance_records`: Student attendance data

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, email [your-email@domain.com] or open an issue in the repository.

## Acknowledgments

- Flutter team for the amazing framework
- Supabase for the backend infrastructure
- All contributors who have helped shape this project
