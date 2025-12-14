import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:later/controllers/page_controllers/history_page_controller.dart';
import 'package:later/services/capsule_data_service.dart';
import 'package:later/services/popup_notification_service.dart';
import 'package:later/views/widgets/_common/default_elements/confirm_dialog.dart';
import 'package:later/views/widgets/_common/default_elements/default_search_bar.dart';
import 'package:later/views/widgets/_common/default_elements/page_header.dart';
import 'package:later/views/widgets/_common/default_elements/popup_notification.dart';
import 'package:later/views/widgets/history_page/capsule_list_tile.dart';
import 'package:later/views/widgets/history_page/capsule_selection_action_bar.dart';
import 'package:provider/provider.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  late final HistoryPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HistoryPageController();

    _searchController.addListener(() {
      _controller.updateSearchQuery(_searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    final capsuleService = context.read<CapsuleDataService>();

    return WillPopScope(
      onWillPop: () async {
        if (_controller.isSelectionMode) {
          _controller.clearSelection();
          return false;
        }
        return true;
      },
      child: Stack(
        children: [
          Column(
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => PageHeader(
                  mainText: "Capsule History",
                  searchBar: DefaultSearchBar(
                    controller: _searchController,
                    hintText: "Find Capsules...",
                  ),
                  actionButtonsRow: _controller.isSelectionMode
                      ? SelectionActionBar(
                          count: _controller.selectedCount,
                          onCancel: _controller.clearSelection,
                          onDelete: () {
                            ConfirmDialog.show(
                              context: context,
                              title:
                                  'Delete ${_controller.selectedCount} capsule${_controller.selectedCount > 1 ? 's' : ''}?',
                              onConfirm: () async {
                                await capsuleService.deleteCapsules(
                                  _controller.selectedIds,
                                );

                                if (!context.mounted) return;

                                PopupNotificationService.showInfo(
                                  context: context,
                                  message:
                                      "${_controller.selectedCount} capsule${_controller.selectedCount > 1 ? 's' : ''} deleted",
                                  position: NotificationPosition.center
                                );
                                _controller.clearSelection();
                              },
                            );
                          },
                        )
                      : null,
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: capsuleService.subscribeToCapsules(
                    FirebaseAuth.instance.currentUser!.uid,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final capsules = snapshot.data ?? [];

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _controller.capsules = capsules;
                    });

                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final filtered = _controller.filteredCapsules;

                        if (filtered.isEmpty) {
                          return Center(
                            child: Text(
                              _controller.searchQuery.isEmpty
                                  ? "No capsules yet"
                                  : "No capsules match your search",
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            0,
                            screenHeight * 0.01,
                            0,
                            screenHeight * 0.15,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final c = filtered[i];
                            return CapsuleListTile(
                              capsule: c,
                              isSelected: _controller.isSelected(c['id']),
                              selectionMode: _controller.isSelectionMode,
                              onTap: () {
                                if (_controller.isSelectionMode) {
                                  _controller.toggleSelection(c['id']);
                                } else {
                                  // open capsule
                                }
                              },
                              onLongPress: () {
                                _controller.toggleSelection(c['id']);
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
