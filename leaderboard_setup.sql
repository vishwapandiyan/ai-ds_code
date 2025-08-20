-- Leaderboard Setup Script for Existing Databases
-- Run this script in your Supabase SQL Editor to add leaderboard functionality

-- Create Leaderboard Table
CREATE TABLE IF NOT EXISTS leaderboard (
    id SERIAL PRIMARY KEY,
    student_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    level_id INTEGER NOT NULL REFERENCES levels(id) ON DELETE CASCADE,
    score INTEGER NOT NULL,
    time_taken INTEGER NOT NULL, -- in seconds
    rank_position INTEGER,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(student_id, level_id)
);

-- Add explicit foreign key constraints with proper names
ALTER TABLE leaderboard 
ADD CONSTRAINT IF NOT EXISTS leaderboard_student_id_fkey 
FOREIGN KEY (student_id) REFERENCES user_profiles(id) ON DELETE CASCADE;

ALTER TABLE leaderboard 
ADD CONSTRAINT IF NOT EXISTS leaderboard_level_id_fkey 
FOREIGN KEY (level_id) REFERENCES levels(id) ON DELETE CASCADE;

-- Enable Row Level Security
ALTER TABLE leaderboard ENABLE ROW LEVEL SECURITY;

-- Create Leaderboard Policies
-- Students can view, insert, and update their own leaderboard entries
CREATE POLICY IF NOT EXISTS "Students can manage their own leaderboard" ON leaderboard
    FOR ALL USING (auth.uid() = student_id);

-- Additional policy to ensure students can insert new entries
CREATE POLICY IF NOT EXISTS "Students can insert new leaderboard entries" ON leaderboard
    FOR INSERT WITH CHECK (auth.uid() = student_id);

-- Admins can view and manage all leaderboard entries
CREATE POLICY IF NOT EXISTS "Admins can manage all leaderboard" ON leaderboard
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Staff can view leaderboard for assigned students
CREATE POLICY IF NOT EXISTS "Staff can view leaderboard for assigned students" ON leaderboard
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_profiles up
            WHERE up.id = auth.uid() 
            AND up.role = 'staff' 
            AND up.id = (
                SELECT assigned_staff_id FROM user_profiles 
                WHERE id = leaderboard.student_id
            )
        )
    );

-- Create Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_leaderboard_level_id ON leaderboard(level_id);
CREATE INDEX IF NOT EXISTS idx_leaderboard_score_time ON leaderboard(level_id, score DESC, time_taken ASC);
CREATE INDEX IF NOT EXISTS idx_leaderboard_rank ON leaderboard(level_id, rank_position);
CREATE INDEX IF NOT EXISTS idx_leaderboard_student_id ON leaderboard(student_id);

-- Insert sample leaderboard data (optional - for testing)
-- This will create some sample entries if you have existing student performance data
INSERT INTO leaderboard (student_id, level_id, score, time_taken, rank_position, completed_at)
SELECT 
    sp.student_id,
    sp.level_id,
    sp.score,
    sp.time_taken,
    ROW_NUMBER() OVER (PARTITION BY sp.level_id ORDER BY sp.score DESC, sp.time_taken ASC) as rank_position,
    sp.completed_at
FROM student_performance sp
WHERE NOT EXISTS (
    SELECT 1 FROM leaderboard l 
    WHERE l.student_id = sp.student_id AND l.level_id = sp.level_id
)
ON CONFLICT (student_id, level_id) DO NOTHING;

-- Update rank positions for existing entries
UPDATE leaderboard 
SET rank_position = subquery.rank_position
FROM (
    SELECT 
        id,
        ROW_NUMBER() OVER (PARTITION BY level_id ORDER BY score DESC, time_taken ASC) as rank_position
    FROM leaderboard
) subquery
WHERE leaderboard.id = subquery.id;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON leaderboard TO authenticated;

-- Verify the setup
SELECT 
    'Leaderboard table created successfully' as status,
    COUNT(*) as total_entries
FROM leaderboard;

-- Insert sample leaderboard data for testing (optional)
-- This will create some sample entries if you have existing student performance data
INSERT INTO leaderboard (student_id, level_id, score, time_taken, rank_position, completed_at)
SELECT 
    sp.student_id,
    sp.level_id,
    sp.score,
    sp.time_taken,
    ROW_NUMBER() OVER (PARTITION BY sp.level_id ORDER BY sp.score DESC, sp.time_taken ASC) as rank_position,
    sp.completed_at
FROM student_performance sp
WHERE NOT EXISTS (
    SELECT 1 FROM leaderboard l 
    WHERE l.student_id = sp.student_id AND l.level_id = sp.level_id
)
ON CONFLICT (student_id, level_id) DO NOTHING;

-- Update rank positions for existing entries
UPDATE leaderboard 
SET rank_position = subquery.rank_position
FROM (
    SELECT 
        id,
        ROW_NUMBER() OVER (PARTITION BY level_id ORDER BY score DESC, time_taken ASC) as rank_position
    FROM leaderboard
) subquery
WHERE leaderboard.id = subquery.id;

-- Show final status
SELECT 
    'Leaderboard setup completed' as status,
    COUNT(*) as total_entries,
    COUNT(DISTINCT student_id) as unique_students,
    COUNT(DISTINCT level_id) as levels_with_data
FROM leaderboard;
