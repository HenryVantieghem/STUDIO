# STUDIO App - Comprehensive Supabase Wiring Prompt

## Overview

Wire the STUDIO iOS party app with full Supabase functionality. This is a social event app where users create parties, invite guests, share media, post statuses, vote on polls, and rate experiences.

**Supabase Project ID:** `bhtexrnnrrymbhqonxfw`

---

## Database Schema Requirements

### 1. Core Tables

```sql
-- Users profile (extends auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  is_private BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Parties
CREATE TABLE parties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  title TEXT NOT NULL,
  description TEXT,
  cover_image_url TEXT,
  location TEXT,
  party_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  is_public BOOLEAN DEFAULT false,
  max_guests INT,
  party_type TEXT, -- pregame, nightclub, houseparty, etc.
  vibe_style TEXT, -- chill, hype, classy, etc.
  dress_code TEXT  -- casual, allBlack, formal, etc.
);

-- Party hosts (up to 5 per party)
CREATE TABLE party_hosts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  party_id UUID REFERENCES parties(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'cohost', -- creator, cohost
  added_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(party_id, user_id)
);

-- Party guests with RSVP status
CREATE TABLE party_guests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  party_id UUID REFERENCES parties(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending', -- pending, accepted, declined, maybe
  invited_by UUID REFERENCES profiles(id),
  invited_at TIMESTAMPTZ DEFAULT NOW(),
  responded_at TIMESTAMPTZ,
  UNIQUE(party_id, user_id)
);

-- Party media (photos/videos)
CREATE TABLE party_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  party_id UUID REFERENCES parties(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  media_type TEXT NOT NULL, -- photo, video
  url TEXT NOT NULL,
  thumbnail_url TEXT,
  caption TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  duration FLOAT -- for videos
);

-- Comments
CREATE TABLE party_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  party_id UUID REFERENCES parties(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  parent_id UUID REFERENCES party_comments(id) ON DELETE CASCADE
);

-- Polls
CREATE TABLE party_polls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  party_id UUID REFERENCES parties(id) ON DELETE CASCADE,
  created_by UUID REFERENCES profiles(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  poll_type TEXT NOT NULL, -- partyMVP, bestDressed, bestMoment, custom
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true
);

-- Poll options
CREATE TABLE poll_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id UUID REFERENCES party_polls(id) ON DELETE CASCADE,
  option_text TEXT, -- for custom polls
  option_user_id UUID REFERENCES profiles(id), -- for user polls (MVP, best dressed)
  vote_count INT DEFAULT 0
);

-- Poll votes
CREATE TABLE poll_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id UUID REFERENCES party_polls(id) ON DELETE CASCADE,
  option_id UUID REFERENCES poll_options(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(poll_id, user_id)
);

-- Status updates (drunk meter, vibe check, etc.)
CREATE TABLE party_statuses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  party_id UUID REFERENCES parties(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  status_type TEXT NOT NULL, -- drunkMeter, vibeCheck, energy, danceMode, etc.
  value INT NOT NULL CHECK (value >= 1 AND value <= 5),
  message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Follow relationships
CREATE TABLE follows (
  follower_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  following_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (follower_id, following_id)
);

-- Notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL, -- partyInvite, comment, poll, status, follow, mention, media
  title TEXT,
  body TEXT,
  data JSONB, -- flexible payload
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Blocked users
CREATE TABLE user_blocks (
  blocker_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  blocked_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (blocker_id, blocked_id)
);
```

### 2. Gamification Tables

```sql
-- User stats for XP/levels
CREATE TABLE user_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
  total_xp INT DEFAULT 0,
  level INT DEFAULT 1,
  parties_hosted INT DEFAULT 0,
  parties_attended INT DEFAULT 0,
  photos_shared INT DEFAULT 0,
  polls_created INT DEFAULT 0,
  polls_voted INT DEFAULT 0,
  drinks_logged INT DEFAULT 0,
  current_streak INT DEFAULT 0,
  longest_streak INT DEFAULT 0,
  last_active_date DATE
);

-- Achievements
CREATE TABLE achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  achievement_type TEXT NOT NULL,
  progress INT DEFAULT 0,
  target INT NOT NULL,
  unlocked_at TIMESTAMPTZ,
  UNIQUE(user_id, achievement_type)
);

-- Drink logs
CREATE TABLE drink_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  party_id UUID REFERENCES parties(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  drink_type TEXT NOT NULL,
  custom_name TEXT,
  quantity INT DEFAULT 1,
  logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- Party ratings
CREATE TABLE party_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  party_id UUID REFERENCES parties(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  overall_rating INT NOT NULL CHECK (overall_rating >= 1 AND overall_rating <= 5),
  vibe_rating INT CHECK (vibe_rating >= 1 AND vibe_rating <= 5),
  music_rating INT CHECK (music_rating >= 1 AND music_rating <= 5),
  crowd_rating INT CHECK (crowd_rating >= 1 AND crowd_rating <= 5),
  venue_rating INT CHECK (venue_rating >= 1 AND venue_rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(party_id, user_id)
);

-- Host ratings
CREATE TABLE host_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  rater_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  party_id UUID REFERENCES parties(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(host_id, rater_id, party_id)
);
```

### 3. Additional Feature Tables

```sql
-- Song requests
CREATE TABLE song_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  party_id UUID REFERENCES parties(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  spotify_uri TEXT,
  status TEXT DEFAULT 'queued', -- queued, playing, played, skipped
  vote_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  played_at TIMESTAMPTZ
);

-- Song votes
CREATE TABLE song_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  song_id UUID REFERENCES song_requests(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  vote_type TEXT NOT NULL, -- up, down
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(song_id, user_id)
);

-- Venue hops (multi-location parties)
CREATE TABLE venue_hops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  party_id UUID REFERENCES parties(id) ON DELETE CASCADE,
  added_by UUID REFERENCES profiles(id),
  venue_name TEXT NOT NULL,
  address TEXT,
  latitude FLOAT,
  longitude FLOAT,
  arrival_time TIMESTAMPTZ,
  departure_time TIMESTAMPTZ,
  is_current BOOLEAN DEFAULT false
);

-- Host requests (drink runs, etc.)
CREATE TABLE host_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  party_id UUID REFERENCES parties(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  request_type TEXT NOT NULL, -- drink_run, song_request, announcement, help, other
  message TEXT,
  status TEXT DEFAULT 'pending', -- pending, approved, dismissed
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Comment likes
CREATE TABLE comment_likes (
  comment_id UUID REFERENCES party_comments(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (comment_id, user_id)
);

-- Party reactions (emoji reactions)
CREATE TABLE party_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  party_id UUID REFERENCES parties(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  target_type TEXT NOT NULL, -- media, comment, status
  target_id UUID NOT NULL,
  emoji TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Row Level Security (RLS) Policies

### Critical RLS Rules

```sql
-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE parties ENABLE ROW LEVEL SECURITY;
ALTER TABLE party_hosts ENABLE ROW LEVEL SECURITY;
ALTER TABLE party_guests ENABLE ROW LEVEL SECURITY;
ALTER TABLE party_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE party_comments ENABLE ROW LEVEL SECURITY;
-- ... enable for all tables

-- Profiles: Users can read all public profiles, update own
CREATE POLICY "Profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING ((SELECT auth.uid()) = id);

-- Parties: Viewable if host, guest (accepted), or public
CREATE POLICY "View parties if authorized" ON parties
  FOR SELECT USING (
    is_public = true OR
    EXISTS (SELECT 1 FROM party_hosts WHERE party_id = id AND user_id = (SELECT auth.uid())) OR
    EXISTS (SELECT 1 FROM party_guests WHERE party_id = id AND user_id = (SELECT auth.uid()) AND status = 'accepted')
  );

-- Party hosts can manage their parties
CREATE POLICY "Hosts can update parties" ON parties
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM party_hosts WHERE party_id = id AND user_id = (SELECT auth.uid()))
  );

-- Guests: Hosts can invite, users can update own status
CREATE POLICY "Hosts can manage guests" ON party_guests
  FOR ALL USING (
    EXISTS (SELECT 1 FROM party_hosts WHERE party_id = party_guests.party_id AND user_id = (SELECT auth.uid()))
  );

CREATE POLICY "Users can update own guest status" ON party_guests
  FOR UPDATE USING (user_id = (SELECT auth.uid()));

-- Media: Party participants can view and add
CREATE POLICY "Participants can view media" ON party_media
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM party_hosts WHERE party_id = party_media.party_id AND user_id = (SELECT auth.uid())) OR
    EXISTS (SELECT 1 FROM party_guests WHERE party_id = party_media.party_id AND user_id = (SELECT auth.uid()) AND status = 'accepted')
  );

-- Comments: Participants can add, own can delete
CREATE POLICY "Participants can add comments" ON party_comments
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM party_hosts WHERE party_id = party_comments.party_id AND user_id = (SELECT auth.uid())) OR
    EXISTS (SELECT 1 FROM party_guests WHERE party_id = party_comments.party_id AND user_id = (SELECT auth.uid()) AND status = 'accepted')
  );

-- Notifications: Users can only see their own
CREATE POLICY "Users see own notifications" ON notifications
  FOR SELECT USING (user_id = (SELECT auth.uid()));
```

---

## Storage Buckets

```sql
-- Create storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);
INSERT INTO storage.buckets (id, name, public) VALUES ('party-media', 'party-media', false);

-- Avatar policies
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload own avatar" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = (SELECT auth.uid())::text
  );

-- Party media policies
CREATE POLICY "Party participants can view media" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'party-media' AND
    EXISTS (
      SELECT 1 FROM parties p
      JOIN party_hosts ph ON ph.party_id = p.id
      WHERE ph.user_id = (SELECT auth.uid())
      AND (storage.foldername(name))[1] = p.id::text
    )
  );
```

---

## Realtime Subscriptions

Enable realtime on these tables:

```sql
-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE party_comments;
ALTER PUBLICATION supabase_realtime ADD TABLE party_statuses;
ALTER PUBLICATION supabase_realtime ADD TABLE party_media;
ALTER PUBLICATION supabase_realtime ADD TABLE party_guests;
ALTER PUBLICATION supabase_realtime ADD TABLE poll_votes;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE song_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE host_requests;
```

---

## Database Functions

### Vote Count Trigger

```sql
-- Auto-update poll vote counts
CREATE OR REPLACE FUNCTION update_poll_vote_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE poll_options SET vote_count = vote_count + 1 WHERE id = NEW.option_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE poll_options SET vote_count = vote_count - 1 WHERE id = OLD.option_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER poll_vote_count_trigger
AFTER INSERT OR DELETE ON poll_votes
FOR EACH ROW EXECUTE FUNCTION update_poll_vote_count();
```

### Song Vote Count Trigger

```sql
CREATE OR REPLACE FUNCTION update_song_vote_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.vote_type = 'up' THEN
      UPDATE song_requests SET vote_count = vote_count + 1 WHERE id = NEW.song_id;
    ELSE
      UPDATE song_requests SET vote_count = vote_count - 1 WHERE id = NEW.song_id;
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.vote_type = 'up' THEN
      UPDATE song_requests SET vote_count = vote_count - 1 WHERE id = OLD.song_id;
    ELSE
      UPDATE song_requests SET vote_count = vote_count + 1 WHERE id = OLD.song_id;
    END IF;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER song_vote_count_trigger
AFTER INSERT OR DELETE ON song_votes
FOR EACH ROW EXECUTE FUNCTION update_song_vote_count();
```

### XP Award Function

```sql
CREATE OR REPLACE FUNCTION award_xp(p_user_id UUID, p_xp INT)
RETURNS INT AS $$
DECLARE
  new_total INT;
  new_level INT;
BEGIN
  UPDATE user_stats
  SET total_xp = total_xp + p_xp,
      level = GREATEST(1, FLOOR(SQRT((total_xp + p_xp) / 100.0))::INT)
  WHERE user_id = p_user_id
  RETURNING total_xp, level INTO new_total, new_level;

  RETURN new_total;
END;
$$ LANGUAGE plpgsql;
```

### Create Notification Function

```sql
CREATE OR REPLACE FUNCTION create_notification(
  p_user_id UUID,
  p_type TEXT,
  p_title TEXT,
  p_body TEXT,
  p_data JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  notification_id UUID;
BEGIN
  INSERT INTO notifications (user_id, type, title, body, data)
  VALUES (p_user_id, p_type, p_title, p_body, p_data)
  RETURNING id INTO notification_id;

  RETURN notification_id;
END;
$$ LANGUAGE plpgsql;
```

### Auto-create User Stats

```sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_stats (user_id) VALUES (NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_profile_created
AFTER INSERT ON profiles
FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

---

## Required Indexes

```sql
-- Performance indexes
CREATE INDEX idx_party_guests_party_id ON party_guests(party_id);
CREATE INDEX idx_party_guests_user_id ON party_guests(user_id);
CREATE INDEX idx_party_media_party_id ON party_media(party_id);
CREATE INDEX idx_party_comments_party_id ON party_comments(party_id);
CREATE INDEX idx_party_statuses_party_id ON party_statuses(party_id);
CREATE INDEX idx_poll_votes_poll_id ON poll_votes(poll_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(user_id, read);
CREATE INDEX idx_follows_follower ON follows(follower_id);
CREATE INDEX idx_follows_following ON follows(following_id);
CREATE INDEX idx_song_requests_party_id ON song_requests(party_id);
CREATE INDEX idx_drink_logs_party_id ON drink_logs(party_id);
```

---

## User Flows to Test

### 1. Authentication
- [ ] Sign up with email/password creates profile
- [ ] Sign in returns valid session
- [ ] Sign out clears session
- [ ] Password reset sends email

### 2. Party Creation
- [ ] Create party with all fields
- [ ] Creator automatically becomes host
- [ ] Party visible in feed
- [ ] Can edit party details

### 3. Guest Management
- [ ] Host can invite guests
- [ ] Guest receives notification
- [ ] Guest can RSVP (accept/decline/maybe)
- [ ] Host can remove guests
- [ ] Guest list shows correct statuses

### 4. Media Sharing
- [ ] Upload photo to party
- [ ] Upload video with thumbnail
- [ ] Media visible to participants
- [ ] Delete own media

### 5. Comments
- [ ] Add comment to party
- [ ] Edit own comment
- [ ] Delete own comment
- [ ] Reply to comment
- [ ] Like comment

### 6. Polls
- [ ] Create custom poll
- [ ] Create MVP poll (select users)
- [ ] Vote on poll
- [ ] See vote counts update
- [ ] Close poll

### 7. Statuses
- [ ] Post drunk meter status
- [ ] Post vibe check status
- [ ] See latest statuses from all users
- [ ] Status updates in real-time

### 8. Song Requests
- [ ] Request a song
- [ ] Upvote/downvote songs
- [ ] Host marks song as playing
- [ ] Queue reorders by votes

### 9. Drink Tracking
- [ ] Log drink
- [ ] See drink counts
- [ ] See party drink stats

### 10. Gamification
- [ ] XP awarded for actions
- [ ] Level calculated correctly
- [ ] Achievements unlock at targets
- [ ] Stats update in real-time

### 11. Real-time
- [ ] New comments appear live
- [ ] New statuses appear live
- [ ] Poll votes update live
- [ ] Notifications push instantly

### 12. Privacy
- [ ] Private parties hidden from public
- [ ] Blocked users can't see content
- [ ] Private accounts require follow approval

---

## Performance Checklist

- [ ] All queries use indexes
- [ ] RLS policies use `(SELECT auth.uid())` for performance
- [ ] Realtime only on necessary tables
- [ ] Storage policies properly scoped
- [ ] Pagination on all list queries
- [ ] Counts use database functions

---

## Security Checklist

- [ ] RLS enabled on ALL tables
- [ ] No admin bypass policies
- [ ] Storage buckets properly secured
- [ ] User can only modify own data
- [ ] Hosts can only manage own parties
- [ ] Blocked users enforced everywhere
- [ ] Rate limiting on sensitive endpoints

---

## Deployment Steps

1. Create tables in order (profiles first, then parties, etc.)
2. Enable RLS on all tables
3. Create all policies
4. Create storage buckets and policies
5. Enable realtime on specified tables
6. Create triggers and functions
7. Create indexes
8. Test all user flows
9. Verify security policies

---

## Notes for Claude Code with Supabase MCP

When wiring this app:

1. **Use MCP Supabase tools** for direct database operations
2. **Always check RLS** - queries will fail without proper auth
3. **Use transactions** for multi-table operations
4. **Test edge cases** - empty results, no permissions, etc.
5. **Handle errors gracefully** - network, auth, permissions
6. **Cache appropriately** - use CacheManager for frequently accessed data
7. **Subscribe to realtime** - use RealtimeManager for live updates
8. **Award XP** - call GamificationService after user actions

The iOS Swift code is already structured with:
- Services for each feature (PartyService, SocialService, etc.)
- ViewModels for state management
- Caching layer (CacheManager)
- Realtime support (RealtimeManager)
- Error handling patterns

Just need database schema and policies applied to Supabase!
