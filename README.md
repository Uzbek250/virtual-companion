# Virtual Companion 🐱

A personal AI virtual companion that lives in its own small world, remembers the user, speaks naturally, and develops a long-term relationship over time.

## Vision

Virtual Companion is not intended to be just another chatbot. The goal is to create a companion that feels present in a persistent virtual world: it can sleep, move between rooms, read, remember shared experiences, and welcome the user when they return.

## MVP v0.1

The first working release focuses on one complete experience:

1. First launch asks the user's name.
2. The user chooses the companion's name.
3. An anonymous identity is created without asking for email, phone number, or password.
4. A virtual cat companion appears in a simple room.
5. The user can have a live voice conversation.
6. Important conversation details can become memories.
7. The companion remembers the user on later visits.
8. The companion reacts to the time since the user's last visit.
9. The companion welcomes the user naturally when they return.

## Planned Architecture

- Frontend: React + TypeScript + Vite
- Backend: Node.js + TypeScript
- AI: Gemini
- Live voice: Gemini Live API
- Database: Supabase PostgreSQL
- Identity: Supabase Anonymous Sign-In
- Authorization: Supabase Row Level Security (RLS)
- Repository: GitHub

## Development Principle

Build in small, verified increments. Every milestone should produce a runnable state before the next feature is added.

## Project Status

🚧 Early development. The repository is intentionally starting from a clean slate.
