# IDEAS_NOT_DONE.md

Ideas that came up while polishing and were left out on purpose (scope control). Each is a candidate for a
later branch.

## Settings

- **Language.** The stub page said "coming soon". There are no translations (no `intl` ARB files, all text is
  English in the widgets), so a language picker could not change anything. Removed instead of faked. Doing
  it properly means extracting every string, which touches every screen.
- **App appearance (dark mode).** Same reason: one light palette exists. A dark theme needs a second set of
  colour tokens and checking every screen and image asset against it. Removed instead of faked.
- **Per-person capsule notifications in Settings.** Following someone already has its own bell
  (`following/{uid}.notificationsEnabled`). A list of "people whose capsules notify me" in Settings would
  duplicate it.
- **Data export ("download my data").** Useful next to account deletion, but needs a callable function that
  zips Firestore documents and Storage files.
- **Read receipts switch.** Hiding "Read" from friends needs a rule change and a client that stops writing
  `lastReadAt` while still clearing the unread count. Small, but a behaviour decision for the owner.

## Messages

- **Typing indicator, reactions, message edit/delete.** Out of scope for the polish mission.
- **Backfilling unread counts for old chats.** See MIGRATIONS_NEEDED.md §1: no reliable "last read" exists.
- **Badge count on the app icon.** iOS badge numbers need the total unread from the server in every push
  (the old static `badge: 1` was wrong and was removed). Android launchers mostly show a dot already.

## Notifications

- **Grouping several chats into one Android summary notification.** One notification per chat is done (tag);
  a summary group needs a native group key per channel.
- **iOS push.** The owner said it is not wanted for now (no APNs key in the project).

## Quality

- **Raw `Color.fromARGB` / `Color.fromRGBO`** in a few pre-existing widgets slipped past the token check (it
  only matched `Color(0x…)`). Handled in Phase 7; see PROGRESS.md.
