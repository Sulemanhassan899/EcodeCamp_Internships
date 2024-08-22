// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';


Color DarkBlueTextColor = Color(0xFF222939);
Color Orange = Color(0xffffb56b);
Color White = Color(0xffffffff);



final LinearGradient BackgroundColor = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment(0.8, 1),
  colors: <Color>[
    Color.fromARGB(255, 255, 33, 204),
    Color.fromARGB(255, 144, 46, 238),
    Color.fromARGB(255, 39, 43, 220),
    Color(0xff8425f8),
    Color(0xfff422c4),
  ],
  tileMode: TileMode.mirror,
);


const SizedBoxHeight = SizedBox(
  height: 25,
);


//Font 14

TextStyle H1NormalBlack = TextStyle(
    fontSize: 14,
    fontFamily: 'Poppins',
    color: DarkBlueTextColor,
    letterSpacing: 2);

//Font 16


TextStyle WhiteNormalText = TextStyle(
    color: White,
    fontFamily: 'Poppins',
    fontSize: 16);


//Font 24

TextStyle WhiteBoldText = TextStyle(
    fontSize: 24,
    fontFamily: 'Poppins',
    color: White,
    fontWeight: FontWeight.bold);


//Font 42

TextStyle LargeWhiteBoldText = TextStyle(
    fontSize: 42,
    fontFamily: 'Poppins',
    color: White,
    fontWeight: FontWeight.bold);
