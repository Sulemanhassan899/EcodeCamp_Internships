// ignore_for_file: sized_box_for_whitespace, prefer_const_constructors, unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../Utils/constants.dart';

class SliderMenu extends StatefulWidget {
  final Function(String) onItemSelected;
  final String selectedTableName;

  const SliderMenu({
    super.key,
    required this.onItemSelected,
    required this.selectedTableName,
  });

  @override
  State<SliderMenu> createState() => _SliderMenuState();
}

class _SliderMenuState extends State<SliderMenu> {
  Database? _database;
  final TextEditingController _tableNameController = TextEditingController();
  List<Map<String, dynamic>> _tableNamesWithCounts = [];
  String _selectedTableName = 'Personal Expense'; // Default selected table

  @override
  void initState() {
    super.initState();
    _initDatabase();
    _loadTableNamesWithCounts();
  }


  @override
  void didUpdateWidget(SliderMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadTableNamesWithCounts();
  }

  void forceRebuild() {
    _loadTableNamesWithCounts();
  }



  Future<void> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'expenses.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {},
      onOpen: (db) async {},
    );
    await createNewTable(
        _selectedTableName  ); // Create 'Personal Expense' table by default
    await _loadTableNamesWithCounts();

    if (_tableNamesWithCounts.isNotEmpty) {
      setState(() {
        _selectedTableName = _tableNamesWithCounts
            .map((item) => item['name'] as String)
            .contains(widget.selectedTableName)
            ? widget.selectedTableName
            : _tableNamesWithCounts.first['name'];
      });
      widget.onItemSelected(_selectedTableName);
    } else {
      // Handle the case where there are no tables
      widget.onItemSelected(_selectedTableName);
    }
  }




  Future<void> _loadTableNamesWithCounts() async {
    if (_database != null) {
      List<Map<String, dynamic>> tables = await _database!.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata';");

      List<Map<String, dynamic>> tableNamesWithCounts = [];

      for (var table in tables) {
        String tableName = table['name'] as String;
        int count = Sqflite.firstIntValue(
            await _database!.rawQuery('SELECT COUNT(*) FROM "$tableName"')) ??
            0;
        tableNamesWithCounts.add({'name': tableName, 'count': count});
      }

      if (mounted) {
        setState(() {
          _tableNamesWithCounts = tableNamesWithCounts;
          print("Slider updated: $_tableNamesWithCounts");
        });
      }
    }
  }


  String getInitials(String tableName) {
    List<String> words = tableName.split(' ');
    String initials = words.take(2).map((word) =>
    word.isNotEmpty ? word[0].toUpperCase() : '').join(' ');
    return initials;
  }

  Future<void> createNewTable(String tableName) async {
    if (_database != null) {
      // Ensure the table name is correctly quoted
      final quotedTableName = '"$tableName"';

      try {
        await _database!.execute(
            'CREATE TABLE IF NOT EXISTS $quotedTableName ('
                'id INTEGER PRIMARY KEY, '
                'imageUrl TEXT, '
                'note TEXT, '
                'amount REAL, '
                'date TEXT, '
                'category TEXT, '
                'categoryIcon TEXT, '
                'fileSize TEXT, '
                'fileType TEXT)'
        );
      } catch (e) {
        print('Error creating table: $e');
      }

      await _loadTableNamesWithCounts();
    }
  }




  Future<void> deleteTable(String tableName) async {
    if (_database != null) {
      await _database!.execute('DROP TABLE IF EXISTS "$tableName"');
      await _loadTableNamesWithCounts();
    }
  }



  _showTableManagementBottomSheet(BuildContext context, bool isDelete) {

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              height: MediaQuery.of(context).size.height - 200, // Set height to device height
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(width: 70),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30),
                              child: Text(
                                isDelete ? 'Delete Table' : 'Create Table',
                                style: H1BlackBold,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 48),
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  Navigator.pop(context); // This will close the bottom sheet
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
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        textCapitalization: TextCapitalization.words,
                        controller: _tableNameController,
                        decoration: InputDecoration(
                          labelText: 'Table Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    // Color Selection Circles
                    SizedBox(
                      width: 329,
                      height: 54,
                      child: FloatingActionButton(
                        heroTag: 'new and old',
                        onPressed: () async {
                          HapticFeedback.heavyImpact();
                          String tableName = _tableNameController.text;
                          if (tableName.isNotEmpty) {
                            await createNewTable(tableName);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Please enter a table name.')),
                            );
                          }
                          _tableNameController.clear();
                          Navigator.pop(context);
                          await _loadTableNamesWithCounts(); // Reload the table names
                        },
                        backgroundColor: isDelete ? Color(0xFFD40019) : Color(0xFF0D43FF),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Center(
                            child: Text(
                              isDelete ? 'Delete Table' : 'Add Table',
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
          },
        );
      },
    );
  }


  @override

  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          var maxWidth = constraints.maxWidth;
          var maxHeight = constraints.maxHeight;

          return Scaffold(
            backgroundColor: White,
            body: Padding(
              padding: const EdgeInsets.only(top: 50, left: 4, right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1st set
                  SvgPicture.asset(
                    TrackApp,
                    width: 60,
                    height: 60,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
                      child:  ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          ..._tableNamesWithCounts
                              .asMap()
                              .entries
                              .map((
                              entry) => // Use asMap().entries to access the index
                          _createDrawerItem(
                            index: entry.key, // Pass the index
                            text: '${entry
                                .value['name']}  no of records: ${entry
                                .value['count']}',
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              setState(() {
                                _selectedTableName = entry.value['name'];
                              });
                              widget.onItemSelected(entry.value['name']);
                            },
                            isSelected: entry.value['name'] ==
                                _selectedTableName,
                          )),
                          Gap(32),
                          //on this
                          SizedBox(
                            width: 180,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () async {
                                HapticFeedback.heavyImpact(); // Add haptic feedback here
                                _showTableManagementBottomSheet(context, false);
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all<Color>(Color(0xFF0D43FF)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 22, // Adjust the size of the icon
                                      ),
                                      const SizedBox(width: 8),
                                      // Space between icon and text
                                      Text(
                                        'Create new',
                                        style: H1SemiBoldWhite,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )



                        ],
                      ),
                    ),
                  ),


                  Divider(
                    color: Grey1, // Divider between red and yellow containers
                    thickness: 0.5,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 0, bottom: 24,),
                    child: Container(
                        width: 300,
                        height: 232,

                        padding: const EdgeInsets.all(24),

                        child: Column(

                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Other',
                                style: H1BlackBold
                            ),
                            const Gap(16),
                            InkWell(
                              onTap: (){
                                HapticFeedback.mediumImpact();
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                // Align items in the center vertically
                                children: [
                                  Text(
                                      'Rate App',
                                      style: NotesBodyGrey2
                                  ),
                                  Spacer(),
                                  SvgPicture.asset(
                                    RightArrow,
                                    width: 13,
                                    height: 22,
                                  ),

                                ],
                              ),
                            ),
                            const Gap(16),
                            InkWell(
                              onTap: (){
                                HapticFeedback.mediumImpact();
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                // Align items in the center vertically
                                children: [
                                  Text(
                                      'Terms of Service',
                                      style: NotesBodyGrey2
                                  ),
                                  Spacer(),
                                  SvgPicture.asset(
                                    RightArrow,
                                    width: 13,
                                    height: 22,
                                  ),

                                ],
                              ),
                            ),
                            const Gap(16),
                            InkWell(
                              onTap: (){
                                HapticFeedback.mediumImpact();
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                // Align items in the center vertically
                                children: [
                                  Text(
                                      'Privacy Policy',
                                      style: NotesBodyGrey2
                                  ),
                                  Spacer(),
                                  SvgPicture.asset(
                                    RightArrow,
                                    width: 13,
                                    height: 22,
                                  ),

                                ],
                              ),
                            ),

                          ],
                        )

                    ),
                  ),
                ],
              ),
            ),
          );
        }
    );
  }



  final List<Color> colors = [
    TablePink,
    TableYellow,
    TableGreen,
    TableRed,
    TableBlue ,
    TableDarkGrey ,
    TableLightBlue ,
    TablePurple ,
  ];


  Widget _createDrawerItem({
    required String text,
    required VoidCallback onTap,
    required bool isSelected,
    required int index, // Add index parameter
  }) {
    String tableName = text.split('  ')[0];
    Color backgroundColor = colors[index % colors.length]; // Ensure index is within the list range

    return InkWell(
      onTap: onTap,
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: backgroundColor, // Use determined color
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 22,
              child: Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Text(
                  getInitials(tableName), // Get initials from just the table name
                  style: H1WhiteBold,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          tableName,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Text(
          '${_tableNamesWithCounts.firstWhere((item) => item['name'] == tableName)['count']} Records',
          style: TextStyle(
            color: Colors.black, // Text color for the count
            fontSize: 14, // Font size for the count
          ),
        ),
        tileColor: isSelected ? Color(0xFFE6EBFF) : null, // Change the background color when selected
      ),
    );
  }



}






