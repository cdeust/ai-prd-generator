# Example: Basic PRD Generation

## User Request

```
Generate a PRD for:

Title: "User Authentication System"
Description: "Add OAuth 2.0 login with Google and GitHub providers"
```

## Expected Workflow

1. **Claude analyzes** the title and description
2. **Clarification questions** (mandatory):
   ```
   I need to clarify a few points before generating the PRD:

   1. **Session Management** - How long should user sessions last? (e.g., 24 hours, 7 days, remember me option)
   2. **Account Creation** - Should first-time OAuth users automatically get accounts, or require admin approval?
   3. **Existing Users** - Do you have existing username/password users that need to link OAuth accounts?
   4. **Permissions** - Will different OAuth providers grant different permission levels?
   5. **Fallback** - Should we keep username/password login as a backup option?

   Current confidence: 65%
   Target: 90%
   ```

3. **User provides answers**

4. **PRD Generation** with:
   - Overview (summary, goals, success metrics)
   - Requirements (functional/non-functional)
   - User Stories
   - Technical Specification
   - Test Cases
   - Acceptance Criteria
   - **JIRA Tickets** (epics, stories, tasks)
   - Appendix (clarification Q&A, verification results)

5. **Chain of Verification** validates PRD quality

## Sample Output Structure

```markdown
# User Authentication System

**Confidence Score**: 0.92/1.00
**Generated**: 2026-01-20

## 1. Overview

### Summary
Implement OAuth 2.0 authentication supporting Google and GitHub providers...

### Goals
- Enable users to log in with existing accounts
- Reduce friction in signup process
- Improve security with delegated authentication

### Success Metrics
- 70% of new users choose OAuth over traditional signup
- OAuth login completion rate > 95%
- Average login time < 3 seconds

## 2. Requirements

### Functional Requirements

**FR1**: System shall support OAuth 2.0 login with Google provider
**FR2**: System shall support OAuth 2.0 login with GitHub provider
**FR3**: System shall create user account on first successful OAuth login
**FR4**: System shall link multiple OAuth providers to single account
**FR5**: System shall maintain username/password login as fallback

### Non-Functional Requirements

**NFR1**: OAuth flow shall complete within 5 seconds (95th percentile)
**NFR2**: System shall support 10,000 concurrent OAuth requests
**NFR3**: OAuth tokens shall be encrypted at rest using AES-256
**NFR4**: System shall comply with GDPR for user data handling

## 3. User Stories

**US1**: As a new user, I want to sign up with my Google account so I don't create another password
**US2**: As an existing user, I want to link my GitHub account so I can login with either
**US3**: As a user, I want my session to persist for 7 days so I don't re-login constantly

## 4. Technical Specification

### Authentication Flow
1. User clicks "Login with Google/GitHub"
2. Redirect to provider OAuth page
3. User grants permissions
4. Provider redirects back with authorization code
5. Backend exchanges code for access token
6. Backend retrieves user profile
7. Backend creates/updates user account
8. Backend issues JWT session token

### API Endpoints

**POST /api/auth/oauth/google/start**
- Initiates Google OAuth flow
- Returns authorization URL

**POST /api/auth/oauth/google/callback**
- Handles OAuth callback
- Creates/updates user account
- Returns JWT token

**POST /api/auth/oauth/github/start**
- Initiates GitHub OAuth flow
- Returns authorization URL

**POST /api/auth/oauth/github/callback**
- Handles OAuth callback
- Creates/updates user account
- Returns JWT token

### Data Models

```typescript
interface User {
  id: string
  email: string
  oauthProviders: OAuthProvider[]
  createdAt: Date
  lastLoginAt: Date
}

interface OAuthProvider {
  provider: 'google' | 'github'
  providerId: string
  email: string
  linkedAt: Date
}
```

## 5. Test Cases

**TC1**: Given new user clicks "Login with Google", when OAuth succeeds, then account created and logged in
**TC2**: Given existing user with Google, when links GitHub, then both providers work for login
**TC3**: Given OAuth provider is down, when user tries login, then fallback to username/password shown

## 6. Acceptance Criteria

**AC1**: User can complete Google OAuth flow in one click
**AC2**: User can complete GitHub OAuth flow in one click
**AC3**: User can link multiple OAuth providers to one account
**AC4**: User session persists for configured duration
**AC5**: OAuth tokens are never exposed to frontend

## 7. JIRA Tickets

### Epic: User Authentication System
**Story Points**: 34
**Components**: Auth, Backend, Frontend
**Labels**: oauth, security, authentication

#### Story: Google OAuth Integration
**As a** user
**I want** to log in with my Google account
**So that** I don't need to create another password

**Acceptance Criteria**:
- [ ] Google OAuth consent screen configured
- [ ] OAuth flow redirects to Google successfully
- [ ] Callback endpoint processes Google response
- [ ] User account created/updated on success
- [ ] JWT token issued with appropriate claims
- [ ] Error handling for failed OAuth attempts

**Story Points**: 8
**Labels**: backend, frontend, google, oauth

#### Story: GitHub OAuth Integration
**Story Points**: 8
**Labels**: backend, frontend, github, oauth

#### Task: Set up OAuth client credentials
**Description**: Register OAuth applications with Google and GitHub
**Story Points**: 2
**Labels**: devops, configuration

#### Task: Implement OAuth callback handler
**Description**: Backend endpoint to process OAuth callbacks and issue JWTs
**Story Points**: 5
**Labels**: backend, security

#### Task: Create OAuth UI components
**Description**: Login buttons and OAuth flow UI
**Story Points**: 3
**Labels**: frontend, ui

## Appendix

### A. Clarification Q&A

**Q1**: How long should user sessions last?
**A1**: 7 days by default, with "remember me" option for 30 days

**Q2**: Should first-time OAuth users automatically get accounts?
**A2**: Yes, auto-create accounts for any successful OAuth

**Q3**: Do you have existing username/password users?
**A3**: Yes, keep as fallback and allow linking

### B. Verification Results

**Chain of Verification Score**: 0.89/1.00

**Judge 1 (Claude Opus)**: 0.92
- Completeness: Excellent
- Consistency: Minor gap (session timeout not in API spec)
- Testability: Well-defined

**Judge 2 (GPT-4)**: 0.88
- Completeness: Good
- Clarity: Excellent
- Gap: Missing error handling details

**Judge 3 (Gemini Pro)**: 0.87
- Completeness: Good
- Technical feasibility: Excellent
- Gap: GDPR compliance details sparse

**Consensus**: High-quality PRD, ready for implementation with minor refinements
```

## Notes

- No codebase provided → No RAG context
- No mockup provided → No vision analysis
- Clarification essential to reach 90%+ confidence
- JIRA tickets ready to import directly
