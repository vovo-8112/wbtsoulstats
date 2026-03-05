import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SoulControls extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool loading;
  final VoidCallback onLoadPressed;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback onExplorerPressed;
  final VoidCallback onClaimPressed;
  final VoidCallback onAddCalendarPressed;
  final VoidCallback onAddToWatchlistPressed;

  const SoulControls({
    super.key,
    required this.controller,
    this.focusNode,
    required this.loading,
    required this.onLoadPressed,
    this.onSubmitted,
    required this.onExplorerPressed,
    required this.onClaimPressed,
    required this.onAddCalendarPressed,
    required this.onAddToWatchlistPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Track Soul',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            onSubmitted: onSubmitted,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
            decoration: const InputDecoration(
              labelText: 'Soul ID',
              hintText: 'Enter your Soul ID',
              prefixIcon: Icon(Icons.tag_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: AppColors.textButton,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: loading ? null : onLoadPressed,
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: AppColors.textButton,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt_rounded, size: 16),
                      SizedBox(width: 8),
                      Text('Load Soul Data'),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAddToWatchlistPressed,
                  icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                  label: const Text('Add to Watchlist'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Explorer',
                  icon: Icons.account_tree_outlined,
                  onPressed: onExplorerPressed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'Claim',
                  icon: Icons.payments_outlined,
                  onPressed: onClaimPressed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'Calendar',
                  icon: Icons.event_available_outlined,
                  onPressed: onAddCalendarPressed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
