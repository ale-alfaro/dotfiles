# Lua Pattern Matching Cheatsheet

Lua's string patterns are a powerful tool for text manipulation. They are **not** regular expressions (regex) but offer a similar, simpler, and more lightweight functionality.

---

### Core Concepts

-   **Patterns, not Regex:** Lua patterns are more limited but often faster than full PCRE/POSIX regex.
-   **Magic Characters:** Certain characters have special meanings. To match them literally, you must escape them with a `%`.
-   **Escape Character:** The escape character is `%`. Use it to escape magic characters (e.g., `%.` matches a literal dot) and to introduce character classes (e.g., `%d` for digits).

---

### Magic Characters

| Character | Description                                                                                             | Example                               |
| :-------- | :------------------------------------------------------------------------------------------------------ | :------------------------------------ |
| `.`       | Matches any single character.                                                                           | `"a.c"` matches `"abc"`, `"axc"`, etc. |
| `()`      | Captures a substring that matches the enclosed pattern.                                                 | `"h(..)"` on `"hello"` captures `"el"`. |
| `%`       | The escape character.                                                                                   | `"%."` matches a literal dot `.`.      |
| `^`       | Anchors the pattern to the beginning of the string.                                                     | `"^a"` matches `"apple"`, not `"banana"`. |
| `$`       | Anchors the pattern to the end of the string.                                                           | `"a$"` matches `"banana"`, not `"apple"`. |
| `*`       | **Greedy:** Matches 0 or more repetitions of the preceding character/class. Matches the longest possible sequence. | `"a*"` matches `""`, `"a"`, `"aa"`, etc. |
| `+`       | **Greedy:** Matches 1 or more repetitions of the preceding character/class. Matches the longest possible sequence. | `"a+"` matches `"a"`, `"aa"`, etc.      |
| `-`       | **Non-Greedy:** Matches 0 or more repetitions. Matches the shortest possible sequence.                    | `".-,"` on `"a,b,c"` matches `"a,"`.   |
| `?`       | Matches 0 or 1 occurrence of the preceding character/class.                                             | `"a?"` matches `""` or `"a"`.          |

---

### Character Classes

Character classes match a specific set of characters.

| Class | Description                               | Negative Class | Description                         |
| :---- | :---------------------------------------- | :------------- | :---------------------------------- |
| `%a`  | All letters                               | `%A`           | Any character that is not a letter  |
| `%c`  | Control characters                        | `%C`           | Any character that is not a control |
| `%d`  | All digits                                | `%D`           | Any character that is not a digit   |
| `%l`  | Lower-case letters                        | `%L`           | Any non-lower-case letter           |
| `%p`  | Punctuation characters                    | `%P`           | Any non-punctuation character       |
| `%s`  | Space characters                          | `%S`           | Any non-space character             |
| `%u`  | Upper-case letters                        | `%U`           | Any non-upper-case letter           |
| `%w`  | Alphanumeric characters (letters & digits) | `%W`           | Any non-alphanumeric character      |
| `%x`  | Hexadecimal digits                        | `%X`           | Any non-hexadecimal digit           |
| `%z`  | The character with representation 0       |                |                                     |

---

### Custom Character Sets `[...]`

You can define your own set of characters to match.

| Pattern     | Description                                                              |
| :---------- | :----------------------------------------------------------------------- |
| `[abc]`     | Matches `a`, `b`, or `c`.                                                |
| `[a-z]`     | Matches any character in the range `a` to `z`.                           |
| `[0-9%s]`   | Matches any digit or a space character.                                  |
| `[^abc]`    | **Negated Set:** Matches any character that is **not** `a`, `b`, or `c`. |
| `[^%d]`     | Matches any non-digit (same as `%D`).                                    |

---

### Captures `()`

Captures are used to extract parts of a string that match a pattern. They are returned as separate values from functions like `string.match`.

-   **Simple Capture:** `s:match("(%w+)")` captures the first word.
-   **Multiple Captures:** `s:match("(%w+)%s*=%s*(%d+)")` captures a key and a value like `"key = 123"`.
-   **Positional Captures:** In `string.gsub`, you can refer to captures by their position (`%1`, `%2`, etc.).
    -   `s:gsub("(%w+)", "word: %1")` would turn `"hello"` into `"word: hello"`.

---

### Common `string` Functions

| Function                               | Description                                                                                                                            |
| :------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------- |
| `string.match(s, pattern, [init])`     | Returns the captures from the first match of `pattern` in `s`.                                                                         |
| `string.gmatch(s, pattern)`            | Returns an iterator function that, each time it is called, returns the next captures from the pattern in the string.                    |
| `string.find(s, pattern, [init])`      | Returns the start and end indices of the first match. Does not return captures.                                                        |
| `string.gsub(s, pattern, repl, [n])`   | **G**lobal **sub**stitution. Replaces all occurrences (`n` limit is optional) of `pattern` with the `repl` string and returns the new string. |

---

### Practical Examples

#### 1. Parse a GitHub URL

Extract the user and repository name from a URL.

```lua
local url = "https://github.com/nvim-lua/plenary.nvim"
local user, repo = url:match("github.com/([^/]+)/([^/]+)")
-- user -> "nvim-lua"
-- repo -> "plenary.nvim"
```

#### 2. Get Filename and Extension

```lua
local filepath = "path/to/my_file.txt"
local name, ext = filepath:match("([^/]+)%.([^%.]+)$")
-- name -> "my_file"
-- ext  -> "txt"
```

#### 3. Find All Words in a String

Using an iterator with `gmatch`.

```lua
local s = "hello world from lua"
for word in s:gmatch("%w+") do
  print(word)
end
-- Prints:
-- hello
-- world
-- from
-- lua
```

#### 4. Swap Key-Value Pairs

Using `gsub` with positional captures.

```lua
local s = "name=John, role=admin"
local swapped = s:gsub("(%w+)%s*=%s*(%w+)", "%2=%1")
-- swapped -> "John=name, admin=role"
```
