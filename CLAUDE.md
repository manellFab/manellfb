# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single-page Kanban board for a fictitious bank's internal IT PMO (demo/training tool). No build, lint, or test tooling exists: no npm, bundler, or framework. Do not add any. Do not use UOB's real logo or trademarks; the UI uses a neutral "IT PMO" text wordmark and a blue palette.

## Two files, one app

- `index.html` is the source of truth. It is self-contained (markup, `<style>`, `<script>`), has zero external resources, and must work by double-clicking it (`file://`, no server).
- `artifact.html` is a derived copy for publishing as a Claude artifact (private page at claude.ai). It differs from `index.html` only in: no `<!DOCTYPE>/<html>/<head>/<body>` wrapper, a `<title>` plus `claude:viewport-fit-sides` meta at the top, light/dark theme tokens (`--heading`, `--accent-fg`, `--low-bg`, etc., with dark overrides), and safe-area side gutters. Make behavioural changes in `index.html`, then re-derive `artifact.html` and republish to the same file path to keep the URL. Artifact sandboxes block outbound `fetch`, so the FormSubmit call fails there by design (the app shows its "email notification failed" toast).

## Architecture (all in the `<script>` block)

- `state = { tasks, filters, nextId, confirmDeleteId, dragId, focusKey }` is the only source of truth. There is intentionally no persistence (no localStorage, sessionStorage, IndexedDB or cookies); a refresh re-seeds via `seedTasks()`. The UI states this.
- `renderBoard()` is the only place card and column DOM is written, rebuilding `#board` via `innerHTML` from state. Every user-supplied string must pass through `escapeHtml()`. Toasts use `textContent`.
- Because the board is re-rendered wholesale, all board events (click, change, and the HTML5 drag-and-drop events) are delegated on `#board` in `wireBoard()`. Do not attach listeners to individual cards.
- Focus survives re-renders through `state.focusKey` matched against `data-focus` attributes. Set it before calling `renderBoard()` when focus must land on a specific control, for example the delete confirm's "Yes" button.
- Deleting uses an inline "Delete? Yes / No" state (`state.confirmDeleteId`), never `confirm()`. Moving uses both drag and drop and a keyboard-accessible `<select>` ("Move ▸").
- Add Task is a custom overlay modal (not `<dialog>`), so toasts can render above it. `handleSubmit` validates, then adds the card optimistically via `addTask`, then awaits `notifyNewTask` in try/catch. A network failure only shows a warning toast and never breaks the board.
- Dates are plain `YYYY-MM-DD` strings compared lexically against `isoDate(0)` (local date). Seed due dates are relative to today, so the overdue examples stay valid.

## Config and conventions

- `FORMSUBMIT_ENDPOINT` (top of the script) is the only place the notification email goes. It is still the `YOUR_EMAIL@example.com` placeholder. FormSubmit needs a one-time activation: the first submission emails a confirmation link to that address. Never send the email address anywhere else.
- Task IDs use the format `UOB-ITPM-####` (zero-padded, via `state.nextId`), and the email subject starts `[UOB IT PMO]`. Both are required by the spec; keep them.
- CSS uses custom properties for palette and spacing, with no `!important`. Layout stacks columns below 768px.
