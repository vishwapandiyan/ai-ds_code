# Deployment Guide

## 🚀 Production Deployment

### 1. Build for Production

```bash
# Build the Flutter web app
flutter build web --release

# The build output will be in the `build/web/` directory
```

### 2. Deploy to Web Server

#### Option A: Deploy to Firebase Hosting

1. **Install Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   ```

2. **Initialize Firebase**:
   ```bash
   firebase login
   firebase init hosting
   ```

3. **Configure Firebase**:
   - Set public directory to `build/web`
   - Configure as single-page app
   - Set up GitHub Actions (optional)

4. **Deploy**:
   ```bash
   firebase deploy
   ```

#### Option B: Deploy to Netlify

1. **Connect your Git repository** to Netlify
2. **Set build settings**:
   - Build command: `flutter build web --release`
   - Publish directory: `build/web`
3. **Deploy automatically** on Git push

#### Option C: Deploy to Vercel

1. **Connect your Git repository** to Vercel
2. **Set build settings**:
   - Framework preset: Other
   - Build command: `flutter build web --release`
   - Output directory: `build/web`
3. **Deploy automatically** on Git push

### 3. Environment Configuration

#### Update Supabase Configuration

Before deploying, ensure your Supabase configuration is correct:

1. **Update `lib/services/supabase_service.dart`**:
   ```dart
   static const String supabaseUrl = 'YOUR_PRODUCTION_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_PRODUCTION_SUPABASE_ANON_KEY';
   ```

2. **Configure Supabase Auth**:
   - Go to Supabase Dashboard → Authentication → Settings
   - Add your production domain to Site URL
   - Add redirect URLs for your production domain

### 4. Database Migration

Ensure your production database has the required schema:

1. **Run the main schema** (`database_schema.sql`)
2. **Run the student fields migration**:
   ```sql
   ALTER TABLE user_profiles 
   ADD COLUMN IF NOT EXISTS enrollment_no VARCHAR(20),
   ADD COLUMN IF NOT EXISTS class VARCHAR(20),
   ADD COLUMN IF NOT EXISTS year INTEGER;
   ```

### 5. Testing Production

1. **Test user registration** and approval workflow
2. **Test MCQ functionality** with randomized questions
3. **Test profile editing** for students
4. **Test all user roles** (Student, Staff, Admin)
5. **Test notifications** and messaging

## 🔧 Development Deployment

### Local Development

```bash
# Run in development mode
flutter run -d chrome --web-port 3000

# Or use the provided script
./dev.sh
```

### Staging Environment

1. **Create a staging Supabase project**
2. **Update configuration** for staging
3. **Deploy to staging URL**
4. **Test all features** before production

## 📊 Monitoring

### Supabase Monitoring

1. **Database Performance**: Monitor query performance in Supabase Dashboard
2. **Authentication Logs**: Check auth events and errors
3. **Real-time Connections**: Monitor active connections

### Application Monitoring

1. **Error Tracking**: Implement error tracking (e.g., Sentry)
2. **Performance Monitoring**: Monitor app performance
3. **User Analytics**: Track user behavior and engagement

## 🔒 Security Considerations

1. **Row Level Security**: Ensure RLS policies are properly configured
2. **API Keys**: Never expose service role keys in client code
3. **CORS**: Configure CORS properly for your domain
4. **HTTPS**: Always use HTTPS in production
5. **Input Validation**: Validate all user inputs

## 🚨 Troubleshooting

### Common Issues

1. **CORS Errors**: Check Supabase CORS settings
2. **Authentication Issues**: Verify Site URL and redirect URLs
3. **Database Connection**: Check Supabase URL and API keys
4. **Build Errors**: Ensure all dependencies are properly installed

### Support

For issues related to:
- **Flutter**: Check Flutter documentation and community
- **Supabase**: Check Supabase documentation and Discord
- **Deployment**: Check your hosting provider's documentation 