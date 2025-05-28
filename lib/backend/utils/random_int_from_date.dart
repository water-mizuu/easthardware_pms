import 'dart:math';

int randomIntFromDate() {
  return (DateTime.now().hashCode * Random().nextDouble()).hashCode;
}
