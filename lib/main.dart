// ignore_for_file: camel_case_types
import 'package:flutter/material.dart';
// import 'package:mynotes/colors.dart';
import 'package:mynotes/constants/Routes.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/views/EmailVerification.dart';
import 'package:mynotes/views/Notes/new_note.dart';
import 'package:mynotes/views/Notes/update_note.dart';
import 'package:mynotes/views/RegisterView.dart';
import 'package:mynotes/views/loginView.dart';
import 'package:mynotes/views/Notes/notes_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: const HomePage(),
    routes: {
      LoginRoute: (context) => const LoginView(),
      RegisterRoute: (context) => const RegistrationView(),
      NotesRoute: (context) => const NotesView(),
      VerifyEmailRoute: (context) => const VerifyEmail(),
      NewNoteRoute: (context) => const NewNote(),
      UpdateNoteRoute: (context) => const UpdateNote(),
    },
  ));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      //Here firebase is kick started
      future: AuthService.firebase().initialize(),
      builder: (context, snapshot) {
        //Build is done when the future is completed

        switch (snapshot.connectionState) {
          //Here we are using switch if the connection in the future is done then we move to this case
          //In which we display buttons and text fields
          case ConnectionState.done:
            {
              final user = AuthService.firebase().currentUser;
              if (user != null) {
                if (user.isUserVerified) {
                  return const MainUI();
                } else {
                  return const VerifyEmail();
                }
              } else {
                return const LoginView();
              }
            }
          //If the connection is not done then loading will be displayed
          default:
            {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
        } //Switch Statement
      },
    );
  }
}
