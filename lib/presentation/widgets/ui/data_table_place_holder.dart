import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:fluent_ui/fluent_ui.dart';

class DataTablePlaceHolder extends StatelessWidget {
  final IconData icon;
  final String items;
  const DataTablePlaceHolder(
    this.icon,
    this.items, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          Spacing.v16,
          Text(
            'No $items found',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    ));
  }
}
