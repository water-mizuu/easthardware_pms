import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:fluent_ui/fluent_ui.dart';

class StaffDashboardPanePage extends StatelessWidget {
  const StaffDashboardPanePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: AppPadding.panePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Staff Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Text('Welcome to the Staff Dashboard!'),
          SizedBox(height: 16),
          // Add more widgets here as needed
        ],
      ),
    );
  }
}
