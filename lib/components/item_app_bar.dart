import 'package:flutter/material.dart';

class ItemAppBar extends StatelessWidget {
  const ItemAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        color: const Color.fromARGB(255, 0, 76, 135),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 30,
              )),
          // const Spacer(),
          // IconButton(
          //     onPressed: () {},
          //     icon: const Icon(
          //       Icons.notifications_none_outlined,
          //       color: Colors.white,
          //       size: 30,
          //     ))
        ]));
  }
}
