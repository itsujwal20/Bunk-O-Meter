import 'package:flutter/material.dart';

class SubjectEntryPage extends StatefulWidget {
  final int bunkableClasses;

  SubjectEntryPage({required this.bunkableClasses});

  @override
  _SubjectEntryPageState createState() => _SubjectEntryPageState();
}

class _SubjectEntryPageState extends State<SubjectEntryPage> {
  int numSubjects = 0;
  List<TextEditingController> subjectControllers = [];
  List<TextEditingController> attendedControllers = [];
  List<TextEditingController> conductedControllers = [];
  String errorMessage = "";

  void generateSubjects() {
    subjectControllers = List.generate(numSubjects, (_) => TextEditingController());
    attendedControllers = List.generate(numSubjects, (_) => TextEditingController());
    conductedControllers = List.generate(numSubjects, (_) => TextEditingController());
    setState(() {});
  }

  @override
  void dispose() {
    for (var controller in subjectControllers) {
      controller.dispose();
    }
    for (var controller in attendedControllers) {
      controller.dispose();
    }
    for (var controller in conductedControllers) {
      controller.dispose();
    }
    subjectControllers.clear();
    attendedControllers.clear();
    conductedControllers.clear();
    super.dispose();
  }

  void validateAndGeneratePlan() {
    if (numSubjects <= 0) {
      setState(() {
        errorMessage = "Error: Enter a valid number of subjects!";
      });
      return;
    }

    bool hasError = false;
    errorMessage = "";
    List<Map<String, dynamic>> subjects = [];

    for (int i = 0; i < numSubjects; i++) {
      String subjectName = subjectControllers[i].text.trim();
      String attendedText = attendedControllers[i].text.trim();
      String conductedText = conductedControllers[i].text.trim();

      if (subjectName.isEmpty || attendedText.isEmpty || conductedText.isEmpty) {
        setState(() {
          errorMessage = "Error: Enter all input fields!";
        });
        hasError = true;
        break;
      }

      int? attended = int.tryParse(attendedText);
      int? conducted = int.tryParse(conductedText);

      if (attended == null || conducted == null || conducted == 0) {
        setState(() {
          errorMessage = "Error: Enter valid numeric values!";
        });
        hasError = true;
        break;
      }

      if (attended > conducted) {
        setState(() {
          errorMessage = "Error: Attended classes cannot be greater than conducted classes!";
        });
        hasError = true;
        break;
      }

      double attendancePercentage = (attended / conducted) * 100;
      subjects.add({
        "name": subjectName,
        "attended": attended,
        "conducted": conducted,
        "attendancePercentage": attendancePercentage,
      });
    }

    if (hasError) {
      return;
    }

    subjects.sort((a, b) => b["attendancePercentage"].compareTo(a["attendancePercentage"]));

    int remainingBunks = widget.bunkableClasses;
    List<String> bunkPlan = [];
    int totalWeight = subjects.fold(0, (sum, subject) => sum + (subject["attendancePercentage"] as double).toInt());

    if (totalWeight == 0) {
      setState(() {
        errorMessage = "Error: Attendance percentages cannot all be zero!";
      });
      return;
    }

    for (var subject in subjects) {
      int weight = subject["attendancePercentage"].toInt();
      int assignedBunks = ((weight / totalWeight) * widget.bunkableClasses).round();
      assignedBunks = assignedBunks.clamp(0, remainingBunks);
      remainingBunks -= assignedBunks;
      subject["bunks"] = assignedBunks;
    }

    int index = 0;
    while (remainingBunks > 0) {
      subjects[index % numSubjects]["bunks"] += 1;
      remainingBunks--;
      index++;
    }

    for (var subject in subjects) {
      int bunks = subject["bunks"] ?? 0;
      bunkPlan.add("${subject['name']}: Bunk up to $bunks classes.");
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Bunking Plan"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: bunkPlan.map((plan) => Text(
                plan,
                style: TextStyle(fontWeight: FontWeight.bold), // Make text bold
              )).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Enter Subject Details"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, null);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Enter number of subjects"),
              onChanged: (value) {
                setState(() {
                  numSubjects = int.tryParse(value) ?? 0;
                  generateSubjects();
                });
              },
            ),
            SizedBox(height: 10),
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(errorMessage, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: numSubjects,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Subject ${index + 1}", style: TextStyle(fontWeight: FontWeight.bold)),
                          TextField(
                            controller: subjectControllers[index],
                            decoration: InputDecoration(labelText: "Subject Name"),
                          ),
                          TextField(
                            controller: attendedControllers[index],
                            decoration: InputDecoration(labelText: "Classes Attended"),
                            keyboardType: TextInputType.number,
                          ),
                          TextField(
                            controller: conductedControllers[index],
                            decoration: InputDecoration(labelText: "Classes Conducted"),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            Text(
              "You can bunk ${widget.bunkableClasses} number of classes",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 10),

            SizedBox(height: 10),
            ElevatedButton(
              onPressed: validateAndGeneratePlan,
              child: Text("Generate Bunking Plan"),
            ),
          ],
        ),
      ),
    );
  }
}
