import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SoulControls extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onLoadPressed;
  final VoidCallback onExplorerPressed;
  final VoidCallback onClaimPressed;
  final VoidCallback onAddCalendarPressed;
  final VoidCallback onAddToWatchlistPressed;

  const SoulControls({
    super.key,
    required this.controller,
    required this.loading,
    required this.onLoadPressed,
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
            keyboardType: TextInputType.number,
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
                      Icon(Icons.download_for_offline_rounded, size: 16),
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionButton(
                label: 'Explorer',
                icon: Icons.account_tree_outlined,
                onPressed: onExplorerPressed,
              ),
              _ActionButton(
                label: 'Claim',
                icon: Icons.payments_outlined,
                onPressed: onClaimPressed,
              ),
              _ActionButton(
                label: 'Calendar',
                icon: Icons.event_available_outlined,
                onPressed: onAddCalendarPressed,
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
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}
