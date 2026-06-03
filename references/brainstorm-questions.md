# Brainstorm Questions — `AskUserQuestion` JSON

Use this exact phrasing in the brainstorm phase (step [2]) so every codelab starts from the same well-shaped questions. Call `AskUserQuestion` with all four questions in a **single batched call** — don't split across turns.

## When to call

After confirming the topic in free text (step 2a). The four structured questions cover audience, difficulty, duration, and format.

## The call

```json
[
  {
    "question": "Who's the target audience for this codelab?",
    "header": "Audience",
    "multiSelect": false,
    "options": [
      {
        "label": "Backend / full-stack developers",
        "description": "Comfortable in server / database / API context. Assume they know HTTP, JSON, basic SQL."
      },
      {
        "label": "Frontend / mobile developers",
        "description": "UI-focused. Assume they know HTML/CSS/JS or a mobile framework. May not know backend deeply."
      },
      {
        "label": "ML / data engineers",
        "description": "Python + notebooks + cloud tooling background. Assume comfort with pandas, models, GPUs."
      },
      {
        "label": "Mixed technical audience",
        "description": "Range of backgrounds. Codelab should not assume any one stack. More explanatory."
      }
    ]
  },
  {
    "question": "What difficulty level should we aim for?",
    "header": "Difficulty",
    "multiSelect": false,
    "options": [
      {
        "label": "Beginner",
        "description": "No prior knowledge of the specific topic. Define jargon. More handholding. Frequent checkpoints."
      },
      {
        "label": "Intermediate (Recommended)",
        "description": "Audience knows the domain but not this specific topic. Skip the basics, focus on what's new."
      },
      {
        "label": "Advanced",
        "description": "Deep dive. Assumes fluency. Optimization, internals, edge cases, comparative analysis."
      }
    ]
  },
  {
    "question": "Roughly how long should the codelab take to complete?",
    "header": "Duration",
    "multiSelect": false,
    "options": [
      {
        "label": "15 minutes — quick intro",
        "description": "3-4 short steps. Focused on a single concept or small example."
      },
      {
        "label": "30 minutes — hands-on tutorial (Recommended)",
        "description": "5-7 steps. Build something small end-to-end. The sweet spot for most codelabs."
      },
      {
        "label": "1 hour — extended project",
        "description": "8-10 steps. Substantial outcome. Multiple components or integrations."
      },
      {
        "label": "2+ hours — deep workshop",
        "description": "10+ steps. Multi-part. Significant prerequisites. Plan a coffee break."
      }
    ]
  },
  {
    "question": "What format suits the material best?",
    "header": "Format",
    "multiSelect": false,
    "options": [
      {
        "label": "Hands-on coding (Recommended)",
        "description": "Reader writes/runs code along the way. Each step has a clear deliverable. Maximum stickiness."
      },
      {
        "label": "Concept walkthrough",
        "description": "Explains a concept with diagrams + examples. Less code, more explanation. Good for architecture topics."
      },
      {
        "label": "Mixed (concepts + light coding)",
        "description": "Some explanatory sections, some hands-on. Best for advanced or architectural topics where you need to set up context before the code makes sense."
      }
    ]
  }
]
```

## After the answers come back

Write a **scope statement** in chat using this structure:

```
Topic: <one sentence>
Audience: <who, plus assumed background — derive from Audience + Difficulty answers>
Outcome: <what the learner will be able to do at the end>
Format: <how the codelab is structured — derive from Format answer>
Duration: <total time — from Duration answer>
Out of scope: <what we explicitly will NOT cover>
```

Get explicit confirmation ("looks good", "yes", "go ahead") before moving to step [3]. The scope statement is the contract — refer back to it if the user starts drifting toward scope creep in later phases.

## Why these four dimensions, not more

- **Audience role** + **Difficulty** together pin down the assumed background. Asking "what's their background?" as free text gets fuzzy answers; the option-based question forces a concrete choice.
- **Duration** is necessary because the same topic at 15 min vs 2 hours is a completely different codelab. It also constrains the outline (sum of step durations).
- **Format** determines the balance of prose vs code blocks. Concept walkthroughs need diagrams; hands-on tutorials need clear deliverables per step.

Asking more than four pre-built questions is overkill — additional dimensions (preferred language, specific tools, naming conventions) come out naturally during outline review.

## When to skip the brainstorm

Don't skip it by default. The only legitimate skip cases:

1. The user has *already* given full scope in their invocation ("Build a 30-minute hands-on Python codelab for intermediate backend devs about async generators, no concept walkthrough needed"). In that case, restate the scope back and ask "anything to adjust?" — still confirm, don't just assume.
2. They explicitly say "skip the brainstorm" / "I know what I want" / "just write it". Respect that, but ask them for a one-sentence scope statement so you have *something* to anchor the outline to.

If in doubt, brainstorm. The cost is two minutes; the cost of a misscoped codelab is far higher.
