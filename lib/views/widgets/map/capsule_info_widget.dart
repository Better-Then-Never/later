import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CapsuleInfoPanel extends StatefulWidget {
  final String title;
  final String dateStamp;
  final Timestamp openAt;
  final VoidCallback onMoreInfo;

  const CapsuleInfoPanel({
    super.key,
    required this.title,
    required this.dateStamp,
    required this.openAt,
    required this.onMoreInfo,
  });

  @override
  State<CapsuleInfoPanel> createState() => _CapsuleInfoPanelState();
}

class _CapsuleInfoPanelState extends State<CapsuleInfoPanel> {
  late Timer _timer;
  late Duration _remaining;
  bool get _isOpen => DateTime.now().isAfter(widget.openAt.toDate());

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _updateRemaining());
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final target = widget.openAt.toDate();
    _remaining = target.difference(now);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return "";

    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    final parts = <String>[];

    if (days > 0) parts.add("${days}d");
    if (hours > 0 || days > 0) parts.add("${hours}h");
    if (minutes > 0 || hours > 0 || days > 0) parts.add("${minutes}m");
    parts.add("${seconds}s");

    return parts.join(" ");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Irina',
              fontSize: 25,
            ),
          ),
          Text(
            widget.dateStamp,
            style: const TextStyle(fontFamily: 'Irina', fontSize: 16),
          ),

          const Spacer(),
          if (!_isOpen) ...[
            Text(
              "Opens in ${_formatDuration(_remaining)}",
              style: const TextStyle(
                color: Colors.red,
                fontFamily: 'Irina',
                fontSize: 16,
              ),
            ),
          ] else ...[
            const Text(
              "Check out what`s inside!",
              style: TextStyle(
                color: Colors.green,
                fontFamily: 'Irina',
                fontSize: 16,
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isOpen
                      ? const Color.fromARGB(255, 86, 201, 46)
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                onPressed: _isOpen ? widget.onMoreInfo : null,
                child: Text(
                  _isOpen ? 'Open' : 'Locked',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Irina',
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
