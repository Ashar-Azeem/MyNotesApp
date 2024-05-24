import 'package:flutter/material.dart';
import 'package:mynotes/constants/Routes.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/utilities/ErrorDialog.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool passwordInvisible = true;
  late TextEditingController email;
  late TextEditingController password;
  @override
  void initState() {
    email = TextEditingController();
    password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Login'),
      ),
      //This column is the parent column of all text fields login and register button
      body: Column(
        children: [
          //Space above the icon
          const SizedBox(
            height: 10,
          ),
          //Icon
          Align(
            alignment: Alignment.topCenter,
            child: Image.asset(
              "assets/images/Icon.png",
              height: 150,
              width: 240,
            ),
          ),
          //Space below the icon
          const SizedBox(
            height: 25,
          ),
          Column(
            //this centers the whole column
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(children: [
                  TextField(
                    enableSuggestions: false,
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                    controller: email,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(
                            borderSide: BorderSide(
                          width: 1,
                          color: Colors.grey,
                        )),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(width: 1, color: Colors.grey),
                        ),
                        labelText: 'Email'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    obscureText: passwordInvisible,
                    enableSuggestions: false,
                    autocorrect: false,
                    controller: password,
                    decoration: InputDecoration(
                        border: const OutlineInputBorder(
                            borderSide:
                                BorderSide(width: 1, color: Colors.grey)),
                        focusedBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(width: 1, color: Colors.grey)),
                        labelText: 'Password',
                        suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                passwordInvisible = !passwordInvisible;
                              });
                            },
                            icon: Icon(
                              //ternary operator  bool ? open eye: close eye
                              passwordInvisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ))),
                  ),
                ]),
              ),
              TextButton(
                onPressed: () async {
                  final e = email.text;
                  final p = password.text;

                  try {
                    await AuthService.firebase().login(email: e, password: p);
                    final user = AuthService.firebase().currentUser;
                    if (user?.isUserVerified ?? false) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          NotesRoute, (route) => false);
                    } else {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          VerifyEmailRoute, (route) => false);
                    }
                  } on UserNotFoundAuthException {
                    await showErrorDialog(context, 'User not found');
                  } on WrongPasswordAuthException {
                    await showErrorDialog(context, 'Incorrect password  ');
                  } on GenericAuthException {
                    await showErrorDialog(context, 'Authentication error');
                  }
                },
                child: const Text("Login"),
              ),
              TextButton(
                  onPressed: () {
                    //Navigator is an stack that keeps track of our views
                    //In this case we are adding the new view into that stack.
                    //and when route is false then previous screen is not accesible.

                    //Navigator Stack stores the addresses of all the views
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        RegisterRoute, (route) => false);
                  },
                  child: const Text("Not registered yet ? Register here"))
            ],
          ),
        ],
      ),
    );
  }
}
