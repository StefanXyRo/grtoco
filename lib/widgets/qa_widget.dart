import 'package:flutter/material.dart';
import 'package:grtoco/models/interactive_post.dart';
import 'package:grtoco/services/group_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class QaWidget extends StatefulWidget {
  final InteractivePost qaPost;

  const QaWidget({Key? key, required this.qaPost}) : super(key: key);

  @override
  _QaWidgetState createState() => _QaWidgetState();
}

class _QaWidgetState extends State<QaWidget> {
  late GroupService _groupService;
  final _answerController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _groupService = GroupService();
  }

  Future<void> _submitAnswer() async {
    final userId = context.read<User?>()?.uid;
    if (userId == null || _answerController.text.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _groupService.answerQuestion(
        widget.qaPost.postId,
        _answerController.text,
      );
      _answerController.clear();
      // The UI will update via the stream in the parent widget,
      // so we don't need to optimistically update here.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit answer: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Q&A: ${widget.qaPost.question ?? ''}',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 16),
            _buildAnswerInput(),
            SizedBox(height: 16),
            Text(
              'Answers',
              style: Theme.of(context).textTheme.subtitle1,
            ),
            SizedBox(height: 8),
            _buildAnswersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _answerController,
            decoration: InputDecoration(
              hintText: 'Type your answer...',
              border: OutlineInputBorder(),
            ),
            minLines: 1,
            maxLines: 3,
          ),
        ),
        SizedBox(width: 8),
        _isSubmitting
            ? CircularProgressIndicator()
            : IconButton(
                icon: Icon(Icons.send),
                onPressed: _submitAnswer,
              ),
      ],
    );
  }

  Widget _buildAnswersList() {
    final answers = widget.qaPost.answers ?? [];
    if (answers.isEmpty) {
      return Text('No answers yet.');
    }

    // Sort answers by timestamp, newest first
    answers.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: answers.length,
      itemBuilder: (context, index) {
        final answer = answers[index];
        final authorId = answer['authorId'];
        final answerContent = answer['answerContent'];
        final timestamp = answer['timestamp'] as DateTime;
        final formattedDate = DateFormat.yMMMd().add_jm().format(timestamp);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            title: Text(answerContent),
            subtitle: Text('Answered by $authorId on $formattedDate'),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }
}
