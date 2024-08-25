import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import '../Utils/constants.dart';


class CustomAppBar2 extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuClicked;
  final String title;

  const CustomAppBar2({
    Key? key,
    required this.onMenuClicked,
    this.title = ' ',
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(60);


  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: SvgPicture.asset(
          Menu,
          height: 22,
          width: 20,
        ),
        onPressed: () {
          HapticFeedback.mediumImpact();
          onMenuClicked();
        },
      ),
      title: Text(
        title,
        style: H1BlackBold,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: () {
            HapticFeedback.mediumImpact();
          },
        ),
      ],
    );
  }
}



