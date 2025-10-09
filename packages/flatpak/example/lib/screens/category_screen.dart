import 'package:flutter/material.dart';

class CategoryScreen extends StatefulWidget{
  const CategoryScreen({
    super.key,
    required this.category,
  });

  final String category;
  @override
  State<StatefulWidget> createState() =>_categoryscreenstate();
}

class _categoryscreenstate extends State<CategoryScreen>{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),

        scrolledUnderElevation: 0.0,
      ),
    );
  }
}

