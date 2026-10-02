import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/material.dart';

/// The page a CF node's card opens.
///
/// A placeholder until the detail task fills it: the name in the bar, the id
/// it will fetch with under it.
class CfDetailPage extends StatelessWidget {
  const CfDetailPage({super.key, required this.args});

  final CfDetailArgs args;

  static const route = AppRouteArg(page: CfDetailPage.new, path: '/cf/detail');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: Text(args.name)),
      body: Center(child: Text(args.id, style: UIs.text13Grey)),
    );
  }
}

/// Which node a [CfDetailPage] opens: its id on the site, and the name the
/// list already had for the bar.
final class CfDetailArgs {
  const CfDetailArgs({required this.id, required this.name});

  final String id;
  final String name;
}
