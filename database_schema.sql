-- Students' Coding Portal Database Schema
-- Supabase SQL Schema

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- User Profiles Table
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('student', 'staff', 'admin')),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'declined', 'removed')),
    assigned_staff_id UUID REFERENCES user_profiles(id),
    username VARCHAR(50),
    password VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Levels Table
CREATE TABLE levels (
    id SERIAL PRIMARY KEY,
    level_number INTEGER NOT NULL UNIQUE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- MCQs Table
CREATE TABLE mcqs (
    id SERIAL PRIMARY KEY,
    level_id INTEGER NOT NULL REFERENCES levels(id) ON DELETE CASCADE,
    question_number INTEGER NOT NULL,
    question TEXT NOT NULL,
    options TEXT[] NOT NULL,
    correct_answer INTEGER NOT NULL CHECK (correct_answer >= 0 AND correct_answer < array_length(options, 1)),
    explanation TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(level_id, question_number)
);

-- Student Performance Table
CREATE TABLE student_performance (
    id SERIAL PRIMARY KEY,
    student_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    level_id INTEGER NOT NULL REFERENCES levels(id) ON DELETE CASCADE,
    score INTEGER NOT NULL,
    total_questions INTEGER NOT NULL,
    correct_answers INTEGER NOT NULL,
    time_taken INTEGER NOT NULL, -- in seconds
    answers JSONB NOT NULL, -- stores student answers
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(student_id, level_id)
);

-- Notifications Table
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    from_user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    to_user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('meeting', 'approval', 'decline', 'general')),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security (RLS) Policies

-- Enable RLS on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE mcqs ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_performance ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- User Profiles Policies
CREATE POLICY "Users can view their own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles" ON user_profiles
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Staff can view assigned students" ON user_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() AND role = 'staff' AND id = user_profiles.assigned_staff_id
        )
    );

-- Levels Policies
CREATE POLICY "All authenticated users can view levels" ON levels
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Only admins can manage levels" ON levels
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- MCQs Policies
CREATE POLICY "All authenticated users can view MCQs" ON mcqs
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Only admins can manage MCQs" ON mcqs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Student Performance Policies
CREATE POLICY "Students can view their own performance" ON student_performance
    FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "Students can insert their own performance" ON student_performance
    FOR INSERT WITH CHECK (auth.uid() = student_id);

CREATE POLICY "Staff can view assigned students' performance" ON student_performance
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_profiles up
            WHERE up.id = auth.uid() 
            AND up.role = 'staff' 
            AND up.id = (
                SELECT assigned_staff_id FROM user_profiles 
                WHERE id = student_performance.student_id
            )
        )
    );

CREATE POLICY "Admins can view all performance" ON student_performance
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Notifications Policies
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (auth.uid() = to_user_id);

CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = to_user_id);

CREATE POLICY "Users can send notifications" ON notifications
    FOR INSERT WITH CHECK (auth.uid() = from_user_id);

-- Functions and Triggers

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_user_profiles_updated_at 
    BEFORE UPDATE ON user_profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_levels_updated_at 
    BEFORE UPDATE ON levels 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mcqs_updated_at 
    BEFORE UPDATE ON mcqs 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to automatically create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, phone, role, status)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'phone', ''),
        COALESCE(NEW.raw_user_meta_data->>'role', 'student'),
        CASE 
            WHEN COALESCE(NEW.raw_user_meta_data->>'role', 'student') = 'student' THEN 'pending'
            ELSE 'active'
        END
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create user profile on signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to create staff account and send invitation email
CREATE OR REPLACE FUNCTION create_staff_invitation(
  staff_email TEXT,
  staff_phone TEXT,
  admin_id UUID
) RETURNS UUID AS $$
DECLARE
  new_user_id UUID;
  temp_password TEXT;
BEGIN
  -- Generate a temporary password
  temp_password := 'temp_' || substr(md5(random()::text), 1, 8);
  
  -- Create user in auth.users (this would typically be done via Supabase Auth API)
  -- For now, we'll create the user profile and let the trigger handle auth.users
  INSERT INTO user_profiles (id, email, phone, role, status, created_by)
  VALUES (
    gen_random_uuid(),
    staff_email,
    staff_phone,
    'staff',
    'pending_confirmation',
    admin_id
  ) RETURNING id INTO new_user_id;
  
  -- Log the invitation
  INSERT INTO notifications (user_id, title, message, type)
  VALUES (
    new_user_id,
    'Staff Account Created',
    'Your staff account has been created by an administrator. Please check your email for confirmation instructions.',
    'staff_invitation'
  );
  
  RETURN new_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_staff_invitation(TEXT, TEXT, UUID) TO authenticated;

-- Indexes for better performance
CREATE INDEX idx_user_profiles_role ON user_profiles(role);
CREATE INDEX idx_user_profiles_status ON user_profiles(status);
CREATE INDEX idx_user_profiles_assigned_staff ON user_profiles(assigned_staff_id);
CREATE INDEX idx_mcqs_level_id ON mcqs(level_id);
CREATE INDEX idx_student_performance_student_id ON student_performance(student_id);
CREATE INDEX idx_student_performance_level_id ON student_performance(level_id);
CREATE INDEX idx_notifications_to_user_id ON notifications(to_user_id);
CREATE INDEX idx_notifications_created_at ON notifications(created_at); 