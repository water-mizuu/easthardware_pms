import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_list/user_list_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/archive/archive_sort_enums.dart';
import 'package:easthardware_pms/presentation/cubit/archive/archived_product_display/archived_product_display_cubit.dart';
import 'package:easthardware_pms/presentation/cubit/archive/archived_user_display/archived_user_display_cubit.dart';
import 'package:easthardware_pms/presentation/views/archive/archived_product_data_source.dart';
import 'package:easthardware_pms/presentation/views/archive/archived_user_data_source.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/table_theme_data.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataColumn, PaginatedDataTable;
import 'package:flutter_bloc/flutter_bloc.dart';

class ArchivePanePage extends StatefulWidget {
  const ArchivePanePage({super.key});

  @override
  State<ArchivePanePage> createState() => _ArchivePanePageState();
}

class _ArchivePanePageState extends State<ArchivePanePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ArchivedProductDisplayCubit()),
        BlocProvider(create: (context) => ArchivedUserDisplayCubit()),
      ],
      child: Padding(
        padding: AppPadding.panePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PageHeader(),
            Spacing.v12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: NavigationView(
                      clipBehavior: Clip.hardEdge,
                      contentShape: const RoundedRectangleBorder(),
                      paneBodyBuilder: (_, __) => SingleChildScrollView(
                        child: _buildSelectedTab(),
                      ),
                      pane: NavigationPane(
                        displayMode: PaneDisplayMode.top,
                        selected: _selectedIndex,
                        onItemPressed: (index) {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        items: [
                          PaneItem(
                            icon: const Icon(FluentIcons.product),
                            title: const Text('Products'),
                            body: const SizedBox.shrink(),
                          ),
                          PaneItem(
                            icon: const Icon(FluentIcons.people),
                            title: const Text('Users'),
                            body: const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTab() {
    switch (_selectedIndex) {
      case 0:
        return const ArchivedProductsBody();
      case 1:
        return ArchivedUsersBody();
      default:
        return const Center(child: Text('No tab selected'));
    }
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const HeadingText('Archive'),
        const Spacer(flex: 1),
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class ArchivedProductsBody extends StatefulWidget {
  const ArchivedProductsBody({super.key});

  static const ArchivedProductsBody instance = ArchivedProductsBody();

  @override
  State<ArchivedProductsBody> createState() => _ArchivedProductsBodyState();
}

class _ArchivedProductsBodyState extends State<ArchivedProductsBody> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final productBloc = context.read<ProductListBloc>();
    final archivedProducts = productBloc.state.allProducts
        .where((p) => p.archiveStatus != null && p.archiveStatus! > 0)
        .toList();
    context.read<ArchivedProductDisplayCubit>().updateProducts(archivedProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int? _getSortColumnIndex(ArchivedProductSortBy sortBy) {
    switch (sortBy) {
      case ArchivedProductSortBy.idAscending:
      case ArchivedProductSortBy.idDescending:
        return 0;
      case ArchivedProductSortBy.skuAscending:
      case ArchivedProductSortBy.skuDescending:
        return 1;
      case ArchivedProductSortBy.nameAscending:
      case ArchivedProductSortBy.nameDescending:
        return 2;
      case ArchivedProductSortBy.categoryAscending:
      case ArchivedProductSortBy.categoryDescending:
        return 3;
      case ArchivedProductSortBy.priceAscending:
      case ArchivedProductSortBy.priceDescending:
        return 4;
      default:
        return null;
    }
  }

  bool _getSortAscending(ArchivedProductSortBy sortBy) {
    switch (sortBy) {
      case ArchivedProductSortBy.idAscending:
      case ArchivedProductSortBy.skuAscending:
      case ArchivedProductSortBy.nameAscending:
      case ArchivedProductSortBy.categoryAscending:
      case ArchivedProductSortBy.priceAscending:
        return true;
      case ArchivedProductSortBy.idDescending:
      case ArchivedProductSortBy.skuDescending:
      case ArchivedProductSortBy.nameDescending:
      case ArchivedProductSortBy.categoryDescending:
      case ArchivedProductSortBy.priceDescending:
        return false;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductListBloc, ProductListState>(
      listenWhen: (previous, current) => previous.allProducts != current.allProducts,
      listener: (context, state) {
        final archivedProducts = state.allProducts
            .where((p) => p.archiveStatus != null && p.archiveStatus! > 0)
            .toList();
        context.read<ArchivedProductDisplayCubit>().updateProducts(archivedProducts);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextBox(
                controller: _searchController,
                placeholder: 'Search by name, SKU or category',
                onChanged: (value) {
                  context.read<ArchivedProductDisplayCubit>().filterProducts(value);
                },
              ),
            ],
          ),
          Spacing.v12,
          BlocBuilder<ArchivedProductDisplayCubit, ArchivedProductDisplayState>(
            builder: (context, state) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).acrylicBackgroundColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: state.filteredProducts.isEmpty
                    ? Container(
                        constraints: const BoxConstraints(minHeight: 600),
                        decoration: const BoxDecoration(color: Colors.white),
                        child: const Center(
                          child: BodyText('No archived products found.'),
                        ),
                      )
                    : TableThemeData(
                        child: PaginatedDataTable(
                          showFirstLastButtons: true,
                          showCheckboxColumn: false,
                          horizontalMargin: 20,
                          columnSpacing: 16,
                          checkboxHorizontalMargin: 0,
                          sortColumnIndex: _getSortColumnIndex(state.sortBy),
                          sortAscending: _getSortAscending(state.sortBy),
                          columns: [
                            DataColumn(
                              label: Expanded(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 60),
                                  child: const Text('ID', style: TextStyles.strong),
                                ),
                              ),
                              onSort: (_, __) {
                                final cubit = context.read<ArchivedProductDisplayCubit>();
                                if (state.sortBy == ArchivedProductSortBy.idAscending) {
                                  cubit.sort(ArchivedProductSortBy.idDescending);
                                } else {
                                  cubit.sort(ArchivedProductSortBy.idAscending);
                                }
                              },
                            ),
                            DataColumn(
                              label: Expanded(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 100),
                                  child: const Text('SKU', style: TextStyles.strong),
                                ),
                              ),
                              onSort: (_, __) {
                                final cubit = context.read<ArchivedProductDisplayCubit>();
                                if (state.sortBy == ArchivedProductSortBy.skuAscending) {
                                  cubit.sort(ArchivedProductSortBy.skuDescending);
                                } else {
                                  cubit.sort(ArchivedProductSortBy.skuAscending);
                                }
                              },
                            ),
                            DataColumn(
                              label: Expanded(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 150),
                                  child: const Text('Name', style: TextStyles.strong),
                                ),
                              ),
                              onSort: (_, __) {
                                final cubit = context.read<ArchivedProductDisplayCubit>();
                                if (state.sortBy == ArchivedProductSortBy.nameAscending) {
                                  cubit.sort(ArchivedProductSortBy.nameDescending);
                                } else {
                                  cubit.sort(ArchivedProductSortBy.nameAscending);
                                }
                              },
                            ),
                            DataColumn(
                              label: Expanded(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 100),
                                  child: const Text('Category', style: TextStyles.strong),
                                ),
                              ),
                              onSort: (_, __) {
                                final cubit = context.read<ArchivedProductDisplayCubit>();
                                if (state.sortBy == ArchivedProductSortBy.categoryAscending) {
                                  cubit.sort(ArchivedProductSortBy.categoryDescending);
                                } else {
                                  cubit.sort(ArchivedProductSortBy.categoryAscending);
                                }
                              },
                            ),
                            DataColumn(
                              label: Expanded(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 100),
                                  child: const Text('Price', style: TextStyles.strong),
                                ),
                              ),
                              onSort: (_, __) {
                                final cubit = context.read<ArchivedProductDisplayCubit>();
                                if (state.sortBy == ArchivedProductSortBy.priceAscending) {
                                  cubit.sort(ArchivedProductSortBy.priceDescending);
                                } else {
                                  cubit.sort(ArchivedProductSortBy.priceAscending);
                                }
                              },
                            ),
                          ],
                          source: ArchivedProductDataSource(
                            products: state.filteredProducts,
                          ),
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ArchivedUsersBody extends StatefulWidget {
  ArchivedUsersBody();

  static final ArchivedUsersBody instance = ArchivedUsersBody();

  @override
  State<ArchivedUsersBody> createState() => _ArchivedUsersBodyState();
}

class _ArchivedUsersBodyState extends State<ArchivedUsersBody> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final userBloc = context.read<UserListBloc>();
    final archivedUsers =
        userBloc.state.users.where((u) => u.archiveStatus != null && u.archiveStatus! > 0).toList();
    context.read<ArchivedUserDisplayCubit>().updateUsers(archivedUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int? _getSortColumnIndex(ArchivedUserSortBy sortBy) {
    switch (sortBy) {
      case ArchivedUserSortBy.idAscending:
      case ArchivedUserSortBy.idDescending:
        return 0;
      case ArchivedUserSortBy.usernameAscending:
      case ArchivedUserSortBy.usernameDescending:
        return 1;
      case ArchivedUserSortBy.nameAscending:
      case ArchivedUserSortBy.nameDescending:
        return 2;
      case ArchivedUserSortBy.accessLevelAscending:
      case ArchivedUserSortBy.accessLevelDescending:
        return 3;
      case ArchivedUserSortBy.creationDateAscending:
      case ArchivedUserSortBy.creationDateDescending:
        return 4;
      default:
        return null;
    }
  }

  bool _getSortAscending(ArchivedUserSortBy sortBy) {
    switch (sortBy) {
      case ArchivedUserSortBy.idAscending:
      case ArchivedUserSortBy.usernameAscending:
      case ArchivedUserSortBy.nameAscending:
      case ArchivedUserSortBy.accessLevelAscending:
      case ArchivedUserSortBy.creationDateAscending:
        return true;
      case ArchivedUserSortBy.idDescending:
      case ArchivedUserSortBy.usernameDescending:
      case ArchivedUserSortBy.nameDescending:
      case ArchivedUserSortBy.accessLevelDescending:
      case ArchivedUserSortBy.creationDateDescending:
        return false;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserListBloc, UserListState>(
      listenWhen: (previous, current) => previous.users != current.users,
      listener: (context, state) {
        final archivedUsers =
            state.users.where((u) => u.archiveStatus != null && u.archiveStatus! > 0).toList();
        context.read<ArchivedUserDisplayCubit>().updateUsers(archivedUsers);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextBox(
                  controller: _searchController,
                  placeholder: 'Search by username or name',
                  onChanged: (value) {
                    context.read<ArchivedUserDisplayCubit>().filterUsers(value);
                  },
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
          Spacing.v12,
          BlocBuilder<ArchivedUserDisplayCubit, ArchivedUserDisplayState>(
            builder: (context, state) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).acrylicBackgroundColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: state.filteredUsers.isEmpty
                    ? Container(
                        constraints: const BoxConstraints(minHeight: 600),
                        decoration: const BoxDecoration(color: Colors.white),
                        child: const Center(
                          child: BodyText('No archived users found.'),
                        ),
                      )
                    : TableThemeData(
                        child: PaginatedDataTable(
                          showFirstLastButtons: true,
                          showCheckboxColumn: false,
                          horizontalMargin: 20,
                          columnSpacing: 16,
                          checkboxHorizontalMargin: 0,
                          sortColumnIndex: _getSortColumnIndex(state.sortBy),
                          sortAscending: _getSortAscending(state.sortBy),
                          columns: [
                            DataColumn(
                              label: Expanded(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 60),
                                  child: const Text('ID', style: TextStyles.strong),
                                ),
                              ),
                              onSort: (_, __) {
                                final cubit = context.read<ArchivedUserDisplayCubit>();
                                if (state.sortBy == ArchivedUserSortBy.idAscending) {
                                  cubit.sort(ArchivedUserSortBy.idDescending);
                                } else {
                                  cubit.sort(ArchivedUserSortBy.idAscending);
                                }
                              },
                            ),
                            DataColumn(
                              label: Expanded(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 100),
                                  child: const Text('Username', style: TextStyles.strong),
                                ),
                              ),
                              onSort: (_, __) {
                                final cubit = context.read<ArchivedUserDisplayCubit>();
                                if (state.sortBy == ArchivedUserSortBy.usernameAscending) {
                                  cubit.sort(ArchivedUserSortBy.usernameDescending);
                                } else {
                                  cubit.sort(ArchivedUserSortBy.usernameAscending);
                                }
                              },
                            ),
                            DataColumn(
                              label: Expanded(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 150),
                                  child: const Text('Name', style: TextStyles.strong),
                                ),
                              ),
                              onSort: (_, __) {
                                final cubit = context.read<ArchivedUserDisplayCubit>();
                                if (state.sortBy == ArchivedUserSortBy.nameAscending) {
                                  cubit.sort(ArchivedUserSortBy.nameDescending);
                                } else {
                                  cubit.sort(ArchivedUserSortBy.nameAscending);
                                }
                              },
                            ),
                            DataColumn(
                              label: Expanded(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 100),
                                  child: const Text('Access Level', style: TextStyles.strong),
                                ),
                              ),
                              onSort: (_, __) {
                                final cubit = context.read<ArchivedUserDisplayCubit>();
                                if (state.sortBy == ArchivedUserSortBy.accessLevelAscending) {
                                  cubit.sort(ArchivedUserSortBy.accessLevelDescending);
                                } else {
                                  cubit.sort(ArchivedUserSortBy.accessLevelAscending);
                                }
                              },
                            ),
                            DataColumn(
                              label: Expanded(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 120),
                                  child: const Text('Creation Date', style: TextStyles.strong),
                                ),
                              ),
                              onSort: (_, __) {
                                final cubit = context.read<ArchivedUserDisplayCubit>();
                                if (state.sortBy == ArchivedUserSortBy.creationDateAscending) {
                                  cubit.sort(ArchivedUserSortBy.creationDateDescending);
                                } else {
                                  cubit.sort(ArchivedUserSortBy.creationDateAscending);
                                }
                              },
                            ),
                          ],
                          source: ArchivedUserDataSource(
                            users: state.filteredUsers,
                          ),
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}
