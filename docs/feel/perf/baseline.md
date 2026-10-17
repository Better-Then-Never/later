
| Flow | Frames | Janky % | Worst frame (ms) | p90 frame (ms) | Janky % per run |
|---|---|---|---|---|---|
| add_friends_transition | 160 | 2.5 | 18.1 | 5.1 | 2.5 / 5.0 / 2.5 |
| camera_capture | 145 | 1.4 | 19.9 | 2.9 | 1.4 / 1.4 / 2.0 |
| camera_open_close | 165 | 1.2 | 28.4 | 3.3 | 1.2 / 0.6 / 1.2 |
| capsule_dialog | 149 | 0.7 | 14.5 | 3.0 | 1.4 / 0.7 / 0.7 |
| chat_open | 283 | 3.2 | 14.4 | 6.6 | 7.4 / 3.2 / 2.1 |
| chat_options_sheet | 251 | 0.0 | 6.4 | 4.0 | 0.0 / 0.0 / 0.0 |
| chat_scroll | 308 | 0.0 | 6.3 | 4.0 | 0.0 / 0.0 / 0.0 |
| history_scroll | 336 | 0.0 | 6.4 | 3.7 | 0.0 / 0.0 / 0.3 |
| map_focus | 174 | 0.6 | 14.1 | 2.7 | 0.6 / 0.6 / 0.6 |
| map_pan_heatmap | 191 | 0.5 | 8.8 | 3.1 | 0.5 / 0.5 / 0.0 |
| map_pan_markers | 188 | 0.0 | 3.6 | 2.6 | 0.0 / 0.5 / 0.0 |
| map_zoom_in | 207 | 0.0 | 3.7 | 2.2 | 0.0 / 0.0 / 0.0 |
| map_zoom_out | 327 | 0.0 | 4.1 | 2.7 | 0.0 / 0.0 / 0.0 |
| notifications_tabs | 251 | 10.8 | 15.5 | 8.8 | 10.8 / 12.4 / 7.5 |
| photo_viewer | 123 | 0.8 | 13.1 | 6.2 | 0.8 / 2.4 / 0.8 |
| settings_open_close | 104 | 12.4 | 33.4 | 9.8 | 15.4 / 12.4 / 9.6 |
| startup | 62 | 8.1 | 26.5 | 4.2 | 9.8 / 8.1 / 7.6 |
| tab_switches | 317 | 0.3 | 29.6 | 3.5 | 0.3 / 0.3 / 0.3 |
| theme_switch | 129 | 16.8 | 31.6 | 12.7 | 13.2 / 16.8 / 61.3 |

| Measured | Median | All |
|---|---|---|
| camera_capture.camera.feedback_ms | 26 | 34, 26, 11 |
| camera_capture.camera.file_ms | 1053 | 1053, 908, 1113 |
| camera_capture.creation.firstFrame_ms | 1070 | 1070, 932, 1129 |
| camera_tap_to_creation_test_ms | 1094 | 1094, 951, 1137 |
| chat_open.chat.messagesShown_ms | 21 | 20, 29, 19, 19, 22, 22 |
| chat_open_test_ms | 34 | 98, 27, 42, 108, 27, 26, 99, 34, 34 |
| startup_ms_to_home | 397 | 397, 402, 397 |

Android (TimeStats, app layers, whole run):
run_1: 22 of 253 frames janky (8.7 %), app-attributed 22
run_2: 23 of 220 frames janky (10.5 %), app-attributed 23
run_3: 25 of 251 frames janky (10.0 %), app-attributed 25
