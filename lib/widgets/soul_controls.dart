import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SoulControls extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onLoadPressed;
  final VoidCallback onExplorerPressed;
  final VoidCallback onClaimPressed;
  final VoidCallback onAddCalendarPressed;

  const SoulControls({
    super.key,
    required this.controller,
    required this.loading,
    required this.onLoadPressed,
    required this.onExplorerPressed,
    required this.onClaimPressed,
    required this.onAddCalendarPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Soul ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: AppColors.textButton,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            onPressed: loading ? null : onLoadPressed,
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.textButton,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Load 🔍'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppColors.textButton,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                  ),
                  onPressed: onExplorerPressed,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: const Text('Explorer 📁'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppColors.textButton,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                  ),
                  onPressed: onClaimPressed,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: const Text('Claim 💸'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppColors.textButton,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                  ),
                  onPressed: onAddCalendarPressed,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: const Text('Add 📅'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
