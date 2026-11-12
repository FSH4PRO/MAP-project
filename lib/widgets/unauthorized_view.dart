import 'package:flutter/material.dart';

/// Shown by the route guard when the role lacks the route's permission.
class UnauthorizedView extends StatelessWidget {
  const UnauthorizedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('غير مصرّح')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, size: 64),
            SizedBox(height: 12),
            Text('ليست لديك صلاحية للوصول إلى هذه الصفحة'),
          ],
        ),
      ),
    );
  }
}
