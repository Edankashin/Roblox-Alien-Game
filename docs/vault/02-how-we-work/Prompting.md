# How we work with Claude

- One system per change. One button, one panel, one service.
- Name the instance path. "inside StarterGui.MainGui.Button" beats "the button".
- Say where each script goes and why (client, server, shared, remote event between).
- Paste the error together with the action that caused it.
- Plan first for anything that touches more than two files; correct the plan, then build.
- Ask for an explanation of what changed, so the team can test and debug it.
- When a review corrects the look of something, the correction goes into the UI Playbook in the same change.
- Every number lives in `src/shared/data`; every string in `src/shared/strings`.
