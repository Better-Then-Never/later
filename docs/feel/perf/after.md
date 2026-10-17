Running build hooks...Running build hooks...Budget 8.3 ms, 3 run(s); medians over runs.

| Flow | Frames | Janky % | Worst frame (ms) | p90 frame (ms) | Janky % per run |
|---|---|---|---|---|---|
| add_friends_transition | 162 | 1.2 | 22.6 | 3.7 | 0.0 / 1.2 / 2.5 |
| camera_capture | 151 | 0.7 | 13.8 | 2.7 | 1.3 / 0.7 / 0.7 |
| camera_open_close | 168 | 0.6 | 9.6 | 3.3 | 1.2 / 0.6 / 0.0 |
| camera_pinch | 216 | 0.0 | 5.8 | 3.5 | 0.0 / 0.0 / 0.0 |
| capsule_dialog | 155 | 3.2 | 12.2 | 6.6 | 3.2 / 5.2 / 2.6 |
| chat_open | 286 | 1.7 | 15.2 | 5.3 | 2.1 / 1.7 / 1.0 |
| chat_options_sheet | 250 | 1.2 | 10.6 | 5.0 | 2.4 / 1.2 / 0.8 |
| chat_scroll | 308 | 0.0 | 7.0 | 4.3 | 0.0 / 0.0 / 0.0 |
| creation_save | 250 | 0.4 | 11.5 | 2.4 | 0.5 / 0.4 / 0.0 |
| history_scroll | 336 | 0.0 | 5.5 | 3.4 | 0.0 / 0.0 / 0.0 |
| map_focus | 158 | 0.0 | 8.0 | 2.8 | 0.0 / 0.6 / 0.0 |
| map_pan_heatmap | 185 | 0.0 | 3.8 | 2.6 | 0.0 / 0.0 / 0.0 |
| map_pan_markers | 184 | 0.0 | 4.0 | 2.5 | 0.0 / 0.0 / 0.5 |
| map_zoom_in | 200 | 0.0 | 4.2 | 2.5 | 0.0 / 0.0 / 0.0 |
| map_zoom_out | 327 | 0.0 | 4.5 | 2.6 | 0.0 / 0.0 / 0.0 |
| notifications_tabs | 281 | 1.1 | 10.9 | 2.9 | 1.1 / 0.7 / 1.1 |
| photo_viewer | 126 | 0.0 | 4.6 | 3.0 | 0.0 / 0.0 / 0.0 |
| settings_open_close | 122 | 3.3 | 14.4 | 4.5 | 2.5 / 4.1 / 3.3 |
| startup | 106 | 6.6 | 41.9 | 4.0 | 3.8 / 8.7 / 6.6 |
| tab_switches | 304 | 1.0 | 20.5 | 3.4 | 0.7 / 1.0 / 1.3 |
| theme_switch | 266 | 0.4 | 21.1 | 2.6 | 0.4 / 0.8 / 0.4 |

| Measured | Median | All |
|---|---|---|
| add_friends_transition_wall_ms | 2297 | 2234, 2325, 2297 |
| camera_capture.camera.feedback_ms | 24 | 24, 25, 15 |
| camera_capture.camera.file_ms | 1083 | 1090, 1083, 1073 |
| camera_capture.creation.firstFrame_ms | 1111 | 1111, 1114, 1096 |
| camera_capture_wall_ms | 3276 | 3292, 3276, 3242 |
| camera_flash_step_0 | 0 | 0, 0, 0 |
| camera_flash_step_1 | 1 | 1, 1, 1 |
| camera_flash_step_2 | 2 | 2, 2, 2 |
| camera_flash_step_3 | 3 | 3, 3, 3 |
| camera_flash_step_4 | 0 | 0, 0, 0 |
| camera_flash_step_5 | 1 | 1, 1, 1 |
| camera_open_close_wall_ms | 4077 | 4077, 4096, 4055 |
| camera_pinch_wall_ms | 5370 | 5443, 5370, 5311 |
| camera_pinch_zoom_x100 | 380 | 380, 380, 380 |
| camera_tap_to_creation_test_ms | 1131 | 1131, 1133, 1110 |
| capsule_dialog_wall_ms | 2269 | 2269, 2308, 2246 |
| chat_open.chat.messagesShown_ms | 23 | 24, 27, 23, 20, 20 |
| chat_open_test_ms | 44 | 10007, 188, 35, 123, 44, 36, 96, 28, 28 |
| chat_open_wall_ms | 7799 | 17775, 7799, 7648 |
| chat_options_sheet_wall_ms | 4476 | 4476, 4516, 4459 |
| chat_scroll_wall_ms | 18636 | 18636, 18698, 18623 |
| creation_save_to_closed_ms | 1877 | 1606, 1877, 2025 |
| creation_save_wall_ms | 3140 | 2832, 3140, 3236 |
| history_scroll_wall_ms | 14096 | 14315, 14096, 14010 |
| map_focus_wall_ms | 3170 | 3170, 3177, 3137 |
| map_pan_heatmap_wall_ms | 4478 | 4470, 4520, 4478 |
| map_pan_markers_wall_ms | 4501 | 4495, 4501, 4548 |
| map_zoom_in_wall_ms | 2995 | 3004, 2995, 2955 |
| map_zoom_out_wall_ms | 5580 | 5628, 5552, 5580 |
| notifications_tabs_wall_ms | 4503 | 4503, 4598, 4485 |
| photo_viewer_wall_ms | 2263 | 2264, 2263, 2255 |
| settings_open_close_wall_ms | 2241 | 2204, 2328, 2241 |
| startup_ms_to_home | 469 | 728, 469, 447 |
| tab_switches_wall_ms | 7617 | 7633, 7617, 7518 |
| theme_switch_wall_ms | 4852 | 4852, 4865, 4826 |

Android main-thread stalls (Choreographer "Skipped N frames", whole run; Flutter gets no vsync meanwhile, so nothing moves):
run_1: none
run_2: 3 stalls, 150 frames in all, longest 60 (~0.5 s at 120 Hz): 60, 41, 49
run_3: 1 stalls, 49 frames in all, longest 49 (~0.4 s at 120 Hz): 49
