import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:easthardware_pms/presentation/router/app_router.dart';
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

abstract interface class PdfGenerator {
  String get fileName;

  /// Generates a PDF document with the given [format].
  Future<Uint8List> generatePdf(PdfPageFormat? format);
}

class PdfGenerationState with ChangeNotifier {
  OverlayEntry? _overlayEntry;
  OverlayEntry? get overlayEntry => _overlayEntry;
  set overlayEntry(OverlayEntry? entry) {
    if (_overlayEntry != entry) {
      if (_overlayEntry != null && entry == null) {
        _overlayEntry?.remove();
      }

      _overlayEntry = entry;

      notifyListeners();
    }
  }

  String? _fileName;
  String? get fileName => _fileName;
  set fileName(String? name) {
    if (_fileName != name) {
      _fileName = name;
      notifyListeners();
    }
  }

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

void showPdfOverlay({required Widget Function(BuildContext, OverlayEntry) builder}) {
  late final OverlayEntry entry;
  entry = OverlayEntry(builder: (c) => builder(c, entry));

  Overlay.of(overlayWidgetKey.currentContext!).insert(entry);
}

/// This PDF generation
class PdfOverlay extends StatelessWidget {
  const PdfOverlay({required this.overlayEntry, required this.generatorCreator, super.key});

  final OverlayEntry overlayEntry;
  final PdfGenerator Function() generatorCreator;

  @override
  Widget build(BuildContext context) {
    return Provider<PdfGenerator>(
      create: (_) => generatorCreator(),
      child: Builder(builder: (context) {
        return ChangeNotifierProvider(
          lazy: false,
          create: (_) => PdfGenerationState()
            ..fileName = context.read<PdfGenerator>().fileName
            ..overlayEntry = overlayEntry,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Provider.value(
                value: constraints,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () {
                          context.read<PdfGenerationState>().overlayEntry = null;
                        },
                        child: ColoredBox(color: Colors.black.withOpacity(0.2)),
                      ),
                    ),
                    const Positioned.fill(child: Center(child: _PdfOverlayBody())),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class _PdfOverlayBody extends StatelessWidget {
  const _PdfOverlayBody();

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
              GrayText('To print the report, click the print icon below.'),
              GrayText('To zoom and drag, double click the preview. '
                  'To move to different pages, double click again.')
            ],
          ),
          Spacing.h12,
          Center(
            child: SizedBox(
              width: 36.0,
              height: 36.0,
              child: Button(
                style: const ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.zero),
                ),
                onPressed: () {
                  context.read<PdfGenerationState>().overlayEntry = null;
                },
                child: const Icon(FluentIcons.cancel, size: 12.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final pageFormats = [
  (PdfPageFormat.a3, "A3", '11.69" x 16.54"'),
  (PdfPageFormat.a4, "A4", '8.27" x 11.69"'),
  (PdfPageFormat.a5, "A5", '5.83" x 8.27"'),
  (PdfPageFormat.a6, "A6", '4.13" x 5.83"'),
  (PdfPageFormat.letter, "Short Bond", '8.5" x 11"'),
  (PdfPageFormat(8.5.inch, 13.inch, marginAll: 1.inch), "Long Bond", '8.5" x 13"'),
  (PdfPageFormat.legal, "Legal", '8.5" x 14"'),
];

class _MenuChoices extends StatelessWidget {
  const _MenuChoices();

  @override
  Widget build(BuildContext context) {
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
                    await _saveReport(context);
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
                    onLayout: (format) => context.read<PdfGenerator>().generatePdf(format),
                    name: context.read<PdfGenerator>().fileName,
                  );

                  if (!context.mounted) return;
                  if (didPrint) {
                    context.read<PdfGenerationState>().overlayEntry = null;
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

    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey, width: 1.0)),
      constraints: BoxConstraints(
        maxHeight: 480,
        minHeight: min(constraints.maxHeight, 480),
        maxWidth: 600,
        minWidth: min(constraints.maxWidth, 600),
      ),
      child: PdfPreview(
        key: ValueKey(generationState.toRecord()),
        build: (_) async {
          final generator = context.read<PdfGenerator>();

          return await generator.generatePdf(generationState.pageFormat);
        },
        useActions: false,
      ),
    );
  }
}

Future<void> _saveReport(BuildContext context) async {
  try {
    final pageFormat = context.read<PdfGenerationState>().pageFormat;
    final generator = context.read<PdfGenerator>();
    final pdf = await generator.generatePdf(pageFormat);
    final defaultFileName = generator.fileName;

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
  }
}

extension on num {
  double get inch => this * PdfPageFormat.inch;
  double get cm => this * PdfPageFormat.cm;
}
