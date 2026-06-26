# Google Form Generation Prompt Spec

This guide explains how to generate a custom prompt that the user can feed into an LLM (such as Gemini, Claude, or ChatGPT) to automatically generate a Google Apps Script for creating a Google Form feedback template.

## Workflow Integration

During step [9] of the codelab publishing process, the agent parses the authored `codelab.md` to extract the codelab title and the titles of each step. The agent then writes a customized text file `feedback-form-prompt.txt` to the project root.

## Prompt Template

Here is the template that the agent should populate and save as `feedback-form-prompt.txt`.

```text
Please write a Google Apps Script to create a Google Form. The form should be titled "{{CODELAB_TITLE}} Feedback".

The script should configure the form with the following structure and sections:

### Section 1: Participant Info (Optional)
- Section Title: "Participant Information (Optional)"
- Description: "Thank you for completing the '{{CODELAB_TITLE}}' codelab! Please take a moment to share your feedback to help us improve."
- Question 1: "Your Name" (Paragraph text, NOT required)
- Question 2: "Your Email" (Paragraph text, NOT required)

### Step-by-Step Sections (One section for each main codelab step)
Create a separate section for each of the following steps:
{{STEP_SECTIONS}}

For each step section, include these questions:
1. "How clear were the instructions in this step?" (Scale question from 1 to 5, where 1 is "Very unclear" and 5 is "Very clear")
2. "Did you face any issues or errors in this step?" (Multiple choice: "Yes", "No")
3. "Step Feedback / Comments" (Paragraph text, NOT required)

### Final Section: Overall Feedback
- Section Title: "Overall Feedback"
- Description: "Please share your overall thoughts on the codelab."
- Question 1: "Overall, how would you rate this codelab?" (Scale question from 1 to 5, where 1 is "Poor" and 5 is "Excellent")
- Question 2: "What did you like most about this codelab?" (Paragraph text, NOT required)
- Question 3: "What could be improved?" (Paragraph text, NOT required)
- Question 4: "Any other suggestions?" (Paragraph text, NOT required)

Requirements for the Google Apps Script code:
1. It must create the form using `FormApp.create('{{CODELAB_TITLE}} Feedback')`.
2. It must add the sections and questions programmatically in the correct sequence.
3. Scale questions must use `addScaleItem()`. Multiple choice must use `addMultipleChoiceItem()`. Text/Paragraph questions must use `addParagraphTextItem()`.
4. All text / paragraph / multiple choice questions in Section 1 and all step feedback/comments questions must be optional (not required). The scale questions can be optional or required.
5. In the log, print the URL of the created form using `Logger.log('Published URL: ' + form.getPublishedUrl())` and `Logger.log('Edit URL: ' + form.getEditUrl())`.

Output ONLY the ready-to-run Google Apps Script code inside a javascript code block.
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
