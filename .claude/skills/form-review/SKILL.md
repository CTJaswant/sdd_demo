---
name: form-review
description: Reviews proactively a React form for validation and accessibility gaps. Use when asked to review any form or page with inputs.Any frontend component that has a form or wizard step can be reviewed with this skill.
user-invocable: true
---
# Form Review

When reviewing a React form, check each item and report PASS or GAP with the line:

1. Does each required field show an error message when empty?
   (A disabled button with no message = GAP.)
2. Do required fields have `aria-required="true"`?
3. Do invalid fields have `aria-invalid` and an error linked by `aria-describedby`?
4. Are error messages announced with `role="alert"`?
5. Does the Notes textarea have a `maxLength`?
6. Can the quantity field accept 0, negative, or empty? (It should not.)

End with the single most important fix to make first.