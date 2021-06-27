import 'package:flutter/material.dart';

import 'package:InventoryCoop/counter.dart';
import 'package:InventoryCoop/api/client.dart';
import 'package:InventoryCoop/model/inventory.dart';
import 'package:InventoryCoop/model/storage.dart';

class InventoriesWidget extends StatefulWidget {
  @override
  InventoriesState createState() => InventoriesState();
}

class InventoriesState extends State<InventoriesWidget> {
  Future<List<Inventory>> _inventories;
  Inventory _selectedInventory;

  @override
  void initState() {
    super.initState();
    _inventories = ApiClient().fetchInventories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventaires'),
      ),
      body: FutureBuilder<List<Inventory>>(
        future: _inventories,
        // a previously-obtained Future<String> or null
        builder:
            (BuildContext context, AsyncSnapshot<List<Inventory>> snapshot) {
          List<Widget> children = <Widget>[];
          if (snapshot.hasData) {
            snapshot.data.forEach((inventory) {
              if (inventory.isActive()) {
                if (_selectedInventory == null) {
                  _selectedInventory = inventory;
                }
                children.add(RadioListTile<Inventory>(
                  title: Text(inventory.date),
                  value: inventory,
                  groupValue: _selectedInventory,
                  onChanged: (Inventory value) {
                    setState(() {
                      _selectedInventory = value;
                    });
                  },
                ));
              }
            });
            children.add(Align(
                child: ElevatedButton(
                  child: Text('Valider'),
                  onPressed: () {
                    Storage().inventory = _selectedInventory;
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CounterWidget()),
                    );
                  },
                )
            ));
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
              const Padding(
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
