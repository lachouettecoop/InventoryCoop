import 'package:flutter/material.dart';

import 'package:InventoryCoop/api/client.dart';
import 'package:InventoryCoop/inventory.dart';
import 'package:InventoryCoop/model/product.dart';
import 'package:InventoryCoop/model/storage.dart';

class CounterWidget extends StatefulWidget {
  @override
  _CounterState createState() => _CounterState();
}

class _CounterState extends State<CounterWidget> {
  String _name = Storage().user.lastname;
  String _team = '';
  Future<List<Product>> _products;

  @override
  void initState() {
    super.initState();
    _products = ApiClient().fetchProducts({
      'inventory': Storage().inventory.id,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compteur'),
      ),
      body: FutureBuilder<List<Product>>(
        future: _products,
        builder: (BuildContext context, AsyncSnapshot<List<Product>> snapshot) {
          Storage().products.clear();
          List<Widget> children = List<Widget>();
          if (snapshot.hasData) {
            Storage().products.addAll(snapshot.data);
            children = <Widget>[
              TextFormField(
                initialValue: Storage().user.lastname,
                decoration: InputDecoration(
                  labelText: 'Votre nom',
                ),
                onChanged: (text) {
                  setState(() {
                    _name = text;
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
                  });
                },
              ),
              Align(
                child: RaisedButton(
                  child: Text('Valider'),
                  onPressed: (_name.isEmpty || _team.isEmpty)
                    ? null
                    : () {
                      Storage().counter = _name;
                      Storage().zone = _team;
                      ApiClient().fetchCounts({
                        'inventory': Storage().inventory.id,
                        'counter': Storage().counter,
                        'zone': Storage().zone,
                      }).then((counts) {
                        Storage().counts.clear();
                        Storage().counts.addAll(counts);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => InventoryWidget()),
                        );
                      });
                      },
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
                child: CircularProgressIndicator(),
                width: 60,
                height: 60,
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
