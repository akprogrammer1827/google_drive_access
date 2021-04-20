import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_drive/authentication/google_auth_client.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:googleapis/drive/v3.dart';
import 'package:path/path.dart' as path;
import 'package:progress_dialog/progress_dialog.dart';

//Get Google Account
GoogleSignInAccount account;
GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'https://www.googleapis.com/auth/drive.file',
  ],
);

class DriveScreen extends StatefulWidget {
  @override
  DriveScreenState createState() {
    return new DriveScreenState();
  }
}

class DriveScreenState extends State<DriveScreen> {

  //Drive Api
  DriveApi api;
  //FilesList
  ga.FileList list;
  //Progress Dialog
  ProgressDialog pr;
  //Scaffold Key
  GlobalKey<ScaffoldState> _scaffold = GlobalKey();

  //Main UI Widget
  @override
  Widget build(BuildContext context) {
    return account != null ? homeScreen() : loginScreen();
  }

 //Login Method
  Future<void> login() async {
    try {
      account = await _googleSignIn.signIn();
      final client =
          GoogleHttpClient(await _googleSignIn.currentUser.authHeaders);
      api = DriveApi(client);
    } catch (error) {
      print('DriveScreen.login.ERROR... $error');
      _scaffold.currentState.showSnackBar(SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Text(
          'Error : $error',
          style: TextStyle(color: Colors.white),
        ),
      ));
    }
    setState(() {});
  }

  //Upload Method
  _uploadFileToGoogleDrive() async {
    var client = GoogleHttpClient(await account.authHeaders);
    var drive = ga.DriveApi(client);
    ga.File fileToUpload = ga.File();
    var file = await FilePicker.getFile();
    fileToUpload.name = path.basename(file.absolute.path);

    pr.show();
    var response = await drive.files.create(
      fileToUpload,
      uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
    );
    pr.update(
      progress: 50.0,
      message: "Please wait still uploading...",
      progressWidget: Container(
          padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
      maxProgress: 100.0,
      progressTextStyle: TextStyle(
          color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
      messageTextStyle: TextStyle(
          color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600),
    );

    Future.delayed(Duration(seconds: 5)).then((value) {
      pr.hide().whenComplete(() async {
        print(response);
        _scaffold.currentState.showSnackBar(SnackBar(
          content: Text('File Uploaded => Name : ${response.name}'),
        ));
      });
    });

    setState(() {
      _listGoogleDriveFiles();
    });
  }

  //Listing Files Method
  Future<void> _listGoogleDriveFiles() async {
    var client = GoogleHttpClient(await account.authHeaders);
    var drive = ga.DriveApi(client);
    drive.files.list().then((value) {
      setState(() {
        list = value;
        for (var i = 0; i < list.files.length; i++) {
          print("Id: ${list.files[i].id} File Name:${list.files[i].name}");
        }
      });
    });
  }

  //Logout Method
  void logout() {
    _googleSignIn.signOut();
    setState(() {
      account = null;
    });
  }

  //Home Screen Widget
  Widget homeScreen(){
    pr = new ProgressDialog(context);
    pr.style(message: 'Uploading.....');
    return Scaffold(
      key: _scaffold,
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage:
                NetworkImage(account.photoUrl, scale: 0.3),
              ),
              accountEmail: Text(account.email),
              accountName: Text(account.displayName),
            )
          ],
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Text('Google Drive Access'),
        actions:<Widget>[
          IconButton(icon: Icon(Icons.exit_to_app), onPressed: logout)
        ],
      ),
      floatingActionButton:FloatingActionButton(
        onPressed: _uploadFileToGoogleDrive,
        child: Icon(Icons.add),
        tooltip: 'Upload File',
      ),
      body: Center(
          child:Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: FutureBuilder(
                    initialData: null,
                    future: api.files.list(),
                    builder: (context, AsyncSnapshot snapshot) {
                      if (snapshot.connectionState !=
                          ConnectionState.done) {
                        return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Loading Files',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                      fontSize: 18),
                                ),
                              ],
                            ));
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text('Something went wrong'),
                        );
                      } else {
                        return ListView(
                          physics: BouncingScrollPhysics(),
                          children: (snapshot.data as FileList)
                              .files
                              .map((f) => ListTile(
                            dense: true,
                            title: Text(
                              f.name,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17),
                            ),
                            leading: Icon(
                              Icons.insert_drive_file,
                              color: Colors.black,
                            ),
                          ))
                              .toList(),
                        );
                      }
                    }),
              ),
            ],
          )
      ),
    );
  }

  //Login Screen Widget
  Widget loginScreen(){
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Google Drive Access'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CupertinoButton(
              color: Colors.blue,
              child: Text('Sign in with Google'),
              onPressed: login),
        ),
      ),
    );
  }
  
}
