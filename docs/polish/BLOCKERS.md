# BLOCKERS.md (polish branch)

Things this branch could not finish without the owner. Each has a place in the code ready for it.

## B-01. Support email: resolved 2026-10-17

The owner gave `betterthannever.business@gmail.com`. Help now shows "Contact support" and "Report a problem"
(verified on the emulator: the email app opens with the address, subject and app information).

## B-02. Privacy policy and terms: resolved 2026-10-17, review recommended

Written at the owner's request in `public/privacy.html` and `public/terms.html`, modelled on common messenger
policies and matched to what the app actually stores (Firestore in the EU, Storage in US-EAST1, no analytics or
ads, messages not end-to-end encrypted, account deletion via `functions/lib/account.js`). Linked from About and
from the signup page. They name the operator "Better Than Never" with the support address. **Owner:** add the
legal entity name and postal address if there is one, and have a lawyer review them before relying on them.

## B-06. The app asks for Contacts and Microphone but uses neither

The permission screen requests both, yet no code reads contacts or records audio. The privacy policy says so
truthfully, but Google Play and the App Store reject or flag apps that request permissions they do not need.
**Recommended:** remove both from the permission screens and from the Android manifest / iOS Info.plist.

## B-07. Backups keep user data indefinitely

`gs://later-da778-backups/before-migration` (the export made before the data migration) contains every account
as of 2026-10-16. The policy says copies in backups are deleted when the backups are removed. **Recommended:**
delete that export once the migration is confirmed good, or add a lifecycle rule (for example 90 days).

## B-03. Functions must be deployed before shipping "Delete account"

The client deletes the Auth account; `cleanupDeletedAccount` (auth `onDelete`) removes the data. The function
is written and tested on the emulators (functions tests, 23/23) but not deployed: deploying is not allowed
from this branch. If the app ships first, deleted accounts leave their data behind. Order:
MIGRATIONS_NEEDED.md §2.

## B-04. Message pushes and the settings were not tested on a real device with FCM

The emulators have no FCM. Verified: the sender's decisions and payloads (functions tests: mute, categories,
quiet hours across midnight and time zones, preview, silent channel, chat tag, dead-token pruning), the
client's tap routing (unit test) and the settings writes (rules + widget tests). Not verified: delivery,
the Android channels as the system shows them, tag replacement, and opening a chat from a tapped push.

**Owner:** after deploying (B-03 order), send a message between two test devices and walk through
Settings > Notifications.

## B-05. Changing the sign-in email needs the Firebase email template

`verifyBeforeUpdateEmail` sends Firebase's standard "verify your new email" message. It works with the
default template, but the sender name and wording come from the Firebase console (Authentication >
Templates), which this branch cannot change.
