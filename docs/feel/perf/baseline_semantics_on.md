
| Flow | Frames | Janky % | Worst frame (ms) | p90 frame (ms) | Janky % per run |
|---|---|---|---|---|---|
| add_friends_transition | 119 | 2.5 | 17.5 | 4.8 | 2.5 / 3.3 / 2.5 |
| camera_capture | 151 | 1.3 | 19.8 | 3.0 | 1.3 / 1.3 / 1.3 |
| camera_open_close | 165 | 1.2 | 39.9 | 3.4 | 1.2 / 1.2 / 1.2 |
| capsule_dialog | 151 | 0.7 | 9.5 | 3.4 | 0.7 / 0.7 / 1.3 |
| chat_open | 234 | 10.3 | 19.2 | 8.3 | 5.1 / 10.3 / 10.7 |
| chat_options_sheet | 234 | 0.4 | 11.6 | 4.4 | 0.0 / 0.4 / 0.4 |
| chat_scroll | 268 | 0.0 | 6.9 | 4.3 | 0.0 / 0.0 / 0.0 |
| history_scroll | 286 | 0.0 | 6.3 | 4.3 | 0.0 / 0.0 / 0.0 |
| map_focus | 158 | 0.6 | 16.4 | 3.1 | 0.6 / 0.6 / 0.0 |
| map_pan_heatmap | 189 | 0.0 | 5.2 | 2.7 | 0.5 / 0.0 / 0.0 |
| map_pan_markers | 188 | 0.0 | 4.0 | 2.6 | 0.0 / 0.0 / 0.0 |
| map_zoom_in | 200 | 0.0 | 4.4 | 2.4 | 0.0 / 0.0 / 0.0 |
| map_zoom_out | 283 | 0.0 | 4.7 | 3.2 | 0.0 / 0.0 / 0.0 |
| notifications_tabs | 140 | 10.1 | 21.5 | 8.1 | 10.1 / 15.0 / 9.0 |
| photo_viewer | 124 | 0.8 | 11.7 | 6.8 | 0.8 / 1.6 / 0.8 |
| settings_open_close | 102 | 14.4 | 42.3 | 10.0 | 11.3 / 15.7 / 14.4 |
| startup | 60 | 9.4 | 33.0 | 6.5 | 14.3 / 8.3 / 9.4 |
| tab_switches | 202 | 0.0 | 8.0 | 3.7 | 0.0 / 0.0 / 1.0 |
| theme_switch | 129 | 14.1 | 31.7 | 14.7 | 14.0 / 16.7 / 14.1 |

| Measured | Median | All |
|---|---|---|
| camera_capture.camera.feedback_ms | 22 | 22, 19, 37 |
| camera_capture.camera.file_ms | 1124 | 1131, 1076, 1124 |
| camera_capture.creation.firstFrame_ms | 1139 | 1155, 1101, 1139 |
| camera_tap_to_creation_test_ms | 1160 | 1167, 1111, 1160 |
| chat_open.chat.messagesShown_ms | 23 | 23, 33, 23 |
| chat_open_test_ms | 42 | 122, 40, 35, 112, 42, 45, 121, 37, 35 |
| startup_ms_to_home | 373 | 373, 417, 358 |

Android (TimeStats, app layers, whole run):
run_1: 26 of 224 frames janky (11.6 %), app-attributed 26
run_2: 20 of 213 frames janky (9.4 %), app-attributed 20
run_3: 22 of 214 frames janky (10.3 %), app-attributed 22
