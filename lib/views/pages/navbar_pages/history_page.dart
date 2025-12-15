import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:later/controllers/page_controllers/history_page_controller.dart';
import 'package:later/data/models/time_capsule.dart';
import 'package:later/data/notifiers.dart';
import 'package:later/services/capsule_data_service.dart';
import 'package:later/services/map_capsule_jump_service.dart';
import 'package:later/services/popup_notification_service.dart';
import 'package:later/services/user_favorite_capsules_service.dart';
import 'package:later/views/widgets/_common/default_buttons/default_button_with_icon.dart';
import 'package:later/views/widgets/_common/default_elements/confirm_dialog.dart';
import 'package:later/views/widgets/_common/default_elements/default_search_bar.dart';
import 'package:later/views/widgets/_common/default_elements/page_header.dart';
import 'package:later/views/widgets/history_page/capsule_list_tile.dart';
import 'package:later/views/widgets/history_page/capsule_selection_action_bar.dart';
import 'package:later/views/widgets/history_page/menu_item_node.dart';
import 'package:later/views/widgets/history_page/nested_menu.dart';
import 'package:provider/provider.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  late final HistoryPageController _controller;
  late final Stream<List<Map<String, dynamic>>> _capsulesStream;

  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _controller = HistoryPageController();
    _capsulesStream = context.read<CapsuleDataService>().subscribeToCapsules(
      FirebaseAuth.instance.currentUser!.uid,
    );
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
    double screenWidth = MediaQuery.of(context).size.height;

    final capsuleService = context.read<CapsuleDataService>();
    final favoriteService = context.read<FavoriteCapsuleService>();

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
                  mainText: "My Capsules",
                  searchBar: DefaultSearchBar(
                    controller: _searchController,
                    searchFocusNode: _searchFocusNode,
                    hintText: "Find Capsules...",
                  ),
                  actionButtonsRow: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DefaultButtonWithIcon(
                              height: screenHeight * 0.05,
                              onTap: () => _openSortMenu(context),
                              assetPath:
                                  'assets/images/icons/history_page/sort.png',
                              text: _controller.activeSortLabel,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Expanded(
                            child: DefaultButtonWithIcon(
                              height: screenHeight * 0.05,
                              assetPath:
                                  'assets/images/icons/history_page/filter.png',
                              text: _controller.activeFilterLabel,
                              onTap: () => _openFilterMenu(context),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Expanded(
                            child: DefaultButtonWithIcon(
                              height: screenHeight * 0.05,
                              onTap: () => _controller.resetAll(),
                              assetPath:
                                  'assets/images/icons/history_page/sort.png',
                              text: 'Reset',
                            ),
                          ),
                        ],
                      ),
                      if (_controller.isSelectionMode)
                        SelectionActionBar(
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
                                  position: NotificationPosition.bottom,
                                );
                                _controller.clearSelection();
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _capsulesStream,
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
                        final filtered = _controller.filteredCapsules(
                          favoriteService,
                        );
                        ;

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
                            final capsuleId = c['id'];
                            final capsuleTitle = c['title'];
                            return Selector<FavoriteCapsuleService, bool>(
                              selector: (_, service) =>
                                  service.isFavorite(capsuleId),
                              builder: (_, isFavorite, __) {
                                return CapsuleListTile(
                                  key: ValueKey(capsuleId),
                                  capsule: c,
                                  isSelected: _controller.isSelected(capsuleId),
                                  selectionMode: _controller.isSelectionMode,
                                  isFavorite: isFavorite,
                                  onFavoriteTap: () {
                                    favoriteService.toggleFavorite(capsuleId);
                                    PopupNotificationService.showInfo(
                                      context: context,
                                      message:
                                          "${capsuleTitle} ${favoriteService.isFavorite(capsuleId) ? 'Added to' : 'Removed from'}  favorites",
                                      position: NotificationPosition.bottom,
                                    );
                                  },
                                  onTap: () {
                                    if (_controller.isSelectionMode) {
                                      _controller.toggleSelection(capsuleId);
                                    } else if (c['location'] != null) {
                                      context.read<CapsuleJumpService>().jumpTo(
                                        c,
                                      );

                                      selectedPageNotifier.value = 0;
                                    }
                                  },
                                  onLongPress: () {
                                    _controller.toggleSelection(capsuleId);
                                  },
                                );
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

  void _openFilterMenu(BuildContext context) {
    final controller = _controller;
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: NestedMenu(
          title: 'Filter By',
          rootItems: [
            MenuItemNode(label: 'Reset', onTap: controller.resetFilters),

            MenuItemNode(
              label: 'Color',
              children: CapsuleColor.values.map((color) {
                return MenuItemNode(
                  label: color.label,
                  onTap: () {
                    controller.setColorFilter(color);
                  },
                );
              }).toList(),
            ),

            MenuItemNode(
              label: 'Visibility',
              children: CapsulePrivacy.values.map((privacy) {
                return MenuItemNode(
                  label: privacy.label,
                  onTap: () {
                    controller.setPrivacyFilter(privacy);
                    controller.filterMode = FilterMode.visibility;
                  },
                );
              }).toList(),
            ),

            MenuItemNode(
              label: 'Capsule',
              children: [
                MenuItemNode(
                  label: 'Favorite',
                  onTap: () => _controller.setFavoriteFilter(true),
                ),
                MenuItemNode(
                  label: 'Any',
                  onTap: () => _controller.setFavoriteFilter(false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openSortMenu(BuildContext context) {
    final controller = _controller;
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: NestedMenu(
          title: 'Sort By',
          rootItems: [
            MenuItemNode(
              label: 'Reset',
              onTap: () => controller.resetSort(),
            ),

            MenuItemNode(
              label: 'Relevance',
              children: [
                MenuItemNode(
                  label: 'From Oldest',
                  onTap: () =>
                      controller.setSort(SortMode.relevance, SortOrder.oldest),
                ),
                MenuItemNode(
                  label: 'From Newest',
                  onTap: () =>
                      controller.setSort(SortMode.relevance, SortOrder.newest),
                ),
              ],
            ),

            MenuItemNode(
              label: 'Distance',
              children: [
                MenuItemNode(
                  label: 'From Closest',
                  onTap: () =>
                      controller.setSort(SortMode.distance, SortOrder.closest),
                ),
                MenuItemNode(
                  label: 'From Farthest',
                  onTap: () =>
                      controller.setSort(SortMode.distance, SortOrder.farthest),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
