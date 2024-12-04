import 'package:flutter/material.dart';
import 'package:roadway/component/file.dart';

class Entity extends StatefulWidget {
  const Entity(
      {super.key,
      required this.item,
      required this.onTap,
      required this.widthUnits,
      required this.heightUnits});

  final Map<String, dynamic> item;
  final Function() onTap;
  final int widthUnits;
  final int heightUnits;

  @override
  State<Entity> createState() => _EntityState();
}

class _EntityState extends State<Entity> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.widthUnits * 48,
        height: widget.heightUnits * 48,
        child: FileCard(item: widget.item),
      ),
    );
  }
}
