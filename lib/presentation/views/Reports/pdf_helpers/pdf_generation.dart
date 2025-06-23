import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/inventory_report/inventory_report_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/notification.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

enum PageOrientation {
  portrait("Portrait"),
  landscape("Landscape"),
  ;

  const PageOrientation(this.name);

  final String name;
}

abstract base class PdfGenerator {
  /// Generates a PDF document with the given [format], [products], and [selectedDate].
  Future<Uint8List> generatePdf(
    PdfPageFormat? format,
    List<Product> products,
    DateTime selectedDate,
  );
}

class PdfGenerationState with ChangeNotifier {
  PageOrientation _orientation = PageOrientation.portrait;
  PageOrientation get orientation => _orientation;
  set orientation(PageOrientation orientation) {
    if (_orientation != orientation) {
      _orientation = orientation;
      _pageFormat = switch (orientation) {
        PageOrientation.portrait => _pageFormat.portrait,
        PageOrientation.landscape => _pageFormat.landscape,
      };
      notifyListeners();
    }
  }

  PdfPageFormat _pageFormat = PdfPageFormat.letter;
  PdfPageFormat get pageFormat => _pageFormat;
  set pageFormat(PdfPageFormat format) {
    if (_pageFormat != format) {
      _pageFormat = switch (orientation) {
        PageOrientation.portrait => format.portrait,
        PageOrientation.landscape => format.landscape,
      };
      notifyListeners();
    }
  }

  Record toRecord() {
    return (
      orientation: _orientation,
      pageFormat: _pageFormat,
    );
  }
}

class InventoryReportOverlay extends StatelessWidget {
  const InventoryReportOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PdfGenerationState(),
      child: LayoutBuilder(
        builder: (_, constraints) {
          return Provider.value(
            value: constraints,
            child: ColoredBox(
              color: Colors.black.withOpacity(0.2),
              child: const Center(child: _InventoryReportOverlayBody()),
            ),
          );
        },
      ),
    );
  }
}

class _InventoryReportOverlayBody extends StatelessWidget {
  const _InventoryReportOverlayBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppPadding.panePadding,
      decoration: BoxDecoration(
        color: FluentTheme.of(context).cardColor,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: const IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(),
            Spacing.v12,
            IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PdfPreview(),
                  Spacing.h16,
                  _MenuChoices(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DisplayText('Print or Save PDF'),
              Spacing.v4,
              GrayText('To print the report, click the print icon below.')
            ],
          ),
          AspectRatio(
            aspectRatio: 1.0,
            child: Button(
              child: const Icon(FluentIcons.cancel),
              onPressed: () {
                context.read<InventoryReportBloc>().add(const InventoryReportRemoveOverlayEvent());
              },
            ),
          ),
        ],
      ),
    );
  }
}

const pageFormats = [
  (PdfPageFormat.a3, "A3", '11.69" x 16.54"'),
  (PdfPageFormat.a4, "A4", '8.27" x 11.69"'),
  (PdfPageFormat.a5, "A5", '5.83" x 8.27"'),
  (PdfPageFormat.a6, "A6", '4.13" x 5.83"'),
  (PdfPageFormat.letter, "Short Bond", '8.5" x 11"'),
  (
    PdfPageFormat(
      8.5 * PdfPageFormat.inch,
      13 * PdfPageFormat.inch,
      marginAll: PdfPageFormat.inch,
    ),
    "Long Bond",
    '8.5" x 13"',
  ),
  (PdfPageFormat.legal, "Legal", '8.5" x 14"'),
];

class _MenuChoices extends StatelessWidget {
  const _MenuChoices();

  @override
  Widget build(BuildContext context) {
    final reportState = context.watch<InventoryReportBloc>().state;
    final products = context.watch<InventoryReportBloc>().state.queryData.filteredProducts ??
        context.read<ProductListBloc>().state.allProducts;

    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SelectedLayout(),
          const _SelectedOrientation(),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  'Save as PDF',
                  onPressed: () async {
                    await _saveReport(context, context.read<InventoryReportBloc>(), products);
                  },
                ),
              ),
              Spacing.h8,
              TextButtonFilled(
                'Print',
                onPressed: () async {
                  // Show print preview
                  final didPrint = await Printing.layoutPdf(
                    format: context.read<PdfGenerationState>().pageFormat,
                    onLayout: (format) => context.read<PdfGenerator>().generatePdf(
                          format,
                          products,
                          reportState.effectiveSelectedDate,
                        ),
                    name: 'Inventory_Report_${reportState.effectiveSelectedDate.day}-'
                        '${reportState.effectiveSelectedDate.month}-'
                        '${reportState.effectiveSelectedDate.year}.pdf',
                  );

                  if (!context.mounted) return;
                  if (didPrint) {
                    context
                        .read<InventoryReportBloc>()
                        .add(const InventoryReportRemoveOverlayEvent());
                  }
                },
              ),
            ],
          ),
        ].withSpacing(() => Spacing.v12),
      ),
    );
  }
}

class _SelectedLayout extends StatelessWidget {
  const _SelectedLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("Page Size: "),
        Spacing.v8,
        ComboBox(
          isExpanded: true,
          value: context.select((PdfGenerationState s) => s.pageFormat).portrait,
          onChanged: (format) {
            if (format != null) {
              context.read<PdfGenerationState>().pageFormat = format;
            }
          },
          items: [
            for (final (format, name, dimensions) in pageFormats)
              ComboBoxItem(
                value: format.portrait,
                child: Text("$name - $dimensions"),
              ),
          ],
        ),
      ],
    );
  }
}

class _SelectedOrientation extends StatelessWidget {
  const _SelectedOrientation();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("Orientation: "),
        Spacing.v8,
        ComboBox(
          isExpanded: true,
          value: context.select((PdfGenerationState s) => s.orientation),
          onChanged: (format) {
            if (format != null) {
              context.read<PdfGenerationState>().orientation = format;
            }
          },
          items: [
            for (final value in PageOrientation.values)
              ComboBoxItem(
                value: value,
                child: Text(value.name),
              ),
          ],
        ),
      ],
    );
  }
}

class _PdfPreview extends StatelessWidget {
  const _PdfPreview();

  @override
  Widget build(BuildContext context) {
    final constraints = context.watch<BoxConstraints>();
    final generationState = context.watch<PdfGenerationState>();
    final reportState = context.watch<InventoryReportBloc>().state;
    final products = context.watch<InventoryReportBloc>().state.queryData.filteredProducts ??
        context.read<ProductListBloc>().state.allProducts;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 480,
        minHeight: min(constraints.maxHeight, 480),
        maxWidth: 360,
        minWidth: min(constraints.maxWidth, 360),
      ),
      child: PdfPreview(
        key: ValueKey(generationState.toRecord()),
        build: (_) async {
          final generator = context.read<PdfGenerator>();

          return await generator.generatePdf(
            generationState.pageFormat,
            products,
            reportState.effectiveSelectedDate,
          );
        },
        useActions: false,
      ),
    );
  }
}

Future<void> _saveReport(
  BuildContext context,
  InventoryReportBloc bloc,
  List<Product> products,
) async {
  bloc.add(const InventoryReportSetGeneratingEvent(true));

  try {
    final dateTime = bloc.state.effectiveSelectedDate;
    final generator = context.read<PdfGenerator>();
    final pdf = await generator.generatePdf(PdfPageFormat.letter, products, dateTime);
    final defaultFileName = 'Inventory_Report_${dateTime.day}-' //
        '${dateTime.month}-'
        '${dateTime.year}.pdf';

    // Show native file picker dialog to choose save location
    final outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Inventory Report',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (outputFile != null) {
      // User selected a location, save the file
      final file = File(outputFile);
      await file.writeAsBytes(pdf);

      if (context.mounted) {
        showNotification.success(
          title: 'Success',
          message: 'PDF saved successfully to: $outputFile',
        );
      }
    } else {
      // User cancelled the dialog
    }
  } catch (e) {
    if (context.mounted) {
      showNotification.error(
        title: 'Error',
        message: 'Failed to save report: $e',
      );
    }
  } finally {
    bloc.add(const InventoryReportSetGeneratingEvent(false));
  }
}
