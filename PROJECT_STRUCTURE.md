# Project Structure

## 📁 Directory Structure

```
students/
├── lib/                          # Main Flutter application code
│   ├── controllers/              # Business logic controllers
│   │   ├── auth_controller.dart
│   │   ├── level_controller.dart
│   │   └── admin_controller.dart
│   ├── models/                   # Data models
│   │   ├── user.dart
│   │   ├── level.dart
│   │   ├── performance.dart
│   │   └── notification.dart
│   ├── services/                 # External service integrations
│   │   └── supabase_service.dart
│   ├── views/                    # UI screens and components
│   │   ├── auth/                 # Authentication screens
│   │   ├── dashboard/            # Role-specific dashboards
│   │   ├── mcq/                  # MCQ test screens
│   │   ├── notifications/        # Notification screens
│   │   ├── profile/              # Profile management
│   │   └── messaging/            # Messaging screens
│   ├── widgets/                  # Reusable UI components
│   └── main.dart                 # Application entry point
├── web/                          # Web-specific files
│   ├── index.html
│   ├── manifest.json
│   └── icons/                    # App icons
├── assets/                       # Static assets
│   └── images/                   # Image files
├── test/                         # Test files
├── supabase/                     # Supabase configuration
│   ├── config.toml              # Supabase CLI configuration
│   ├── functions/               # Edge functions (if any)
│   └── templates/               # Database templates
├── database_schema.sql          # Main database schema
├── sample_data.sql              # Sample data for testing
├── SUPABASE_SETUP.md            # Supabase setup instructions
├── DEPLOYMENT.md                # Deployment guide
├── setup.sh                     # Development setup script
├── dev.sh                       # Development run script
├── deploy.sh                    # Production deployment script
├── pubspec.yaml                 # Flutter dependencies
├── pubspec.lock                 # Locked dependency versions
├── analysis_options.yaml        # Dart analysis configuration
├── .gitignore                   # Git ignore rules
└── README.md                    # Project documentation
```

## 🔧 Key Files

### Core Application Files
- **`lib/main.dart`**: Application entry point and routing
- **`lib/services/supabase_service.dart`**: Supabase integration and API calls
- **`lib/controllers/`**: Business logic and state management
- **`lib/models/`**: Data structures and serialization

### Configuration Files
- **`pubspec.yaml`**: Flutter dependencies and project configuration
- **`analysis_options.yaml`**: Dart code analysis rules
- **`supabase/config.toml`**: Supabase CLI configuration

### Database Files
- **`database_schema.sql`**: Complete database schema with RLS policies
- **`sample_data.sql`**: Sample data for testing and development

### Documentation Files
- **`README.md`**: Main project documentation
- **`SUPABASE_SETUP.md`**: Detailed Supabase setup guide
- **`DEPLOYMENT.md`**: Production deployment instructions

### Scripts
- **`setup.sh`**: Automated development environment setup
- **`dev.sh`**: Quick development server start
- **`deploy.sh`**: Production build and deployment

## 🏗️ Architecture Overview

### MVC Pattern
- **Models**: Data structures in `lib/models/`
- **Views**: UI components in `lib/views/`
- **Controllers**: Business logic in `lib/controllers/`

### State Management
- **Provider Pattern**: Used throughout the application
- **Controllers**: Manage specific feature states
- **Services**: Handle external API interactions

### Database Design
- **PostgreSQL**: Primary database (via Supabase)
- **Row Level Security**: Fine-grained access control
- **Real-time**: Live updates for notifications

## 🚀 Development Workflow

1. **Setup**: Run `./setup.sh` for initial setup
2. **Development**: Use `./dev.sh` for local development
3. **Database**: Use Supabase dashboard for database management
4. **Testing**: Use `flutter test` for unit tests
5. **Deployment**: Use `./deploy.sh` for production builds

## 📊 Database Schema

### Core Tables
- **user_profiles**: User information and roles
- **levels**: MCQ test levels
- **mcqs**: Multiple choice questions
- **student_performance**: Test results and analytics
- **notifications**: User notifications and messages

### Key Features
- **Role-based access**: Student, Staff, Admin roles
- **Student profiles**: Username, enrollment, class, year
- **MCQ randomization**: Questions shuffled for each test
- **Performance tracking**: Detailed analytics and reports
- **Real-time notifications**: Live messaging system 