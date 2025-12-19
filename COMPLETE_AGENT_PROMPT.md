# Complete Agent Prompt: Fix Supabase Database Issues

## Original Problem Statement

I have a Swift iOS app (STUDIO) with persistent errors that keep occurring. The app uses Supabase as the backend. Despite multiple attempts to fix the issues with Claude code, the problems persist. The errors shown in the app screenshots indicate:

1. **"infinite recursion detected in policy for relation 'party_hosts'"** - This error appears when trying to create a party, specifically during the host addition step after party creation.

2. **"column party_guests.invited_at does not exist"** - The app code is trying to query a column named `invited_at` but the database uses `created_at` instead.

3. **"column parties_1.party_date does not exist"** - Queries are referencing `party_date` but the database column is named `starts_at`.

4. **Login issues** - Authentication flow is not working properly.

5. **Party creation with empty title** - Users should be able to create parties without entering a title (should use default "Untitled Party").

## Supabase Project Information

- **Project Reference ID**: `bhtexrnnrrymbhqonxfw`
- **Project Name**: STUDIO
- **Region**: West US (Oregon)
- **Tables**: profiles, parties, party_hosts, party_guests, party_media, party_comments, party_polls, poll_options, poll_votes, party_statuses, follows, notifications

## Code Fixes Already Applied

The following code changes have been committed to the repository:
- Fixed column name mismatches: Changed `invited_at` to `created_at` in queries
- Updated party creation to allow empty titles (uses default)
- Added debug logging instrumentation

## Database Issues to Fix

The SQL script at `/Users/henryvantieghem/STUDIO/supabase_fixes.sql` addresses:

1. **RLS Infinite Recursion**: 
   - The current RLS policies on `party_hosts` and `parties` tables are causing infinite recursion
   - Policies need to be rewritten to avoid circular dependencies
   - The fix checks `created_by` directly on `parties` table rather than joining through `party_hosts`

2. **Column Name Mismatches**:
   - Ensure `parties.starts_at` exists (not `party_date`)
   - Ensure `party_guests.created_at` exists (not `invited_at`)
   - Drop old column names if they exist

3. **Missing Columns**:
   - Add `created_by` column to `parties` table if missing
   - This column is critical for RLS policies to work correctly

4. **Default Values**:
   - Set default title "Untitled Party" for parties table
   - Update existing NULL/empty titles

5. **Performance Indexes**:
   - Add indexes on frequently queried columns for better performance

## Your Task

Using the Supabase MCP tools available in Cursor:

1. **Read the SQL script** from `/Users/henryvantieghem/STUDIO/supabase_fixes.sql`

2. **Execute the SQL script** on the Supabase project `bhtexrnnrrymbhqonxfw`

3. **Verify the fixes were applied** by:
   - Checking that all columns exist with correct names
   - Verifying RLS policies are in place and non-recursive
   - Confirming indexes are created
   - Validating default values are set

4. **Test that the fixes work** (if possible):
   - Try creating a test party to ensure no recursion errors
   - Verify queries work with the correct column names

## Expected Outcomes

After successfully applying the fixes:

✅ Party creation should work without "infinite recursion" errors  
✅ Queries using `created_at` instead of `invited_at` should succeed  
✅ Queries using `starts_at` instead of `party_date` should succeed  
✅ RLS policies should allow authenticated users to create parties  
✅ Users should be able to view parties they're hosts or guests of  
✅ Login/authentication should work properly  
✅ Parties can be created with empty titles (uses default)  

## SQL Script Details

The SQL script uses:
- `IF EXISTS` / `IF NOT EXISTS` checks for safety (can be run multiple times)
- `DROP POLICY IF EXISTS` to safely remove old policies
- Direct `created_by` checks to avoid recursion
- Proper column migrations (copying data before dropping old columns)

## Verification Checklist

After running the script, please verify:

- [ ] `parties.created_by` column exists and has index
- [ ] `parties.starts_at` column exists (not `party_date`)
- [ ] `party_guests.created_at` column exists (not `invited_at`)
- [ ] RLS policies on `party_hosts` don't cause recursion
- [ ] RLS policies on `parties` allow proper access control
- [ ] Indexes are created on all mentioned columns
- [ ] Default title is set for parties table
- [ ] All policies use `(SELECT auth.uid())` pattern for performance

## Important Notes

- The SQL script is idempotent - safe to run multiple times
- The script drops and recreates policies to fix recursion
- All new policies check `created_by` directly to avoid circular dependencies
- Existing data is preserved (columns copied before dropping old ones)

Please execute the SQL script using Supabase MCP tools and provide confirmation of successful application and verification results.

