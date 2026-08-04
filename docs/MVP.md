# MVP v0.1 Acceptance Criteria

## Goal

Prove the core emotional loop:

```text
First Visit
  -> Meet Companion
  -> Talk
  -> Remember
  -> Leave
  -> Return
  -> Be Recognized
```

## Milestones

### M1: Project Bootstrap

- Repository has a clean monorepo structure.
- Frontend and backend can start independently.
- Environment variables are documented.
- A health endpoint returns success.

### M2: Onboarding

- First-time user sees a welcome screen.
- User enters a display name.
- User chooses a companion name.
- Onboarding completion is persisted.
- Returning user skips onboarding.

### M3: Companion World

- A simple room renders.
- A cat companion is visible.
- Companion has a finite set of states.
- Companion can transition between idle, sleeping, waking, walking, and talking.

### M4: Live Voice

- User can start a voice session.
- User speech reaches the AI service.
- Companion responds with voice.
- Session can be ended cleanly.

### M5: Memory

- Conversation context is available to the AI.
- Important user facts can be extracted.
- Memories are persisted against the correct user.
- Relevant memories can be retrieved for a later session.

### M6: Return Experience

- Last-seen time is persisted.
- Returning user is detected.
- Companion behavior changes based on elapsed time.
- A contextual welcome is spoken or displayed.

## End-to-End Acceptance Test

1. Install or open the app as a new user.
2. Enter a name.
3. Choose a companion name.
4. Enter the virtual room.
5. Confirm the companion is visible.
6. Start a live voice conversation.
7. Tell the companion a meaningful fact, such as a favorite book.
8. Confirm a memory candidate is created.
9. Exit the app.
10. Return to the app.
11. Confirm the same profile and companion are restored.
12. Confirm the companion reacts to the elapsed time.
13. Confirm the companion can reference a relevant remembered detail.

## Definition of Done

MVP v0.1 is done only when the end-to-end acceptance test passes on a clean user profile and the project has no known blocker in the core flow.
