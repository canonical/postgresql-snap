# Review draft release notes

Review the attached draft release notes of the PostgreSQL snap and edit the file in place.
The draft was generated from a template: changes were sorted into sections by PR labels only,
so most of them ended up in Other improvements, and the highlights are a `TODO` comment.

## Tasks

1. **Re-sort the changes.** Check each item in Other improvements and move it to Features or
   Bug fixes if it belongs there:

   * Features: new or changed behaviour that snap users can see, for example new commands,
     configuration, hooks, or a PostgreSQL version update.
   * Bug fixes: fixes for incorrect behaviour that snap users can run into.
   * Other improvements: everything else, for example CI, tests, dependency updates and docs.

   Move an item only if you are at least 90% sure. If you are 75–90% sure, leave it in place
   and list it in your report. Add moved items to the end of the target section, keeping their
   original order.

   Judge each change by its PR, not only by its title:
   `gh pr view <number> --repo canonical/postgresql-snap --json title,body,files`.
   If you can't read a PR, judge by its title alone and treat the result as less certain.

2. **Remove empty sections.** Remove every section that still has no items: both the heading
   and the HTML comment under it.

3. **Write the highlights.** Replace the `TODO` comment above the links block with 1–3
   paragraphs of prose (not a list) about the most important changes in this release.
   Mention any breaking changes, for example removed commands, changed paths or new
   restrictions on refreshes. Keep it readable and concise: at most 20 lines of up to
   100 characters each, preferably shorter. Don't repeat the version, date and base from the
   intro, and don't describe anything that the listed changes and their PRs don't support.

   Describe what changed, not how to act on it: don't include instructions, steps or commands.
   If users need to do something, for example migrate their data after a breaking change, link
   to the relevant documentation instead. Prefer the snap docs in the repository's `docs/`
   folder; if they don't cover the topic, link to the most specific section of the upstream
   [PostgreSQL documentation](https://www.postgresql.org/docs/) for the track's major version.
   Check that the link works and that the section applies to the snap.

## Rules

* Don't change anything else: keep the intro, the links block, the wording of items, and the
  Changelog, Revisions and Downloads sections as they are.
* Don't commit or push.

## Report

When done, reply in the chat with:

* Moved items: each with its new section and a one-line reason.
* Possible moves (75–90% sure): each with the suggested section and why you're unsure.
* Removed sections.
* Breaking changes found, or "None".
* Anything you couldn't verify.
