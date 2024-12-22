import 'package:flutter/material.dart';
import 'package:inventory_coop/api/client.dart';
import 'package:inventory_coop/inventory.dart';
import 'package:inventory_coop/model/product.dart';
import 'package:inventory_coop/model/storage.dart';

class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key});

  @override
  State<CounterWidget> createState() => _CounterState();
}

class _CounterState extends State<CounterWidget> {
  String _name = Storage().user.lastname;
  String _team = '';
  late Future<List<Product>> _products;
  bool _showValidate = false;

  @override
  void initState() {
    super.initState();
    _checkValidate();
    _products = ApiClient().fetchProducts({
      'inventory': Storage().inventory.id,
    });
  }

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
    _showValidate = _name.isNotEmpty && _team.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compteur', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: FutureBuilder<List<Product>>(
        future: _products,
        builder: (BuildContext context, AsyncSnapshot<List<Product>> snapshot) {
          Storage().products.clear();
          List<Widget> children = <Widget>[];
          if (snapshot.hasData) {
            Storage().products.addAll(snapshot.data as Iterable<Product>);
            children = <Widget>[
              TextFormField(
                initialValue: Storage().user.lastname,
                decoration: InputDecoration(
                  labelText: 'Votre nom',
                ),
                onChanged: (text) {
                  setState(() {
                    _name = text;
                    _checkValidate();
                  });
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Num. de l'equipe",
                ),
                keyboardType: TextInputType.number,
                onChanged: (text) {
                  setState(() {
                    _team = text;
                    _checkValidate();
                  });
                },
              ),
              Align(
                child: ElevatedButton(
                  onPressed: !_showValidate
                    ? null
                    : () {
                    _showValidate = false;
                      Future.delayed(const Duration(milliseconds: 100), () {
                        Storage().counter = _name;
                        Storage().zone = _team;
                        ApiClient().fetchCounts({
                          'inventory': Storage().inventory.id,
                          'counter': Storage().counter,
                          'zone': Storage().zone,
                        }).then((counts) {
                          Storage().counts.clear();
                          Storage().counts.addAll(counts);
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => InventoryWidget()),
                            );
                          }
                          _checkValidate();
                        }).catchError((e) {
                          _showAlert('Impossible de récuperer les comptes',
                              "Recommencer l'opértion.\n\n${e.toString()}");
                          _checkValidate();
                        });
                      });
                  },
                  child: Text('Valider'),
              )),
            ];
          } else if (snapshot.hasError) {
            children = <Widget>[
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Error: ${snapshot.error}'),
              )
            ];
          } else {
            children = <Widget>[
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(),
              ),
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('Awaiting result...'),
              )
            ];
          }
          return ListView(
            children: children,
          );
        },
      ),
    );
  }
}
