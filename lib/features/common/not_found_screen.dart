import 'package:flutter/material.dart';

class NotFoundScreen extends StatelessWidget {
  final String error;
  const NotFoundScreen({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(error));
  }
}
