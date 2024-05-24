import 'package:flutter/material.dart';
import 'package:mynotes/constants/Routes.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/utilities/ErrorDialog.dart';

class RegistrationView extends StatefulWidget {
  const RegistrationView({super.key});

  @override
  State<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<RegistrationView> {
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
        appBar: AppBar(title: const Text("Register")),
        //This column is the parent column of all text fields login and register button
        body: Column(
          children: [
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
              height: 30,
            ),
            Column(
              //this centers the whole column
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FractionallySizedBox(
                  //This covers the two text fields inorder to have some space between two text fields
                  child: Padding(
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
                              borderSide:
                                  BorderSide(width: 1, color: Colors.grey),
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
                ),
                TextButton(
                  onPressed: () async {
                    final e = email.text;
                    final p = password.text;

                    try {
                      await AuthService.firebase()
                          .createUser(email: e, password: p);
                      await AuthService.firebase().sendVerificationEmail();
                      //Going to verify email view
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          VerifyEmailRoute, (route) => false);
                    } on WeakPasswordAuthException {
                      await showErrorDialog(context, 'Weak password');
                    } on EmailAlreadyInUseAuthException {
                      await showErrorDialog(context, 'Email already in use');
                    } on InvalidEmailAuthException {
                      await showErrorDialog(context, 'Invalid email address');
                    } on GenericAuthException {
                      await showErrorDialog(context, 'Authentication error');
                    }
                  },
                  child: const Text("Register"),
                ),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          LoginRoute, (route) => false);
                    },
                    child: const Text('Already registered ? Login here!'))
              ],
            ),
          ],
        ));
  }
}
