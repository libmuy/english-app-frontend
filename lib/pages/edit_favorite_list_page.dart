// File: lib/pages/edit_favorite_list_page.dart
import 'package:flutter/material.dart';
import '../domain/entities.dart';
import '../providers/service_locator.dart';
import '../providers/learning_provider.dart';
import '../utils/utils.dart';
import 'manage_favorite_list_sentences_page.dart'; // Import the manage sentences page


class EditFavoriteListPage extends StatefulWidget {
  const EditFavoriteListPage({super.key});

  @override
  createState() => _EditFavoriteListPageState();
}

class _EditFavoriteListPageState extends State<EditFavoriteListPage> {
  final LearningProvider _learningProvider = getIt<LearningProvider>();
  late Future<List<FavoriteList>> _favoriteListsFuture;
  List<FavoriteList> _favoriteLists = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _favoriteListsFuture = _learningProvider.fetchFavoriteLists();
  }

  void _refreshFavoriteLists() {
    setState(() {
      _favoriteListsFuture = _learningProvider.fetchFavoriteLists();
    });
  }

  void _showCreateFavoriteListDialog() {
    final formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Favorite List'),
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
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Create'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    await _learningProvider.addFavoriteList(nameController.text.trim());
                    setState(() {
                      _isLoading = false;
                    });
                    Navigator.of(context).pop();
                    _refreshFavoriteLists();
                    showSnackBar(context, 'Favorite list created successfully');
                  } catch (error) {
                    setState(() {
                      _isLoading = false;
                      _errorMessage = error.toString();
                    });
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditFavoriteListDialog(FavoriteList list) {
    final formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController(text: list.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Favorite List'),
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
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Update'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    await _learningProvider.updateFavoriteList(list.id, nameController.text.trim());
                    setState(() {
                      _isLoading = false;
                    });
                    Navigator.of(context).pop();
                    _refreshFavoriteLists();
                    showSnackBar(context, 'Favorite list updated successfully');
                  } catch (error) {
                    setState(() {
                      _isLoading = false;
                      _errorMessage = error.toString();
                    });
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteFavoriteList(FavoriteList list) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Favorite List'),
          content: Text('Are you sure you want to delete "${list.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Set delete button color to red
              ),
              onPressed: () async {
                try {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  await _learningProvider.deleteFavoriteList(list.id);
                  setState(() {
                    _isLoading = false;
                  });
                  Navigator.of(context).pop();
                  _refreshFavoriteLists();
                  showSnackBar(context, 'Favorite list deleted successfully');
                } catch (error) {
                  setState(() {
                    _isLoading = false;
                    _errorMessage = error.toString();
                  });
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToManageSentences(FavoriteList list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageFavoriteListSentencesPage(favoriteList: list),
      ),
    ).then((_) {
      _refreshFavoriteLists();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Favorite Lists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateFavoriteListDialog,
            tooltip: 'Create New Favorite List',
          ),
        ],
      ),
      body: FutureBuilder<List<FavoriteList>>(
        future: _favoriteListsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No favorite lists found.'));
          }

          _favoriteLists = snapshot.data!;

          return ListView.builder(
            itemCount: _favoriteLists.length,
            itemBuilder: (context, index) {
              final list = _favoriteLists[index];
              return ListTile(
                title: Text(list.name),
                subtitle: Text('${list.sentenceCount} sentences'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit List',
                      onPressed: () => _showEditFavoriteListDialog(list),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete List',
                      onPressed: () => _confirmDeleteFavoriteList(list),
                      color: Colors.red,
                    ),
                  ],
                ),
                onTap: () => _navigateToManageSentences(list),
              );
            },
          );
        },
      ),
    );
  }
}
