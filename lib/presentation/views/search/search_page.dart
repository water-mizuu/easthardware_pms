import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/search/search_cubit.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:scroll_animator/scroll_animator.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final SearchCubit _searchCubit;
  late final AnimatedScrollController _scrollController;

  List<SingleChildWidget> get providers {
    return [
      BlocProvider<SearchCubit>.value(value: _searchCubit),
    ];
  }

  @override
  void initState() {
    super.initState();

    _searchCubit = SearchCubit(context.read<ProductListBloc>().state.allProducts);
    _scrollController = AnimatedScrollController(animationFactory: const ChromiumEaseInOut());
  }

  @override
  void dispose() {
    _searchCubit.close();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: AppPadding.panePadding,
            child: _PageHeader(),
          ),
          Spacing.v4,
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppPadding.panePadding.horizontal / 2,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SearchBody(),
                  ].withSpacing(() => Spacing.v16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const HeadingText('Search'),
        const Spacer(flex: 1),
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class SearchBody extends StatelessWidget {
  const SearchBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SubheadingText('Inventory Summary'),
        TextBox(
          onChanged: (value) => context.read<SearchCubit>().updateQuery(value),
        ),
        Spacing.v8,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (result, score) in context.watch<SearchCubit>().state.results.products)
              Text(
                (result.name, score).toString(),
                style: FluentTheme.of(context).typography.body,
              ),
          ],
        ),
      ].withSpacing(() => Spacing.v8),
    );
  }
}
