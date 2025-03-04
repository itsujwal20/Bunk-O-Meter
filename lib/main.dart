import 'package:flutter/material.dart';
import 'dart:math';
import 'subject_entry_page.dart'; // Import the SubjectEntryPage file
import 'splash_screen.dart'; // Import your splash screen

void main() {
  runApp(BunkOMeterApp());
}

class BunkOMeterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // Start with the splash screen
    );
  }
}


class AttendanceCalculator extends StatefulWidget {
  @override
  _AttendanceCalculatorState createState() => _AttendanceCalculatorState();
}

class _AttendanceCalculatorState extends State<AttendanceCalculator> {
  final TextEditingController attendedController = TextEditingController();
  final TextEditingController conductedController = TextEditingController();
  final TextEditingController upcomingController = TextEditingController();
  final TextEditingController currentDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController weeklyClassesController = TextEditingController();
  final TextEditingController labSessionsController = TextEditingController();
  final TextEditingController attendancePercentageController = TextEditingController();

  List<Subject> subjects = [];
  bool showSubjectWise = false;
  bool knowsUpcomingClasses = false;
  bool willingToBunkLabs = false;
  int upcoming = 0;
  double requiredPercentage = 75.0;
  int totalBunkable = 0;

  void resetFields() {
    setState(() {
      attendedController.clear();
      conductedController.clear();
      upcomingController.clear();
      currentDateController.clear();
      endDateController.clear();
      weeklyClassesController.clear();
      labSessionsController.clear();
      attendancePercentageController.clear();

      knowsUpcomingClasses = false;
      willingToBunkLabs = false;
      upcoming = 0;
      totalBunkable = 0;
      subjects.clear();  // Clears subject list as well
    });
  }

  void _showSubjectStrategyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Subject-wise Bunking Strategy"),
          content: Text("Here, we will calculate the subject-wise bunking strategy."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close dialog
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  int calculateUpcomingClasses(int cDay, int cMonth, int cYear, int eDay, int eMonth, int eYear, int weeklyClasses) {
    if (weeklyClasses <= 0) {
      throw Exception("Error: Number of weekly classes must be greater than zero.");
    }

    DateTime currentDate = DateTime(cYear, cMonth, cDay);
    DateTime endDate = DateTime(eYear, eMonth, eDay);

    if (currentDate.isAfter(endDate)) {
      throw Exception("Error: Semester end date cannot be before the current date.");
    }

    int daysRemaining = endDate.difference(currentDate).inDays;
    return max(0, (daysRemaining / 7).floor() * weeklyClasses);
  }



  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Result"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  List<int> _parseDate(String date) {
    if (date.length != 8 || int.tryParse(date) == null) {
      throw Exception("Invalid date format. Use DDMMYYYY.");
    }

    int day = int.parse(date.substring(0, 2));
    int month = int.parse(date.substring(2, 4));
    int year = int.parse(date.substring(4, 8));

    try {
      DateTime validDate = DateTime(year, month, day);
      return [validDate.day, validDate.month, validDate.year];
    } catch (e) {
      throw Exception("Invalid date. Please enter a valid date in DDMMYYYY format.");
    }
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.005),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9, // Adjust width dynamically
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
      ),
    );
  }

  void calculateBunkableClasses() {
    int attended = int.tryParse(attendedController.text) ?? 0;
    int conducted = int.tryParse(conductedController.text) ?? 0;

    if (attended > conducted) {
      _showError("Error: Attended classes cannot be greater than conducted classes.");
      return;
    }

    requiredPercentage = double.tryParse(attendancePercentageController.text) ?? 75.0;
    int weeklyClasses = int.tryParse(weeklyClassesController.text) ?? 0;
    int weeklyLabs = int.tryParse(labSessionsController.text) ?? 0;

    setState(() {
      if (!knowsUpcomingClasses) {
        try {
          List<int> currentDate = _parseDate(currentDateController.text);
          List<int> endDate = _parseDate(endDateController.text);

          upcoming = calculateUpcomingClasses(
              currentDate[0], currentDate[1], currentDate[2],
              endDate[0], endDate[1], endDate[2], weeklyClasses
          );
        } catch (_) {
          _showError("Invalid date format (DDMMYYYY)");
          return;
        }
      } else {
        upcoming = int.tryParse(upcomingController.text) ?? 0;
      }
    });

    totalBunkable = 0;
    int weeksRemaining = (upcoming / weeklyClasses).floor();
    int totalLabClasses = weeksRemaining * weeklyLabs;

    if (!willingToBunkLabs) {
      upcoming -= totalLabClasses;
      if (totalLabClasses > 0) {
        _showMessage("Total lab classes are mandatory and cannot be bunked: $totalLabClasses");
      }
    }

    int totalClasses = conducted + upcoming;
    int minAttendanceRequired = ((requiredPercentage / 100) * totalClasses).ceil();
    totalBunkable = max(0, attended + upcoming - minAttendanceRequired);

    if (totalBunkable <= 0) {
      _showMessage("You cannot bunk any classes.");
    } else {
      _showBunkableDialog(totalBunkable);
    }
  }


  void _showBunkableDialog(int bunkableClasses) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Bunkable Classes",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20), // Bigger & Bold Title
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "These are the $bunkableClasses classes you can bunk.",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), // Make text bold
              ),
              SizedBox(height: 16),
              Text(
                "Do you need a subject-wise bunking strategy?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), // Make text bold
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubjectEntryPage(bunkableClasses: bunkableClasses),
                        ),
                      );
                    },
                    child: Text("Yes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), // Bold Button Text
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      resetFields(); // Reset data if "No" is selected
                    },
                    child: Text("No", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), // Bold Button Text
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bunk-O-Meter")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(attendedController, "Total classes attended"),
                _buildTextField(conductedController, "Total classes conducted"),
                SwitchListTile(
                  title: Text("Do you know the total number of upcoming classes?"),
                  value: knowsUpcomingClasses,
                  onChanged: (value) => setState(() => knowsUpcomingClasses = value),
                ),
                if (knowsUpcomingClasses)
                  _buildTextField(upcomingController, "Enter total upcoming classes"),
                if (!knowsUpcomingClasses) ...[
                  _buildTextField(currentDateController, "Enter current date (DDMMYYYY)"),
                  _buildTextField(endDateController, "Enter semester end date (DDMMYYYY)"),
                ],
                _buildTextField(weeklyClassesController, "Enter number of classes per week"),
                SwitchListTile(
                  title: Text("Are you willing to bunk labs?"),
                  value: willingToBunkLabs,
                  onChanged: (value) => setState(() => willingToBunkLabs = value),
                ),
                _buildTextField(labSessionsController, "Enter number of lab sessions per week"),
                _buildTextField(attendancePercentageController, "Enter required attendance percentage"),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: calculateBunkableClasses,
                  child: Text("Calculate Bunkable Classes"),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: resetFields,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text("Reset", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
      ),
    );
  }
}

class Subject {
  String name;
  int attended;
  int conducted;

  Subject({this.name = "", this.attended = 0, this.conducted = 0});
}