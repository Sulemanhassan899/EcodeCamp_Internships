// ignore_for_file: prefer_const_constructors, prefer_const_declarations, sized_box_for_whitespace, unused_field, prefer_final_fields, avoid_print, avoid_function_literals_in_foreach_calls, unused_local_variable

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slider_drawer/flutter_slider_drawer.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sqflite/sqflite.dart';
import '../Screens/AddExpense.dart';
import '../models/CustomAppBar2.dart';
import '../Utils/constants.dart';
import 'package:path/path.dart';

import '../models/SliderMenu.dart';


class HomeScreen extends StatefulWidget {
  static String routeName = "/HomeScreen";
  final String? tableName;

  HomeScreen({this.tableName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  GlobalKey<SliderDrawerState> _sliderDrawerKey = GlobalKey<
      SliderDrawerState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _tableNames = ' ';
  List<Map<String, dynamic>> _savedExpenses = [];
  Database? _database;
  List<Map<String, dynamic>> _expenses = [];
  String selectedFilter = 'This Week';
  double _totalAmountMonth = 0;
  double _totalAmountWeek = 0;
  double _totalAmount6Months = 0;
  double _totalAmountYear = 0;
  int _totalRecordsYear = 0;

  int _currentPage = 0;
  int _pageSize = 30; // Number of records per page
  bool _hasMoreExpenses = true; // To check if more expenses are available

  List<Map<String, dynamic>> _monthlyExpenses = [];
  List<Map<String, dynamic>> _weekExpenses = [];
  List<Map<String, dynamic>> _sixMonthExpenses = [];
  List<Map<String, dynamic>> _threeMonthExpenses = [];
  List<Map<String, dynamic>> _yearlyExpenses = [];
  List<Map<String, dynamic>> _monthlyTotals = [];

  final List<Color> gradientColors = [
    const Color(0xff0d43ff),
    const Color(0xff0d43ff),
  ];


  @override
  void initState() {
    super.initState();
    _tableNames = widget.tableName ?? ''; // Set initial table name
    _initDatabase();
    _fetchExpenses();
  }


  Future<void> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'expenses.db');

    _database = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {},
      onUpgrade: (db, oldVersion, newVersion) async {},
    );
  }


  Future<void> _fetchExpenses() async {
    if (_database != null) {
      final tableName = _tableNames.contains(' ')
          ? '"$_tableNames"'
          : _tableNames;
      final List<Map<String, dynamic>> expenses = await _database!.query(
        tableName,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (expenses.length < _pageSize) {
        _hasMoreExpenses = false; // No more records to load
      }

      setState(() {
        if (_currentPage == 0) {
          _savedExpenses = List.from(expenses); // Initialize on the first page
        } else {
          _savedExpenses.addAll(
              expenses); // Add more records on subsequent pages
        }
        _savedExpenses.sort((a, b) {
          DateTime dateA = _parseDate(a['date']);
          DateTime dateB = _parseDate(b['date']);
          return dateB.compareTo(dateA); // Sort in descending order
        });
      });
      _updateTotals();


      if (selectedFilter == 'This Week') {
        _calculateTotalAmountForCurrentWeek();
      }
      if (selectedFilter == '1 Month') {
        _calculateTotalAmountForCurrentMonth();
      }
      if (selectedFilter == '3 Month') {
        _calculateTotalAmountForLast3Months();
      }
      if (selectedFilter == '6 Month') {
        _calculateTotalAmountForLast6Months();
      }
      if (selectedFilter == 'All') {
        _calculateTotalAmountForAll();
      }
    }
  }

  void _updateTotals() {
    if (selectedFilter == 'This Week') {
      _calculateTotalAmountForCurrentWeek();
    } else if (selectedFilter == '1 Month') {
      _calculateTotalAmountForCurrentMonth();
    } else if (selectedFilter == '3 Month') {
      _calculateTotalAmountForLast3Months();
    } else if (selectedFilter == '6 Month') {
      _calculateTotalAmountForLast6Months();
    } else if (selectedFilter == 'All') {
      _calculateTotalAmountForAll();
    }
  }

  Future<void> _deleteExpense(int id) async {
    if (_database != null) {
      final tableName = _tableNames.contains(' ') ? '"$_tableNames"' : _tableNames;

      // Delete the expense from the database
      await _database!.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      // Remove the expense from the local list
      setState(() {
        _savedExpenses.removeWhere((expense) => expense['id'] == id);
      });

      // Recalculate totals and update UI
      _updateTotals();

      // Show a confirmation message
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Expense deleted successfully')),
      );
    }
  }

  void _onSliderItemSelected(String title) {
    setState(() {
      _tableNames = title;
      _fetchExpenses(); // Fetch expenses for the newly selected table
    });
    _sliderDrawerKey.currentState?.closeSlider();
  }


  DateTime _parseDate(String dateStr) {
    List<String> dateFormats = [
      'yyyy-MM-dd',
      'MMM d, yyyy',
      'dd-MM-yyyy',
      'MM-yyyy'
          'dd-MM'
    ];
    for (var format in dateFormats) {
      try {
        return DateFormat(format).parse(dateStr);
      } catch (e) {
        FormatException("Invalid date format: $dateStr");
      }
    }
    throw FormatException("Invalid date format: $dateStr");
  }


  //
  //
//
//
//
//
//
//
//
//
//
//
//
//
//Current week
  String _getCurrentWeekDateRange() {
    DateTime now = DateTime.now();
    DateTime firstDayOfWeek =
    now.subtract(Duration(days: now.weekday - 1)); // Monday of current week
    DateTime lastDayOfWeek =
    firstDayOfWeek.add(Duration(days: 6)); // Sunday of current week

    DateFormat dateFormat = DateFormat('d MMM yyyy');
    String startDate = dateFormat.format(firstDayOfWeek);
    String endDate = dateFormat.format(lastDayOfWeek);

    return '$startDate to $endDate';
  }

  Future<void> _calculateTotalAmountForCurrentWeek() async {
    DateTime now = DateTime.now();
    DateTime firstDayOfWeek =
    now.subtract(Duration(days: now.weekday - 1)); // Monday of current week
    DateTime lastDayOfWeek =
    firstDayOfWeek.add(Duration(days: 6)); // Sunday of current week

    double totalAmount = 0;
    Map<String, List<Map<String, dynamic>>> groupedExpenses = {};

    for (var expense in _savedExpenses) {
      DateTime expenseDate;
      try {
        expenseDate = _parseDate(expense['date']);
      } catch (e) {
        // Handle invalid date format gracefully
        print('Error parsing date: ${expense['date']}');
        continue; // Skip this expense
      }

      if (expenseDate.isAfter(firstDayOfWeek.subtract(Duration(days: 1))) &&
          expenseDate.isBefore(lastDayOfWeek.add(Duration(days: 1)))) {
        totalAmount += expense['amount'];

        String formattedDate = DateFormat('MMM dd, yyyy').format(expenseDate);

        if (groupedExpenses.containsKey(formattedDate)) {
          groupedExpenses[formattedDate]!.add(expense);
        } else {
          groupedExpenses[formattedDate] = [expense];
        }
      }
    }

    setState(() {
      _totalAmountWeek = totalAmount;
      _weekExpenses = groupedExpenses.entries.map((entry) {
        return {
          'date': entry.key,
          'expenses': entry.value,
        };
      }).toList();
      _weekExpenses.sort((a, b) =>
          _parseDate(b['date']).compareTo(
              _parseDate(a['date']))); // Sort in descending order

    });
  }


  List<FlSpot> _getSpotsForCurrentWeek() {
    final DateTime now = DateTime.now();
    final DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

    final List<FlSpot> spots = [];
    for (int i = 0; i < 7; i++) {
      final DateTime day = startOfWeek.add(Duration(days: i));
      final String dayStr = DateFormat('MMM d, yyyy')
          .format(day); // Use 'MMM d, yyyy' to match your saved date format
      final double totalAmountForDay = _savedExpenses
          .where((expense) => expense['date'] == dayStr)
          .fold(0.0, (sum, expense) => sum + expense['amount']);
      spots.add(FlSpot(i.toDouble(), totalAmountForDay));
    }
    print(spots);

    return spots;
  }


  List<String> _getTitlesForCurrentWeek() {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  }

  Widget buildLineChartContainerWeek() {
    final spots =
    _getSpotsForCurrentWeek(); // Get the spots for the current month
    return Container(
      width: spots.length * 60.0, // Width based on number of data points
      height: 220,
      decoration: ShapeDecoration(
        color: White,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  interval: 1,
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final style = GrpahBottomTilesGrey2;

                    final titles = _getTitlesForCurrentWeek();
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8.0,
                      child: Text(titles[value.toInt()], style: style),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: false,
            ),
            lineBarsData: [
              LineChartBarData(
                spots: _getSpotsForCurrentWeek(),
                isCurved: true,
                preventCurveOverShooting: true,
                barWidth: 2,
                color: Blue,
                isStrokeCapRound: true,
                dotData: const FlDotData(
                  show: false,
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: gradientColors
                        .map((color) => color.withOpacity(0.1))
                        .toList(),
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> lineBarsSpot) {
                  return lineBarsSpot.map((lineBarSpot) {
                    return LineTooltipItem(
                      '${lineBarSpot.y.toString()}',
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }


//
//
//
//
//
//
//
//
//
//
//
//
//Current month

  String _getCurrentMonthDateRange() {
    DateTime now = DateTime.now();
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    DateFormat dateFormat = DateFormat('d MMM yyyy');
    String startDate = dateFormat.format(firstDayOfMonth);
    String endDate = dateFormat.format(lastDayOfMonth);

    return '$startDate to $endDate';
  }

  Future<void> _calculateTotalAmountForCurrentMonth() async {
    DateTime now = DateTime.now();
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    double totalAmount = 0;
    Map<String, List<Map<String, dynamic>>> CurrentMonthgroupedExpenses = {};

    for (var expense in _savedExpenses) {
      DateTime expenseDate;
      try {
        expenseDate = _parseDate(expense['date']);
      } catch (e) {
        // Handle invalid date format gracefully
        print('Error parsing date: ${expense['date']}');
        continue; // Skip this expense
      }

      if (expenseDate.isAfter(firstDayOfMonth.subtract(Duration(days: 1))) &&
          expenseDate.isBefore(lastDayOfMonth.add(Duration(days: 1)))) {
        totalAmount += expense['amount'];

        String formattedDate = DateFormat('MMM dd, yyyy').format(expenseDate);

        if (CurrentMonthgroupedExpenses.containsKey(formattedDate)) {
          CurrentMonthgroupedExpenses[formattedDate]!.add(expense);
        } else {
          CurrentMonthgroupedExpenses[formattedDate] = [expense];
        }
      }
    }

    setState(() {
      _totalAmountMonth = totalAmount;
      _monthlyExpenses = CurrentMonthgroupedExpenses.entries.map((entry) {
        return {
          'date': entry.key,
          'expenses': entry.value,
        };
      }).toList();

      _monthlyExpenses.sort((a, b) =>
          _parseDate(b['date']).compareTo(
              _parseDate(a['date']))); // Sort in descending order

    });
  }

  List<FlSpot> _getSpotsForCurrentMonth() {
    final DateTime now = DateTime.now();
    final DateTime startOfMonth = DateTime(now.year, now.month, 1);
    final DateTime endOfMonth = DateTime(now.year, now.month + 1, 0);

    final List<FlSpot> spots = [];
    for (int i = 0; i < endOfMonth.day; i++) {
      final DateTime day = startOfMonth.add(Duration(days: i));
      final double totalAmountForDay = _monthlyExpenses
          .where((expense) =>
      _parseDate(expense['date']).day == day.day &&
          _parseDate(expense['date']).month == day.month &&
          _parseDate(expense['date']).year == day.year)
          .fold(
          0.0,
              (sum, expense) =>
          sum +
              expense['expenses']
                  .fold(0.0, (innerSum, e) => innerSum + e['amount']));
      spots.add(FlSpot(i.toDouble(), totalAmountForDay));
    }

    return spots;
  }

  List<String> _getTitlesForCurrentMonth() {
    final DateTime now = DateTime.now();
    final DateTime startOfMonth = DateTime(now.year, now.month, 1);
    final DateTime endOfMonth = DateTime(now.year, now.month + 1, 0);
    return List.generate(endOfMonth.day, (index) => (index + 1).toString());
  }

  Widget buildLineChartContainerMonth() {
    final spots =
    _getSpotsForCurrentMonth(); // Get the spots for the current month
    final titles =
    _getTitlesForCurrentMonth(); // Get the titles for the current month

    return Container(
      width: spots.length * 80.0, // Width based on number of data points
      height: 220,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 4,
                  getTitlesWidget: (value, meta) {
                    final style = GrpahBottomTilesGrey2;
                    if (selectedFilter == '1 Month') {
                      final int index = value.toInt();
                      if (index >= 0 && index < titles.length) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(titles[index], style: style),
                        );
                      }
                    }
                    return Container();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: false,
            ),
            lineBarsData: [
              LineChartBarData(
                spots: selectedFilter == 'This Week'
                    ? _getSpotsForCurrentWeek()
                    : spots,
                isCurved: true,
                preventCurveOverShooting: true,
                barWidth: 1,
                color: Blue,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: false,
                  getDotPainter: (spot, delta, lineBarData, index) {
                    return FlDotCirclePainter(radius: 4, color: Blue);
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: gradientColors
                        .map((color) => color.withOpacity(0.1))
                        .toList(),
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> lineBarsSpot) {
                  return lineBarsSpot.map((lineBarSpot) {
                    return LineTooltipItem(
                      '${lineBarSpot.y.toString()}',
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  //
  //
//
//
//
//
//
//
//
//
//
//
//
//
//3  month

  String _getPastThreeMonthsDateRange() {
    DateTime now = DateTime.now();
    DateTime firstDayOfPast3Months = DateTime(now.year, now.month - 2, 1);
    DateTime lastDayOfPast3Months = DateTime(now.year, now.month + 1, 0);

    DateFormat dateFormat = DateFormat('d MMM yyyy');
    String startDate = dateFormat.format(firstDayOfPast3Months);
    String endDate = dateFormat.format(lastDayOfPast3Months);

    return '$startDate to $endDate';
  }

  Future<void> _calculateTotalAmountForLast3Months() async {
    DateTime now = DateTime.now();
    DateTime firstDayOfThreeMonthsAgo = DateTime(now.year, now.month - 2, 1);
    DateTime lastDayOfCurrentMonth = DateTime(now.year, now.month + 1, 0);

    double totalAmount = 0;
    List<Map<String, dynamic>> threeMonthExpenses = [];

    Map<DateTime, Map<String, Map<String, dynamic>>> monthlyExpenses = {};

    for (var expense in _savedExpenses) {
      DateTime expenseDate = _parseDate(expense['date']);
      if (expenseDate.isAfter(firstDayOfThreeMonthsAgo) &&
          expenseDate.isBefore(lastDayOfCurrentMonth)) {
        totalAmount += expense['amount'];
        DateTime expenseMonth = DateTime(expenseDate.year, expenseDate.month);

        if (!monthlyExpenses.containsKey(expenseMonth)) {
          monthlyExpenses[expenseMonth] = {};
        }

        String category = expense['category'];
        if (!monthlyExpenses[expenseMonth]!.containsKey(category)) {
          monthlyExpenses[expenseMonth]![category] = {
            'total': 0.0,
            'count': 0,
            'categoryIcon': expense['categoryIcon'] ?? ''
          };
        }

        monthlyExpenses[expenseMonth]![category]!['total'] =
            (monthlyExpenses[expenseMonth]![category]!['total'] ?? 0) +
                expense['amount'];
        monthlyExpenses[expenseMonth]![category]!['count'] =
            (monthlyExpenses[expenseMonth]![category]!['count'] ?? 0) + 1;
      }
    }

    threeMonthExpenses = monthlyExpenses.entries.map((entry) {
      DateTime month = entry.key;
      Map<String, dynamic> monthData = entry.value;

      return {
        'month': DateFormat.MMMM().format(month),
        'year': month.year,
        'expenses': monthData.entries.map((e) {
          return {
            'category': e.key,
            'total': e.value['total'],
            'count': e.value['count'],
            'categoryIcon': e.value['categoryIcon'],
          };
        }).toList(),
      };
    }).toList();

    // Sort by year and month, with the most recent month first
    threeMonthExpenses.sort((a, b) {
      if (a['year'] != b['year']) {
        return b['year'].compareTo(a['year']);
      } else {
        return DateFormat('MMMM').parse(b['month']).compareTo(
            DateFormat('MMMM').parse(a['month']));
      }
    });

    setState(() {
      _totalAmountMonth = totalAmount;
      _threeMonthExpenses = threeMonthExpenses;
    });
  }


  List<FlSpot> _getSpotsForLast3Months() {
    final DateTime now = DateTime.now();
    final DateTime threeMonthsAgo = DateTime(now.year, now.month - 2, 1);
    final List<FlSpot> spots = [];

    int index = 0; // Index for x-axis

    for (DateTime month = threeMonthsAgo;
    month.isBefore(now);
    month = DateTime(month.year, month.month + 1, 1)) {
      final double totalAmountForMonth = _savedExpenses
          .where((expense) =>
      _parseDate(expense['date']).month == month.month &&
          _parseDate(expense['date']).year == month.year)
          .fold(0.0, (sum, expense) => sum + expense['amount']);
      spots.add(FlSpot(index.toDouble(), totalAmountForMonth));
      index++;
    }

    print("Total spots generated: ${spots.length}");
    return spots;
  }

  List<String> _getTitlesForLast3Months() {
    final DateTime now = DateTime.now();
    final DateTime threeMonthsAgo = DateTime(now.year, now.month - 2, 1);

    final List<String> months = [];

    for (DateTime date = threeMonthsAgo;
    date.isBefore(now);
    date = DateTime(date.year, date.month + 1, 1)) {
      months.add(DateFormat('MMM yyyy').format(date)); // Format with 'MMM yyyy'
    }

    return months;
  }

  Widget buildLineChartContainer3Months() {
    final spots =
    _getSpotsForLast3Months(); // Get the spots for the last 3 months
    final titles = _getTitlesForLast3Months();

    return Container(
      width: spots.length * 130.0,
      // Set a fixed width or calculate dynamically based on titles.length
      height: 220,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40, // Ensure there's enough space for titles
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final style = GrpahBottomTilesGrey2;
                    final int index = value.toInt();
                    if (index >= 0 && index < titles.length) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(titles[index], style: style),
                      );
                    }
                    return Container();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: false,
            ),
            lineBarsData: [
              LineChartBarData(
                spots: selectedFilter == 'This Week'
                    ? _getSpotsForCurrentWeek()
                    : spots,
                isCurved: true,
                preventCurveOverShooting: true,
                barWidth: 1,
                color: Blue,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: false,
                  getDotPainter: (spot, delta, lineBarData, index) {
                    return FlDotCirclePainter(radius: 4, color: Blue);
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: gradientColors
                        .map((color) => color.withOpacity(0.1))
                        .toList(),
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> lineBarsSpot) {
                  return lineBarsSpot.map((lineBarSpot) {
                    return LineTooltipItem(
                      '${lineBarSpot.y.toString()}',
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  //
  //
//
//
//
//
//
//
//
//
//
//
//
//
//6 month

  String _getPast6MonthsDateRange() {
    DateTime now = DateTime.now();
    DateTime sixMonthsAgo =
    DateTime(now.year, now.month - 5, 1); // Start of 6 months ago
    DateTime lastDayOfPast6Months =
    DateTime(now.year, now.month, 30); // Last day of the previous month

    DateFormat dateFormat = DateFormat('d MMM yyyy');
    String startDate = dateFormat.format(sixMonthsAgo);
    String endDate = dateFormat.format(lastDayOfPast6Months);

    return '$startDate to $endDate';
  }

  Future<void> _calculateTotalAmountForLast6Months() async {
    DateTime now = DateTime.now();
    DateTime sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

    double totalAmount = 0;
    Map<String, double> monthTotals = {};
    Map<String, int> monthRecordsCount = {};

    for (var expense in _savedExpenses) {
      DateTime expenseDate;
      try {
        expenseDate = _parseDate(expense['date']);
      } catch (e) {
        // Handle invalid date format gracefully
        print('Error parsing date: ${expense['date']}');
        continue; // Skip this expense
      }

      if (expenseDate.isAfter(sixMonthsAgo) && expenseDate.isBefore(now)) {
        String monthYear = DateFormat('MMM yyyy').format(expenseDate);

        totalAmount += expense['amount'];

        if (monthTotals.containsKey(monthYear)) {
          monthTotals[monthYear] = monthTotals[monthYear]! + expense['amount'];
          monthRecordsCount[monthYear] = monthRecordsCount[monthYear]! + 1;
        } else {
          monthTotals[monthYear] = expense['amount'];
          monthRecordsCount[monthYear] = 1;
        }
      }
    }

    List<Map<String, dynamic>> sixMonthExpenses =
    monthTotals.entries.map((entry) {
      return {
        'month': entry.key,
        'total': entry.value,
        'recordCounts': monthRecordsCount[entry.key]!,
      };
    }).toList();

    setState(() {
      _totalAmount6Months = totalAmount;
      _sixMonthExpenses = sixMonthExpenses;
      print(sixMonthExpenses);
      _sixMonthExpenses.sort((a, b) => b['total'].compareTo(a['total']));
    });
  }

  List<FlSpot> _getSpotsForLast6Months() {
    final DateTime now = DateTime.now();
    final DateTime sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
    final List<FlSpot> spots = [];

    for (int i = 0; i < 6; i++) {
      final DateTime monthStart =
      DateTime(sixMonthsAgo.year, sixMonthsAgo.month + i, 1);
      final double totalAmountForMonth = _savedExpenses
          .where((expense) =>
      _parseDate(expense['date']).month == monthStart.month &&
          _parseDate(expense['date']).year == monthStart.year)
          .fold(0.0, (sum, expense) => sum + expense['amount']);
      spots.add(FlSpot(i.toDouble(), totalAmountForMonth));
    }

    print("Total spots generated: ${spots.length}");
    return spots;
  }

  List<String> _getTitlesForLast6Months() {
    final DateTime now = DateTime.now();
    final DateTime sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

    final List<String> months = [];

    for (DateTime date = sixMonthsAgo;
    date.isBefore(now);
    date = DateTime(date.year, date.month + 1, 1)) {
      months.add(DateFormat('MMM yyyy').format(date)); // Format with 'MMM yyyy'
    }

    return months;
  }

  Widget buildLineChartContainer6Months() {
    final spots =
    _getSpotsForLast6Months(); // Get the spots for the last 6 months
    final titles = _getTitlesForLast6Months();

    return Container(
      width: spots.length * 90.0, // Adjust width based on number of data points
      height: 220,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  // Set interval to 1 as we are dealing with months
                  getTitlesWidget: (value, meta) {
                    final style = GrpahBottomTilesGrey2;
                    final int index = value.toInt();
                    if (index >= 0 && index < titles.length) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(titles[index], style: style),
                      );
                    }
                    return Container();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: false,
            ),
            lineBarsData: [
              LineChartBarData(
                spots: selectedFilter == 'This Week'
                    ? _getSpotsForCurrentWeek()
                    : spots,
                isCurved: true,
                preventCurveOverShooting: true,
                barWidth: 1,
                color: Blue,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: false,
                  getDotPainter: (spot, delta, lineBarData, index) {
                    return FlDotCirclePainter(radius: 4, color: Blue);
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: gradientColors
                        .map((color) => color.withOpacity(0.1))
                        .toList(),
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> lineBarsSpot) {
                  return lineBarsSpot.map((lineBarSpot) {
                    return LineTooltipItem(
                      '${lineBarSpot.y.toString()}',
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  //
  //
//
//
//
//
//
//
//
//
//
//
//
//
//All
  String _getPastAllDateRange() {
    DateTime now = DateTime.now();
    DateTime firstDayOfPast12Months =
    DateTime(now.year, now.month - 12, 1); // 12 months ago
    DateTime lastDayOfPast12Months =
    DateTime(now.year, now.month + 1, 0); // Last day of current month

    DateFormat dateFormat = DateFormat('d MMM yyyy');
    String startDate = dateFormat.format(firstDayOfPast12Months);
    String endDate = dateFormat.format(lastDayOfPast12Months);

    return '$startDate to $endDate';
  }

  Future<void> _calculateTotalAmountForAll() async {
    DateTime now = DateTime.now();
    DateTime oneYearAgo = DateTime(now.year - 1, now.month, now.day);

    double totalAmount = 0;
    Map<String, double> monthTotals = {};
    Map<String, int> monthRecordsCount = {};

    for (var expense in _savedExpenses) {
      DateTime expenseDate;
      try {
        expenseDate = _parseDate(expense['date']);
      } catch (e) {
        // Handle invalid date format gracefully
        print('Error parsing date: ${expense['date']}');
        continue; // Skip this expense
      }

      if (expenseDate.isAfter(oneYearAgo) && expenseDate.isBefore(now)) {
        String monthYear = DateFormat('MMM yyyy').format(expenseDate);

        totalAmount += expense['amount'];

        if (monthTotals.containsKey(monthYear)) {
          monthTotals[monthYear] = monthTotals[monthYear]! + expense['amount'];
          monthRecordsCount[monthYear] = monthRecordsCount[monthYear]! + 1;
        } else {
          monthTotals[monthYear] = expense['amount'];
          monthRecordsCount[monthYear] = 1;
        }
      }
    }

    List<Map<String, dynamic>> sixMonthExpenses =
    monthTotals.entries.map((entry) {
      return {
        'month': entry.key,
        'total': entry.value,
        'recordCounts': monthRecordsCount[entry.key]!,
      };
    }).toList();

    setState(() {
      _totalAmount6Months = totalAmount;
      _sixMonthExpenses = sixMonthExpenses;
      print(sixMonthExpenses);
      _sixMonthExpenses.sort((a, b) => b['total'].compareTo(a['total']));
    });
  }

  List<FlSpot> _getSpotsForAll() {
    final DateTime now = DateTime.now();
    final DateTime oneYearAgo = DateTime(now.year, now.month - 11, 1);
    final List<FlSpot> spots = [];

    for (int i = 0; i < 12; i++) {
      final DateTime monthStart =
      DateTime(oneYearAgo.year, oneYearAgo.month + i, 1);
      final double totalAmountForMonth = _savedExpenses
          .where((expense) =>
      _parseDate(expense['date']).month == monthStart.month &&
          _parseDate(expense['date']).year == monthStart.year)
          .fold(0.0, (sum, expense) => sum + expense['amount']);
      spots.add(FlSpot(i.toDouble(), totalAmountForMonth));
    }

    return spots;
  }

  List<String> _getTitlesForAll() {
    final DateTime now = DateTime.now();
    final DateTime oneYearAgo = DateTime(now.year, now.month - 11, 1);
    List<String> titles = [];

    for (int i = 0; i < 12; i++) {
      final DateTime monthDate =
      DateTime(oneYearAgo.year, oneYearAgo.month + i, 1);
      titles.add(DateFormat('MMM yyy').format(monthDate));
    }

    return titles;
  }

  Widget buildLineChartContainerAll() {
    final spots = _getSpotsForAll();
    final titles = _getTitlesForAll();

    final double interval = 1.0;

    final DateTime now = DateTime.now();
    final int currentMonthIndex = DateTime(now.year, now.month, 1)
        .difference(DateTime(now.year, now.month - 11, 1))
        .inDays ~/
        30;

    final double initialScrollOffset =
        currentMonthIndex * 80.0; // Adjust based on your item width

    // Define the ScrollController
    final ScrollController scrollController = ScrollController(
      initialScrollOffset: initialScrollOffset,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: scrollController, // Use the ScrollController
      child: Container(
        width: spots.length * 90.0,
        // Adjust width based on number of data points
        height: 220,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      final style = GrpahBottomTilesGrey2;
                      final int index = value.toInt();
                      if (index >= 0 && index < titles.length) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(titles[index], style: style),
                        );
                      }
                      return Container();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: false,
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: selectedFilter == 'This Week'
                      ? _getSpotsForCurrentWeek()
                      : spots,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  barWidth: 1,
                  color: Blue,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: false,
                    getDotPainter: (spot, delta, lineBarData, index) {
                      return FlDotCirclePainter(radius: 4, color: Blue);
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: gradientColors
                          .map((color) => color.withOpacity(0.1))
                          .toList(),
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 8,
                  fitInsideVertically: true,
                  getTooltipItems: (List<LineBarSpot> lineBarsSpot) {
                    return lineBarsSpot.map((lineBarSpot) {
                      return LineTooltipItem(
                        '${lineBarSpot.y.toStringAsFixed(2)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
                touchCallback:
                    (FlTouchEvent event, LineTouchResponse? touchResponse) {
                  // You can add custom touch handling here if needed
                },
                handleBuiltInTouches: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SlideTransition(
        position: Tween<Offset>(
          begin: Offset.zero,
          end: Offset(0.3, 0), // Adjust this value to control how far it slides
        ).animate(CurvedAnimation(
          parent: _sliderDrawerKey.currentState?.animationController ?? AnimationController(vsync: this, duration: Duration.zero),
          curve: Curves.easeInOut,
        )),
        child: Container(
          width: 228,
          height: 54,
          child: GestureDetector(
            child: ElevatedButton(
              onPressed: (){  Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeftJoined,
                  isIos: true,
                  childCurrent: widget,
                  duration: Duration(milliseconds: 800),
                  reverseDuration: Duration(milliseconds: 800),
                  child: AddExpenseScreen(
                    tableName: _tableNames,
                  ),
                ),
              );},
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF0D43FF)),
              ),
              child: Center(
                child: Text(
                  'Add Expense',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ),

      body: SliderDrawer(
        key: _sliderDrawerKey,
        appBar: CustomAppBar2(
          onMenuClicked: () {
            _sliderDrawerKey.currentState?.toggle();
          },
          title: _tableNames,
        ),
        slider: SliderMenu(
          onItemSelected: _onSliderItemSelected,
          selectedTableName: _tableNames,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            var maxWidth = constraints.maxWidth;
            var maxHeight = constraints.maxHeight;

            return SingleChildScrollView(

              child: Center(
                  child: Column(
                    children: [
                      Container(
                        height: 46,

                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Gap(12),
                              FilterChip(
                                label: Text(
                                  "This Week",
                                  style: selectedFilter == 'This Week'
                                      ? DaysTextBodyBlack
                                      : DaysTextBodyGrey,
                                ),
                                selected: selectedFilter == 'This Week',
                                selectedColor: Grey3,
                                backgroundColor: White,
                                showCheckmark: false,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  side: BorderSide(
                                    color: Colors.white,
                                  ),
                                ),
                                onSelected: (bool value) {
                                  HapticFeedback
                                      .mediumImpact(); // Add haptic feedback

                                  setState(() {
                                    selectedFilter = 'This Week';
                                  });
                                  _calculateTotalAmountForCurrentWeek();
                                },
                              ),
                              Gap(8),
                              FilterChip(
                                label: Text(
                                  "1 Month",
                                  style: selectedFilter == '1 Month'
                                      ? DaysTextBodyBlack
                                      : DaysTextBodyGrey,
                                ),
                                selected: selectedFilter == '1 Month',
                                selectedColor: Grey3,
                                backgroundColor: White,
                                showCheckmark: false,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  side: BorderSide(
                                    color: Colors.white,
                                  ),
                                ),
                                onSelected: (bool value) {
                                  HapticFeedback
                                      .mediumImpact(); // Add haptic feedback
                                  setState(() {
                                    selectedFilter = '1 Month';
                                  });
                                  _calculateTotalAmountForCurrentMonth();
                                },
                              ),
                              Gap(8),
                              FilterChip(
                                label: Text(
                                  "3 Months",
                                  style: selectedFilter == '3 Months'
                                      ? DaysTextBodyBlack
                                      : DaysTextBodyGrey,
                                ),
                                selected: selectedFilter == '3 Months',
                                selectedColor: Grey3,
                                backgroundColor: White,
                                showCheckmark: false,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  side: BorderSide(
                                    color: Colors.white,
                                  ),
                                ),
                                onSelected: (bool value) {
                                  HapticFeedback
                                      .mediumImpact(); // Add haptic feedback

                                  setState(() {
                                    selectedFilter = '3 Months';
                                  });
                                  _calculateTotalAmountForLast3Months();
                                },
                              ),
                              Gap(8),
                              FilterChip(
                                label: Text(
                                  "6 Months",
                                  style: selectedFilter == '6 Months'
                                      ? DaysTextBodyBlack
                                      : DaysTextBodyGrey,
                                ),
                                selected: selectedFilter == '6 Months',
                                selectedColor: Grey3,
                                backgroundColor: White,
                                showCheckmark: false,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  side: BorderSide(
                                    color: Colors.white,
                                  ),
                                ),
                                onSelected: (bool value) {
                                  HapticFeedback
                                      .mediumImpact(); // Add haptic feedback

                                  setState(() {
                                    selectedFilter = '6 Months';
                                  });
                                  _calculateTotalAmountForLast6Months();
                                },
                              ),
                              Gap(8),
                              FilterChip(
                                label: Text(
                                  "All",
                                  style: selectedFilter == 'All'
                                      ? DaysTextBodyBlack
                                      : DaysTextBodyGrey,
                                ),
                                selected: selectedFilter == 'All',
                                selectedColor: Grey3,
                                backgroundColor: White,
                                showCheckmark: false,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  side: BorderSide(
                                    color: Colors.white,
                                  ),
                                ),
                                onSelected: (bool value) {
                                  HapticFeedback
                                      .mediumImpact(); // Add haptic feedback

                                  setState(() {
                                    selectedFilter = 'All';
                                  });
                                  _calculateTotalAmountForAll();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),


                      if (selectedFilter == 'This Week')
                        Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Column(
                              children: [
                                // Current week date display
                                Text(
                                  'Total - ${_getCurrentWeekDateRange()}',
                                  style: NotesBodyGrey2,
                                ),
                                Text('${_totalAmountWeek.toStringAsFixed(0)}',
                                    style: TotalAmountBold),
                                SizedBox(height: 10),
                                buildLineChartContainerWeek(),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: _weekExpenses.length,
                                  itemBuilder: (context, index) {
                                    var groupedExpense = _weekExpenses[index];
                                    var expenses = groupedExpense['expenses'];
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Text(
                                            '${DateFormat('d MMMM').format(
                                                _parseDate(
                                                    groupedExpense['date']))}',
                                            style: H1BlackBold,
                                          ),
                                        ),
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics: NeverScrollableScrollPhysics(),
                                          itemCount: expenses.length,
                                          itemBuilder: (context, expenseIndex) {
                                            var expense = expenses[expenseIndex];
                                            return ListTile(

                                              title: Row(
                                                children: [
                                                  expense['categoryIcon'] !=
                                                      null &&
                                                      expense['categoryIcon']
                                                          .isNotEmpty
                                                      ? SvgPicture.asset(
                                                    expense['categoryIcon'],
                                                    width: 50,
                                                    height: 50,
                                                    fit: BoxFit.cover,
                                                  )
                                                      : Icon(Icons.category),
                                                  Gap(12),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment
                                                        .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            ' ${expense['category']}',
                                                            style: H1Normal,
                                                          ),
                                                          Gap(10),
                                                          expense['imageUrl'] !=
                                                              null &&
                                                              expense['imageUrl']
                                                                  .isNotEmpty
                                                              ? SvgPicture
                                                              .asset(
                                                            ListImageReceipt,
                                                            width: 12,
                                                            height: 22,
                                                            fit: BoxFit.cover,
                                                          )
                                                              : Text(""),
                                                        ],
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets
                                                            .only(left: 8),
                                                        child: Text(
                                                          expense['note']
                                                              ?.toString() ??
                                                              'No Notes',
                                                          style: DaysTextBodyGrey2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Gap(12),
                                                ],
                                              ),

                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '${expense['amount']
                                                        .toInt()}',
                                                    // Change this line
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight
                                                          .bold,
                                                    ),
                                                  ),
                                                   IconButton(
                                                icon: Icon(Icons.delete, color: Colors.red),
                                                onPressed: () => _deleteExpense(expense['id']),
                                              ),


                                                ],
                                              ),


                                            );
                                          },
                                        ),

                                      ],
                                    );
                                  },
                                ),
                                Gap(50),


                              ],
                            )),
                      if (selectedFilter == '1 Month')
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Column(
                            children: [
                              // Current month date display
                              Text(
                                'Total - ${_getCurrentMonthDateRange()}',
                                style: NotesBodyGrey2,
                              ),
                              Text('${_totalAmountMonth.toStringAsFixed(0)}',
                                  style: TotalAmountBold),
                              SizedBox(height: 10),
                              buildLineChartContainerMonth(),
                              SizedBox(height: 10),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: _monthlyExpenses.length,
                                itemBuilder: (context, index) {
                                  var CurrentMonthgroupedExpenses =
                                  _monthlyExpenses[index];
                                  var expenses =
                                  CurrentMonthgroupedExpenses['expenses'];
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Text(
                                          '  ${DateFormat('d MMMM').format(
                                              _parseDate(
                                                  CurrentMonthgroupedExpenses['date']))}',
                                          style: H1BlackBold,
                                        ),
                                      ),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: expenses.length,
                                        itemBuilder: (context, expenseIndex) {
                                          var expense = expenses[expenseIndex];
                                          return ListTile(
                                            title: Row(
                                              children: [
                                                expense['categoryIcon'] !=
                                                    null &&
                                                    expense['categoryIcon']
                                                        .isNotEmpty
                                                    ? SvgPicture.asset(
                                                  expense['categoryIcon'],
                                                  width: 50,
                                                  height: 50,
                                                  fit: BoxFit.cover,
                                                )
                                                    : Icon(Icons.category),
                                                Gap(12),
                                                Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          ' ${expense['category']}',
                                                          style: H1Normal,
                                                        ),
                                                        Gap(10),
                                                        expense['imageUrl'] !=
                                                            null &&
                                                            expense['imageUrl']
                                                                .isNotEmpty
                                                            ? SvgPicture.asset(
                                                          ListImageReceipt,
                                                          width: 12,
                                                          height: 22,
                                                          fit: BoxFit.cover,
                                                        )
                                                            : Text(""),
                                                      ],
                                                    ),
                                                    Padding(
                                                      padding:
                                                      const EdgeInsets.only(
                                                          left: 8),
                                                      child: Text(
                                                        expense['note']
                                                            ?.toString() ??
                                                            'No Notes',
                                                        style: DaysTextBodyGrey2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Gap(12),
                                              ],
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '${expense['amount']
                                                      .toInt()}',
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight
                                                          .bold),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                              Gap(70),

                            ],
                          ),
                        ),
                      if (selectedFilter == '3 Months')
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Column(
                            children: [
                              Text(
                                'Total - ${_getPastThreeMonthsDateRange()}',
                                style: NotesBodyGrey2,
                              ),
                              Text(
                                '${_totalAmountMonth.toStringAsFixed(0)}',
                                style: TotalAmountBold,
                              ),
                              SizedBox(height: 10),
                              buildLineChartContainer3Months(),
                              ListView.builder(
                                physics: NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: _threeMonthExpenses.length,
                                itemBuilder: (context, index) {
                                  var monthData = _threeMonthExpenses[index];
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Text(
                                          '${monthData['month']} ${monthData['year']}',
                                          style: H1BlackBold,
                                        ),

                                      ),
                                      ...monthData['expenses']
                                          .map<Widget>((expense) {
                                        return ListTile(
                                          title: Row(
                                            children: [
                                              expense['categoryIcon'] != null &&
                                                  expense['categoryIcon']
                                                      .isNotEmpty
                                                  ? SvgPicture.asset(
                                                expense['categoryIcon'],
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                              )
                                                  : Icon(Icons.category),
                                              SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${expense['category']}',
                                                    style: H1Normal,
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .only(
                                                        left: 4),
                                                    child: Text(
                                                      ' ${expense['count']} Transactions',
                                                      style: DaysTextBodyGrey2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          trailing: Text(
                                            ' ${expense['total'].toInt()}',
                                            style: H1BlackBold,
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  );
                                },
                              ),
                              Gap(70),

                            ],
                          ),
                        ),
                      if (selectedFilter == '6 Months')
                        Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Column(
                            children: [
                              Text(
                                'Total - ${_getPast6MonthsDateRange()}',
                                style: NotesBodyGrey2,
                              ),
                              Text('${_totalAmount6Months.toStringAsFixed(0)}',
                                  style: TotalAmountBold),
                              SizedBox(height: 10),
                              buildLineChartContainer6Months(),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: _sixMonthExpenses.length,
                                itemBuilder: (context, index) {
                                  var expense = _sixMonthExpenses[index];
                                  return ListTile(
                                    title: Text(
                                      '${expense['month']}',
                                      style: H1NormalSemi,
                                    ),
                                    subtitle: Text(
                                      '${expense['recordCounts']} Transactions',
                                      style: DaysTextBodyGrey2,
                                    ),
                                    trailing: Text(
                                      '${expense['total'].toInt()}',
                                      style: H1BlackBold,
                                    ),
                                  );
                                },
                              ),
                              Gap(70),

                            ],
                          ),
                        ),
                      if (selectedFilter == 'All')
                        Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Column(
                            children: [
                              Text(
                                'Total - ${_getPastAllDateRange()}',
                                style: NotesBodyGrey2,
                              ),
                              Text(
                                '${_totalAmount6Months.toStringAsFixed(0)}',
                                style: TotalAmountBold,
                              ),
                              SizedBox(height: 20),
                              buildLineChartContainerAll(),
                              SizedBox(height: 10),
                              ListView.builder(
                                physics: NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: _sixMonthExpenses.length,
                                itemBuilder: (context, index) {
                                  var expense = _sixMonthExpenses[index];
                                  return ListTile(
                                    title: Text(
                                      '${expense['month']}',
                                      style: H1NormalSemi,
                                    ),
                                    subtitle: Text(
                                      '${expense['recordCounts']} Transactions',
                                      style: DaysTextBodyGrey2,
                                    ),
                                    trailing: Text(
                                      '${expense['total'].toInt()}',
                                      style: H1BlackBold,
                                    ),
                                  );
                                },
                              ),
                              Gap(70),

                            ],
                          ),
                        ),


                    ],
                  )),
            );
          },
        ),
      ),
    );
  }
}
