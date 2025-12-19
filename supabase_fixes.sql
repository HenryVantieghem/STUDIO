-- Supabase Database Fixes
-- Run these in the Supabase SQL Editor to fix the errors

-- ============================================
-- FIX 1: Drop problematic RLS policies that cause infinite recursion
-- ============================================

-- Drop existing policies on party_hosts that might cause recursion
DROP POLICY IF EXISTS "Users can view party_hosts" ON party_hosts;
DROP POLICY IF EXISTS "Hosts can view their party_hosts" ON party_hosts;
DROP POLICY IF EXISTS "Users can insert into party_hosts" ON party_hosts;
DROP POLICY IF EXISTS "Creators can add hosts" ON party_hosts;
DROP POLICY IF EXISTS "Hosts can add hosts" ON party_hosts;

-- Create simple, non-recursive policies for party_hosts

-- SELECT: Users can see hosts for parties they're part of (as host or guest)
CREATE POLICY "Users can view hosts for their parties"
ON party_hosts FOR SELECT
TO authenticated
USING (
    -- User is a host themselves
    user_id = (SELECT auth.uid())
    OR
    -- User is a guest of the party
    EXISTS (
        SELECT 1 FROM party_guests pg
        WHERE pg.party_id = party_hosts.party_id
        AND pg.user_id = (SELECT auth.uid())
    )
);

-- INSERT: Only party hosts can add new hosts (but not recursively checking party_hosts)
CREATE POLICY "Party creators can add hosts"
ON party_hosts FOR INSERT
TO authenticated
WITH CHECK (
    -- User is the creator of the party
    EXISTS (
        SELECT 1 FROM parties p
        WHERE p.id = party_hosts.party_id
        AND p.created_by = (SELECT auth.uid())
    )
);

-- UPDATE/DELETE: Only party creator can manage hosts
CREATE POLICY "Party creators can manage hosts"
ON party_hosts FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM parties p
        WHERE p.id = party_hosts.party_id
        AND p.created_by = (SELECT auth.uid())
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM parties p
        WHERE p.id = party_hosts.party_id
        AND p.created_by = (SELECT auth.uid())
    )
);

CREATE POLICY "Party creators can delete hosts"
ON party_hosts FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM parties p
        WHERE p.id = party_hosts.party_id
        AND p.created_by = (SELECT auth.uid())
    )
);

-- ============================================
-- FIX 2: Ensure parties table has created_by column
-- ============================================

-- Check if created_by column exists, add if not
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'parties' AND column_name = 'created_by'
    ) THEN
        ALTER TABLE parties ADD COLUMN created_by UUID REFERENCES auth.users(id);
        CREATE INDEX IF NOT EXISTS idx_parties_created_by ON parties(created_by);
    END IF;
END $$;

-- ============================================
-- FIX 3: Ensure parties table uses starts_at (not party_date)
-- ============================================

-- Verify starts_at column exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'parties' AND column_name = 'starts_at'
    ) THEN
        ALTER TABLE parties ADD COLUMN starts_at TIMESTAMPTZ;
    END IF;
END $$;

-- Drop party_date column if it exists (old column name)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'parties' AND column_name = 'party_date'
    ) THEN
        ALTER TABLE parties DROP COLUMN party_date;
    END IF;
END $$;

-- ============================================
-- FIX 4: Ensure party_guests uses created_at (not invited_at)
-- ============================================

-- Verify created_at column exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'party_guests' AND column_name = 'created_at'
    ) THEN
        ALTER TABLE party_guests ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
END $$;

-- Drop invited_at column if it exists (should use created_at instead)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'party_guests' AND column_name = 'invited_at'
    ) THEN
        -- Copy data if needed
        UPDATE party_guests SET created_at = invited_at WHERE created_at IS NULL;
        ALTER TABLE party_guests DROP COLUMN invited_at;
    END IF;
END $$;

-- ============================================
-- FIX 5: Fix RLS policies for parties table
-- ============================================

-- Drop existing policies that might cause recursion
DROP POLICY IF EXISTS "Users can view their parties" ON parties;
DROP POLICY IF EXISTS "Hosts can view their parties" ON parties;
DROP POLICY IF EXISTS "Guests can view their parties" ON parties;
DROP POLICY IF EXISTS "Users can create parties" ON parties;

-- Create clean, non-recursive policies for parties

-- SELECT: Users can view parties they created, are hosts of, or are guests of
CREATE POLICY "Users can view their parties"
ON parties FOR SELECT
TO authenticated
USING (
    -- User is the creator
    created_by = (SELECT auth.uid())
    OR
    -- User is a host (direct check, no join)
    EXISTS (
        SELECT 1 FROM party_hosts ph
        WHERE ph.party_id = parties.id
        AND ph.user_id = (SELECT auth.uid())
    )
    OR
    -- User is an accepted guest
    EXISTS (
        SELECT 1 FROM party_guests pg
        WHERE pg.party_id = parties.id
        AND pg.user_id = (SELECT auth.uid())
        AND pg.status = 'accepted'
    )
    OR
    -- Party is public
    privacy = 'public'
);

-- INSERT: Authenticated users can create parties
CREATE POLICY "Users can create parties"
ON parties FOR INSERT
TO authenticated
WITH CHECK (
    created_by = (SELECT auth.uid())
);

-- UPDATE: Only creator can update
CREATE POLICY "Creators can update parties"
ON parties FOR UPDATE
TO authenticated
USING (created_by = (SELECT auth.uid()))
WITH CHECK (created_by = (SELECT auth.uid()));

-- DELETE: Only creator can delete
CREATE POLICY "Creators can delete parties"
ON parties FOR DELETE
TO authenticated
USING (created_by = (SELECT auth.uid()));

-- ============================================
-- FIX 6: Ensure title has a default value
-- ============================================

-- Set default title if null
DO $$
BEGIN
    -- Set default for existing rows
    UPDATE parties SET title = 'Untitled Party' WHERE title IS NULL OR title = '';
    
    -- Alter column to have default
    ALTER TABLE parties ALTER COLUMN title SET DEFAULT 'Untitled Party';
END $$;

-- ============================================
-- FIX 7: Add indexes for performance
-- ============================================

CREATE INDEX IF NOT EXISTS idx_party_hosts_party_id ON party_hosts(party_id);
CREATE INDEX IF NOT EXISTS idx_party_hosts_user_id ON party_hosts(user_id);
CREATE INDEX IF NOT EXISTS idx_party_guests_party_id ON party_guests(party_id);
CREATE INDEX IF NOT EXISTS idx_party_guests_user_id ON party_guests(user_id);
CREATE INDEX IF NOT EXISTS idx_party_guests_status ON party_guests(status);
CREATE INDEX IF NOT EXISTS idx_parties_created_by ON parties(created_by);
CREATE INDEX IF NOT EXISTS idx_parties_status ON parties(status);
CREATE INDEX IF NOT EXISTS idx_parties_privacy ON parties(privacy);

