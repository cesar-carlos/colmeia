import 'dart:math' as math;

import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:colmeia/shared/widgets/pagination/app_table_pagination_footer.dart';
import 'package:flutter/material.dart';

class AppTablePaginationFooterDemoPage extends StatefulWidget {
  const AppTablePaginationFooterDemoPage({super.key});

  @override
  State<AppTablePaginationFooterDemoPage> createState() =>
      _AppTablePaginationFooterDemoPageState();
}

class _AppTablePaginationFooterDemoPageState
    extends State<AppTablePaginationFooterDemoPage> {
  static const List<int> _pageSizeOptions = <int>[10, 20, 50, 100];
  static const int _totalItems = 1240;

  int _pageSize = 20;
  int _currentPage = 1;

  int get _totalPages => math.max(1, (_totalItems / _pageSize).ceil());

  int get _rangeStart => (_currentPage - 1) * _pageSize + 1;

  int get _rangeEnd => math.min(_currentPage * _pageSize, _totalItems);

  void _goToPage(int page) {
    setState(() {
      _currentPage = page.clamp(1, _totalPages);
    });
  }

  void _setPageSize(int size) {
    setState(() {
      _pageSize = size;
      _currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Paginacao',
          title: 'Rodape de tabela',
          subtitle:
              'Estilo corporativo: itens por pagina, resumo e numeros de '
              'pagina com destaque no container primario do tema.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Exemplo (dados fake)',
          child: AppTablePaginationFooter(
            currentPage: _currentPage,
            totalPages: _totalPages,
            pageSize: _pageSize,
            rangeStart: _rangeStart,
            rangeEnd: _rangeEnd,
            totalItems: _totalItems,
            entityLabel: 'vendas',
            pageSizeOptions: _pageSizeOptions,
            onPageSizeChanged: _setPageSize,
            onPrevious: _currentPage > 1
                ? () => _goToPage(_currentPage - 1)
                : null,
            onNext: _currentPage < _totalPages
                ? () => _goToPage(_currentPage + 1)
                : null,
            onPageSelected: _goToPage,
          ),
        ),
      ],
    );
  }
}
