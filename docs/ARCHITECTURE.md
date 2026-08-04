# Architecture v0.1

## High-Level System

```text
React + TypeScript + Vite
        |
        +-- Virtual World UI
        +-- Companion State
        +-- Onboarding
        +-- Voice Client
        |
        v
Node.js + TypeScript API
        |
        +-- AI orchestration
        +-- Memory extraction/retrieval
        +-- Welcome engine
        +-- World rules
        |
        v
Supabase
        +-- Anonymous Auth
        +-- PostgreSQL
        +-- Row Level Security
```

## Frontend Responsibilities

- Render the virtual room.
- Render companion states and animations.
- Manage onboarding screens.
- Start and manage live voice sessions.
- Maintain short-lived UI state.
- Call backend APIs.

## Backend Responsibilities

- Validate requests.
- Orchestrate AI features.
- Retrieve relevant memories.
- Extract durable memories from conversations.
- Calculate return context.
- Generate structured companion actions.
- Enforce world rules before actions are executed.

## Identity

The user does not manually register with email, phone, or password during MVP onboarding.

The application uses a provider-managed anonymous identity/session. The application stores the user-facing profile name separately from authentication identity.

Conceptually:

```text
Anonymous Auth User
        |
        +-- Profile
              |
              +-- Companion
              +-- Memories
              +-- Conversations
              +-- World State
```

## Data Model

Core entities:

- `profiles`
- `companions`
- `memories`
- `world_state`
- `conversations`
- `messages`

Every user-owned record must be scoped to the authenticated anonymous user and protected with Row Level Security.

## AI Architecture

The AI is not allowed to directly mutate the database or arbitrarily control the virtual world.

The intended flow is:

```text
User Input
   |
   v
AI Context Builder
   |
   +-- User Profile
   +-- Companion Profile
   +-- Relevant Memories
   +-- Recent Conversation
   +-- World State
   |
   v
AI Model
   |
   v
Structured Response / Proposed Action
   |
   v
World Rules + Validation
   |
   v
World State Update
```

This separation keeps the AI flexible while keeping world state deterministic and testable.

## Memory Architecture

Memory is selective rather than a raw dump of every conversation.

Candidate memory types:

- fact
- preference
- event
- relationship

Each candidate should have an importance score and should be persisted only when it passes the configured threshold or is explicitly confirmed by the user.

## Return Experience

On app startup:

1. Restore the anonymous session.
2. Load the profile and companion.
3. Read the last-seen timestamp.
4. Determine elapsed time.
5. Load current world state.
6. Generate a contextual welcome behavior.
7. Render the companion's transition into the welcome state.

## Security Principles

- Never expose privileged backend keys to the browser.
- Never store provider secrets in source control.
- Use environment variables for secrets.
- Apply RLS to all user-owned tables.
- Validate and authorize every backend mutation.
- Treat AI-generated actions as untrusted input until validated.
