import 'package:flutter/material.dart';
import 'package:mynotes/services/crud/notes_service.dart';
import 'package:mynotes/utilities/ErrorDialog.dart';
import 'package:share_plus/share_plus.dart';

class UpdateNote extends StatefulWidget {
  const UpdateNote({super.key});

  @override
  State<UpdateNote> createState() => _UpdateNoteState();
}

class _UpdateNoteState extends State<UpdateNote> {
  String? textCheck;
  DatabaseNote? newNote;
  late final NotesService notesService;
  late final TextEditingController textController;
  @override
  initState() {
    notesService = NotesService();
    textController = TextEditingController();
    super.initState();
  }

  Future<DatabaseNote> getExistingNote(BuildContext context) async {
    final note = ModalRoute.of(context)!.settings.arguments as DatabaseNote;
    textController.text = note.text;
    textCheck = note.text;
    newNote = note;
    return note;
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
    if (note != null && text.isNotEmpty && text != textCheck) {
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
        title: const Text('Edit Note'),
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
        future: getExistingNote(context),
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
