<!-- markdownlint-disable MD041 MD013 MD031 -->
Given the following git diff, generate a concise and descriptive commit message.

1. First, analyze the last 50 commit messages in this repository (provided below).
2. If the majority of them follow the Conventional Commits specification, write the new commit message using the Conventional Commits style.
   - Use the correct type (feat, fix, chore, refactor, docs, test, style, perf, build, ci, etc.).
   - Include an optional scope in parentheses if appropriate.
   - Do not include breaking change notation unless the diff clearly indicates a breaking change.
   - **Example:**
     ```text
      fix(ui): prevent session file from being saved in headless or worker instances

      Only save the session file if a UI is attached, avoiding unwanted session writes from
      headless processes such as test workers.
      ```
3. If the majority do **not** follow the Conventional Commits style, instead mimic the style and format of the recent commit history.
   - **Example:**
     ```text
      vim: include recent commit history in codecompanion conventional_commit prompt

      Pass the last 50 commit messages as context to improve the quality of generated conventional commit messages.
     ```
4. If the style is unclear or tied, default to Conventional Commits.

**Important:**
- Output only the commit message, in plain text. Do not include any explanations, code blocks, or extra formatting.
- Keep the commit message under 72 characters if possible.
- Write a short summary in the imperative mood after the colon.
- Optionally, add a longer description after a blank line if more context is needed.

Recent commit history:
```text
%s
```

Git diff:
```diff
%s
```
