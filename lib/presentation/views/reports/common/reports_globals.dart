import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:fluent_ui/fluent_ui.dart';

class ReportsGlobals {
  static DateTime get defaultStartDate => DateTime(DateTime.now().year);
  static DateTime get defaultEndDate => DateTime.now();

  static Widget summaryItem(String label, String value, IconData icon) {
    return Builder(builder: (context) {
      return Column(
        children: [
          Icon(icon, size: 32),
          Spacing.v8,
          HeadingText(value),
          Text(label, style: TextStyles.caption),
        ],
      );
    });
  }
}
