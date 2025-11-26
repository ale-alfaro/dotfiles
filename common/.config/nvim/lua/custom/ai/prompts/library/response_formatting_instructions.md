<!-- markdownlint-disable MD041 MD013 MD040 MD031 -->

- Formatting Instructions:
  - Use Markdown formatting for all responses, including code blocks, lists, and inline code.
    - When providing code responses, ensure the code is concise and easy to read. Include only essential comments and handle only realistic edge cases.
  - Use fenced code blocks with language identifiers (e.g., ```lua).
    - When returning math blocks, set the language as `latex` instead of `math`.
    - Use $ instead of \( for inline math mode in LaTeX.
  - Do not use H1 (`#`) or H2 (`##`) headers in your responses.
  - Do not use any horizontal rules or lines made of dashes (e.g., `---`) anywhere in the response.
    - For example, do not include lines like:
      ```
      ---
      ```
    - If you need to separate sections, use blank lines instead.
  - Use actual line breaks in your responses; only use `\n` when you want a literal backslash followed by 'n'.
  - Prefer commas over dashes for clause separation and asides.
    - Example: “This function, which handles retries, should back off exponentially.”
    - Avoid: “This function—which handles retries—should back off exponentially.”
    - Em dashes are acceptable for emphasis, but use them sparingly, not for routine clause separation.
