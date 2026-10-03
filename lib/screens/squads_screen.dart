import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';
import '../widgets/responsive_page.dart';

class SquadsScreen extends StatelessWidget {
  const SquadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الفرق')),
      body: const ResponsivePage(
        child: EmptyState(
          icon: Icons.groups_rounded,
          title: 'الفرق قريبًا',
          subtitle:
              'يمكنك قريبًا استعراض فرق الكشافة التاسعة، أفرادها، برامجها وأنشطتها.',
        ),
      ),
    );
  }
}