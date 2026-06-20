-- Vantage SQL Database Initialization Migration

-- Config table
CREATE TABLE IF NOT EXISTS vantage_settings (
  key text PRIMARY KEY,
  value text NOT NULL
);

-- Seed default passwords
INSERT INTO vantage_settings (key, value) VALUES 
('admin_password', 'JgiSnpsu'),
('scanner_password', 'YashbotJgi')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- Create events table
CREATE TABLE IF NOT EXISTS events (
  id text PRIMARY KEY,
  title text NOT NULL,
  category text NOT NULL,
  date text NOT NULL,
  location text NOT NULL,
  capacity integer NOT NULL,
  doors text NOT NULL,
  age_limit text NOT NULL,
  status text NOT NULL CHECK (status IN ('active', 'paused', 'sold_out', 'cancelled', 'draft')),
  image text NOT NULL,
  description text,
  lineup_title text,
  lineup jsonb DEFAULT '[]'::jsonb,
  tiers jsonb NOT NULL,
  is_public boolean DEFAULT true,
  is_featured boolean DEFAULT false,
  is_archived boolean DEFAULT false,
  booking_start timestamptz,
  booking_end timestamptz,
  last_booking_time timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS on events
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- Enable RLS on vantage_settings
ALTER TABLE vantage_settings ENABLE ROW LEVEL SECURITY;

-- SECURITY DEFINER functions to fetch settings values without policy recursion
CREATE OR REPLACE FUNCTION get_admin_password()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT value FROM vantage_settings WHERE key = 'admin_password';
$$;

CREATE OR REPLACE FUNCTION get_scanner_password()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT value FROM vantage_settings WHERE key = 'scanner_password';
$$;

-- Vantage settings policies
CREATE POLICY "Admins can modify settings" ON vantage_settings
  FOR ALL
  USING (
    current_setting('request.headers', true)::json->>'x-admin-password' = get_admin_password()
  )
  WITH CHECK (
    current_setting('request.headers', true)::json->>'x-admin-password' = get_admin_password()
  );

CREATE POLICY "Allow public settings select" ON vantage_settings
  FOR SELECT
  USING (true);

-- Events policies
CREATE POLICY "Allow public read of public non-draft events" ON events
  FOR SELECT
  USING (
    (status <> 'draft' AND is_public = true AND is_archived = false)
    OR
    (current_setting('request.headers', true)::json->>'x-admin-password' = get_admin_password())
  );

CREATE POLICY "Admins can modify events" ON events
  FOR ALL
  USING (
    current_setting('request.headers', true)::json->>'x-admin-password' = get_admin_password()
  )
  WITH CHECK (
    current_setting('request.headers', true)::json->>'x-admin-password' = get_admin_password()
  );

-- Create tickets table
CREATE TABLE IF NOT EXISTS tickets (
  id text PRIMARY KEY,
  event_id text NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  event_name text NOT NULL,
  attendee_name text NOT NULL,
  attendee_email text NOT NULL,
  tier_name text NOT NULL,
  price numeric NOT NULL,
  quantity integer NOT NULL,
  total_paid numeric NOT NULL,
  purchase_date timestamptz DEFAULT now(),
  status text NOT NULL CHECK (status IN ('valid', 'scanned')),
  scan_time timestamptz,
  scan_gate text
);

-- Enable RLS on tickets
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;

-- Tickets policies
CREATE POLICY "Users can read own tickets" ON tickets
  FOR SELECT
  USING (
    attendee_email = current_setting('request.headers', true)::json->>'x-user-email'
    OR
    current_setting('request.headers', true)::json->>'x-admin-password' = get_admin_password()
    OR
    current_setting('request.headers', true)::json->>'x-scanner-password' = get_scanner_password()
  );

CREATE POLICY "Anyone can insert tickets if active" ON tickets
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM events
      WHERE events.id = event_id
        AND events.status = 'active'
        AND events.is_public = true
        AND (events.booking_start IS NULL OR events.booking_start <= now())
        AND (events.booking_end IS NULL OR events.booking_end >= now())
    )
  );

CREATE POLICY "Admins can manage tickets" ON tickets
  FOR ALL
  USING (
    current_setting('request.headers', true)::json->>'x-admin-password' = get_admin_password()
  );

CREATE POLICY "Scanner staff can update ticket scan status" ON tickets
  FOR UPDATE
  USING (
    current_setting('request.headers', true)::json->>'x-scanner-password' = get_scanner_password()
  )
  WITH CHECK (
    current_setting('request.headers', true)::json->>'x-scanner-password' = get_scanner_password()
  );

-- Create logs table
CREATE TABLE IF NOT EXISTS logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type text NOT NULL CHECK (type IN ('success', 'error', 'audit')),
  gate text,
  ticket_id text,
  attendee_name text,
  message text,
  timestamp timestamptz DEFAULT now()
);

-- Enable RLS on logs
ALTER TABLE logs ENABLE ROW LEVEL SECURITY;

-- Logs policies
CREATE POLICY "Admins can manage logs" ON logs
  FOR ALL
  USING (
    current_setting('request.headers', true)::json->>'x-admin-password' = get_admin_password()
  );

CREATE POLICY "Anyone can insert logs" ON logs
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Scanner can read logs" ON logs
  FOR SELECT
  USING (
    current_setting('request.headers', true)::json->>'x-scanner-password' = get_scanner_password()
  );

-- Seed default events
INSERT INTO events (id, title, category, date, location, capacity, doors, age_limit, status, image, description, lineup_title, lineup, tiers, is_public, is_featured) VALUES
(
  'neon-velocity',
  'NEON VELOCITY 2024',
  'MUSIC FESTIVAL',
  'OCTOBER 24-26, 2024',
  'THE SPHERE, LAS VEGAS',
  18000,
  '6:00 PM',
  '21+',
  'active',
  'https://lh3.googleusercontent.com/aida-public/AB6AXuAGPVZLaK26vv38jRe6dDqeuCcXwsy6hVL7lsY_7QGuwc50C38UProzjKe5GZjIGfOyC0--n8n33YC_YRy2WJ5uVy1Rq8BS7-M2C6rkAsfTHxZDbPfinOprE9vrC2VbqrdRPE4ILwNpiW0NhiIOiTS0brlwoY1R4PUepVyTU_6WflAYwDANqF5qu-nV1eVVvlNDQVINo_n2uBZjWJKBpL4io4m98HVsA-jyccbLChJmolHuZn2iDGuLIf51JoXDw9lOoxGqWDTvpsFt',
  'Experience the zenith of electronic soundscapes at Neon Velocity 2024. Transforming The Sphere into a multidimensional sensory arena with cutting-edge audio engineering and visual installations.',
  'Featured Lineup',
  '[
    {"name": "SYNTH WAVE", "role": "HEADLINER", "image": "https://lh3.googleusercontent.com/aida-public/AB6AXuBFv5oL-d7mDt5h9WtWJwMnPSCYneVk6Zg2aHR_oOnWxrSLBXC2CtwU4tJxsbYkNzcis6IEj5s_BO8k56kiV2JRY3-Iz8Jl3Vfzv7p0SzIoePaMbRolwZHH-349I0R63zNaBhcUtoWAZeXhry7tU9eOHbIce93NI81XNbZ5NK6T60ttD3PTO4SUm8NRgU9EbKicALpTGr8zctnY06CCdYpU9Sm9BGZqR-J3xNL-Cey4oLxiNaMftQ325xO_2JOvfqytfkfflwaxW2eI"},
    {"name": "KINETIC FLOW", "role": "FRIDAY MAIN", "image": "https://lh3.googleusercontent.com/aida-public/AB6AXuCN4Kp9xJcTSB5yiE1HfjAlxZG0t6e_tOyKeHzWBq8xMzM78WW-911T7mCD7bf_WvX_3kvYwaRHv4goli90EbvvhPN1VGTXYE6kY3cVnfP8dc5NQustDJ8CdKZ_m_kEccZ3LrZoNFlQb2cXBqx18WF941NYyYrWCjY00HHVBfe5oovmRfGO2_WpjKLpGve0q3KpDtuRiYseKgcZuOjWSc_qmJZ3WexQD1kpqKfG-wtrfzSNnSUGo_AIM0sM9a-EyZyiz4d8xoenNE0C"},
    {"name": "CYBER BEAT", "role": "SPECIAL GUEST", "image": "https://lh3.googleusercontent.com/aida-public/AB6AXuAWY_CyCYP4VyRNw5FvG9HB6_SK89t83G22B_dvuQM7TYv4R5uAYszhYotLBmUD7C8dkFDPVTp3zZKK5Pd3K31LuR4OVCLrk20dI3Sh7sp1OIdlrsJrkcheJF-aLVR_0QJwbeKOwebLRG3l5VozVEpn9YsGTvqP-hWpWPJBFdM1dEyMIOMg_Wyx_VgxhRtHb6UaUD_qIH2uF5yOaYAKae4NsakF1SW1Wu9JLNqs8gJh39h2zP6Bc2K9-z36qFZbf0qCXwULthd26rKe"}
  ]'::jsonb,
  '[
    {"name": "VIP Experience", "price": 15000, "desc": "Front row access + Lounge", "qtyLeft": 12},
    {"name": "Premium Access", "price": 7500, "desc": "Elevated viewing deck", "qtyLeft": 100},
    {"name": "General Admission", "price": 3500, "desc": "Main arena floor access", "qtyLeft": 250}
  ]'::jsonb,
  true,
  false
),
(
  'neon-eclipse',
  'NEON ECLIPSE 2024',
  'MUSIC / ELECTRONIC',
  'NOVEMBER 15-16, 2024',
  'THE VOID DISTRICT, NEW YORK',
  5000,
  '8:00 PM',
  '18+',
  'active',
  'https://lh3.googleusercontent.com/aida-public/AB6AXuCSHwGo8C797_C_o_1mdVMCnLAINlYeiq9-oSO__eTUHD7vdnilzpvVLodlRBhpfrUh7kHpl7RmSit07SGEkCOFGWGt34TZ1DutXYsyK1AM34remj1uSgtr3QinAus98BO5wj-MhdjAKdj0QutJxmPnq0U7dqU-tggz3LnKYYqnPHMDfLxDgCCq4R3K0EQWgUWt2auEj-mManJkJQJyWqz0HkjguRBZkAHcWimQSCQrsC5wU0KjEHNtqPLZC0irA0KpWfpO2q5DpH_N',
  'The premier underground electronic music festival, bringing together world-class visual artists and dark-techno beatmakers for a 48-hour sonic journey in the Void District.',
  'DJ Lineup',
  '[
    {"name": "DJ Matrix", "role": "HEADLINER", "image": "https://lh3.googleusercontent.com/aida-public/AB6AXuBFv5oL-d7mDt5h9WtWJwMnPSCYneVk6Zg2aHR_oOnWxrSLBXC2CtwU4tJxsbYkNzcis6IEj5s_BO8k56kiV2JRY3-Iz8Jl3Vfzv7p0SzIoePaMbRolwZHH-349I0R63zNaBhcUtoWAZeXhry7tU9eOHbIce93NI81XNbZ5NK6T60ttD3PTO4SUm8NRgU9EbKicALpTGr8zctnY06CCdYpU9Sm9BGZqR-J3xNL-Cey4oLxiNaMftQ325xO_2JOvfqytfkfflwaxW2eI"},
    {"name": "Pixel Pulse", "role": "SUPPORTING", "image": "https://lh3.googleusercontent.com/aida-public/AB6AXuCN4Kp9xJcTSB5yiE1HfjAlxZG0t6e_tOyKeHzWBq8xMzM78WW-911T7mCD7bf_WvX_3kvYwaRHv4goli90EbvvhPN1VGTXYE6kY3cVnfP8dc5NQustDJ8CdKZ_m_kEccZ3LrZoNFlQb2cXBqx18WF941NYyYrWCjY00HHVBfe5oovmRfGO2_WpjKLpGve0q3KpDtuRiYseKgcZuOjWSc_qmJZ3WexQD1kpqKfG-wtrfzSNnSUGo_AIM0sM9a-EyZyiz4d8xoenNE0C"},
    {"name": "Sub-Zero", "role": "SPECIAL GUEST", "image": "https://lh3.googleusercontent.com/aida-public/AB6AXuAWY_CyCYP4VyRNw5FvG9HB6_SK89t83G22B_dvuQM7TYv4R5uAYszhYotLBmUD7C8dkFDPVTp3zZKK5Pd3K31LuR4OVCLrk20dI3Sh7sp1OIdlrsJrkcheJF-aLVR_0QJwbeKOwebLRG3l5VozVEpn9YsGTvqP-hWpWPJBFdM1dEyMIOMg_Wyx_VgxhRtHb6UaUD_qIH2uF5yOaYAKae4NsakF1SW1Wu9JLNqs8gJh39h2zP6Bc2K9-z36qFZbf0qCXwULthd26rKe"}
  ]'::jsonb,
  '[
    {"name": "Mainstage Pass", "price": 4999, "desc": "Main arena + Laser show", "qtyLeft": 45},
    {"name": "VIP Backstage", "price": 12500, "desc": "Artist meet & greet", "qtyLeft": 5}
  ]'::jsonb,
  true,
  true
),
(
  'silicon-horizon',
  'SILICON HORIZON 2024',
  'TECH CONFERENCE',
  'DECEMBER 02-04, 2024',
  'TECH CENTRE, SAN FRANCISCO',
  3000,
  '9:00 AM',
  'All Ages',
  'active',
  'https://lh3.googleusercontent.com/aida-public/AB6AXuAhIgSiexNqcVzIDixPBD9cOnB14hTLUoeW42k9tjzJYxxxqtVGtxWsuv2QnjhoWeeu1zlJxwW5P7gBK52vfHbI8XfgUw0jklNwSvfKZ84stktcUFBsrAj1A3FLy4U9Kk5ruyYJm4r5Cj47n5alW5VxjSjFo8JlQHRCtcwNskW-wA_0sy4HUA8O-5BEnvs_I9sXLTqlwDKiShm76lpvZ0r-kQ-uoAshQyGjK3ZBfmE3exHXuf1eYYVQTnhylp2dsTVwtYqW5rfEjo9w',
  'Join global visionaries and leading researchers at Silicon Horizon, the premier summit on generative AI, neural interfaces, and the future of human-machine collaboration.',
  'Keynote Speakers',
  '[
    {"name": "Dr. Aris Thorne", "role": "AI Research Lead", "image": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80"},
    {"name": "Elena Rostova", "role": "Neural Interfaces Expert", "image": "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=300&q=80"},
    {"name": "Marcus Chen", "role": "Quantum Computing Director", "image": "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80"}
  ]'::jsonb,
  '[
    {"name": "Conference Pass", "price": 25000, "desc": "Access to all talks & workshops", "qtyLeft": 80},
    {"name": "All-Access VIP", "price": 50000, "desc": "Executive dinners + Private lounge", "qtyLeft": 10}
  ]'::jsonb,
  true,
  false
),
(
  'echoes-in-rain',
  'Echoes in the Rain',
  'MUSIC / ELECTRONIC',
  'OCTOBER 12, 2024',
  'OUTDOOR FOREST AMPHITHEATRE',
  4000,
  '4:00 PM',
  'All Ages',
  'active',
  'https://lh3.googleusercontent.com/aida-public/AB6AXuCb2-UhvYiBuW2ukvjuSPFwjymY8lGGjKJKRg1Td1-Ub6oTlndvA7F3CFVGRhcG8p5TLJ-vFEpCsIWV7uDoZZrJH2Sgwz_-hM8MjPTwgytvAbDQUx9RmRU3A6Gpgd-vLtgx3mrRTN6-1JHenLZr40P_rlsM75MGVKq-eIanDyN8kLI_CBtj62VVBPiv0K-P9EDA6pKwe-V_H-_-Bo7CIaQY-rA0N8PQgwkLVf04QleTgv4WAjkclXniitOJaXDOlDPbACYHQh2mpBb-',
  'An ambient and neo-classical music gathering nestled in the heart of the forest. Unplug and connect with nature through soundscapes, acoustic instruments, and organic lighting.',
  'Featured Artists',
  '[
    {"name": "Forest Echoes", "role": "AMBIENT LIVE", "image": "https://images.unsplash.com/photo-1465847899084-d164df4dedc6?auto=format&fit=crop&w=300&q=80"},
    {"name": "Raindance Duo", "role": "ACOUSTIC SET", "image": "https://images.unsplash.com/photo-1511192336575-5a79af67a629?auto=format&fit=crop&w=300&q=80"},
    {"name": "Luna Breeze", "role": "SOLO VIOLINIST", "image": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80"}
  ]'::jsonb,
  '[
    {"name": "Book Ticket", "price": 2000, "desc": "General Pass", "qtyLeft": 150}
  ]'::jsonb,
  true,
  false
),
(
  'digital-canvas',
  'Digital Canvas Expo',
  'ART & TECH',
  'NOVEMBER 05, 2024',
  'METROPOLIS GALLERY',
  1500,
  '10:00 AM',
  'All Ages',
  'active',
  'https://lh3.googleusercontent.com/aida-public/AB6AXuDzhL3N7COnZFnVD10E5UasCcJ9MBcc9CSjnHEJAm3r9ZiPFIDRa4a0rrg3nPXVpwJUyg-9izo-6Dk903HqzKcCvEf8IpiZ4PkZuQS0-lXHgqWMdYkT2kMCOW9cp3CAvlPP9yhommAFdpOivwu5vdefq2rLybjtJBmpfGSKs2aFV-YiGQ0O-plPTbUoP9KeiEOlZfCHG28PHlmZG5RtsYR2dEUpipQr4mYgzecj6KaCLQkAaPKnZt-JfgLSvLmnxAAKe0l-F_Jiy6F5',
  'Explore the intersection of fine art and digital technology. Features interactive projections, virtual reality installations, and generative artwork from international digital artists.',
  'Exhibiting Artists',
  '[
    {"name": "Nova Cypher", "role": "GENERATIVE ART", "image": "https://images.unsplash.com/photo-1541701494587-cb58502866ab?auto=format&fit=crop&w=300&q=80"},
    {"name": "Voxel Studio", "role": "VR IMMERSIVE", "image": "https://images.unsplash.com/photo-1592478411213-6153e4ebc07d?auto=format&fit=crop&w=300&q=80"},
    {"name": "Spectra", "role": "LED INSTALLATIONS", "image": "https://images.unsplash.com/photo-1550745165-9bc0b252726f?auto=format&fit=crop&w=300&q=80"}
  ]'::jsonb,
  '[
    {"name": "Book Ticket", "price": 1500, "desc": "Expo access", "qtyLeft": 60}
  ]'::jsonb,
  true,
  false
),
(
  'midnight-pulse',
  'Midnight Pulse',
  'MUSIC / ELECTRONIC',
  'OCTOBER 30, 2024',
  'CLUB APEX',
  800,
  '10:00 PM',
  '21+',
  'active',
  'https://lh3.googleusercontent.com/aida-public/AB6AXuD_f3QWQ3WS5azNwGLEu_eSfc5ffK6h-mcEXflqmQsY8enzFHTXyCHy34EpvNVJGa_LiJ6tJ8q4s8joDQvoUkLJiiN8qJaoUU8KwndXbs53vu7fqazjT-sku6bvxaalAZeh9B4PQyMs9ryrGPHJFqOaJ2HY4Y6IP3zeK1_MoUrdZoBhV4mOrb2yrJqRVruUz5-snbK9L2vk6YOrIS9VTYrkWR0d9_GmTKpRiOhOSeEvPzQUwQUKKuPeFcnrMRK8EqbvsXCA0fvCldXy',
  'A high-octane late-night club experience at Club Apex. Dive into deep house, techno, and electro beats with immersive sound systems and custom laser choreography.',
  'Club Lineup',
  '[
    {"name": "Apex Resident", "role": "RESIDENT DJ", "image": "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=300&q=80"},
    {"name": "Pulse Project", "role": "LIVE SET", "image": "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=300&q=80"}
  ]'::jsonb,
  '[
    {"name": "Book Now", "price": 3500, "desc": "General Access", "qtyLeft": 40}
  ]'::jsonb,
  true,
  false
),
(
  'code-craft',
  'Code & Craft',
  'TECH WORKSHOP',
  'NOVEMBER 18, 2024',
  'TECH HUB ALPHA',
  300,
  '9:00 AM',
  'All Ages',
  'active',
  'https://lh3.googleusercontent.com/aida-public/AB6AXuADPr0evSJHNJtjGnUQ14IPjozGbQSwpwT9hjOzcPCEYeH106eznPbHBj_c8TXwBhWOOuv3lbSC5MwevQ8sXE_pyAoZ6yBjhdZb8ZsqFIceU7fha2KptRWTtlggoT38VRvpcj9Clb7jK8b3dOXGNF5LmyAJkPrsBg2PgFrvfmTuAmtk7odz_heuf4ajeSkDJjrc01Q7mwmn9409PqVF2L_9vRwqVnB7r9By800wuAbKwNrTs3oSSrJVgQiblk_S_96aAPOsqHTUCIZU',
  'A hands-on coding and software architecture workshop for modern developers. Learn advanced pattern designs, performance optimizations, and building scalable cloud-native architectures.',
  'Workshop Instructors',
  '[
    {"name": "Sarah Jenkins", "role": "STAFF ENGINEER", "image": "https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=300&q=80"},
    {"name": "David Cole", "role": "CLOUD ARCHITECT", "image": "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=300&q=80"}
  ]'::jsonb,
  '[
    {"name": "Book Now", "price": 7500, "desc": "Full workshop + Kit", "qtyLeft": 15}
  ]'::jsonb,
  true,
  false
),
(
  'elite-gala',
  'Elite Gala Night',
  'CONFERENCES',
  'DECEMBER 10, 2024',
  'EXCELSIOR BALLROOM',
  500,
  '7:00 PM',
  '18+',
  'active',
  'https://lh3.googleusercontent.com/aida-public/AB6AXuDyPynP-hZZ3LiT6tgMGnhbxKCTde1-Dbmcg0mtbo5lGwm4NrKl8s_Qnkki2gihQu5C2wCdGwTyJiIH7alt4YbR1qvVWwataNKUvIDdZUC0jKiUAsh4M38POWAAOtcZTHjCWhLdQ5OwiqzbkHkLdvzUeJO3k7NODW5595Khr3oO_pMvU-fApdTguKgqQNk_6r1C9lopq5asOIvgk8lS89Pmog5c1c9zzAA7sEeqxfaApRW4Q27-SIdE0xN9jYyKL_YM-7unVaPLmQZk',
  'A sophisticated formal gathering celebrating excellence in innovation and leadership. Connect with industry pioneers, executives, and leaders over an evening of fine dining and keynotes.',
  'Guest Speakers',
  '[
    {"name": "Victor Sterling", "role": "VANTAGE CEO", "image": "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=300&q=80"},
    {"name": "Claire Belmont", "role": "VENTURES PARTNER", "image": "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=300&q=80"}
  ]'::jsonb,
  '[
    {"name": "Book Now", "price": 15000, "desc": "Gala access", "qtyLeft": 20}
  ]'::jsonb,
  true,
  false
)
ON CONFLICT (id) DO NOTHING;

-- Enable Realtime replication
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime FOR TABLE events, tickets, logs;
COMMIT;
