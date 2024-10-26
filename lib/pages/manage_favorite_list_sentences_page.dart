// File: lib/pages/manage_favorite_list_sentences_page.dart
import 'package:flutter/material.dart';
import '../domain/entities.dart';
import '../providers/service_locator.dart';
import '../providers/learning_provider.dart';
import '../utils/utils.dart';


class ManageFavoriteListSentencesPage extends StatefulWidget {
  final FavoriteList favoriteList;

  const ManageFavoriteListSentencesPage({super.key, required this.favoriteList});

  @override
  createState() => _ManageFavoriteListSentencesPageState();
}

class _ManageFavoriteListSentencesPageState extends State<ManageFavoriteListSentencesPage> {
  final LearningProvider _learningProvider = getIt<LearningProvider>();
  List<Sentence> _listSentences = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSentences();
  }

  void _loadSentences() {
    // Fetch all sentences and the sentences in the favorite list
    _learningProvider.fetchSentences(
      SentenceSource(type: SentenceSourceType.favorite,
        favoriteListId: widget.favoriteList.id,
      )
    ).then((result) {
      setState(() {
        // here will not got a part of the result.
        _listSentences = result.sentences;
      });
    }).catchError((error) {
      setState(() {
        _errorMessage = error.toString();
      });
    });
  }

  void _removeSentence(Sentence sentence) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      await _learningProvider.updateFavoriteSentence(widget.favoriteList.id, sentence, false);
      setState(() {
        _isLoading = false;
        _listSentences.removeWhere((s) => s.id == sentence.id);
      });
      showSnackBar(context, 'Sentence removed from the favorite list.');
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
      showSnackBar(context, 'Error: $_errorMessage');
    }
  }

  Widget _buildListSentences() {
    return _listSentences.isEmpty
        ? const Center(child: Text('No sentences in this favorite list.'))
        : ListView.builder(
            itemCount: _listSentences.length,
            itemBuilder: (context, index) {
              final sentence = _listSentences[index];
              return ListTile(
                title: Text(sentence.english),
                subtitle: Text(sentence.chinese),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => _removeSentence(sentence),
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage "${widget.favoriteList.name}"'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : _buildListSentences(),
    );
  }
}
