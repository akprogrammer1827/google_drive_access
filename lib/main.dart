import 'package:flutter/material.dart';
import 'package:google_drive/screens/drive_screen.dart';

void main() => runApp(DriveApp());

class DriveApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home:DriveScreen(),
    );
  }
}

