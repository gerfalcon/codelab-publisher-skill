# Google Form Generation Prompt Spec

This guide explains how to generate a custom prompt that the user can copy and paste directly into Gemini within the Google Forms website ("Help me create a form") to automatically build a feedback form.

## Workflow Integration

During step [9] of the codelab publishing process, the agent parses the authored `codelab.md` to extract the codelab title and the titles of each step. The agent then writes a customized text file `feedback-form-prompt.txt` to the project root.

## Prompt Template

Here is the template that the agent should populate and save as `feedback-form-prompt.txt`.

```text
Create a feedback form for the codelab titled "{{CODELAB_TITLE}}".

Please structure the form with the following sections and questions:

Section 1: Participant Information (Optional)
- Description: "Thank you for completing the '{{CODELAB_TITLE}}' codelab! Please take a moment to share your feedback to help us improve."
- Question 1: "Your Name" (Paragraph text, optional)
- Question 2: "Your Email" (Paragraph text, optional)

Step-by-Step Sections (Create a separate section for each of these codelab steps):
{{STEP_SECTIONS}}

For each step section, include these questions:
1. "How clear were the instructions in this step?" (Scale question from 1 to 5, where 1 is "Very unclear" and 5 is "Very clear")
2. "Did you face any issues or errors in this step?" (Multiple choice: "Yes", "No")
3. "Step Feedback / Comments" (Paragraph text, optional)

Final Section: Overall Feedback
- Section Title: "Overall Feedback"
- Description: "Please share your overall thoughts on the codelab."
- Question 1: "Overall, how would you rate this codelab?" (Scale question from 1 to 5, where 1 is "Poor" and 5 is "Excellent")
- Question 2: "What did you like most about this codelab?" (Paragraph text, optional)
- Question 3: "What could be improved?" (Paragraph text, optional)
- Question 4: "Any other suggestions?" (Paragraph text, optional)
```

## How to extract sections from `codelab.md`

1. Read `codelab.md`.
2. Find the main H1 heading (e.g. `# My Codelab Title`) for `{{CODELAB_TITLE}}`.
3. Find all H2 headings (e.g. `## Overview`, `## 1. Getting Started`, `## Wrap up`).
4. Generate the `{{STEP_SECTIONS}}` content by listing each step.
   - For example:
     - Section: "Step: Overview"
     - Section: "Step: 1. Getting Started"
     - Section: "Step: 2. Building the app"
     - Section: "Step: Wrap up"
