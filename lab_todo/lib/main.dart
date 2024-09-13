import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart'; // นำเข้าไฟล์ firebase_options.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // ใช้ DefaultFirebaseOptions สำหรับการตั้งค่า Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: const TodaApp(),
    );
  }
}

class TodaApp extends StatefulWidget {
  const TodaApp({
    super.key,
  });

  @override
  State<TodaApp> createState() => _TodaAppState();
}

class _TodaAppState extends State<TodaApp> {
  late TextEditingController _texteditController;
  late TextEditingController _descriptionController;

  final List<String> _myList = [];
  @override
  void initState() {
    super.initState();
    _texteditController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  void addTodoHandle(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Add new task"),
            content: SizedBox(
              width: 120,
              height: 140,
              child: Column(
                children: [
                  TextField(
                    controller: _texteditController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Input your task"),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), labelText: "Description"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    // เพิ่มข้อมูลลงใน collection "tasks" ใน Firestore พร้อมสถานะเริ่มต้นเป็น false
                    CollectionReference tasks =
                        FirebaseFirestore.instance.collection("tasks");
                    tasks.add({
                      'name': _texteditController.text,
                      'note': _descriptionController.text,
                      'status': false, // สถานะเริ่มต้นของงาน
                    }).then((res) {
                      print('Task added: $res');
                    }).catchError((onError) {
                      print("Failed to add new Task: $onError");
                    });
                    setState(() {
                      _myList.add(_texteditController.text);
                    });
                    _texteditController.text = "";
                    _descriptionController.text = "";
                    Navigator.pop(context);
                  },
                  child: const Text("Save"))
            ],
          );
        });
  }

  // ฟังก์ชันสำหรับแก้ไขข้อมูล
  void editTodoHandle(BuildContext context, DocumentSnapshot task) {
    // ใช้ค่าเดิมสำหรับการแก้ไข
    _texteditController.text = task['name'];
    _descriptionController.text = task['note'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit task"),
          content: SizedBox(
            width: 120,
            height: 140,
            child: Column(
              children: [
                TextField(
                  controller: _texteditController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Edit your task",
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Edit Description",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // อัปเดตงานใน Firestore
                FirebaseFirestore.instance
                    .collection("tasks")
                    .doc(task.id)
                    .update({
                  'name': _texteditController.text,
                  'note': _descriptionController.text,
                }).then((res) {
                  print('Task updated');
                }).catchError((onError) {
                  print("Failed to update task: $onError");
                });
                Navigator.pop(context);
              },
              child: const Text("Update"),
            )
          ],
        );
      },
    );
  }

  // ฟังก์ชันสำหรับลบข้อมูล
  void deleteTodoHandle(BuildContext context, DocumentSnapshot task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete task"),
          content: const Text("Are you sure you want to delete this task?"),
          actions: [
            TextButton(
              onPressed: () {
                // ลบงานจาก Firestore
                FirebaseFirestore.instance
                    .collection("tasks")
                    .doc(task.id)
                    .delete()
                    .then((res) {
                  print('Task deleted');
                }).catchError((onError) {
                  print("Failed to delete task: $onError");
                });
                Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
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
        title: const Text("Todo"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection("tasks").snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data?.docs.isEmpty == true) {
              return const Center(child: Text("No tasks available"));
            }
            return ListView.builder(
              itemCount: snapshot.data?.docs.length,
              itemBuilder: (context, index) {
                var task = snapshot.data?.docs[index];

                if (task == null || task.data() == null) {
                  return const ListTile(
                    title: Text("Invalid task"),
                  );
                }

                var taskData = task.data() as Map<String, dynamic>;
                var taskName = taskData.containsKey("name") ? taskData["name"] : "No name";
                var taskNote = taskData.containsKey("note") ? taskData["note"] : "No description available";
                var taskStatus = taskData.containsKey("status") && taskData["status"] is bool
                    ? taskData["status"] as bool
                    : false;

                return ListTile(
                  title: Text(taskName),
                  subtitle: Text(taskNote),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          // เรียกฟังก์ชันแก้ไข
                          editTodoHandle(context, task);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          // เรียกฟังก์ชันลบ
                          deleteTodoHandle(context, task);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          taskStatus
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                        ),
                        onPressed: () {
                          // อัปเดตสถานะของงานใน Firestore
                          FirebaseFirestore.instance
                              .collection("tasks")
                              .doc(task.id)
                              .update({
                            'status': !taskStatus,
                          }).then((res) {
                            print('Task status updated');
                          }).catchError((onError) {
                            print("Failed to update task status: $onError");
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addTodoHandle(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
