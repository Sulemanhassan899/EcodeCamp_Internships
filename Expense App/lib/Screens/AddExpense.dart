// ignore_for_file: prefer_const_constructors, prefer_final_fields, avoid_print, unused_field

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:onscreen_num_keyboard/onscreen_num_keyboard.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import '../Screens/HomeScreen.dart';
import '../Utils/constants.dart';
import '../models/DatePicker.dart';

class AddExpenseScreen extends StatefulWidget {
  static const routeName = '/AddExpenseScreen';

  final String tableName;

  const AddExpenseScreen({Key? key, required this.tableName}) : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  List<Map<String, dynamic>> _expenses = [];
  final TextEditingController inputFieldController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController imageController = TextEditingController();
  String enteredDigits = '';
  File? _selectedImage;
  String? DefaultSelectedCategory;
  Database? _database;
  String? selectedCategory;
  DateTime? selectedDate;
  String selectedCategoryName = 'Select Category';
  String selectedCategoryIcon = DefaultCategory;
  String? _receiptText;
  Color inputFieldTextColor = Colors.black; // Default text color
  bool isAmountInvalid = false; // Tracks if the amount is zero
  bool _isAmountZero = false;
  ScrollController _scrollController = ScrollController();
  int _currentOffset = 0;

  @override
  void initState() {
    super.initState();
    _initDatabase();

  }


  Future<void> _initDatabase() async {
    _database = await openDatabase(
      'expenses.db',
      version: 2,
      onCreate: (db, version) {
        // Create index for faster queries
        db.execute('CREATE INDEX IF NOT EXISTS idx_date ON ${widget.tableName} (date)');
      },
      onUpgrade: (db, oldVersion, newVersion) {},
    );
  }



  Future<void> _saveExpense({DateTime? selectedDate}) async {
    if (_database == null) return;

    try {
      final double amount = inputFieldController.text.isEmpty
          ? 0
          : double.parse(inputFieldController.text);

      if (amount == 0) return; // Don't save if amount is zero

      final Map<String, dynamic> expense = {
        'imageUrl': _selectedImage?.path ?? '',
        'note': noteController.text ?? '',
        'amount': amount.toInt(), // Change this line
        'date': selectedDate != null
            ? DateFormat.yMMMd().format(selectedDate)
            : DateFormat.yMMMd().format(DateTime.now()),
        'category': selectedCategoryName == 'Select Category' ? "Miscellaneous " : selectedCategoryName,
        'categoryIcon': selectedCategoryIcon ?? '',
        'fileSize': _selectedImage?.lengthSync().toString() ?? '',
        'fileType': _selectedImage != null
            ? _selectedImage!.path.split('.').last
            : '',
      };

      String tableName = widget.tableName.contains(' ') ? '"${widget.tableName}"' : widget.tableName;
      print('Saving expense in table: $tableName');
      print('Data: $expense');

      await _database!.insert(tableName, expense, conflictAlgorithm: ConflictAlgorithm.replace);
      print('Expense saved in table "$tableName": $expense');

      resetFields();

    } catch (e) {
      print('Error saving expense: $e');
    }
  }







  final List<Map<String, String>> categories = [
    {'Name': 'Add New', 'SvgPath': 'assets/categorieslist/icon.svg'},
    {'Name': 'Groceries', 'SvgPath': 'assets/categorieslist/icon-1.svg'},
    {'Name': 'Fuel', 'SvgPath': 'assets/categorieslist/icon-2.svg'},
    {'Name': 'Food & Drinks', 'SvgPath': 'assets/categorieslist/icon-3.svg'},
    {'Name': 'Car / Bike', 'SvgPath': 'assets/categorieslist/icon-4.svg'},
    {'Name': 'Taxi', 'SvgPath': 'assets/categorieslist/icon-5.svg'},
    {'Name': 'Clothes', 'SvgPath': 'assets/categorieslist/icon-6.svg'},
    {'Name': 'Shopping', 'SvgPath': 'assets/categorieslist/icon-7.svg'},
    {'Name': 'Electricity', 'SvgPath': 'assets/categorieslist/icon-8.svg'},
    {'Name': 'Gas', 'SvgPath': 'assets/categorieslist/icon-9.svg'},
    {'Name': 'Entertainment', 'SvgPath': 'assets/categorieslist/icon-10.svg'},
    {'Name': 'Internet', 'SvgPath': 'assets/categorieslist/icon-11.svg'},
    {'Name': 'Rent', 'SvgPath': 'assets/categorieslist/icon-12.svg'},
    {'Name': 'House', 'SvgPath': 'assets/categorieslist/icon-13.svg'},
    {'Name': 'Gym', 'SvgPath': 'assets/categorieslist/icon-14.svg'},
    {'Name': 'Subscription', 'SvgPath': 'assets/categorieslist/icon-15.svg'},
    {'Name': 'Beauty', 'SvgPath': 'assets/categorieslist/icon-16.svg'},
    {'Name': 'Vacation', 'SvgPath': 'assets/categorieslist/icon-17.svg'},
    {'Name': 'Health Care', 'SvgPath': 'assets/categorieslist/icon-18.svg'},
    {'Name': 'Education', 'SvgPath': 'assets/categorieslist/icon-19.svg'},
    {'Name': 'Loan', 'SvgPath': 'assets/categorieslist/icon-20.svg'},
    {'Name': 'Pets', 'SvgPath': 'assets/categorieslist/icon-21.svg'},
    {'Name': 'Insurance', 'SvgPath': 'assets/categorieslist/icon-22.svg'},
    {'Name': 'Gifts', 'SvgPath': 'assets/categorieslist/icon-23.svg'},
    {'Name': 'Donations', 'SvgPath': 'assets/categorieslist/icon-24.svg'},
    {'Name': 'Tax', 'SvgPath': 'assets/categorieslist/icon-25.svg'},
    {'Name': 'Other', 'SvgPath': 'assets/categorieslist/icon-26.svg'},


    // Add more categories as needed
  ];


  List<String> keyboardValues = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'Done',
    '0',
    '<',
    // Empty string for the empty button, and '<' for backspace
  ];

  void onKeyboardButtonPressed(String value) {
    HapticFeedback.lightImpact(); // Add this line for haptic feedback

    if (value == '<') {
      if (inputFieldController.text.isNotEmpty) {
        inputFieldController.text = inputFieldController.text
            .substring(0, inputFieldController.text.length - 1);
      }
    } else if (value == 'Done') {
      setState(() {
        enteredDigits = inputFieldController.text;
      });
    } else {
      inputFieldController.text += value;
    }
  }


  void handleDateSelected(DateTime date) {
    selectedDate = date;
    print("Selected date: $date");
  }

  void resetFields() {
    setState(() {
      selectedDate = null;
      noteController.clear();
      inputFieldController.clear();
      selectedCategoryName = 'Select Category';
      selectedCategoryIcon = DefaultCategory;
    });
  }


  void _CategoryBottomSheet(BuildContext context, Function(String, String) updateCategory) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height - 200,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(width: 70),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  'Select Category',
                                  style: H1BlackBold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 48),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  HapticFeedback.heavyImpact();

                                },
                                child: SvgPicture.asset(
                                  CancelButton,
                                  width: 48,
                                  height: 48,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GridView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final categoryName = category['Name'] ?? 'Unknown';
                        final svgPath = category['SvgPath'] ?? 'Unknown';

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            setState(() {
                              selectedCategoryName = categoryName;
                              selectedCategoryIcon = svgPath;
                            });

                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  child: SvgPicture.asset(
                                    svgPath,
                                    width: 60,
                                    height: 60,
                                    color: selectedCategoryName == categoryName
                                        ? null
                                        : null,
                                    placeholderBuilder: (context) =>
                                        Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.red,
                                          child: const Icon(Icons.error),
                                        ),
                                  ),
                                ),
                                Text(
                                  categoryName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: selectedCategoryName == categoryName
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    BuildContext context = this.context;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: Text('Camera'),
                  onTap: () async {
                    HapticFeedback.heavyImpact();

                    Navigator.of(context).pop();
                    final ImagePicker _picker = ImagePicker();
                    final XFile? pickedFile =
                    await _picker.pickImage(source: ImageSource.camera);

                    if (pickedFile != null) {
                      setState(() {
                        _selectedImage = File(pickedFile.path);
                        _receiptText = _selectedImage!.path.split('/').last.substring(0, 7); // Update _receiptText with first 7 characters of image file name
                      });
                    }
                  },
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: Text('Gallery'),
                  onTap: () async {
                    HapticFeedback.heavyImpact();

                    Navigator.of(context).pop();
                    final ImagePicker _picker = ImagePicker();
                    final XFile? pickedFile =
                    await _picker.pickImage(source: ImageSource.gallery);

                    if (pickedFile != null) {
                      setState(() {
                        _selectedImage = File(pickedFile.path);
                        _receiptText = _selectedImage!.path.split('/').last.substring(0, 7); // Update _receiptText with first 7 characters of image file name
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: White,
        leading:   Hero(
          tag: 'back_arrow', // Ensure this tag is unique within the subtree
          child: IconButton(
            icon: SvgPicture.asset(
              BackArrow, // Ensure you have this SVG in your assets/icons folder
              height: 22,
              width: 20,
            ),
            onPressed: () {
              HapticFeedback.heavyImpact();

              Navigator.pushAndRemoveUntil(
                context,
                PageTransition(
                    type: PageTransitionType.leftToRight,
                    isIos: true,
                    childCurrent: widget,duration: Duration(milliseconds: 500) ,
                    reverseDuration: Duration(milliseconds: 500),
                    child: HomeScreen(tableName: widget.tableName)
                ),
                  (Route<dynamic> route) => false,

            );
            HapticFeedback.heavyImpact();

            }
          ),
        ),
        title: Text(
          'Add Expense ',
          style: H1BlackBold,
        ),

        centerTitle: true,
      ),

      body:  LayoutBuilder(
        builder: (context, constraints) {
          var maxWidth = constraints.maxWidth;
          var maxHeight = constraints.maxHeight;

          return SingleChildScrollView(
            child: Container(
              color: White,
              child: Column(
                children: [


                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: inputFieldController,
                            builder: (context, value, child) {
                              final inputText = value.text;
                              final double amount = inputText.isEmpty ? 0 : double.tryParse(inputText) ?? 0;
                              final Color textColor = amount == 0 ? Colors.red : Black;

                              return TextFormField(
                                controller: inputFieldController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      width: 0,
                                      color: Colors.transparent,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      width: 0,
                                      color: Colors.transparent,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      width: 0,
                                      color: Colors.transparent,
                                    ),
                                  ),
                                  hintText: '0',
                                ),
                                style: AmountBodyBold.copyWith(color: textColor),
                                keyboardType: TextInputType.none,
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Text('PKR', style: H1Normal),
                        ),
                        SizedBox(width: 40),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 8),
                    child: GestureDetector(
                      onTap: () =>
                          _CategoryBottomSheet(
                              context, (String categoryName, String svgPath) {
                            setState(() {
                              selectedCategoryName = categoryName;
                              selectedCategoryIcon = svgPath;
                            });
                          }), // Pass context to the method

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: ShapeDecoration(
                                    color: Color(0xFFF4F5F9),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                  ),
                                  child: Center(
                                    // icon should be displayed here
                                    child: SvgPicture.asset(
                                      selectedCategoryIcon,
                                      width: 60,
                                      height: 60,
                                    ),
                                  ),
                                ),
                                // and its name here
                                SizedBox(width: 24,),

                                Text(selectedCategoryName, style: H1Normal),
                              ],
                            ),
                          ),
                          SvgPicture.asset(
                            DownArrow,
                            width: 60,
                            height: 60,
                          ),
                          SizedBox(width: 20),


                        ],
                      ),
                    ),
                  ),


                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          clipBehavior: Clip.antiAlias,
                          decoration: ShapeDecoration(
                            color: Color(0xFFF4F5F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              Notes,
                              width: 60,
                              height: 60,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 15.04),
                            child: TextFormField(
                              controller: noteController,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Add Notes',
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          width: 164,
                          height: 54,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0),
                          // Adjusted padding to prevent overflow
                          decoration: ShapeDecoration(
                            color: Color(0xFFF4F5F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 15.04),
                                  // Adjust padding as needed
                                  child: DatePicker(
                                      onDateSelected: handleDateSelected),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: (){
                            HapticFeedback.heavyImpact();
                            _pickImage;
                            },
                          child: Container(
                            width: 164,
                            height: 54,
                            padding: const EdgeInsets.all(8),
                            decoration: ShapeDecoration(
                              color: _receiptText != null
                                  ? Color(0xFFD9EADA)
                                  : Color(0xFFF4F5F9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _receiptText != null
                                    ? SvgPicture.asset(
                                    'assets/images/checkcircle.svg', width: 18,
                                    height: 22)
                                    : SvgPicture.asset(
                                    ImageReceipt, width: 18, height: 22),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8, bottom: 1),
                                  child: _receiptText != null
                                      ? Text(
                                    _receiptText!,
                                    style: ButtonTextBlack,
                                  )
                                      : Text(
                                    'Accept Receipt',
                                    style: ButtonTextBlack,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),



                NumericKeyboard(
                    onKeyboardTap: (value) {
                      HapticFeedback.lightImpact(); // Add this line for haptic feedback on every key press
                      onKeyboardButtonPressed(value);
                    },
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                    ),
                    rightButtonFn: () {
                      HapticFeedback.lightImpact(); // Add haptic feedback here as well
                      onKeyboardButtonPressed('<');
                    },
                    rightButtonLongPressFn: () {
                      HapticFeedback.lightImpact(); // Add haptic feedback here as well
                      setState(() {
                        inputFieldController.clear();
                      });
                    },
                    rightIcon: const Icon(
                      Icons.backspace_outlined,
                      color: Colors.black,
                    ),
                    leftButtonFn: () {
                      HapticFeedback.lightImpact(); // Add haptic feedback here as well
                      onKeyboardButtonPressed('.');
                    },
                    leftIcon: const Text(
                      '.',
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.black,
                      ),
                    ),
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  ),

                  Gap(8),


                  Gap(8),


                  SizedBox(
                    width: 329,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: ()async {
                        HapticFeedback.mediumImpact();

                        final double amount = inputFieldController.text.isEmpty
                            ? 0
                            : double.parse(inputFieldController.text);

                        if (amount != 0) {
                          await _saveExpense(selectedDate: selectedDate);
                          resetFields();
                          Navigator.pushAndRemoveUntil(
                            context,
                            PageTransition(
                              type: PageTransitionType.leftToRight,
                              isIos: true,
                              childCurrent: widget,
                              duration: Duration(milliseconds: 500),
                              reverseDuration: Duration(milliseconds: 800),
                              child: HomeScreen(tableName: widget.tableName), // Pass the table name here
                            ),
                                (route) => false, // Removes all previous routes
                          );


                        }
                        else {
                          setState(() {
                            inputFieldController.text = '0';
                          });
                        }
                      },

                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                            Color(0xFF0D43FF)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Center(
                          child: Text(
                            'Add Expense',
                            style: H1SemiBoldWhite,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          );
        }
        ),

    );
  }
}


