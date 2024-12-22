import 'dart:async';
import 'dart:collection';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:inventory_coop/api/client.dart';
import 'package:inventory_coop/model/count.dart';
import 'package:inventory_coop/model/product.dart';
import 'package:inventory_coop/model/storage.dart';

import 'api/client.dart';
import 'barcode_scanner.dart';
import 'model/count.dart';
import 'model/product.dart';
import 'model/storage.dart';


const noBareCode = '-';

class InventoryWidget extends StatefulWidget {
  const InventoryWidget({super.key});

  @override
  State<InventoryWidget> createState() => InventoryState();
}

class InventoryState extends State<InventoryWidget> {
  final _barcodeController = TextEditingController();
  final _productNameController = TextEditingController();
  final _qtyController = TextEditingController();

  final _qtyFocus = FocusNode();
  bool _recordInProgress = false;

  final List<Count> _countsDisplayed = [];

  final HashMap<String, Product> _productsByBarcode = HashMap<String, Product>();
  final HashMap<String, Product> _productsByName = HashMap<String, Product>();
  final HashMap<String, Product> _productsById = HashMap<String, Product>();

  @override
  void initState() {
    super.initState();
    _productsByBarcode.clear();
    _productsByName.clear();
    _productsById.clear();
    for (var product in Storage().products) {
      if (product.barcode.isNotEmpty) {
        _productsByBarcode[product.barcode] = product;
      }
      _productsByName[product.name] = product;
      _productsById[product.id] = product;
    }

    _countsDisplayed.clear();
    for (var count in Storage().counts) {
      _countsDisplayed.insert(0, count);
    }

    _barcodeController.addListener(() {
      if (_barcodeController.text == noBareCode) {
        return;
      }
      var product = _productsByBarcode[_barcodeController.text];
      if (product != null) {
        if (product.name != _productNameController.text) {
          _productNameController.text = product.name;
          FocusScope.of(context).requestFocus(_qtyFocus);
          Future.delayed(const Duration(milliseconds: 500), () {
            setState(() {
              SystemChannels.textInput.invokeMethod('TextInput.show');
            });
          });
        }
      } else {
        _productNameController.clear();
        _qtyController.clear();
      }
    });
    _productNameController.addListener(() {
      var product = _productsByName[_productNameController.text];
      if (product != null) {
        var barcode = noBareCode;
        if (product.barcode.isNotEmpty) {
          barcode = product.barcode;
        }
        if (barcode != _barcodeController.text) {
          _barcodeController.text = barcode;
          FocusScope.of(context).requestFocus(_qtyFocus);
          Future.delayed(const Duration(milliseconds: 500), () {
            setState(() {
              SystemChannels.textInput.invokeMethod('TextInput.show');
            });
          });
        }
      } else {
        _barcodeController.clear();
        _qtyController.clear();
      }
    });
  }

  bool _isQtyValid() {
    try {
      var qty = double.parse(_qtyController.text);
      _qtyController.text = NumberFormat('####.##').format(qty);
      return true;
    } on FormatException {
      // Nothing to do.
    }
    return false;
  }

  void _startBarcodeScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScanner()),
    );

    if (result != null && result is String) {
      setState(() {
        _barcodeController.text = result;
      });
    }
  }

  void recordCount() {
    _recordInProgress = true;
    var product = _productsByName[_productNameController.text];
    if (product != null && _isQtyValid()) {
      ApiClient().postCount(Storage().counter, Storage().zone,
          _qtyController.text, product.id, Storage().inventory.id);
      _countsDisplayed.insert(
          0,
          Count(
            counter: Storage().counter,
            zone: Storage().zone,
            product: product.id,
            qty: _qtyController.text,
          ));
      _barcodeController.clear();
      _productNameController.clear();
      _qtyController.clear();
      _recordInProgress = false;
      FocusScope.of(context).unfocus();
    }
  }

  List<Widget> columnChildren() {
    return <Widget>[
      Card(
        child: Column(
          spacing: 10,
          children: [
            SizedBox(height: 5),
            TypeAheadField<String>(
              controller: _barcodeController,
              suggestionsCallback: (pattern) {
                List<String> suggestions = [];
                if (pattern.length > 1) {
                  for (var barcode in _productsByBarcode.keys) {
                    if (barcode.contains(pattern)) {
                      suggestions.add(barcode);
                    }
                  }
                }
                return suggestions;
              },
              builder: (context, controller, focusNode) {
                return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Code-barre',
                      prefixIcon: IconButton(
                        onPressed: () => controller.clear(),
                        icon: Icon(Icons.cancel),
                      ),
                    )
                );
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  dense: true,
                  title: Text(suggestion),
                );
              },
              hideOnEmpty: true,
              hideOnLoading: true,
              onSelected: (suggestion) {
                _barcodeController.text = suggestion;
              },
            ),
            TypeAheadField<String>(
              controller: _productNameController,
              suggestionsCallback: (pattern) {
                List<String> suggestions = [];
                if (pattern.length > 1) {
                  for (var name in _productsByName.keys) {
                    var fuzzyName = removeDiacritics(name).toLowerCase();
                    var fuzzyPattern = removeDiacritics(pattern).toLowerCase();
                    var therms = fuzzyPattern.split(' ');
                    var match = true;
                    for (final therm in therms) {
                      if (!fuzzyName.contains(therm)) {
                        match = false;
                        break;
                      }
                    }
                    if (match) {
                      suggestions.add(name);
                    }
                  }
                }
                return suggestions;
              },
              builder: (context, controller, focusNode) {
                return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Nom du produit',
                      prefixIcon: IconButton(
                        onPressed: () => controller.clear(),
                        icon: Icon(Icons.cancel),
                      ),
                    )
                );
              },
              hideOnEmpty: true,
              hideOnLoading: true,
              itemBuilder: (context, suggestion) {
                return ListTile(
                  dense: true,
                  title: Text(suggestion as String),
                );
              },
              onSelected: (suggestion) {
                _productNameController.text = suggestion;
              },
            ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    flex: 6,
                    child: TextField(
                      controller: _qtyController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Quantité',
                        prefixIcon: IconButton(
                          onPressed: () => _qtyController.clear(),
                          icon: Icon(Icons.cancel),
                        ),
                      ),
                      onSubmitted: (String value) {
                        recordCount();
                      },
                      focusNode: _qtyFocus,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _productNameController.text.isEmpty
                        ? null
                        : () => setState(() { recordCount(); }),
                    child: Text('Enregistrer'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 5),
          ],
        ),
      ),
      Expanded(
          child: ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: _countsDisplayed.length,
              itemBuilder: (BuildContext context, int index) {
                var count = _countsDisplayed[index];
                var product = _productsById[count.product];
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text("    ${product!.name}"),
                      Text("${count.qty}    "),
                    ],
                  ),
                );
              })),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventaire', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: columnChildren(),
      ),
      floatingActionButton: FloatingActionButton.large(
        tooltip: "Scan",
        onPressed: _startBarcodeScanner,
        child: Icon(Icons.camera), // Icon for the button
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
