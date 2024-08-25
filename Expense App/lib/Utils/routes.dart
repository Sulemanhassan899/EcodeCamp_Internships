
// We use name route
// All our routes will be available here

import 'package:flutter/cupertino.dart';
import '../Screens/AddExpense.dart';
import '../Screens/HomeScreen.dart';

final Map<String, WidgetBuilder> routes = {

  HomeScreen.routeName: (context) =>  HomeScreen(),
  AddExpenseScreen.routeName: (context) =>  AddExpenseScreen(tableName: '',),

};
