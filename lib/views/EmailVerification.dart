import 'package:flutter/material.dart';
import 'package:mynotes/constants/Routes.dart';
import 'package:mynotes/services/auth/auth_service.dart';

class VerifyEmail extends StatelessWidget {
  const VerifyEmail({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Column(
        children: [
          const SizedBox(
            height: 15,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Image.asset(
              "assets/images/Emailicon.png",
              height: 200,
              width: 200,
            ),
          ),
          const SizedBox(
            height: 25,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Column(children: [
              Text(
                "We've sent you a verification email. Please open it to verify your account.",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                  "If you haven't received verification email yet, click the button below.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
              SizedBox(
                height: 10,
              )
            ]),
          ),
          TextButton(
              onPressed: () async {
                await AuthService.firebase().sendVerificationEmail();
              },
              child: const Text("Send Verification Email",
                  style: TextStyle(
                    color: Colors.lightBlue,
                    fontWeight: FontWeight.w800,
                  ))),
          TextButton(
              onPressed: () async {
                await AuthService.firebase().logout();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(RegisterRoute, (route) => false);
              },
              child: const Text('Restart',
                  style: TextStyle(
                    color: Colors.lightBlue,
                    fontWeight: FontWeight.w800,
                  ))),
        ],
      ),
    );
  }
}
