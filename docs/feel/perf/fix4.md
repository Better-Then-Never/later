
| Flow | Frames | Janky % | Worst frame (ms) | p90 frame (ms) | Janky % per run |
|---|---|---|---|---|---|
| add_friends_transition | 164 | 1.8 | 15.0 | 4.3 | 1.8 / 1.2 / 1.8 |
| camera_capture | 153 | 1.3 | 13.7 | 3.4 | 1.3 / 1.3 / 1.9 |
| camera_open_close | 166 | 0.6 | 9.5 | 3.3 | 0.6 / 1.2 / 0.6 |
| capsule_dialog | 149 | 1.3 | 15.6 | 3.4 | 1.4 / 1.3 / 1.3 |
| chat_open | 276 | 1.4 | 16.8 | 5.1 | 0.7 / 2.2 / 1.4 |
| chat_options_sheet | 251 | 0.0 | 8.2 | 3.9 | 0.0 / 0.0 / 0.4 |
| chat_scroll | 308 | 0.0 | 7.0 | 3.9 | 0.0 / 0.0 / 0.0 |
| history_scroll | 335 | 0.0 | 6.4 | 3.4 | 0.0 / 0.0 / 0.0 |
| map_focus | 159 | 0.6 | 9.5 | 2.5 | 0.6 / 0.6 / 0.0 |
| map_pan_heatmap | 188 | 0.0 | 4.9 | 2.5 | 0.0 / 0.0 / 0.0 |
| map_pan_markers | 187 | 0.0 | 3.4 | 2.4 | 0.0 / 0.0 / 0.0 |
| map_zoom_in | 201 | 0.0 | 4.2 | 2.3 | 0.0 / 0.0 / 0.0 |
| map_zoom_out | 329 | 0.0 | 3.7 | 2.6 | 0.0 / 0.0 / 0.0 |
| notifications_tabs | 255 | 6.6 | 17.9 | 7.1 | 8.7 / 6.6 / 4.3 |
| photo_viewer | 122 | 1.7 | 17.9 | 4.4 | 1.7 / 2.4 / 0.8 |
| settings_open_close | 121 | 2.5 | 15.7 | 4.6 | 4.1 / 2.5 / 0.8 |
| startup | 128 | 5.5 | 26.8 | 3.8 | 5.8 / 5.5 / 4.7 |
| tab_switches | 317 | 0.6 | 27.6 | 3.3 | 0.9 / 0.3 / 0.6 |
| theme_switch | 291 | 0.7 | 23.1 | 2.8 | 0.7 / 0.3 / 0.7 |

| Measured | Median | All |
|---|---|---|
| add_friends_transition_wall_ms | 2257 | 2257, 2271, 2257 |
| camera_capture.camera.feedback_ms | 20 | 31, 20, 11 |
| camera_capture.camera.file_ms | 1107 | 1107, 1086, 1120 |
| camera_capture.creation.firstFrame_ms | 1126 | 1126, 1105, 1148 |
| camera_capture_wall_ms | 3259 | 3259, 3236, 3281 |
| camera_open_close_wall_ms | 4048 | 4048, 4060, 4033 |
| camera_tap_to_creation_test_ms | 1147 | 1147, 1114, 1169 |
| capsule_dialog_wall_ms | 2258 | 2258, 2272, 2237 |
| chat_open.chat.messagesShown_ms | 23 | 32, 22, 29, 24, 21, 22 |
| chat_open_test_ms | 43 | 98, 43, 28, 106, 43, 36, 93, 28, 28 |
| chat_open_wall_ms | 7682 | 7682, 7707, 7658 |
| chat_options_sheet_wall_ms | 4466 | 4466, 4457, 4505 |
| chat_scroll_wall_ms | 18582 | 18582, 18574, 18631 |
| history_scroll_wall_ms | 13965 | 13958, 14028, 13965 |
| map_focus_wall_ms | 3139 | 3123, 3139, 3153 |
| map_pan_heatmap_wall_ms | 4488 | 4488, 4470, 4534 |
| map_pan_markers_wall_ms | 4472 | 4461, 4472, 4479 |
| map_zoom_in_wall_ms | 2937 | 2938, 2937, 2835 |
| map_zoom_out_wall_ms | 5492 | 5487, 5513, 5492 |
| notifications_tabs_wall_ms | 4525 | 4448, 4527, 4525 |
| photo_viewer_wall_ms | 2239 | 2242, 2239, 2226 |
| settings_open_close_wall_ms | 2230 | 2277, 2230, 2212 |
| startup_ms_to_home | 486 | 500, 486, 431 |
| tab_switches_wall_ms | 7569 | 7589, 7569, 7568 |
| theme_switch_wall_ms | 4811 | 4811, 4793, 4846 |

Android main-thread stalls (Choreographer "Skipped N frames", whole run; Flutter gets no vsync meanwhile, so nothing moves):
run_1: 2 stalls, 609 frames in all, longest 565 (~4.7 s at 120 Hz): 44, 565
run_2: 3 stalls, 643 frames in all, longest 566 (~4.7 s at 120 Hz): 41, 36, 566
run_3: 2 stalls, 614 frames in all, longest 569 (~4.7 s at 120 Hz): 45, 569
