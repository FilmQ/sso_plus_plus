import 'package:flutter/material.dart';

/// The round avatar of a consultant (U3-2, U5-1) with two letters.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar(this.name, {super.key});

  final String name;

  /// The first letter of the first name and of the last name. The SQL gives
  /// the title first ("นพ. ธนา ศรีสุข"), so the last two words are used.
  static String initials(String name) {
    final List<String> words = name.split(' ').where((String w) => w.isNotEmpty).toList();
    return words.skip(words.length > 2 ? words.length - 2 : 0).map((String w) => w[0]).join();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      backgroundColor: colors.primaryContainer,
      child: Text(initials(name), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colors.onPrimaryContainer)),
    );
  }
}
