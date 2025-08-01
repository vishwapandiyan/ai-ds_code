# Students' Coding Portal

A comprehensive web application built with Flutter, Supabase, and MVC architecture for managing student MCQ tests with role-based access control.

## 🚀 Features

### Student Features
- **Registration & Approval Workflow**: Students register with email and phone, await admin approval
- **Profile Management**: Edit username, enrollment number, class, and year
- **MCQ Tests**: Take C programming MCQ tests with 20 questions per level (randomized order)
- **Level Progression**: Access next level only after scoring 70% or higher
- **Performance Tracking**: View detailed results and performance history
- **Real-time Feedback**: Immediate results with explanations

### Staff Features
- **Student Monitoring**: View performance of assigned students
- **Notifications**: Send messages and meeting requests to students
- **Performance Analytics**: Track student progress and time analysis
- **Reports**: Generate performance reports for assigned students

### Admin Features
- **Student Management**: Approve/decline student registrations
- **Staff Assignment**: Assign approved students to staff members
- **Level Management**: Create and manage MCQ levels
- **Staff Promotion**: Promote staff members to admin role
- **System Administration**: Full control over the platform

## 🏗️ Architecture

### MVC Pattern Implementation
- **Models**: User, Level, MCQ, Performance, Notification
- **Views**: Authentication, Dashboards, MCQ Tests, Results
- **Controllers**: Auth, Level, Admin controllers with business logic

### Technology Stack
- **Frontend**: Flutter Web (responsive design)
- **Backend**: Supabase (PostgreSQL, Auth, Real-time)
- **State Management**: Provider pattern
- **Database**: PostgreSQL with Row Level Security (RLS)

## 📋 Prerequisites

- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Supabase account
- Git

## 🛠️ Setup Instructions

### 1. Clone the Repository
```bash
git clone <repository-url>
cd students
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Supabase Setup

#### A. Create Supabase Project
1. Go to [Supabase](https://supabase.com) and create a new project
2. Note down your project URL and anon key

#### B. Configure Database
1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Run the `database_schema.sql` file to create tables and policies
4. Run the `sample_data.sql` file to insert sample data

#### C. Add Student Fields (Required)
Run this SQL script to add the new student fields:
```sql
-- Add new columns to user_profiles table
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS enrollment_no VARCHAR(20),
ADD COLUMN IF NOT EXISTS class VARCHAR(20),
ADD COLUMN IF NOT EXISTS year INTEGER;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_enrollment ON user_profiles(enrollment_no);
CREATE INDEX IF NOT EXISTS idx_user_profiles_class ON user_profiles(class);

-- Update existing students with sample data (optional)
UPDATE user_profiles 
SET 
    enrollment_no = 'EN' || substr(id::text, 1, 8),
    class = 'CSE',
    year = 2
WHERE role = 'student' AND enrollment_no IS NULL;
```

#### D. Configure Authentication
1. Go to Authentication > Settings in Supabase dashboard
2. Enable Email authentication
3. Configure email templates (optional)

### 4. Update Supabase Configuration
1. Open `lib/services/supabase_service.dart`
2. Replace the placeholder values:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 5. Run the Application
```bash
# For web development
flutter run -d chrome

# For production build
flutter build web
```

## 📊 Database Schema

### Tables
- **user_profiles**: User information and roles
- **levels**: MCQ test levels
- **mcqs**: Multiple choice questions
- **student_performance**: Test results and analytics
- **notifications**: System notifications

### Security
- Row Level Security (RLS) enabled on all tables
- Role-based access control
- Secure authentication with Supabase Auth

## 🎯 Sample Data

The application includes:
- 5 levels of C programming MCQs
- 20 questions per level (40 total questions provided)
- Sample admin and staff accounts
- Comprehensive C programming topics

## 🚀 Deployment

### Web Deployment
1. Build the application:
```bash
flutter build web
```

2. Deploy to your preferred hosting service:
   - **Vercel**: Connect your GitHub repository
   - **Netlify**: Drag and drop the `build/web` folder
   - **Firebase Hosting**: Use Firebase CLI
   - **GitHub Pages**: Push to gh-pages branch

### Environment Configuration
Create a `.env` file for production:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

## 🔧 Configuration

### Email Notifications
To enable email notifications:
1. Set up Supabase Edge Functions for email sending
2. Configure SendGrid or similar email service
3. Update the email service methods in `supabase_service.dart`

### Custom Styling
Modify the theme in `lib/main.dart`:
```dart
theme: ThemeData(
  primarySwatch: Colors.blue,
  fontFamily: 'Roboto',
  useMaterial3: true,
  // Add your custom theme here
),
```

## 📱 Features in Detail

### Student Workflow
1. **Registration**: Student registers with email and phone
2. **Approval**: Admin reviews and approves/declines
3. **Assignment**: Approved students are assigned to staff
4. **Credentials**: Random username/password sent via email
5. **Testing**: Students take MCQ tests with level progression
6. **Results**: Immediate feedback with detailed performance

### Admin Workflow
1. **Dashboard**: Overview of pending students and system stats
2. **Student Management**: Approve/decline registrations
3. **Staff Assignment**: Assign students to staff members
4. **Level Creation**: Add new MCQ levels and questions
5. **System Administration**: Manage users and roles

### Staff Workflow
1. **Student Monitoring**: View assigned students' performance
2. **Notifications**: Send messages and meeting requests
3. **Reports**: Generate performance analytics
4. **Progress Tracking**: Monitor student advancement

## 🔒 Security Features

- **Authentication**: Supabase Auth with email/password
- **Authorization**: Role-based access control (Student, Staff, Admin)
- **Data Protection**: Row Level Security (RLS) policies
- **Input Validation**: Form validation and sanitization
- **Secure Communication**: HTTPS and secure API calls

## 🧪 Testing

### Manual Testing
1. **Student Registration**: Test the complete registration flow
2. **Admin Approval**: Test student approval process
3. **MCQ Tests**: Take sample tests and verify scoring
4. **Role Access**: Test different user role permissions

### Automated Testing
```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## 📈 Performance Optimization

- **Lazy Loading**: Load data on demand
- **Caching**: Implement caching for frequently accessed data
- **Image Optimization**: Optimize assets for web
- **Code Splitting**: Split large widgets for better performance

## 🐛 Troubleshooting

### Common Issues

1. **Supabase Connection Error**
   - Verify URL and API key in `supabase_service.dart`
   - Check network connectivity
   - Ensure Supabase project is active

2. **Authentication Issues**
   - Verify email confirmation settings
   - Check Supabase Auth configuration
   - Clear browser cache and cookies

3. **Database Errors**
   - Run database schema again
   - Check RLS policies
   - Verify table permissions

4. **Build Errors**
   - Run `flutter clean`
   - Update dependencies: `flutter pub upgrade`
   - Check Flutter version compatibility

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

## 🔄 Updates and Maintenance

### Regular Maintenance
- Update Flutter and dependencies
- Monitor Supabase usage and limits
- Backup database regularly
- Review and update security policies

### Feature Updates
- Add new MCQ levels
- Implement additional question types
- Enhance analytics and reporting
- Add mobile app support

---

**Built with ❤️ using Flutter and Supabase**
