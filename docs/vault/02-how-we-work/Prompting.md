# How we work with Claude

- One system per change. One button, one panel, one service.
- Name the instance path. "inside StarterGui.MainGui.Button" beats "the button".
- Say where each script goes and why (client, server, shared, remote event between).
- Paste the error together with the action that caused it.
- Plan first for anything that touches more than two files; correct the plan, then build.
- Ask for an explanation of what changed, so the team can test and debug it.
- When a review corrects the look of something, the correction goes into the UI Playbook in the same change.
- Every number lives in `src/shared/data`; every string in `src/shared/strings`.


## The questions round (batch 4)

Before any code for a new system, end the brief with "do you have any questions for me to implement this?", answer them, and ask a second time: "what else could you ask me to make this easier to follow through?" A broad prompt is an idea told to a toddler: the language is shared, the mind is not. Every milestone brief in this project starts this way, and the answers go into the brief itself.
