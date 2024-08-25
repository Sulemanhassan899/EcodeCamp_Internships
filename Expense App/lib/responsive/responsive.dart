import 'package:flutter/material.dart';

class Responsive {
  static late double _screenWidth;
  static late double _screenHeight;
  static late double _blockWidth;
  static late double _blockHeight;

  static late MediaQueryData _mediaQueryData;
  static late Orientation _orientation;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    _orientation = _mediaQueryData.orientation;

    _screenWidth = _mediaQueryData.size.width;
    _screenHeight = _mediaQueryData.size.height;

    _blockWidth = _screenWidth / 100;
    _blockHeight = _screenHeight / 100;
  }

  // Get the device width
  static double get screenWidth => _screenWidth;

  // Get the device height
  static double get screenHeight => _screenHeight;

  // Get the block width (1% of the screen width)
  static double get blockWidth => _blockWidth;

  // Get the block height (1% of the screen height)
  static double get blockHeight => _blockHeight;

  // Method to get the responsive height
  static double height(double height) {
    return _blockHeight * height;
  }

  // Method to get the responsive width
  static double width(double width) {
    return _blockWidth * width;
  }
}
