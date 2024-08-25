import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../Utils/constants.dart';

class DatePicker extends StatefulWidget {
  final Function(DateTime) onDateSelected;

  DatePicker({required this.onDateSelected});

  @override
  _DatePickerState createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  DateTime? selectedDate;

  void _CalenderBottomSheet(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 500,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: Colors.white,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Calendar',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        Navigator.pop(context); // Close the bottom sheet
                      },
                      child: SvgPicture.asset(
                        CancelButton, // Replace with your cancel button asset
                        width: 48,
                        height: 48,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SfDateRangePicker(
                  backgroundColor: Colors.white,
                  todayHighlightColor: Blue,
                  headerStyle: DateRangePickerHeaderStyle(
                    backgroundColor: Colors.white,
                    textStyle: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  monthCellStyle: DateRangePickerMonthCellStyle(
                    textStyle: H1Normal,
                  ),
                  initialSelectedDate: selectedDate ?? DateTime.now(),
                  selectionShape: DateRangePickerSelectionShape.circle,
                  selectionColor: Blue,
                  onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                    setState(() {
                      selectedDate = args.value;
                      if (selectedDate != null) {
                        widget.onDateSelected(selectedDate!);
                        Navigator.pop(context); // Close the bottom sheet after selecting date
                      }
                    });
                  },
                  monthViewSettings: DateRangePickerMonthViewSettings(
                    dayFormat: 'EEE',
                    viewHeaderStyle: DateRangePickerViewHeaderStyle(
                      textStyle: DaysTextBodyGrey,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 60),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: () => _CalenderBottomSheet(context),
            child: Container(
              width: 200,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    Calender,
                    width: 18,
                    height: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    selectedDate != null
                        ? DateFormat.yMMMd().format(selectedDate!)
                        : DateFormat.yMMMd().format(DateTime.now()), // Show current date if selectedDate is null
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
