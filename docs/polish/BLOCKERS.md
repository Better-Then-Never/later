# BLOCKERS.md (polish branch)

Things this branch could not finish without the owner. Each has a place in the code ready for it.

## B-01. No support email address

Help shows "Contact support" and "Report a problem" (an email with the app version and phone filled in) only
when `AppLinks.supportEmail` is set (`lib/core/config/app_links.dart`). No address exists in the repo or the
project, and inventing one would send users' messages nowhere. Until then, Help offers "Copy app
information" for whatever channel users already use.

**Owner:** set `supportEmail` and the two rows appear.

## B-02. No privacy policy or terms of use

About shows "Privacy policy" and "Terms of use" only when `AppLinks.privacyPolicy` / `termsOfService` are set.
Neither document exists. Both stores ask for a privacy policy URL, and with account deletion and message
pushes now in the app, the policy should say what is stored and how deletion works (see
`functions/lib/account.js`).

**Owner:** publish the documents (Firebase Hosting `public/` would do) and set the two links.

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
