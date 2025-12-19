# Supabase Database Fixes - Agent Prompt

## Context & Problem Statement

I have a Swift iOS app (STUDIO) using Supabase as the backend. The app has been experiencing persistent errors that prevent core functionality from working:

### Errors Encountered:

1. **"infinite recursion detected in policy for relation 'party_hosts'"**
   - Occurs when trying to create a party
   - Happens during the `addHost` operation after party creation
   - RLS policies are creating circular dependencies

2. **"column party_guests.invited_at does not exist"**
   - App code queries `invited_at` but database uses `created_at`
   - Occurs in queries like `FeedService.getPendingInvitations()` and `PartyService.getGuests()`

3. **"column parties_1.party_date does not exist"**
   - Some queries reference `party_date` but database uses `starts_at`
   - Occurs when fetching party data with joins

4. **Login/Auth Issues**
   - Authentication flow needs verification
   - May be related to RLS policies blocking profile access

5. **Party Creation Issues**
   - Cannot create parties with empty title (should use default "Untitled Party")
   - RLS policies blocking insert operations

### Supabase Project Details:

- **Project ID/Ref**: `bhtexrnnrrymbhqonxfw`
- **Project Name**: STUDIO
- **Region**: West US (Oregon)
- **Tables**: profiles, parties, party_hosts, party_guests, party_media, party_comments, party_polls, poll_options, poll_votes, party_statuses, follows, notifications

### Code Fixes Already Applied:

The following code changes have already been committed:
- Fixed `invited_at` → `created_at` in PartyService and FeedService
- Updated party creation to allow empty titles
- Added debug instrumentation

### Database Schema Issues to Fix:

1. **RLS Policies**: Need to fix infinite recursion in `party_hosts` and `parties` tables
2. **Column Names**: Ensure correct column names exist (created_at, starts_at, created_by)
3. **Missing Columns**: Add `created_by` to parties table if missing
4. **Default Values**: Set default title for parties
5. **Indexes**: Add performance indexes

## Task

Use the Supabase MCP tools available in Cursor to:

1. **Run the SQL script** located at `supabase_fixes.sql` in this workspace
2. **Verify** that all fixes were applied successfully
3. **Check** the database schema to ensure:
   - All required columns exist with correct names
   - RLS policies are in place and non-recursive
   - Indexes are created
   - Default values are set

## SQL Script Location

The SQL script is at: `/Users/henryvantieghem/STUDIO/supabase_fixes.sql`

## Expected Outcome

After applying the fixes:
- ✅ Party creation should work without infinite recursion errors
- ✅ Queries using `created_at` instead of `invited_at` should work
- ✅ Queries using `starts_at` instead of `party_date` should work
- ✅ RLS policies should allow authenticated users to create parties
- ✅ Users should be able to view parties they're hosts or guests of
- ✅ Login/authentication should work properly

## Verification Steps

After running the script, please verify:

1. Check that `parties.created_by` column exists
2. Check that `parties.starts_at` column exists (not `party_date`)
3. Check that `party_guests.created_at` column exists (not `invited_at`)
4. Verify RLS policies on `party_hosts` table don't cause recursion
5. Verify RLS policies on `parties` table allow proper access
6. Confirm indexes are created
7. Test that a party can be created (if possible via API or SQL)

## Additional Notes

- The SQL script uses `IF EXISTS` and `IF NOT EXISTS` checks, so it's safe to run multiple times
- The script drops and recreates RLS policies to fix recursion issues
- All policies check `created_by` directly rather than joining through `party_hosts` to avoid recursion

Please run the SQL script using Supabase MCP tools and confirm all fixes are applied successfully.

