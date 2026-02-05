import 'package:flutter/material.dart';

class RefreshButton extends StatelessWidget {
  final bool isRefreshing;
  final VoidCallback? onTap;
  final double? size;

  const RefreshButton({
    super.key,
    required this.isRefreshing,
    required this.onTap,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size ?? 40,
      height: size ?? 40,
      child: GestureDetector(
        onTap: isRefreshing ? null : onTap,
        child: Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 33, 150, 243),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}
