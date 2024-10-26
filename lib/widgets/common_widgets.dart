import 'package:flutter/material.dart';

class PlayButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final String subtitle;

  const PlayButton({super.key, required this.text, required this.onPressed, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10),
        shape: const CircleBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5.0).copyWith(top: 18),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(height: 1),
              ),
              const SizedBox(height: 5,),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  height: 1,
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                ),
              ),
            ],
          ),
      ),
    );
  }
}


class ToggleVisibilityButton extends StatelessWidget {
  final bool isVisible;
  final String visibleText;
  final String hiddenText;
  final VoidCallback onPressed;

  const ToggleVisibilityButton({super.key, 
    required this.isVisible,
    required this.visibleText,
    required this.hiddenText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Text(isVisible ? hiddenText : visibleText),
    );
  }
}

class TextContainer extends StatelessWidget {
  final String text;
  final bool isVisible;

  const TextContainer({super.key, required this.text, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: Theme.of(context).colorScheme.primary),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
