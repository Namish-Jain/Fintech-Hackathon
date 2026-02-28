# AGENTS.md — Master Plan for FinBytes

## Project Overview
**App:** FinBytes
**Goal:** Transform complex financial news into 90-word, jargon-free micro-learning cards.
**Stack:** Flutter (Frontend), FastAPI/Python (Backend), Supabase (DB/Auth).
**Current Phase:** Phase 1 — Frontend UI Shell (Mocked)

## How I Should Think
1. **Frontend-First Strategy**: Build the "Face" of the app immediately using hardcoded mock data. 
2. **Understand Intent First**: We are in a 48-hour hackathon. Prioritize a "Pixel Perfect" demo over backend connectivity in the early hours.
3. **Reflect on UX**: The TikTok-style scroll must feel fluid. If animations stutter, optimize the widget tree.
4. **Plan Before Coding**: Propose the Widget tree and State management (Riverpod/Provider) before writing code.
5. **Verify After Changes**: Run `flutter analyze` after every UI component change.

## Plan → Execute → Verify
1. **Plan:** Propose the UI component or screen layout.
2. **Execute:** Implement one Flutter widget or screen at a time.
3. **Verify:** Use the emulator to confirm "Snap" scrolling and "ELI5" toggle functionality. Fix UI bugs before moving to the next screen.

## Context Files
- `agent_docs/tech_stack.md`: Flutter UI packages (`tiktoklikescroller`) and theme details.
- `agent_docs/product_requirements.md`: The 7 news categories and MCQ logic.
- `agent_docs/project_brief.md`: Branding (Deep Navy/Neon Green) and Dark Mode rules.

## Current State
**Last Updated:** February 28, 2026
**Working On:** Flutter Project Initialization & Mock Feed
**Recently Completed:** Pivot to Frontend-First Strategy
**Blocked By:** None

## Roadmap (Updated for Frontend-First)

### Phase 1: The UI Shell & Mock Feed (Hours 0-10)
- [ ] Initialize Flutter app with Premium Dark Mode Theme.
- [ ] Create `ByteModel` and `MockData` (3-5 high-quality sample cards).
- [ ] Implement `tiktoklikescroller` for vertical snapping.
- [ ] Build the **Main Card UI**: Headline, 3 Bullets, Source Badge.
- [ ] Build the **ELI5 Toggle**: Smooth transition between standard and simplified text.

### Phase 2: Onboarding & MCQs (Hours 10-20)
- [ ] Build the 5-question Onboarding Survey.
- [ ] Design and implement the MCQ Quiz Overlay card.
- [ ] Add micro-animations (Lottie) for correct/incorrect answers.

### Phase 3: The AI Brain & Supabase (Hours 20-36)
- [ ] Initialize Supabase Auth & Tables.
- [ ] Build FastAPI backend for AI Summarization (90-word limit).
- [ ] Connect Flutter to real data (Replace Mock with Supabase Stream).

## What NOT To Do
- Do NOT spend time on the Backend until the UI Shell is "Judge-Ready."
- Do NOT use more than 90 words in mock summaries.
- Do NOT ignore mobile responsiveness; test on small and large screen emulators.