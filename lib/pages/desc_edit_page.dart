import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:libmuyenglish/providers/learning_provider.dart';

import '../providers/service_locator.dart';

class DescEditPage extends StatefulWidget {
  const DescEditPage({super.key, required this.sentenceId, required this.styleSheet});
  final int sentenceId;
  final MarkdownStyleSheet styleSheet;

  @override
  createState() => _DescEditPageState();
}

class _DescEditPageState extends State<DescEditPage> {
  final TextEditingController _controller = TextEditingController();
  String _markdownData = '';

  void _updateMarkdown() {
    setState(() {
      _markdownData = _controller.text;
    });
  }
  void _uploadMarkdown() {
    final learningProvider = getIt<LearningProvider>();
    learningProvider.updateSentenceDescription(widget.sentenceId, _controller.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Sentence Description'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: 'Enter markdown content here',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _updateMarkdown,
                  child: Text('Preview'),
                ),
                ElevatedButton(
                  onPressed: _uploadMarkdown,
                  child: Text('Submit'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Markdown(
                  styleSheet: widget.styleSheet,
                  data: _markdownData,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}