# Supabase Setup Guide

## Prerequisites

1. **Supabase CLI**: Already installed ✅
2. **Supabase Account**: Create at https://supabase.com
3. **Flutter Dependencies**: supabase_flutter added to pubspec.yaml ✅

## Setup Instructions

### 1. Create Supabase Project

1. Go to https://supabase.com
2. Sign up/Login to your account
3. Click "New Project"
4. Choose organization and fill project details:
   - **Name**: `grex-expense-splitting` (or your preferred name)
   - **Database Password**: Generate a strong password (save it!)
   - **Region**: Choose closest to your users
5. Wait for project creation (2-3 minutes)

### 2. Get Project Credentials

1. Go to **Project Settings** → **API**
2. Copy the following values:
   - **Project URL**: `https://your-project-id.supabase.co`
   - **anon public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
   - **service_role secret key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (optional)

### 3. Configure Environment Variables

Update your `.env` file with the credentials:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 4. Link Local Project (Optional)

To link your local project with the remote Supabase project:

```bash
cd supabase
supabase login
supabase link --project-ref your-project-id
```

### 5. Local Development (Optional)

To run Supabase locally for development:

```bash
cd supabase
supabase start
```

This will start:
- PostgreSQL database on `localhost:54322`
- Supabase Studio on `http://localhost:54323`
- API Gateway on `http://localhost:54321`

## Next Steps

After setup is complete, you can:

1. **Run Migrations**: Apply database schema
2. **Test Connection**: Verify Flutter app can connect
3. **Enable Real-time**: Configure real-time subscriptions
4. **Set up RLS**: Configure Row Level Security policies

## Troubleshooting

### Common Issues

1. **Connection Failed**: Check project URL and API keys
2. **RLS Denies Access**: Ensure policies are configured correctly
3. **Migration Errors**: Check SQL syntax and dependencies

### Useful Commands

```bash
# Check Supabase status
supabase status

# View logs
supabase logs

# Reset local database
supabase db reset

# Generate types (after schema is created)
supabase gen types typescript --local > lib/types/supabase.ts
```

## Security Notes

- ✅ **anon key**: Safe to use in client-side code
- ⚠️ **service_role key**: Keep secret! Server-side only
- 🔒 **Database password**: Store securely, needed for direct DB access
- 🛡️ **RLS**: Always enable Row Level Security on all tables