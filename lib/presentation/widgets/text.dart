import 'package:fluent_ui/fluent_ui.dart';

class HeadingText extends StatelessWidget {
  const HeadingText(
    this.data, {
    this.textAlign = TextAlign.left,
    this.overflow,
    super.key,
  });

  final String data;
  final TextAlign textAlign;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      textAlign: textAlign,
      overflow: overflow,
      style: const TextStyle(
        fontSize: 24.0,
      ),
    );
  }
}

class SubheadingText extends StatelessWidget {
  const SubheadingText(
    this.data, {
    this.textAlign = TextAlign.left,
    this.overflow,
    super.key,
  });
  final String data;
  final TextAlign textAlign;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      textAlign: textAlign,
      overflow: overflow,
      style: const TextStyle(
        fontSize: 16.0,
      ),
    );
  }
}

class DisplayText extends StatelessWidget {
  const DisplayText(
    this.data, {
    this.textAlign = TextAlign.left,
    this.overflow,
    super.key,
  });
  final String data;
  final TextAlign textAlign;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      textAlign: textAlign,
      overflow: overflow,
      style: const TextStyle(
        fontSize: 20.0,
      ),
    );
  }
}

class BodyText extends StatelessWidget {
  const BodyText(
    this.data, {
    this.textAlign = TextAlign.left,
    this.overflow,
    super.key,
  });
  final String data;
  final TextAlign textAlign;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      textAlign: textAlign,
      overflow: overflow,
      style: const TextStyle(
        fontSize: 14.0,
      ),
    );
  }
}

class StrongText extends StatelessWidget {
  const StrongText(
    this.data, {
    this.textAlign = TextAlign.left,
    this.overflow,
    super.key,
  });
  final String data;
  final TextAlign textAlign;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      textAlign: textAlign,
      overflow: overflow,
      style: const TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class GrayText extends StatelessWidget {
  const GrayText(
    this.data, {
    this.textAlign = TextAlign.left,
    this.overflow,
    super.key,
  });

  final String data;
  final TextAlign textAlign;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(data,
        textAlign: textAlign,
        overflow: overflow,
        style: TextStyle(
          fontSize: 14.0,
          color: Colors.grey[100],
        ));
  }
}

class CaptionText extends StatelessWidget {
  const CaptionText(
    this.data, {
    this.textAlign = TextAlign.left,
    this.overflow,
    super.key,
  });
  final String data;
  final TextAlign textAlign;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      textAlign: textAlign,
      overflow: overflow,
      style: const TextStyle(
        fontSize: 10.0,
      ),
    );
  }
}

class ButtonText extends StatelessWidget {
  const ButtonText(
    this.data, {
    this.textAlign = TextAlign.left,
    this.overflow,
    super.key,
  });
  final String data;
  final TextAlign textAlign;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      textAlign: textAlign,
      overflow: overflow,
      style: const TextStyle(
        fontSize: 14.0,
      ),
    );
  }
}

class ErrorText extends StatelessWidget {
  const ErrorText(
    this.data, {
    this.textAlign = TextAlign.left,
    this.overflow,
    super.key,
  });
  final String data;
  final TextAlign textAlign;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      textAlign: textAlign,
      overflow: overflow,
      style: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 14.0,
        color: Colors.errorPrimaryColor,
      ),
    );
  }
}

extension StringExtension on String {
  String toTitleCase() {
    return split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String capitalize() {
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
