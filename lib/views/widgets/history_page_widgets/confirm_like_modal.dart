import 'package:flutter/material.dart';

class ConfirmLikeModal extends StatelessWidget {
  final bool isUnlike;

  const ConfirmLikeModal({super.key, this.isUnlike = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).pop(false);
      },
      child: Center(
        child: GestureDetector(
          onTap: () {}, // Prevent tap propagation to dismiss
          child: Container(
            width: 264,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 24,
              horizontal: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUnlike ? Icons.favorite_border : Icons.favorite,
                  color: const Color(0xFF56C92E),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    isUnlike ? 'Remove from Favorites?' : 'Add to Favorites?',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    isUnlike
                        ? 'This capsule will be removed from your favorites.'
                        : 'This capsule will appear in your favorites.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 180,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF56C92E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(true); // Confirm
                    },
                    child: Text(
                      isUnlike ? 'Remove' : 'Add',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: 180,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(false); // Cancel
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color.fromARGB(255, 95, 95, 95),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}