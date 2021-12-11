import 'package:flutter/material.dart';

import 'package:inventory_coop/inventories.dart';
import 'package:inventory_coop/api/client.dart';
import 'package:inventory_coop/model/storage.dart';

const String URL_SERVER = 'https://inventaires.lachouettecoop.fr';

class LoginWidget extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<LoginWidget> {
  String _url = URL_SERVER;
  String _email = '';
  String _password = '';
  bool _showPassword = false;
  bool _showValidate = false;

  Future<void> _showAlert(String title, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _checkValidate() {
    _showValidate = _url.isNotEmpty && _email.isNotEmpty && _password.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _checkValidate();
  }

  void submit() {
    _showValidate = false;
    Future.delayed(const Duration(milliseconds: 100), () {
      ApiClient().clear();
      ApiClient().setHostUri(_url);
      var user = ApiClient().login(_email, _password);
      user.then((value) {
        Storage().user = value;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return InventoriesWidget();
          }),
        );
        _checkValidate();
      }).catchError((e) {
        _showAlert('Impossible de se connecter',
            "Verifier l'URL et vos identifiants.\n\n${e.toString()}");
        _checkValidate();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[
      Center(
        child: Image(image: AssetImage('assets/logo.png')),
      ),
      TextFormField(
        initialValue: URL_SERVER,
        decoration: InputDecoration(
          labelText: 'URL du serveur',
        ),
        onChanged: (text) {
          setState(() {
            _url = text;
            _checkValidate();
          });
        },
        onEditingComplete: () =>
          FocusScope.of(context).nextFocus(),
        textInputAction: TextInputAction.next,
      ),
      TextFormField(
        decoration: InputDecoration(
          labelText: 'Email',
        ),
        onChanged: (text) {
          setState(() {
            _email = text;
            _checkValidate();
          });
        },
        onEditingComplete: () =>
            FocusScope.of(context).nextFocus(),
        textInputAction: TextInputAction.next,
      ),
      TextFormField(
        decoration: InputDecoration(
          labelText: 'Mot de passe',
          // Here is key idea
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility_off : Icons.visibility,
              color: Theme.of(context).primaryColorDark,
            ),
            onPressed: () {
              setState(() {
                _showPassword = !_showPassword;
              });
            },
          ),
        ),
        obscureText: !_showPassword,
        onChanged: (text) {
          setState(() {
            _password = text;
            _checkValidate();
          });
        },
        onEditingComplete: () {
          FocusScope.of(context).unfocus();
          if (_url.isNotEmpty && _email.isNotEmpty && _password.isNotEmpty) {
            submit();
          }
        },
        textInputAction: TextInputAction.done,
      ),
      Align(
        child: ElevatedButton(
          child: Text('Valider'),
          onPressed: !_showValidate
              ? null
              : () {
            submit();
          },
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: ListView(
        children: children,
      ),
    );
  }
}
