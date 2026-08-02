import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/kai_event.dart';
import 'events_view_model.dart';

class EatButton extends StatefulWidget {
  const EatButton({super.key, required this.event, this.onEat});

  final KaiEvent event;
  final ValueChanged<KaiEvent>? onEat;

  @override
  State<EatButton> createState() => _EatButtonState();
}

class _EatButtonState extends State<EatButton> {
  bool _isEating = false;

  Future<void> _eat() async {
    if (!widget.event.isActive || _isEating) {
      return;
    }

    setState(() {
      _isEating = true;
    });

    try {
      final updatedEvent = await context.read<EventsViewModel>().eatPortion(widget.event.id);
      widget.onEat?.call(updatedEvent);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not eat a portion.')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isEating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.event.isActive && !_isEating ? _eat : null,
      icon: _isEating
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.restaurant),
      tooltip: widget.event.isActive ? 'Eat a portion' : 'No portions left',
    );
  }
}
