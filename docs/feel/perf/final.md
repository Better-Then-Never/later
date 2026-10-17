Budget 8.3 ms, 1 run(s); medians over runs.

| Flow | Frames | Janky % | Worst frame (ms) | p90 frame (ms) | Janky % per run |
|---|---|---|---|---|---|
| add_friends_transition | 165 | 1.2 | 21.6 | 4.2 | 1.2 |
| camera_capture | 154 | 0.6 | 13.3 | 3.1 | 0.6 |
| camera_open_close | 170 | 1.2 | 16.1 | 3.8 | 1.2 |
| camera_pinch | 214 | 0.9 | 8.4 | 4.8 | 0.9 |
| capsule_dialog | 154 | 0.6 | 9.7 | 3.6 | 0.6 |
| chat_open | 293 | 1.4 | 12.1 | 4.9 | 1.4 |
| chat_options_sheet | 251 | 0.4 | 13.6 | 4.1 | 0.4 |
| chat_scroll | 318 | 0.0 | 6.2 | 3.9 | 0.0 |
| creation_save | 240 | 0.4 | 12.3 | 2.9 | 0.4 |
| history_scroll | 337 | 0.3 | 8.8 | 3.5 | 0.3 |
| map_compass | 177 | 0.0 | 4.6 | 3.3 | 0.0 |
| map_filter_sheet | 249 | 0.8 | 12.2 | 3.5 | 0.8 |
| map_focus | 163 | 1.8 | 11.1 | 3.5 | 1.8 |
| map_pan_heatmap | 186 | 0.0 | 4.2 | 3.4 | 0.0 |
| map_pan_markers | 184 | 0.0 | 6.5 | 3.1 | 0.0 |
| map_zoom_in | 193 | 0.0 | 6.8 | 3.0 | 0.0 |
| map_zoom_out | 295 | 0.0 | 5.1 | 3.4 | 0.0 |
| notifications_scroll | 308 | 0.6 | 11.4 | 3.5 | 0.6 |
| notifications_tabs | 275 | 1.5 | 20.8 | 4.1 | 1.5 |
| passport_open_scroll | 306 | 1.3 | 11.0 | 5.3 | 1.3 |
| photo_viewer | 126 | 0.0 | 6.7 | 3.8 | 0.0 |
| profile_scroll | 293 | 0.3 | 8.7 | 3.9 | 0.3 |
| settings_open_close | 124 | 0.8 | 14.2 | 4.6 | 0.8 |
| startup | 87 | 6.9 | 84.6 | 4.1 | 6.9 |
| streak_card | 280 | 0.0 | 7.6 | 3.9 | 0.0 |
| tab_switches | 286 | 0.7 | 21.7 | 3.8 | 0.7 |
| theme_switch | 265 | 0.8 | 28.1 | 3.0 | 0.8 |

| Measured | Median | All |
|---|---|---|
| add_friends_transition_wall_ms | 2283 | 2283 |
| camera_capture.camera.feedback_ms | 20 | 20 |
| camera_capture.camera.file_ms | 1110 | 1110 |
| camera_capture.creation.firstFrame_ms | 1131 | 1131 |
| camera_capture_wall_ms | 3246 | 3246 |
| camera_flash_step_0 | 0 | 0 |
| camera_flash_step_1 | 1 | 1 |
| camera_flash_step_2 | 2 | 2 |
| camera_flash_step_3 | 3 | 3 |
| camera_flash_step_4 | 0 | 0 |
| camera_flash_step_5 | 1 | 1 |
| camera_open_close_wall_ms | 4047 | 4047 |
| camera_pinch_wall_ms | 5409 | 5409 |
| camera_pinch_zoom_x100 | 380 | 380 |
| camera_tap_to_creation_test_ms | 1143 | 1143 |
| capsule_dialog_wall_ms | 2289 | 2289 |
| chat_open.chat.messagesShown_ms | 23 | 28, 18 |
| chat_open_test_ms | 38 | 129, 38, 30 |
| chat_open_wall_ms | 7727 | 7727 |
| chat_options_sheet_wall_ms | 4454 | 4454 |
| chat_scroll_wall_ms | 18645 | 18645 |
| creation_save_to_closed_ms | 1786 | 1786 |
| creation_save_wall_ms | 2988 | 2988 |
| history_scroll_wall_ms | 13957 | 13957 |
| map_compass_bearing_after_tap | 0 | 0 |
| map_compass_bearing_turned | 0 | 0 |
| map_compass_wall_ms | 3540 | 3540 |
| map_filter_sheet_wall_ms | 4476 | 4476 |
| map_focus_wall_ms | 3151 | 3151 |
| map_pan_heatmap_wall_ms | 4474 | 4474 |
| map_pan_markers_wall_ms | 4492 | 4492 |
| map_zoom_in_wall_ms | 2906 | 2906 |
| map_zoom_out_wall_ms | 5473 | 5473 |
| notifications_scroll_wall_ms | 9397 | 9397 |
| notifications_tabs_wall_ms | 4513 | 4513 |
| passport_open_scroll_wall_ms | 6948 | 6948 |
| photo_viewer_wall_ms | 2255 | 2255 |
| profile_scroll_wall_ms | 4821 | 4821 |
| settings_open_close_wall_ms | 2242 | 2242 |
| startup_ms_to_home | 623 | 623 |
| streak_card_wall_ms | 4480 | 4480 |
| tab_switches_wall_ms | 7539 | 7539 |
| theme_switch_wall_ms | 4793 | 4793 |

Android main-thread stalls (Choreographer "Skipped N frames", whole run; Flutter gets no vsync meanwhile, so nothing moves):
run_1: 1 stalls, 54 frames in all, longest 54 (~0.5 s at 120 Hz): 54
