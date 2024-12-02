import 'package:flutter/material.dart';

class Entity extends StatefulWidget {
  const Entity({super.key, required this.item, required this.onTap});

  final Map<String, dynamic> item;
  final Function() onTap;

  @override
  State<Entity> createState() => _EntityState();
}

class _EntityState extends State<Entity> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SizedBox(
          width: 384,
          height: 192,
          child: Text(widget.item['value']),
        ),
      ),
    );
  }
}