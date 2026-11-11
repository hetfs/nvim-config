# Stage 10: Practical Blink Completion Exercises

The goal is to become comfortable with manual completion, candidate navigation, acceptance, dismissal, and snippet placeholder navigation.

Use these exercises in a temporary Lua file so you can experiment without affecting your project configuration.

## 1. Manually open completion with `Ctrl-Space`

Beginner

Objective: Learn to request completion instead of waiting for automatic suggestions.

Type:

```lua
local user_name = "Binahf"
local user_email = "binahf@example.com"
local user_role = "developer"
```lua

Now create a new line and type:

```lua
local user_
```lua

1. Stop typing.
2. Press `Ctrl-Space`.
3. Observe the completion menu.
4. Examine the available candidates.
5. Press `Ctrl-e` to close the menu.

Expected result: The completion menu opens only after you explicitly request it.

Repeat with:

```lua
vim.
```lua

Notice how completion can provide suggestions from the LSP when available.

## 2. Navigate candidates with `Ctrl-n` and `Ctrl-p`

Beginner

Objective: Learn to move through completion candidates.

Type:

```lua
local customer = {
  name = "Ama",
  email = "ama@example.com",
  address = "Accra",
  phone = "0240000000",
}

customer.
```lua

1. Press `Ctrl-Space`.
2. Press `Ctrl-n` several times.
3. Observe how the selected candidate changes.
4. Press `Ctrl-p` to move backward.
5. Move between candidates without accepting anything.

Expected result:

- `Ctrl-n` selects the next candidate.
- `Ctrl-p` selects the previous candidate.
- The completion menu remains open while navigating.

## 3. Accept completion with `Enter`

Beginner

Objective: Learn to insert a selected completion candidate.

Type:

```lua
local framework = {}
framework.
```lua

1. Press `Ctrl-Space`.
2. Navigate using `Ctrl-n` and `Ctrl-p`.
3. Select a candidate.
4. Press `Enter`.
5. Inspect the inserted text.

Repeat with:

```lua
local message = string.
```lua

Expected result: Pressing `Enter` accepts the selected candidate.

If no candidate is selected, verify how your installed Blink version handles acceptance before assuming the mapping inserts a completion.

## 4. Dismiss completion with `Ctrl-e`

Beginner

Objective: Close the completion menu without accepting a candidate.

Type:

```lua
local application = {}
application.
```lua

1. Press `Ctrl-Space`.
2. Navigate through several candidates.
3. Press `Ctrl-e`.
4. Confirm the menu disappears.
5. Continue typing.

Expected result: The menu closes without inserting the selected candidate.

## 5. Explore documentation with `Ctrl-Space`

Intermediate

Your mapping contains three actions:

```lua
["<C-Space>"] = {
  "show",
  "show_documentation",
  "hide_documentation",
},
```lua

Objective: Understand how Blink handles completion documentation.

1. Open completion with `Ctrl-Space`.
2. Select a candidate with documentation.
3. Press `Ctrl-Space` again.
4. Observe whether the documentation window appears.
5. Press `Ctrl-Space` again and observe the result.

Expected result: You become familiar with the documentation actions associated with the mapping.

Note that this is an action sequence, not three separate key mappings. Its behavior depends on Blink's action handling and current completion state.

## 6. Navigate snippet placeholders with `Tab`

Intermediate

Objective: Learn how snippet expansion and placeholder navigation work together.

Open a Lua file and type:

```lua
local function
```lua

1. Press `Ctrl-Space`.
2. Look for a function snippet from `friendly-snippets`.
3. Select a suitable snippet.
4. Press `Enter` to expand it.
5. Use `Tab` to move to the next placeholder.
6. Fill in each placeholder.

Expected result: The snippet expands and `Tab` moves through its editable placeholders.

If no snippet appears, try searching for a snippet by a keyword such as `function`, `if`, or `for`.

## 7. Navigate backward with `Shift-Tab`

Intermediate

Objective: Move backward through snippet placeholders.

Use a snippet with at least three placeholders.

For example, after expanding a function snippet:

```lua
local function calculate_total(price, quantity)
  return price * quantity
end
```lua

1. Fill in the first placeholder.
2. Press `Tab` to move forward.
3. Fill in the next placeholder.
4. Press `Tab` again.
5. Press `Shift-Tab` to return to the previous placeholder.
6. Modify its value.

Expected result: `Shift-Tab` moves backward through the snippet placeholders.

## 8. Combined practical challenge

Practice challenge

Build this small Lua module using completion and snippets.

Start with:

```lua
local M = {}

M.users = {}

function M.add_user(name, email)
  -- Implement this function.
end

function M.get_user(name)
  -- Implement this function.
end

return M
```lua

Complete the following tasks:

- Use `Ctrl-Space` to request completion for `vim.`.
- Navigate candidates using `Ctrl-n` and `Ctrl-p`.
- Accept a candidate using `Enter`.
- Open another completion menu and dismiss it with `Ctrl-e`.
- Find and expand a function snippet.
- Use `Tab` to navigate forward through placeholders.
- Use `Shift-Tab` to navigate backward.
- Complete the module without relying on automatic completion popups.

## Keymap mastery checklist

Stage 10 practice progress

# 0/9

I can manually open completion using Ctrl-Space.

I can navigate candidates using Ctrl-n and Ctrl-p.

I can accept a candidate using Enter.

I can dismiss completion using Ctrl-e.

I understand the documentation actions.

I can find and expand friendly-snippets definitions.

I can move forward through placeholders using Tab.

I can move backward through placeholders using Shift-Tab.

I can complete a small Lua module using these mappings.

Reset practice checklist

My recommendation: Complete exercises 1–4 first. Then move to snippet exercises 6–7. This separates completion-menu mastery from snippet-navigation mastery, making it easier to identify which mapping needs troubleshooting.
