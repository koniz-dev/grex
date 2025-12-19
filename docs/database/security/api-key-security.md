# API Key Security Guide

## Overview

This document outlines the comprehensive API key security practices implemented in the Grex application for Supabase integration. Proper API key management is critical for maintaining application security and preventing unauthorized access to the database.

## API Key Types

### 1. Anonymous (Anon) Key

**Purpose**: Client-side access with Row Level Security (RLS) enforcement
**Usage**: Safe to use in client-side code (mobile apps, web frontends)
**Permissions**: Limited by RLS policies, cannot bypass security rules

```dart
// ✅ SAFE: Using anon key in client-side code
final supabase = Supabase.initialize(
  url: 'https://your-project.supabase.co',
  anonKey: 'your-anon-key', // Safe for client-side
);
```

**Security Features**:
- Automatically enforces RLS policies
- Cannot access data outside user's permissions
- Rate limited by Supabase
- Can be safely exposed in client applications

### 2. Service Role Key

**Purpose**: Server-side operations that bypass RLS
**Usage**: Server-side only, administrative operations
**Permissions**: Full database access, bypasses all RLS policies

```dart
// ⚠️ DANGER: Service role key should NEVER be in client code
// Only use in secure server environments
final supabaseAdmin = Supabase.initialize(
  url: 'https://your-project.supabase.co',
  anonKey: 'service-role-key', // NEVER expose this!
);
```

**Security Requirements**:
- Must be kept secret at all times
- Never commit to version control
- Only use in trusted server environments
- Rotate regularly

## Environment Configuration

### Environment Variables

All API keys must be stored as environment variables:

```bash
# .env file (never commit this file)
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Flutter/Dart Configuration

```dart
// lib/core/config/env_config.dart
class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://localhost:54321', // Local development
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-local-anon-key',
  );
  
  // Service role key should only be used in server contexts
  static const String supabaseServiceRoleKey = String.fromEnvironment(
    'SUPABASE_SERVICE_ROLE_KEY',
    defaultValue: '',
  );
}
```

## Security Best Practices

### 1. Version Control Security

**✅ DO**:
- Add `.env` to `.gitignore`
- Commit `.env.example` with placeholder values
- Use environment variables for all keys
- Document security requirements in README

**❌ DON'T**:
- Commit actual API keys to git
- Hardcode keys in source code
- Share keys in chat or email
- Store keys in plain text files

### 2. Key Separation

**✅ DO**:
- Use anon key for all client-side operations
- Reserve service role key for admin operations only
- Implement proper RLS policies for anon key access
- Use different keys for different environments

**❌ DON'T**:
- Use service role key in client applications
- Mix development and production keys
- Use the same key for multiple purposes
- Bypass RLS policies unnecessarily

### 3. Access Control

**✅ DO**:
- Implement comprehensive RLS policies
- Use JWT claims for user identification
- Validate permissions at the database level
- Log all administrative operations

**❌ DON'T**:
- Rely solely on client-side validation
- Trust user input without verification
- Grant excessive permissions
- Skip audit logging

## Key Rotation Procedures

### When to Rotate Keys

- **Immediately**: If key is compromised or exposed
- **Regularly**: Every 90 days for service role keys
- **After incidents**: Security breaches or team changes
- **Before major releases**: As part of security hardening

### Rotation Process

1. **Generate New Keys**:
   ```bash
   # In Supabase Dashboard:
   # Settings > API > Generate new anon key
   # Settings > API > Generate new service role key
   ```

2. **Update Environment Variables**:
   ```bash
   # Update production environment
   SUPABASE_ANON_KEY=new-anon-key
   SUPABASE_SERVICE_ROLE_KEY=new-service-role-key
   ```

3. **Deploy Changes**:
   ```bash
   # Deploy with new keys
   flutter build apk --dart-define=SUPABASE_ANON_KEY=new-key
   ```

4. **Revoke Old Keys**:
   ```bash
   # In Supabase Dashboard:
   # Settings > API > Revoke old keys
   ```

5. **Verify Functionality**:
   ```bash
   # Test all critical functions
   # Monitor for authentication errors
   # Verify RLS policies still work
   ```

## Monitoring and Alerting

### Key Usage Monitoring

Monitor API key usage patterns:
- Unusual request volumes
- Requests from unexpected locations
- Failed authentication attempts
- Service role key usage patterns

### Security Alerts

Set up alerts for:
- Multiple failed authentication attempts
- Service role key usage from client IPs
- Unusual data access patterns
- Key rotation reminders

### Audit Logging

Log all key-related activities:
- Key generation and rotation
- Authentication failures
- Administrative operations
- Policy violations

## Development vs Production

### Development Environment

```bash
# .env.development
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
```

### Production Environment

```bash
# .env.production (secure environment only)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-production-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-production-service-role-key
```

## Incident Response

### If API Key is Compromised

1. **Immediate Actions**:
   - Revoke compromised key immediately
   - Generate new key
   - Update all applications
   - Monitor for unauthorized access

2. **Investigation**:
   - Review access logs
   - Identify scope of compromise
   - Check for data breaches
   - Document incident

3. **Recovery**:
   - Deploy new keys to all environments
   - Verify all services are working
   - Update security procedures
   - Conduct post-incident review

### Emergency Contacts

- **Security Team**: security@company.com
- **DevOps Team**: devops@company.com
- **On-call Engineer**: +1-xxx-xxx-xxxx

## Compliance and Auditing

### Security Standards

- **SOC 2**: API key management controls
- **ISO 27001**: Information security management
- **GDPR**: Data protection and access controls
- **OWASP**: Secure coding practices

### Audit Requirements

- **Key Inventory**: Maintain list of all API keys
- **Access Reviews**: Regular review of key permissions
- **Rotation Records**: Document all key rotations
- **Incident Logs**: Record all security incidents

## Testing and Validation

### Security Testing

```bash
# Test API key security
# Windows
.\scripts\windows\database\security\test-api-key-security.ps1

# Linux/macOS
./scripts/linux/database/security/test-api-key-security.sh

# Expected results:
# - No hardcoded keys in code
# - Proper environment variable usage
# - Correct key separation
# - Secure documentation practices
```

### Automated Checks

- **Pre-commit hooks**: Scan for hardcoded keys
- **CI/CD pipeline**: Validate environment configuration
- **Security scans**: Regular vulnerability assessments
- **Penetration testing**: Annual security testing

## Tools and Resources

### Security Tools

- **git-secrets**: Prevent committing secrets
- **truffleHog**: Find secrets in git history
- **Supabase CLI**: Manage keys and configuration
- **Environment validators**: Verify configuration

### Documentation

- [Supabase API Keys Documentation](https://supabase.com/docs/guides/api/api-keys)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Flutter Environment Variables](https://docs.flutter.dev/deployment/flavors)

## Conclusion

Proper API key security is essential for protecting the Grex application and user data. By following these guidelines:

1. **Use environment variables** for all API keys
2. **Separate anon and service role keys** appropriately
3. **Implement comprehensive RLS policies**
4. **Rotate keys regularly**
5. **Monitor usage patterns**
6. **Respond quickly to incidents**

The application maintains a strong security posture while enabling necessary functionality.

## Checklist

### Development Setup
- [ ] API keys stored in environment variables
- [ ] `.env` file added to `.gitignore`
- [ ] `.env.example` created with placeholders
- [ ] No hardcoded keys in source code
- [ ] Proper key separation implemented

### Production Deployment
- [ ] Production keys generated
- [ ] Environment variables configured
- [ ] RLS policies tested
- [ ] Monitoring configured
- [ ] Incident response plan ready

### Ongoing Maintenance
- [ ] Regular key rotation scheduled
- [ ] Security reviews conducted
- [ ] Audit logs monitored
- [ ] Team training completed
- [ ] Documentation updated

---

**Last Updated**: December 11, 2024  
**Next Review**: March 11, 2025  
**Owner**: Security Team