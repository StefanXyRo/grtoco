import 'package:flutter/material.dart';
import 'package:grtoco/models/interactive_post.dart';
import 'package:grtoco/services/group_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PollWidget extends StatefulWidget {
  final InteractivePost poll;

  const PollWidget({Key? key, required this.poll}) : super(key: key);

  @override
  _PollWidgetState createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  late GroupService _groupService;
  String? _votedOption;
  bool _isClosed = false;
  Map<String, double> _votePercentages = {};

  @override
  void initState() {
    super.initState();
    _groupService = GroupService();
    _isClosed = widget.poll.isClosed ?? false;
    _checkIfUserVoted();
    _calculateVotePercentages();
  }

  void _checkIfUserVoted() {
    final userId = context.read<User?>()?.uid;
    if (userId == null || widget.poll.votes == null) return;

    for (var entry in widget.poll.votes!.entries) {
      if (entry.value.contains(userId)) {
        setState(() {
          _votedOption = entry.key;
        });
        break;
      }
    }
  }

  void _calculateVotePercentages() {
    if (widget.poll.votes == null) return;

    final totalVotes = widget.poll.votes!.values.fold<int>(0, (sum, list) => sum + list.length);
    if (totalVotes == 0) return;

    Map<String, double> percentages = {};
    for (var option in widget.poll.options!) {
      final voteCount = widget.poll.votes![option]?.length ?? 0;
      percentages[option] = (voteCount / totalVotes) * 100;
    }
    setState(() {
      _votePercentages = percentages;
    });
  }

  Future<void> _vote(String option) async {
    final userId = context.read<User?>()?.uid;
    if (userId == null || _votedOption != null || _isClosed) return;

    try {
      await _groupService.voteOnPoll(widget.poll.postId, option);
      setState(() {
        _votedOption = option;
        // Optimistically update the UI
        widget.poll.votes!.update(
          option,
          (list) => [...list, userId],
          ifAbsent: () => [userId],
        );
        _calculateVotePercentages();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to vote: $e')),
      );
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
              widget.poll.question ?? 'Poll',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 16),
            ...widget.poll.options!.map((option) => _buildOption(option)).toList(),
            if (_isClosed)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'Poll Closed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String option) {
    final hasVoted = _votedOption != null;
    final percentage = _votePercentages[option] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: hasVoted
          ? _buildResultBar(option, percentage)
          : ListTile(
              title: Text(option),
              leading: Radio<String>(
                value: option,
                groupValue: _votedOption,
                onChanged: (value) {
                  // This is handled by the ListTile onTap
                },
              ),
              onTap: () => _vote(option),
            ),
    );
  }

  Widget _buildResultBar(String option, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              option,
              style: TextStyle(
                fontWeight: _votedOption == option ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text('${percentage.toStringAsFixed(1)}%'),
          ],
        ),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            _votedOption == option ? Colors.blueAccent : Colors.blue,
          ),
        ),
      ],
    );
  }
}
