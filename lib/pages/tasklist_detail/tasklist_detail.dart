import 'package:ametask/models/ametask_color.dart';
import 'package:ametask/models/tasklists_model.dart';
import 'package:ametask/pages/tasklist_detail/widgets/bottom_bar.dart';
import 'package:ametask/pages/tasklist_detail/widgets/delete_button.dart';
import 'package:ametask/pages/tasklist_detail/widgets/info_button.dart';
import 'package:ametask/pages/tasklist_detail/widgets/save_button.dart';
import 'package:flutter/material.dart';
import 'package:ametask/db/database.dart';
import 'package:ametask/pages/tasklist_detail/widgets/tasks_list.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailTasklist extends StatefulWidget {
  final int tasklistId;

  const DetailTasklist({
    Key? key,
    required this.tasklistId,
  }) : super(key: key);

  @override
  State<DetailTasklist> createState() => _DetailTasklistState.initState();
}

class _DetailTasklistState extends State<DetailTasklist> {
  late Tasklist tasklist;
  late int numTasks;
  late int numTasksRemaining;
  bool isLoading = false;
  bool isEdited = false;

  _DetailTasklistState.initState();

  @override
  void initState() {
    super.initState();

    refreshTasklist();
  }

  goBack() {
    Navigator.of(context).pop();
  }

  Future refreshTasklist() async {
    setState(() => isLoading = true);

    tasklist = await AmetaskDatabase.instance.readTasklist(widget.tasklistId);
    numTasks =
        await AmetaskDatabase.instance.countAllTasksFor(widget.tasklistId);
    numTasksRemaining = numTasks -
        await AmetaskDatabase.instance
            .countAllFinishedTasksFor(widget.tasklistId);

    setState(() => isLoading = false);
  }

  saveTasklist() {
    tasklist = tasklist.copy(lastModifDate: DateTime.now());
    AmetaskDatabase.instance.updateTasklist(tasklist);
    isEdited = false;
    refreshTasklist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AmetaskColors.bg1,
      appBar: AppBar(
        title: Text(
          isLoading ? "loading..." : tasklist.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AmetaskColors.bg2,
        foregroundColor: AmetaskColors.white,
        actions: <Widget>[
          isEdited
              ? SaveButton(callback: saveTasklist)
              : InfoTLButton(
                  tasklistId: widget.tasklistId,
                ),
          DeleteTLButton(
            tasklistId: widget.tasklistId,
            context: context,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: TextFormField(
                    minLines: 1,
                    maxLines: 2,
                    keyboardType: TextInputType.text,
                    initialValue: tasklist.name,
                    style: GoogleFonts.poppins(
                        fontSize: 23,
                        color: AmetaskColors.white,
                        fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      fillColor: AmetaskColors.bg3,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          width: 10,
                          color: AmetaskColors.red,
                          style: BorderStyle.solid,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      hintText: "Title",
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 23,
                        color: AmetaskColors.white.withOpacity(0.3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onChanged: (String value) async {
                      tasklist = tasklist.copy(name: value);
                      setState(() {
                        isEdited = true;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: TextFormField(
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    initialValue: tasklist.description,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AmetaskColors.white,
                    ),
                    decoration: InputDecoration(
                      fillColor: AmetaskColors.bg3,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      hintText: "Desciption",
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AmetaskColors.white.withOpacity(0.3),
                      ),
                    ),
                    onChanged: (String value) async {
                      tasklist = tasklist.copy(description: value);

                      setState(() {
                        isEdited = true;
                      });
                    },
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Text(
                    "Tasks :",
                    style: GoogleFonts.poppins(
                        color: AmetaskColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                const Divider(height: 3, color: AmetaskColors.discretLine2),
                TasksList(
                  tasklist: tasklist,
                ),
                BottomTaskslistBar(
                    tasklistId: widget.tasklistId,
                    father: widget,
                    callback: refreshTasklist)
              ],
            ),
    );
  }
}
