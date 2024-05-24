// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mynotes/constants/Routes.dart';
import 'package:mynotes/enums/menu_action.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/crud/notes_service.dart';

class MainUI extends StatelessWidget {
  const MainUI({super.key});

  @override
  Widget build(BuildContext context) {
    return const BackButtonExitApp();
  }
}

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  late final NotesService noteservice;
  final email = AuthService.firebase().currentUser!.email!;

  @override
  void initState() {
    noteservice = NotesService();
    super.initState();
  }

  @override
  void dispose() {
    noteservice.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Notes'),
        actions: [
          PopupMenuButton<MenuAction>(onSelected: (value) async {
            switch (value) {
              case MenuAction.logout:
                {
                  final logout = await showLogOutDialog(
                    context,
                  );
                  if (logout) {
                    await AuthService.firebase().logout();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      LoginRoute,
                      (route) => false,
                    );
                  }
                  break;
                }
            }
          }, itemBuilder: (context) {
            return const [
              PopupMenuItem<MenuAction>(
                value: MenuAction.logout,
                child: Text('Log out'),
              )
            ];
          })
        ],
      ),
      //Waiting to get or create user
      body: FutureBuilder(
        future: noteservice.getOrCreateUser(
          email: email,
        ),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              //When future is completed it moves to below code
              {
                //When changes in stream are detected and stream receives another
                //changes then based on those changes build is again executed
                //with new data received in stream and thats how the whole thing changes
                return StreamBuilder(
                  //Gets all notes in the stream
                  stream: noteservice.allNotes,
                  builder: (
                    context,
                    snapshot,
                  ) {
                    switch (snapshot.connectionState) {
                      //Waiting is used when stream is waiting for some data to
                      //pass through and active state is used when atleast one
                      //chunk of data is passing.
                      case ConnectionState.waiting:
                      case ConnectionState.active:
                        //As stream works like a pipe it will keep sending the data continuosly
                        //and so thats why we are using waiting connection state.
                        {
                          if (snapshot.hasData) {
                            final notes = snapshot.data as List<DatabaseNote>;
                            final size = notes.length;
                            return ListView.builder(
                              //ListView.Builder takes two parameters
                              //one is length of item
                              itemCount: size + 1,
                              //second is the builder and it iterates the length number of times
                              //and you can return a widget on each iteration
                              //after every iteration the widget is build downwards.
                              itemBuilder: (context, index) {
                                //Below this works like a loop
                                if (index < size) {
                                  final currentNote = notes[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        ListTile(
                                          onTap: () {
                                            Navigator.of(context).pushNamed(
                                                UpdateNoteRoute,
                                                arguments: currentNote);
                                          },
                                          title: Text(
                                            currentNote.text,
                                            maxLines: 1,
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          tileColor: const Color.fromARGB(
                                              243, 238, 240, 240),
                                          shape: RoundedRectangleBorder(
                                            side: const BorderSide(
                                              width: 0,
                                              color: Colors.white,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          trailing: IconButton(
                                            onPressed: () async {
                                              final delete =
                                                  await showDeleteDialog(
                                                      context);
                                              if (delete == true) {
                                                await noteservice.deleteNote(
                                                    id: currentNote.id);
                                              }
                                            },
                                            icon: const Icon(Icons.delete),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  return const SizedBox(
                                    height: 100,
                                  );
                                }
                              },
                            );
                          } else {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                        }
                      default:
                        return const Center(child: CircularProgressIndicator());
                    }
                  },
                );
              }
            default:
              return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).pushNamed(NewNoteRoute);
          },
          child: const Icon(
            Icons.add,
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class BackButtonExitApp extends StatefulWidget {
  const BackButtonExitApp({super.key});

  @override
  State<BackButtonExitApp> createState() => _BackButtonExitAppState();
}

class _BackButtonExitAppState extends State<BackButtonExitApp> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show an exit confirmation dialog
        return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Exit App'),
                content: const Text('Are you sure you want to exit the app?'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('No'),
                    onPressed: () {
                      Navigator.of(context).pop(false); // Prevents exit
                    },
                  ),
                  TextButton(
                    child: const Text('Yes'),
                    onPressed: () {
                      Navigator.of(context).pop(true); // Allows exit
                    },
                  ),
                ],
              ),
            ) ??
            false;
      },
      child: const NotesView(), // Your NotesView widget
    );
  }
}

//This displays a dialogue to user asking if they want to logout or not
Future<bool> showLogOutDialog(BuildContext context) {
  //To display the alert dialogue on the screen
  return showDialog<bool>(
    context: context,
    builder: (context) {
      // Aalert dialogue is the messege displayed on the screen
      return AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out'),
        //Further actions played by this alert dialogue
        actions: [
          TextButton(
              onPressed: () {
                //Navigator is a stack of screen , every screen that move to are stored in a stack.
                //The below line of code : Destroy the dialog from the screen and move back to the previous screen
                //and return the bool inside the pop(bool)
                Navigator.of(context).pop(false);
              },
              child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text("Log Out")),
        ],
      );
    },
    // The .then(value) is used to tell the flutter compiler what it will return to Future
    // When user ignores both the button , so in this case it return (null ?? false)
    //Because showDialog can return an optional boolian. Check further by going to ShowDialog class.
  ).then((value) => value ?? false);
}

Future<bool> showDeleteDialog(BuildContext context) {
  //To display the alert dialogue on the screen
  return showDialog<bool>(
    context: context,
    builder: (context) {
      // Aalert dialogue is the messege displayed on the screen
      return AlertDialog(
        title: const Text('Delete'),
        content: const Text('Are you sure you wanna delete this note ?'),
        //Further actions played by this alert dialogue
        actions: [
          TextButton(
              onPressed: () {
                //Navigator is a stack of screen , every screen that move to are stored in a stack.
                //The below line of code : Destroy the dialog from the screen and move back to the previous screen
                //and return the bool inside the pop(bool)
                Navigator.of(context).pop(false);
              },
              child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text("Yes")),
        ],
      );
    },
    // The .then(value) is used to tell the flutter compiler what it will return to Future
    // When user ignores both the button , so in this case it return (null ?? false)
    //Because showDialog can return an optional boolian. Check further by going to ShowDialog class.
  ).then((value) => value ?? false);
}
