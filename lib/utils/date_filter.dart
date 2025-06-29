import 'package:easthardware_pms/presentation/views/dashboard/cards/sales_overview.dart';
import 'package:easthardware_pms/utils/duration.dart';

extension DateFilterExtension on DateTime {
  bool isWithinTheDays(DateTime before, DateTime after) {
    // Check if the date is within the range, inclusive of the boundaries

    /// NOT isBefore === isOnOrAfter
    /// NOT isAfter === isOnOrBefore
    return !isBefore(before.zeroedTime()) && !isAfter(after.add(1.days).zeroedTime());
  }
}
