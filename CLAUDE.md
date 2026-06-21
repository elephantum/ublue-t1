# CLAUDE.md

## Issue workflow

Issues are tracked in `ISSUES.md` (kanban index) and individual files under `issues/`.

**Statuses:** Backlog → In Progress → Testing → Done

### Starting an issue
1. Move the issue link in `ISSUES.md` from Backlog to **In Progress**.
2. Update the `**Status:**` line in the issue file to `In Progress`.
3. Implement the fix.

### Finishing an issue
1. Move the issue link in `ISSUES.md` to **Testing**.
2. Update `**Status:**` to `Testing`.
3. Add a **Testing** section to the issue file listing concrete steps the user should run to verify the fix.

### User adds feedback
The user adds notes directly in the issue file (under a **Notes** or **Testing** section).
Read the file before acting on it — the user may have marked something as "Did not help" or similar.

### Closing an issue
When the user confirms the fix works, move the link to **Done** and update `**Status:**` to `Done`.

### Issue file structure
```
# <Title>

**Status:** Backlog | In Progress | Testing | Done

## Root cause
<brief explanation>

## Fixes applied
<what was changed and why>

## Testing
<concrete steps to verify>

## Notes
<user comments added during testing>
```
