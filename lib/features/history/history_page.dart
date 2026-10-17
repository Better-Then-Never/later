import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/shell/navbar_widget.dart';
import '../../app/router/app_routes.dart';
import '../../core/assets/app_assets.dart';
import '../../core/config/feature_flags.dart';
import '../../core/l10n/l10n.dart';
import '../../data/models/capsule.dart';
import '../../data/models/geo_position.dart';
import '../../app/shell/selected_page.dart';
import '../../shared/widgets/popup/popup_notification_service.dart';
import '../../shared/widgets/buttons/default_button_with_icon.dart';
import '../../shared/widgets/app_sheets.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/default_empty_inbox_info.dart';
import '../../shared/widgets/default_search_bar.dart';
import '../../shared/widgets/page_header.dart';
import '../map/current_location.dart';
import '../map/map_focus.dart';
import 'capsule_labels.dart';
import 'favorites_store.dart';
import 'history_controller.dart';
import 'own_capsules_store.dart';
import 'on_this_day.dart';
import 'widgets/capsule_list_tile.dart';
import 'widgets/on_this_day_strip.dart';
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

  void _confirmDelete() {
    final count = _controller.selectedCount;
    final ids = _controller.selectedIds;
    final store = context.read<OwnCapsulesStore>();
    ConfirmDialog.show(
      context: context,
      title: context.l10n.historyDeleteConfirm(count),
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
          message: context.l10n.historyDeleted(count),
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
      message: added
          ? context.l10n.historyFavoriteAdded(capsule.title)
          : context.l10n.historyFavoriteRemoved(capsule.title),
      position: NotificationPosition.bottom,
    );
  }

  void _onTap(Capsule capsule) {
    if (_controller.isSelectionMode) {
      _controller.toggleSelection(capsule.id);
    } else if (capsule.location != null) {
      context.read<MapFocus>().focus(capsule);
      selectedPageNotifier.value = AppTabs.map;
    }
  }

  /// Sort, Filter and Reset on the shared scale (F-31: they were 5 % of the
  /// screen tall with 32 dp pictures): tap-target height, list-size icons.
  static const _controlHeight = 44.0;
  static const _controlIcon = 24.0;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    // The gap between the header buttons has always been 1% of the height.
    final buttonGap = screenHeight * 0.01;
    final l10n = context.l10n;

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
              mainText: l10n.historyTitle,
              searchBar: DefaultSearchBar(
                controller: _searchController,
                searchFocusNode: _searchFocusNode,
                hintText: l10n.historySearchHint,
              ),
              actionButtonsRow: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DefaultButtonWithIcon(
                          height: _controlHeight,
                          iconSize: _controlIcon,
                          onTap: () => _openSortMenu(context),
                          assetPath: AppIcons.historySort,
                          text: _controller.activeSortLabel(l10n),
                        ),
                      ),
                      SizedBox(width: buttonGap),
                      Expanded(
                        child: DefaultButtonWithIcon(
                          height: _controlHeight,
                          iconSize: _controlIcon,
                          assetPath: AppIcons.historyFilter,
                          text: _controller.activeFilterLabel(l10n),
                          onTap: () => _openFilterMenu(context),
                        ),
                      ),
                      SizedBox(width: buttonGap),
                      Expanded(
                        child: DefaultButtonWithIcon(
                          height: _controlHeight,
                          iconSize: _controlIcon,
                          onTap: _controller.resetAll,
                          // Clear, not sort (F-31: it reused the sort icon).
                          assetPath: AppIcons.friendsDeleteReset,
                          text: l10n.historyReset,
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
    final l10n = context.l10n;
    final error = store.error;
    if (error != null && store.capsules.isEmpty) {
      return DefaultEmptyInboxInfo(
        message: l10n.historyLoadError,
        subtitle: error.message,
        assetPath: AppIcons.navbarHistory,
      );
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
      // Nothing yet: say what a capsule is and offer to make one. Nothing
      // left after a search or filter: say how to get them back.
      return all.isEmpty
          ? DefaultEmptyInboxInfo(
              message: l10n.historyEmpty,
              subtitle: l10n.historyEmptySubtitle,
              assetPath: AppIcons.navbarAdd,
              actionText: l10n.historyCreateFirst,
              onAction: () => AppRoutes.toCamera(context),
            )
          : DefaultEmptyInboxInfo(
              message: l10n.historyNoMatches,
              subtitle: l10n.historyNoMatchesSubtitle,
              assetPath: AppIcons.profileFriendSearch,
              actionText: l10n.historyReset,
              onAction: () {
                _searchController.clear();
                _controller.resetFilters();
              },
            );
    }

    // The whole list, unsearched and unfiltered: then memories lead it.
    final now = DateTime.now();
    final memories = FeatureFlags.memories && !_controller.isNarrowed
        ? OnThisDay.from(all, now)
        : const <Capsule>[];
    final lead = memories.isEmpty ? 0 : 1;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        0,
        screenHeight * 0.01,
        0,
        // Clear of the floating navbar (15 % of the height left the last
        // capsule partly under it on 3-button navigation).
        NavbarWidget.coveredHeight(context) + 16,
      ),
      itemCount: shown.length + lead,
      itemBuilder: (context, index) {
        if (index < lead) {
          return OnThisDayStrip(capsules: memories, now: now, onTap: _onTap);
        }
        final capsule = shown[index - lead];
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
    final l10n = context.l10n;
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    showCenteredSheet<void>(
      context,
      NestedMenu(
        title: l10n.historyFilterBy,
        rootItems: [
          MenuItemNode(
            label: l10n.historyReset,
            onTap: controller.resetFilters,
          ),
          MenuItemNode(
            label: l10n.historyFilterColor,
            children: [
              for (final color in CapsuleColor.values)
                MenuItemNode(
                  label: color.localizedLabel(l10n),
                  onTap: () => controller.setColorFilter(color),
                  selected: controller.colorFilter == color,
                ),
            ],
          ),
          MenuItemNode(
            label: l10n.historyFilterVisibility,
            children: [
              for (final privacy in CapsulePrivacy.values)
                MenuItemNode(
                  label: privacy.localizedLabel(l10n),
                  onTap: () => controller.setPrivacyFilter(privacy),
                  selected: controller.privacyFilter == privacy,
                ),
            ],
          ),
          MenuItemNode(
            label: l10n.historyFilterCapsule,
            children: [
              MenuItemNode(
                label: l10n.historyFilterFavorite,
                onTap: () => controller.setFavoritesOnly(true),
                selected: controller.favoritesOnly,
              ),
              MenuItemNode(
                label: l10n.historyFilterAny,
                onTap: () => controller.setFavoritesOnly(false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openSortMenu(BuildContext context) {
    final controller = _controller;
    final l10n = context.l10n;
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    MenuItemNode item(HistorySort sort) => MenuItemNode(
      label: sort.label(l10n)!,
      onTap: () => controller.setSort(sort),
      selected: controller.sort == sort,
    );
    showCenteredSheet<void>(
      context,
      NestedMenu(
        title: l10n.historySortBy,
        rootItems: [
          MenuItemNode(label: l10n.historyReset, onTap: controller.resetSort),
          MenuItemNode(
            label: l10n.historySortRelevance,
            children: [item(HistorySort.oldest), item(HistorySort.newest)],
          ),
          MenuItemNode(
            label: l10n.historySortDistance,
            children: [item(HistorySort.closest), item(HistorySort.farthest)],
          ),
        ],
      ),
    );
  }
}
