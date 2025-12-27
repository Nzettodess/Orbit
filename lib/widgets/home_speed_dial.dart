import 'package:flutter/material.dart';

class HomeSpeedDial extends StatefulWidget {
  final VoidCallback onAddEvent;
  final VoidCallback onAddLocation;

  const HomeSpeedDial({
    super.key,
    required this.onAddEvent,
    required this.onAddLocation,
  });

  @override
  State<HomeSpeedDial> createState() => _HomeSpeedDialState();
}

class _HomeSpeedDialState extends State<HomeSpeedDial> {
  bool _speedDialOpen = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _speedDialOpen ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Expanded options (visible when open)
          if (_speedDialOpen) ...[
            _buildSpeedDialOption(
              icon: Icons.event,
              label: 'Add Event',
              onTap: () {
                setState(() => _speedDialOpen = false);
                widget.onAddEvent();
              },
            ),
            const SizedBox(height: 12),
            _buildSpeedDialOption(
              icon: Icons.add_location,
              label: 'Add Location',
              onTap: () {
                setState(() => _speedDialOpen = false);
                widget.onAddLocation();
              },
            ),
            const SizedBox(height: 12),
          ],
          // Main FAB
          FloatingActionButton(
            heroTag: "speedDial",
            onPressed: () => setState(() => _speedDialOpen = !_speedDialOpen),
            child: AnimatedRotation(
              turns: _speedDialOpen ? 0.125 : 0, // 45 degree rotation
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _speedDialOpen ? Icons.close : Icons.add,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDialOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          heroTag: label,
          onPressed: onTap,
          child: Icon(icon, color: Colors.black, size: 20),
        ),
      ],
    );
  }
}
