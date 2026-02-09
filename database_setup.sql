-- SafeCampus Database Setup Script
-- Run this entire script in Supabase SQL Editor
-- This will create all tables, policies, triggers, and seed data

-- ============================================================================
-- 1. CREATE TABLES
-- ============================================================================

-- Users Table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  student_id TEXT,
  phone TEXT,
  residence TEXT,
  role TEXT NOT NULL CHECK (role IN ('student', 'security', 'admin')),
  profile_image TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE
);

-- Incidents Table
CREATE TABLE IF NOT EXISTS public.incidents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('theft', 'assault', 'harassment', 'fire', 'medical', 'other')),
  severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'responding', 'investigating', 'on-scene', 'resolved', 'closed')),
  location TEXT NOT NULL,
  description TEXT NOT NULL,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  reported_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  assigned_officer UUID REFERENCES public.users(id) ON DELETE SET NULL,
  is_anonymous BOOLEAN DEFAULT FALSE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  resolved_at TIMESTAMP WITH TIME ZONE
);

-- Incident Media Table
CREATE TABLE IF NOT EXISTS public.incident_media (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  incident_id UUID REFERENCES public.incidents(id) ON DELETE CASCADE NOT NULL,
  media_type TEXT NOT NULL CHECK (media_type IN ('photo', 'audio', 'video')),
  media_url TEXT NOT NULL,
  uploaded_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Alerts Table
CREATE TABLE IF NOT EXISTS public.alerts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('critical', 'warning', 'info', 'allClear')),
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  radius_meters INTEGER,
  created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT TRUE
);

-- Alert Reads Table
CREATE TABLE IF NOT EXISTS public.alert_reads (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  alert_id UUID REFERENCES public.alerts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  read_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(alert_id, user_id)
);

-- Buddy Connections Table
CREATE TABLE IF NOT EXISTS public.buddy_connections (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  buddy_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, buddy_id),
  CHECK (user_id != buddy_id)
);

-- Emergency Contacts Table
CREATE TABLE IF NOT EXISTS public.emergency_contacts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('campus_security', 'police', 'ambulance', 'fire', 'other')),
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  priority INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Personal Emergency Contacts Table (user's personal contacts)
CREATE TABLE IF NOT EXISTS public.personal_contacts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  relationship TEXT,
  is_primary BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- 2. CREATE INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_incidents_status ON public.incidents(status);
CREATE INDEX IF NOT EXISTS idx_incidents_severity ON public.incidents(severity);
CREATE INDEX IF NOT EXISTS idx_incidents_created_at ON public.incidents(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_incidents_reported_by ON public.incidents(reported_by);
CREATE INDEX IF NOT EXISTS idx_incident_media_incident_id ON public.incident_media(incident_id);
CREATE INDEX IF NOT EXISTS idx_alerts_type ON public.alerts(type);
CREATE INDEX IF NOT EXISTS idx_alerts_created_at ON public.alerts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_is_active ON public.alerts(is_active);
CREATE INDEX IF NOT EXISTS idx_alert_reads_user_id ON public.alert_reads(user_id);
CREATE INDEX IF NOT EXISTS idx_alert_reads_alert_id ON public.alert_reads(alert_id);
CREATE INDEX IF NOT EXISTS idx_buddy_connections_user_id ON public.buddy_connections(user_id);
CREATE INDEX IF NOT EXISTS idx_buddy_connections_buddy_id ON public.buddy_connections(buddy_id);
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_type ON public.emergency_contacts(type);
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_priority ON public.emergency_contacts(priority DESC);
CREATE INDEX IF NOT EXISTS idx_personal_contacts_user_id ON public.personal_contacts(user_id);

-- ============================================================================
-- 3. ENABLE ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incident_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alert_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.buddy_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.personal_contacts ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. CREATE RLS POLICIES
-- ============================================================================

-- Users Policies
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
CREATE POLICY "Users can view their own profile"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
CREATE POLICY "Users can update their own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admin can view all users" ON public.users;
CREATE POLICY "Admin can view all users"
  ON public.users FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Security and admin can view all users" ON public.users;
CREATE POLICY "Security and admin can view all users"
  ON public.users FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role IN ('security', 'admin')
    )
  );

-- Incidents Policies
DROP POLICY IF EXISTS "Anyone authenticated can view incidents" ON public.incidents;
CREATE POLICY "Anyone authenticated can view incidents"
  ON public.incidents FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Users can create incidents" ON public.incidents;
CREATE POLICY "Users can create incidents"
  ON public.incidents FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Security and admin can update incidents" ON public.incidents;
CREATE POLICY "Security and admin can update incidents"
  ON public.incidents FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role IN ('security', 'admin')
    )
  );

-- Incident Media Policies
DROP POLICY IF EXISTS "Anyone authenticated can view incident media" ON public.incident_media;
CREATE POLICY "Anyone authenticated can view incident media"
  ON public.incident_media FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Users can upload incident media" ON public.incident_media;
CREATE POLICY "Users can upload incident media"
  ON public.incident_media FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Alerts Policies
DROP POLICY IF EXISTS "Anyone authenticated can view active alerts" ON public.alerts;
CREATE POLICY "Anyone authenticated can view active alerts"
  ON public.alerts FOR SELECT
  USING (auth.uid() IS NOT NULL AND is_active = TRUE);

DROP POLICY IF EXISTS "Security and admin can create alerts" ON public.alerts;
CREATE POLICY "Security and admin can create alerts"
  ON public.alerts FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role IN ('security', 'admin')
    )
  );

DROP POLICY IF EXISTS "Security and admin can update alerts" ON public.alerts;
CREATE POLICY "Security and admin can update alerts"
  ON public.alerts FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role IN ('security', 'admin')
    )
  );

-- Alert Reads Policies
DROP POLICY IF EXISTS "Users can view their own alert reads" ON public.alert_reads;
CREATE POLICY "Users can view their own alert reads"
  ON public.alert_reads FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can mark alerts as read" ON public.alert_reads;
CREATE POLICY "Users can mark alerts as read"
  ON public.alert_reads FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Buddy Connections Policies
DROP POLICY IF EXISTS "Users can view their buddy connections" ON public.buddy_connections;
CREATE POLICY "Users can view their buddy connections"
  ON public.buddy_connections FOR SELECT
  USING (auth.uid() = user_id OR auth.uid() = buddy_id);

DROP POLICY IF EXISTS "Users can create buddy connections" ON public.buddy_connections;
CREATE POLICY "Users can create buddy connections"
  ON public.buddy_connections FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their buddy connections" ON public.buddy_connections;
CREATE POLICY "Users can update their buddy connections"
  ON public.buddy_connections FOR UPDATE
  USING (auth.uid() = user_id OR auth.uid() = buddy_id);

DROP POLICY IF EXISTS "Users can delete their buddy connections" ON public.buddy_connections;
CREATE POLICY "Users can delete their buddy connections"
  ON public.buddy_connections FOR DELETE
  USING (auth.uid() = user_id OR auth.uid() = buddy_id);

-- Emergency Contacts Policies
DROP POLICY IF EXISTS "Anyone authenticated can view emergency contacts" ON public.emergency_contacts;
CREATE POLICY "Anyone authenticated can view emergency contacts"
  ON public.emergency_contacts FOR SELECT
  USING (auth.uid() IS NOT NULL AND is_active = TRUE);

DROP POLICY IF EXISTS "Admin can manage emergency contacts" ON public.emergency_contacts;
CREATE POLICY "Admin can manage emergency contacts"
  ON public.emergency_contacts FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Personal Contacts Policies
DROP POLICY IF EXISTS "Users can view their own personal contacts" ON public.personal_contacts;
CREATE POLICY "Users can view their own personal contacts"
  ON public.personal_contacts FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create their own personal contacts" ON public.personal_contacts;
CREATE POLICY "Users can create their own personal contacts"
  ON public.personal_contacts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own personal contacts" ON public.personal_contacts;
CREATE POLICY "Users can update their own personal contacts"
  ON public.personal_contacts FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own personal contacts" ON public.personal_contacts;
CREATE POLICY "Users can delete their own personal contacts"
  ON public.personal_contacts FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- 5. CREATE FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to tables
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_incidents_updated_at ON public.incidents;
CREATE TRIGGER update_incidents_updated_at
  BEFORE UPDATE ON public.incidents
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_buddy_connections_updated_at ON public.buddy_connections;
CREATE TRIGGER update_buddy_connections_updated_at
  BEFORE UPDATE ON public.buddy_connections
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_personal_contacts_updated_at ON public.personal_contacts;
CREATE TRIGGER update_personal_contacts_updated_at
  BEFORE UPDATE ON public.personal_contacts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 6. SEED INITIAL DATA
-- ============================================================================

-- Insert default emergency contacts
INSERT INTO public.emergency_contacts (name, phone, type, description, priority) 
VALUES
  ('Campus Security', '911', 'campus_security', '24/7 Campus Security Emergency Line', 100),
  ('Police', '911', 'police', 'Local Police Emergency', 90),
  ('Ambulance', '911', 'ambulance', 'Medical Emergency Services', 90),
  ('Fire Department', '911', 'fire', 'Fire Emergency Services', 90),
  ('Campus Health Center', '555-0100', 'other', 'Non-emergency medical assistance', 50)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SETUP COMPLETE
-- ============================================================================

-- Verify tables were created
SELECT 
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name AND table_schema = 'public') as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
  AND table_name IN ('users', 'incidents', 'incident_media', 'alerts', 'alert_reads', 'buddy_connections', 'emergency_contacts')
ORDER BY table_name;

