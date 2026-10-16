# BUGS.md — bugs found during the polish mission

Severity as in docs/refactor/BUGS.md: **S1** crash / freeze / data loss / security, **S2** broken feature,
**S3** visible defect, **S4** minor. Status: `open`, `fixed`, `blocked`, `wontfix`.

| ID | Area | Symptom | Root cause | Sev | Evidence | Status | Fix |
|---|---|---|---|---|---|---|---|
| POL-001 | Startup | "Later isn't responding" at launch (3 of the last 4 debug cold starts; one stayed frozen for over 4 min). | `FirebaseMessaging.onBackgroundMessage` was registered with an **empty** handler. On Android the plugin then starts a second Flutter engine on the main thread at every launch (`FlutterFirebaseMessagingBackgroundExecutor.startBackgroundIsolate` → `FlutterJNI.runBundleAndSnapshotFromLibrary`, from the ANR traces in `dumpsys dropbox data_app_anr`). Pushes carry a `notification` payload that the OS shows by itself, so the handler was never needed. | S1 | ANR traces 17:54 and 18:50; two cold starts after the change, with no ANR and the largest main-thread stall down from 207 to 104 skipped frames | fixed | this commit |
