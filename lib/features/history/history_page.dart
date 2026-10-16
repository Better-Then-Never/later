import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/assets/app_assets.dart';
import '../../data/models/capsule.dart';
import '../../data/models/geo_position.dart';
import '../../app/shell/selected_page.dart';
import '../../shared/widgets/popup/popup_notification_service.dart';
import '../../shared/widgets/buttons/default_button_with_icon.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/default_search_bar.dart';
import '../../shared/widgets/page_header.dart';
import '../map/current_location.dart';
import '../map/map_focus.dart';
import 'favorites_store.dart';
import 'history_controller.dart';
import 'own_capsules_store.dart';
import 'widgets/capsule_list_tile.dart';
import 'widgets/capsule_selection_action_bar.dart';
import 'widgets/menu_item_node.dart';
import 'widgets/nested_menu.dart';

/// "My Capsules": the signed-in user's capsules from [OwnCapsulesStore],
/// newest first, with search, sort, filters, favourites and multi-delete.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _controller = HistoryController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => _controller.updateSearchQuery(_searchController.text),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _plural(int n) => 'capsule${n > 1 ? 's' : ''}';

  void _confirmDelete() {
    final count = _controller.selectedCount;
    final ids = _controller.selectedIds;
    final store = context.read<OwnCapsulesStore>();
    ConfirmDialog.show(
      context: context,
      title: 'Delete $count ${_plural(count)}?',
      onConfirm: () async {
        final failure = await store.delete(ids);
        if (!mounted) return;
        if (failure != null) {
          PopupNotificationService.showError(
            context: context,
            message: failure.message,
            position: NotificationPosition.bottom,
          );
          return;
        }
        PopupNotificationService.showInfo(
          context: context,
          message: '$count ${_plural(count)} deleted',
          position: NotificationPosition.bottom,
        );
        _controller.clearSelection();
      },
    );
  }

  Future<void> _toggleFavorite(Capsule capsule) async {
    final favorites = context.read<FavoritesStore>();
    final failure = await favorites.toggle(capsule.id);
    if (!mounted) return;
    if (failure != null) {
      PopupNotificationService.showError(
        context: context,
        message: failure.message,
        position: NotificationPosition.bottom,
      );
      return;
    }
    final added = favorites.isFavorite(capsule.id);
    PopupNotificationService.showInfo(
      context: context,
      message:
          '${capsule.title} ${added ? 'Added to' : 'Removed from'} favorites',
      position: NotificationPosition.bottom,
    );
  }

  void _onTap(Capsule capsule) {
    if (_controller.isSelectionMode) {
      _controller.toggleSelection(capsule.id);
    } else if (capsule.location != null) {
      context.read<MapFocus>().focus(capsule);
      selectedPageNotifier.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    // The gap between the header buttons has always been 1% of the height.
    final buttonGap = screenHeight * 0.01;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => PopScope(
        canPop: !_controller.isSelectionMode,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _controller.clearSelection();
        },
        child: Column(
          children: [
            PageHeader(
              mainText: 'My Capsules',
              searchBar: DefaultSearchBar(
                controller: _searchController,
                searchFocusNode: _searchFocusNode,
                hintText: 'Find Capsules...',
              ),
              actionButtonsRow: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DefaultButtonWithIcon(
                          height: screenHeight * 0.05,
                          onTap: () => _openSortMenu(context),
                          assetPath: AppIcons.historySort,
                          text: _controller.activeSortLabel,
                        ),
                      ),
                      SizedBox(width: buttonGap),
                      Expanded(
                        child: DefaultButtonWithIcon(
                          height: screenHeight * 0.05,
                          assetPath: AppIcons.historyFilter,
                          text: _controller.activeFilterLabel,
                          onTap: () => _openFilterMenu(context),
                        ),
                      ),
                      SizedBox(width: buttonGap),
                      Expanded(
                        child: DefaultButtonWithIcon(
                          height: screenHeight * 0.05,
                          onTap: _controller.resetAll,
                          assetPath: AppIcons.historySort,
                          text: 'Reset',
                        ),
                      ),
                    ],
                  ),
                  if (_controller.isSelectionMode)
                    SelectionActionBar(
                      count: _controller.selectedCount,
                      onCancel: _controller.clearSelection,
                      onDelete: _confirmDelete,
                    ),
                ],
              ),
            ),
            Expanded(child: _buildList(context, screenHeight)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, double screenHeight) {
    final store = context.watch<OwnCapsulesStore>();
    final favorites = context.watch<FavoritesStore>();
    final here = context.select<CurrentLocation, GeoPosition?>(
      (l) => l.position,
    );

    if (!store.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = store.error;
    if (error != null && store.capsules.isEmpty) {
      return Center(child: Text(error.message));
    }

    final all = store.capsules;
    // Capsules deleted elsewhere cannot stay selected.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.retainSelection(all.map((c) => c.id));
    });

    final shown = _controller.apply(
      all,
      favorites: favorites.favorites,
      from: here,
    );
    if (shown.isEmpty) {
      return Center(
        child: Text(
          _controller.searchQuery.isEmpty
              ? 'No capsules yet'
              : 'No capsules match your search',
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
      itemCount: shown.length,
      itemBuilder: (context, i) {
        final capsule = shown[i];
        return CapsuleListTile(
          key: ValueKey(capsule.id),
          capsule: capsule,
          isSelected: _controller.isSelected(capsule.id),
          isFavorite: favorites.isFavorite(capsule.id),
          onFavoriteTap: () => _toggleFavorite(capsule),
          onTap: () => _onTap(capsule),
          onLongPress: () => _controller.toggleSelection(capsule.id),
        );
      },
    );
  }

  void _openFilterMenu(BuildContext context) {
    final controller = _controller;
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: NestedMenu(
          title: 'Filter By',
          rootItems: [
            MenuItemNode(label: 'Reset', onTap: controller.resetFilters),
            MenuItemNode(
              label: 'Color',
              children: [
                for (final color in CapsuleColor.values)
                  MenuItemNode(
                    label: color.label,
                    onTap: () => controller.setColorFilter(color),
                  ),
              ],
            ),
            MenuItemNode(
              label: 'Visibility',
              children: [
                for (final privacy in CapsulePrivacy.values)
                  MenuItemNode(
                    label: privacy.label,
                    onTap: () => controller.setPrivacyFilter(privacy),
                  ),
              ],
            ),
            MenuItemNode(
              label: 'Capsule',
              children: [
                MenuItemNode(
                  label: 'Favorite',
                  onTap: () => controller.setFavoritesOnly(true),
                ),
                MenuItemNode(
                  label: 'Any',
                  onTap: () => controller.setFavoritesOnly(false),
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
    MenuItemNode item(HistorySort sort) =>
        MenuItemNode(label: sort.label!, onTap: () => controller.setSort(sort));
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: NestedMenu(
          title: 'Sort By',
          rootItems: [
            MenuItemNode(label: 'Reset', onTap: controller.resetSort),
            MenuItemNode(
              label: 'Relevance',
              children: [item(HistorySort.oldest), item(HistorySort.newest)],
            ),
            MenuItemNode(
              label: 'Distance',
              children: [item(HistorySort.closest), item(HistorySort.farthest)],
            ),
          ],
        ),
      ),
    );
  }
}
