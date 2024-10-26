import 'package:flutter/material.dart';

Widget settingItemListTile<T>(
    {required BuildContext context,
    required String title,
    required T? value,
    required List<DropdownMenuItem<T>>? items,
    required void Function(T?)? onChanged}) {
  return ListTile(
    title: settingItemTitle(context, title),
    trailing: DropdownButton<T>(
      alignment: Alignment.center,
      icon: Icon(
        Icons.arrow_drop_down,
        color: Theme.of(context).colorScheme.primary,
      ), // The expandable icon
      iconSize: 24,
      elevation: 16,
      style:
          TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 18),
      underline: Container(
        height: 2,
        color: Theme.of(context).colorScheme.primary,
      ),
      value: value,
      items: items,
      onChanged: onChanged,
    ),
  );
}

Widget settingItemTitle(BuildContext context, String text) {
  return Text(text,
      style: TextStyle(color: Theme.of(context).colorScheme.onSecondary));
}

class SettingGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const SettingGroup({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                title!,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromARGB(11, 0, 0, 0),
                  blurRadius: 20.0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
