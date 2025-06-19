import 'package:fluent_ui/fluent_ui.dart';

class Badges extends StatelessWidget {
  factory Badges.bad(String text) {
    return Badges(
      color: Colors.errorPrimaryColor,
      text: text,
    );
  }
  factory Badges.good(String text) {
    return Badges(
      color: Colors.successPrimaryColor,
      text: text,
    );
  }
  factory Badges.warn(String text) {
    return Badges(
      color: Colors.yellow.dark,
      text: text,
    );
  }
  factory Badges.dull(String text) {
    return Badges(
      color: Colors.grey[40],
      text: text,
    );
  }
  const Badges({
    super.key,
    required this.color,
    this.text,
  });

  final Color color;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Container(
            width: 8.0,
            height: 8.0,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8.0),
          Text(
            text ?? '',
            style: const TextStyle(fontSize: 10.0),
          ),
        ],
      ),
    );
  }
}
