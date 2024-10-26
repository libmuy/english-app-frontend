import 'package:flutter/material.dart';
import 'package:libmuyenglish/providers/learning_provider.dart';
import '../domain/entities.dart';
import '../providers/service_locator.dart';
import 'package:simple_logging/simple_logging.dart';
import '../utils/utils.dart';

typedef OnFavoriteListSelect = void Function(FavoriteList);

final _log = Logger('FavoriteListSelectionSheet', level: LogLevel.debug);

class FavoriteListSelectionSheet extends StatefulWidget {
  final OnFavoriteListSelect onSelect;
  final List<FavoriteList> favoriteLists;
  const FavoriteListSelectionSheet({
    super.key,
    required this.onSelect,
    required this.favoriteLists,
  });

  @override
  createState() => _FavoriteListSelectionSheetState();
}

class _FavoriteListSelectionSheetState
    extends State<FavoriteListSelectionSheet> {
  final _learningProvider = getIt<LearningProvider>();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    Widget title;
    if (_errorMessage != null) {
      title = Text(
        _errorMessage!,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    } else {
      title = Text(
        'Select Favorite List',
        style: Theme.of(context).textTheme.titleLarge,
      );
    }

    return SizedBox(
      height: 400, // Adjust as needed
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(15.0),
            ),
            child: Container(
              color: Theme.of(context).primaryColor,
              padding: const EdgeInsets.all(16.0),
              child: title,
            ),
          ),
          Expanded(
            child: widget.favoriteLists.isEmpty
                ? const Center(child: Text('No favorite lists found.'))
                : ListView.builder(
                    itemCount: widget.favoriteLists.length,
                    itemBuilder: (context, index) {
                      final list = widget.favoriteLists[index];
                      return ListTile(
                        title: Text(list.name),
                        subtitle: Text('${list.sentenceCount} sentences'),
                        onTap: () => widget.onSelect(list),
                      );
                    },
                  ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Create New Favorite List'),
            onTap: _createFavoriteList,
          ),
        ],
      ),
    );
  }

  void _removeErrorMessage() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _createFavoriteList() async {
    final formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Favorite List'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'List Name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                if (value.trim().length < 3) {
                  return 'Name must be at least 3 characters';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                _removeErrorMessage();
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Create'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final name = nameController.text.trim();
                    if (widget.favoriteLists
                            .indexWhere((f) => f.name == name) >=
                        0) {
                      Navigator.of(context).pop();
                      setState(() {
                        _errorMessage = 'Favorite name already exists';
                      });
                      return;
                    }
                    final newListId =
                        await _learningProvider.addFavoriteList(name);
                    Navigator.of(context).pop();
                    setState(() {
                      widget.favoriteLists.add(FavoriteList(
                          id: newListId, name: name, sentenceCount: 0));
                      _errorMessage = null;
                    });
                  } catch (error) {
                    _log.error('Error creating favorite list: $error');
                    showSnackBar(context, 'Failed to create favorite list.');
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
