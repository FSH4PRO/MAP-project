import 'package:flutter/material.dart';

enum LoadStatus { idle, loading, empty, error, success }

class StatusView extends StatelessWidget {
  const StatusView({
    super.key,
    required this.status,
    required this.child,
    this.emptyMessage = 'لا توجد بيانات',
    this.errorMessage,
    this.retryText = 'إعادة المحاولة',
    this.onRetry,
  });

  final LoadStatus status;
  final Widget child;
  final String emptyMessage;
  final String? errorMessage;
  final String retryText;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    switch (status) {
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadStatus.empty:
        return Center(child: Text(emptyMessage));
      case LoadStatus.error:
        final message = errorMessage ?? 'حدث خطأ';
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, style: TextStyle(color: scheme.error)),
                if (onRetry != null) ...[
                  const SizedBox(height: 12),
                  FilledButton(onPressed: onRetry, child: Text(retryText)),
                ],
              ],
            ),
          ),
        );
      case LoadStatus.idle:
      case LoadStatus.success:
        return child;
    }
  }
}
