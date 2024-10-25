import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:codelabmodul3/controller/widget_background.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/auth_controller.dart';

import 'package:codelabmodul3/controller/app_color.dart';
import 'package:codelabmodul3/controller/create_task_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});


  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> scaffoldState = GlobalKey<ScaffoldState>();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final AppColor appColor = AppColor();
  final AuthController _authController = Get.put(AuthController());
  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    double widthScreen = mediaQueryData.size.width;
    double heightScreen = mediaQueryData.size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              _authController.logout(); // Panggil fungsi logout ketika tombol ditekan.
            },
          ),
        ],
      ),
      key: scaffoldState,
      backgroundColor: appColor.colorPrimary,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            WidgetBackground(),
            _buildWidgetListTodo(widthScreen, heightScreen, context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          bool? result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateTaskScreen(isEdit: false),
            ),
          );

          if (result != null && result) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Task has been created'),
              ),
            );
            setState(() {});
          }
        },
        backgroundColor: appColor.colorTertiary,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  Container _buildWidgetListTodo(double widthScreen, double heightScreen,
      BuildContext context) {
    return Container(
      width: widthScreen,
      height: heightScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 16.0),
            child: Text(
              'Todo List',
              style: Theme.of(context).textTheme.titleLarge, // Update text style
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('tasks').orderBy('date').snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: snapshot.data!.docs.length, // Access docs safely
                  itemBuilder: (BuildContext context, int index) {
                    DocumentSnapshot document = snapshot.data!.docs[index]; // Access docs safely
                    Map<String, dynamic> task = document.data() as Map<String, dynamic>; // Type casting
                    String strDate = task['date'];

                    return Card(
                      child: ListTile(
                        title: Text(task['name']),
                        subtitle: Text(
                          task['description'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: false,
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 24.0,
                              height: 24.0,
                              decoration: BoxDecoration(
                                color: appColor.colorSecondary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${int.parse(strDate.split(' ')[0])}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              strDate.split(' ')[1],
                              style: const TextStyle(fontSize: 12.0),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (BuildContext context) {
                            return <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ];
                          },
                          onSelected: (String value) async {
                            if (value == 'edit') {
                              // TODO: fitur edit task
                              bool? result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateTaskScreen(
                                    isEdit: true,
                                    documentId: document.id,
                                    name: task['name'],
                                    description: task['description'],
                                    date: task['date'],
                                  ),
                                ),
                              );
                              if (result != null && result) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Task has been updated')),
                                );
                              }
                            } else if (value == 'delete') {
                              // TODO: fitur hapus task
                              bool confirmDelete = await showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Delete Task'),
                                    content: const Text('Are you sure you want to delete this task?'),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text('Cancel'),
                                        onPressed: () => Navigator.of(context).pop(false),
                                      ),
                                      TextButton(
                                        child: const Text('Delete'),
                                        onPressed: () => Navigator.of(context).pop(true),
                                      ),
                                    ],
                                  );
                                },
                              );

                              // Jika pengguna mengkonfirmasi penghapusan, hapus task dari Firestore
                              if (confirmDelete) {
                                await firestore.collection('tasks').doc(document.id).delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Task has been deleted')),
                                );
                              }
                            }
                          },
                          child: const Icon(Icons.more_vert),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
