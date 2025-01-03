import 'package:flutter/material.dart';
import 'package:inventory_coop/api/client.dart';
import 'package:inventory_coop/counter.dart';
import 'package:inventory_coop/model/inventory.dart';
import 'package:inventory_coop/model/storage.dart';

class InventoriesWidget extends StatefulWidget {
  const InventoriesWidget({super.key});

  @override
  State<InventoriesWidget> createState() => InventoriesState();
}

class InventoriesState extends State<InventoriesWidget> {
  late Future<List<Inventory>> _inventories;
  late Inventory _selectedInventory;

  @override
  void initState() {
    super.initState();
    _inventories = ApiClient().fetchInventories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventaires', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: FutureBuilder<List<Inventory>>(
        future: _inventories,
        // a previously-obtained Future<String> or null
        builder:
            (BuildContext context, AsyncSnapshot<List<Inventory>> snapshot) {
          List<Widget> children = <Widget>[];
          if (snapshot.hasData) {
            snapshot.data?.forEach((inventory) {
              if (inventory.isActive()) {
                _selectedInventory = inventory;
                children.add(RadioListTile<Inventory>(
                  title: Text(inventory.date),
                  value: inventory,
                  groupValue: _selectedInventory,
                  onChanged: (Inventory? value) {
                    setState(() {
                      _selectedInventory = value!;
                    });
                  },
                ));
              }
            });
            children.add(Align(
                child: ElevatedButton(
              child: Text('Valider'),
              onPressed: () {
                Storage().inventory = _selectedInventory as Inventory;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CounterWidget()),
                );
              },
            )));
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
