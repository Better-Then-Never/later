# Security rules tests

Tests for `../../firestore.rules` and `../../storage.rules`, run against local
emulators started just for the tests (Firestore on 8180, Storage on 9299, project
`demo-later-rules`), so they never touch a real project or the dev emulators.

```sh
cd tools/rules-tests
npm install
npm run emulate   # = firebase emulators:exec --config firebase.json --project demo-later-rules "npm test"
```

Requires the Firebase CLI and Java 11+ (`JAVA_HOME`). The `placeholder.*.rules`
files only let the emulators start; each test loads the real rules.
