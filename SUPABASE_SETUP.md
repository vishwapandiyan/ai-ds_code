# Supabase Setup Guide

This guide provides detailed instructions for setting up Supabase as the backend for the Students' Coding Portal.

## 🚀 Step 1: Create Supabase Project

1. **Sign up/Login to Supabase**
   - Go to [supabase.com](https://supabase.com)
   - Sign up or login to your account

2. **Create New Project**
   - Click "New Project"
   - Choose your organization
   - Enter project details:
     - **Name**: `students-coding-portal`
     - **Database Password**: Create a strong password
     - **Region**: Choose closest to your users
   - Click "Create new project"

3. **Wait for Setup**
   - Project creation takes 2-3 minutes
   - You'll receive an email when ready

## 🔧 Step 2: Get Project Credentials

1. **Access Project Settings**
   - Go to your project dashboard
   - Navigate to Settings → API

2. **Copy Credentials**
   - **Project URL**: Copy the URL (e.g., `https://xyz.supabase.co`)
   - **Anon Key**: Copy the anon/public key
   - **Service Role Key**: Keep this secure (for admin operations)

## 📊 Step 3: Set Up Database Schema

1. **Open SQL Editor**
   - In your Supabase dashboard
   - Go to SQL Editor

2. **Run Database Schema**
   - Copy the contents of `database_schema.sql`
   - Paste in SQL Editor
   - Click "Run" to execute

3. **Verify Tables Created**
   - Go to Table Editor
   - You should see these tables:
     - `user_profiles`
     - `levels`
     - `mcqs`
     - `student_performance`
     - `notifications`

## 📝 Step 4: Insert Sample Data

1. **Run Sample Data Script**
   - In SQL Editor, copy contents of `sample_data.sql`
   - Paste and run the script

2. **Verify Data**
   - Check Table Editor
   - You should see:
     - 5 levels in `levels` table
     - 40 MCQs in `mcqs` table (20 for each of first 2 levels)

## 🔐 Step 5: Configure Authentication

1. **Enable Email Auth**
   - Go to Authentication → Settings
   - Enable "Email" provider
   - Configure email templates (optional)

2. **Set Up Email Templates**
   - Go to Authentication → Templates
   - Customize confirmation and recovery emails
   - Add your branding

3. **Configure Redirect URLs**
   - Go to Authentication → Settings → URL Configuration
   - Add your app URLs:
     - **Site URL**: `http://localhost:3000` (development)
     - **Redirect URLs**: `http://localhost:3000/**`

## 🔑 Step 6: Update Flutter Configuration

1. **Update Supabase Service**
   - Open `lib/services/supabase_service.dart`
   - Replace placeholder values:
   ```dart
   static const String supabaseUrl = 'YOUR_ACTUAL_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_ACTUAL_ANON_KEY';
   ```

2. **Test Connection**
   - Run the app: `flutter run -d chrome`
   - Try to register a new user
   - Check Supabase dashboard for new user

## 📧 Step 7: Configure Email Notifications (Optional)

### Option A: Supabase Edge Functions
1. **Install Supabase CLI**
   ```bash
   npm install -g supabase
   ```

2. **Initialize Edge Functions**
   ```bash
   supabase init
   ```

3. **Create Email Function**
   ```bash
   supabase functions new send-email
   ```

4. **Deploy Function**
   ```bash
   supabase functions deploy send-email
   ```

### Option B: External Email Service
1. **Set up SendGrid**
   - Create SendGrid account
   - Get API key
   - Update email service in code

2. **Configure SMTP**
   - Use your own SMTP server
   - Update email configuration

## 🔒 Step 8: Security Configuration

1. **Review RLS Policies**
   - Go to Authentication → Policies
   - Verify all tables have appropriate policies
   - Test with different user roles

2. **Set Up Row Level Security**
   - All tables should have RLS enabled
   - Policies should be working correctly

3. **Test Security**
   - Create test users with different roles
   - Verify access controls work properly

## 🧪 Step 9: Testing the Setup

1. **Test User Registration**
   - Register a new student account
   - Check if user appears in `user_profiles` table
   - Verify status is "pending"

2. **Test Admin Functions**
   - Create admin user manually in database
   - Test student approval workflow
   - Test level management

3. **Test MCQ Functionality**
   - Take a sample MCQ test
   - Verify performance is saved
   - Check results display correctly

## 🚀 Step 10: Production Deployment

1. **Update Environment Variables**
   - Use production Supabase project
   - Update all URLs and keys
   - Configure production email settings

2. **Set Up Custom Domain**
   - Configure custom domain in Supabase
   - Update redirect URLs
   - Set up SSL certificates

3. **Monitor Usage**
   - Check Supabase dashboard regularly
   - Monitor database usage
   - Set up alerts for limits

## 🔧 Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Check redirect URLs
   - Verify email confirmation settings
   - Clear browser cache

2. **Database Connection Issues**
   - Verify project URL and keys
   - Check network connectivity
   - Ensure project is active

3. **RLS Policy Errors**
   - Review policy syntax
   - Test with different user roles
   - Check table permissions

4. **Email Not Working**
   - Verify email provider settings
   - Check SMTP configuration
   - Test with different email addresses

### Debug Commands

```bash
# Check Supabase connection
curl -X GET "https://your-project.supabase.co/rest/v1/" \
  -H "apikey: your-anon-key"

# Test authentication
curl -X POST "https://your-project.supabase.co/auth/v1/signup" \
  -H "apikey: your-anon-key" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Edge Functions Guide](https://supabase.com/docs/guides/functions)

## 🆘 Support

If you encounter issues:
1. Check Supabase status page
2. Review error logs in dashboard
3. Consult Supabase documentation
4. Create issue in project repository

---

**Remember**: Keep your service role key secure and never expose it in client-side code! 