
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'Screens/HomeScreen.dart';
import 'Utils/routes.dart';

void main()  {
  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      initialRoute: HomeScreen.routeName,
      routes: routes,
    );
  }
}

