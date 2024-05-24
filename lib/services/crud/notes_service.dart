// ignore_for_file: non_constant_identifier_names, no_leading_underscores_for_local_identifiers
import 'dart:async';

import 'package:mynotes/services/crud/crud_constants.dart';
import 'package:mynotes/services/crud/crud_exceptions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class NotesService {
  Database? db;
  DatabaseUser? user;
  List<DatabaseNote> notes = [];
  late final StreamController<List<DatabaseNote>> notesStreamController;
  // To create the single instance of notes service
  // As we have used static so this will only have one instance which is class instance and
  //It will only share one memory location for the whole class .
  //we are using the final keyword so that the _shared is only initialized once and can not be
  //reinitialized.
  //and _ is used to make shared private.
  //In simple words it creates one object and locks it , so that no other objects can't be made
  static final _shared = NotesService._sharedInstance();
  //Named private constructor
  NotesService._sharedInstance() {
    notesStreamController =
        StreamController<List<DatabaseNote>>.broadcast(onListen: () {
      notesStreamController.sink.add(notes);
    });
  }
  //factory public constructor
  factory NotesService() => _shared;

  //Takes all the notes and send it to stream controller
  Future<void> sendAllNotes() async {
    final n = await getAllNotes();
    notes = n;
    notesStreamController.add(notes);
  }

  Stream<List<DatabaseNote>> get allNotes => notesStreamController.stream;

  Future<DatabaseUser> getOrCreateUser({required String email}) async {
    try {
      final existedUser = await getUser(email: email);
      user = existedUser;
      await sendAllNotes();
      return existedUser;
    } on CouldNotFindTheUser {
      final createdUser = await createUser(email: email);
      user = createdUser;
      await sendAllNotes();
      return createdUser;
    }
  }

  Future<DatabaseNote> updateNote(
      {required DatabaseNote note, required String text}) async {
    await ensureDBisOpen();
    final DB = getDatabaseOrThrow();
    await getSpecificNote(id: note.id);
    final result = await DB.update(
        noteTable,
        {
          textColumn: text,
          issyncedColumn: 0,
        },
        where: 'id = ?',
        whereArgs: [note.id]);
    if (result == 0) {
      throw CouldNotUpdateNote();
    } else {
      final updatedNote = await getSpecificNote(id: note.id);
      notes.removeWhere((n) => n.id == note.id);
      notes.add(updatedNote);
      notesStreamController.add(notes);
      return updatedNote;
    }
  }

  Future<List<DatabaseNote>> getAllNotes() async {
    await ensureDBisOpen();
    final DB = getDatabaseOrThrow();
    final data = await DB.query(noteTable);
    // return data.map((n) => DatabaseNote.fromRow(n));
    //Second way..
    final currentUser = user;
    List<DatabaseNote> list = [];
    for (var i = 0; i < data.length; i++) {
      final note = DatabaseNote.fromRow(data[i]);
      if (note.userId == currentUser!.id) {
        list.add(note);
      }
    }
    return list;
  }

  Future<DatabaseNote> getSpecificNote({required int id}) async {
    await ensureDBisOpen();
    final DB = getDatabaseOrThrow();
    final data = await DB.query(
      noteTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (data.isEmpty) {
      throw CouldNotFindTheNote();
    } else {
      final specificNote = DatabaseNote.fromRow(data.first);
      notes.removeWhere((note) => note.id == id);
      notes.add(specificNote);
      notesStreamController.add(notes);
      return specificNote;
    }
  }

  Future<int> deleteAllNotes() async {
    await ensureDBisOpen();
    final DB = getDatabaseOrThrow();
    final noOfDeletions = await DB.delete(noteTable);
    notes = [];
    notesStreamController.add(notes);
    return noOfDeletions;
  }

  Future<void> deleteNote({required int id}) async {
    await ensureDBisOpen();
    final DB = getDatabaseOrThrow();
    final result = await DB.delete(
      noteTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result == 0) {
      throw CouldNotDeleteNote();
    } else {
      notes.removeWhere((note) => note.id == id);
      notesStreamController.add(notes);
    }
  }

  Future<DatabaseNote> createNote({required DatabaseUser owner}) async {
    await ensureDBisOpen();
    final DB = getDatabaseOrThrow();
    final user = await getUser(email: owner.email);
    if (user != owner) {
      throw CouldNotFindTheUser();
    }
    String text = '';
    final noteId = await DB.insert(noteTable,
        {userIdColumn: owner.id, textColumn: text, issyncedColumn: 1});
    final databasenote =
        DatabaseNote(id: noteId, userId: owner.id, text: text, isSycnced: true);
    //reactively add notes to streamcontroller
    notes.add(databasenote);
    notesStreamController.add(notes);
    return databasenote;
  }

  Future<DatabaseUser> getUser({required String email}) async {
    await ensureDBisOpen();
    final DB = getDatabaseOrThrow();
    final result = await DB.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (result.isEmpty) {
      throw CouldNotFindTheUser();
    } else {
      return DatabaseUser.fromRow(result.first);
    }
  }

  Future<DatabaseUser> createUser({required String email}) async {
    await ensureDBisOpen();
    final DB = getDatabaseOrThrow();
    final search = await DB.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (search.isNotEmpty) {
      throw UserAlreadyExists();
    }
    final userId = await DB.insert(
      userTable,
      {emailColumn: email.toLowerCase()},
    );

    return DatabaseUser(id: userId, email: email);
  }

  Future<void> deleteUser({required String email}) async {
    await ensureDBisOpen();
    final DB = getDatabaseOrThrow();
    final deleteCount = await DB.delete(userTable,
        where: 'email = ?', whereArgs: [email.toLowerCase()]);
    if (deleteCount != 1) {
      throw UnableToDeleteUser();
    }
  }

  Database getDatabaseOrThrow() {
    final DB = db;
    if (DB == null) {
      throw DatabaseNotOpen();
    } else {
      return DB;
    }
  }

  Future<void> close() async {
    final DB = db;
    if (DB == null) {
      throw DatabaseNotOpen();
    } else {
      await DB.close();
      db = null;
    }
  }

  Future<void> ensureDBisOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpen {
      //empty
    }
  }

  Future<void> open() async {
    if (db != null) {
      throw DatabaseAlreadyOpen();
    }
    try {
      //this line is used to get the path of document folder within your app
      //your database is located.
      final docsPath = await getApplicationDocumentsDirectory();
      //This line gives us the complete path of where the database is located
      //by joining the decument path and database name .
      final dbPath = join(docsPath.path, dbName);
      //This line is simply used to open the database by taking complete path of database.
      //this can also create the database when its not present
      final DB = await openDatabase(dbPath);
      //db will be used as a instance member and we will interact with database through this.
      db = DB;
      //This creates user table if it doesnot exists in the database
      const createUserTable = '''CREATE TABLE IF NOT EXISTS "user" (
  	  "id"	INTEGER NOT NULL,
	    "email"	TEXT NOT NULL UNIQUE,
	    PRIMARY KEY("id" AUTOINCREMENT)
      );''';
      //db.execute executes SQlite query
      await DB.execute(createUserTable);
      //This creates note table if it doesnot exists in the database
      const createNoteTable = '''CREATE TABLE IF NOT EXISTS "note" (
	      "id"	INTEGER NOT NULL,
	      "user_id"	INTEGER NOT NULL,
	      "text"	TEXT,
	      "isSynced"	INTEGER NOT NULL DEFAULT 0,
	      PRIMARY KEY("id" AUTOINCREMENT),
	      FOREIGN KEY("user_id") REFERENCES "user"("id")
    );''';
      await DB.execute(createNoteTable);
      //Send all the notes to stream controller.
    } on MissingPlatformDirectoryException {
      throw UnableToOpenDocumentsDirectary();
    }
  }
}

class DatabaseUser {
  final int id;
  final String email;
  //Required keyword is used so that these fields must be proivided before making an instance.
  DatabaseUser({required this.id, required this.email});
  //Named constructor: 'FromRow'.
  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;

  @override
  String toString() {
    return 'Person: $id   email: $email';
  }

  @override
  bool operator ==(covariant DatabaseUser other) {
    return id == other.id;
  }

  int get hashcode => id.hashCode;
}

class DatabaseNote {
  final int id;
  final int userId;
  final String text;
  final bool isSycnced;

  DatabaseNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSycnced,
  });

  DatabaseNote.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        text = map[textColumn] as String,
        isSycnced = true;
  // isSycnced = map[issyncedColumn] as int == 1 ? true : false;

  @override
  String toString() =>
      'Note id: $id , UserId: $userId , isSynced: $isSycnced, Text: $text,';

  @override
  bool operator ==(covariant DatabaseNote other) {
    return id == other.id;
  }

  int get hashcode => id.hashCode;
}
