import 'package:flutter/material.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/crud/notes_service.dart';
import 'package:mynotes/utilities/ErrorDialog.dart';
import 'package:share_plus/share_plus.dart';

class NewNote extends StatefulWidget {
  const NewNote({super.key});

  @override
  State<NewNote> createState() => _NewNoteState();
}

class _NewNoteState extends State<NewNote> {
  DatabaseNote? newNote;
  bool isBold = false;
  late final NotesService notesService;
  late final TextEditingController textController;
  @override
  initState() {
    notesService = NotesService();
    textController = TextEditingController();
    super.initState();
  }

  Future<DatabaseNote> createNewNote() async {
    final Note = newNote;
    if (Note != null) {
      return Note;
    } else {
      final user = AuthService.firebase().currentUser!;
      final email = user.email!;
      final owner = await notesService.getUser(email: email);
      final createdNote = await notesService.createNote(owner: owner);
      newNote = createdNote;
      return createdNote;
    }
  }

  void textControllerListner() async {
    final note = newNote;
    if (note == null) {
      return;
    }
    final text = textController.text;

    await notesService.updateNote(note: note, text: text);
  }

  void setUpListner() {
    textController.removeListener(textControllerListner);
    textController.addListener(textControllerListner);
  }

  void deleteNoteIfTextIsEmpty() async {
    //If upon the termination of this view the text is empty then don't save the note
    final note = newNote;
    if (textController.text.isEmpty && note != null) {
      await notesService.deleteNote(id: note.id);
    }
  }

  void saveNotesUponDispose() async {
    final note = newNote;
    final text = textController.text;
    if (note != null && text.isNotEmpty) {
      await notesService.updateNote(note: note, text: text);
    }
  }

  @override
  void dispose() {
    deleteNoteIfTextIsEmpty();
    saveNotesUponDispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
        actions: [
          IconButton(
              onPressed: () async {
                final text = textController.text;
                if (text.isEmpty) {
                  await showErrorDialog(
                      context, "You can not share empty note");
                } else {
                  Share.share(text);
                }
              },
              icon: const Icon(Icons.share)),
          IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.done))
        ],
      ),
      body: FutureBuilder(
        future: createNewNote(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              {
                setUpListner();
                return Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: textController,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    decoration: const InputDecoration(
                        hintText: 'Start Typing',
                        border:
                            OutlineInputBorder(borderSide: BorderSide.none)),
                  ),
                );
              }
            default:
              {
                return const Center(child: CircularProgressIndicator());
              }
          }
        },
      ),
    );
  }
}
