import 'dart:async';
import 'dart:collection';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'package:InventoryCoop/api/client.dart';
import 'package:InventoryCoop/model/count.dart';
import 'package:InventoryCoop/model/product.dart';
import 'package:InventoryCoop/model/storage.dart';

class InventoryWidget extends StatefulWidget {
  @override
  InventoryState createState() => InventoryState();
}

class InventoryState extends State<InventoryWidget> {
  final _barcodeController = TextEditingController();
  final _productNameController = TextEditingController();
  final _qtyController = TextEditingController();
  bool _activeButton = false;

  final _qtyFocus = FocusNode();

  List<Count> _countsDisplayed = [];

  HashMap<String, Product> _productsByBarcode = HashMap<String, Product>();
  HashMap<String, Product> _productsByName = HashMap<String, Product>();
  HashMap<String, Product> _productsById = HashMap<String, Product>();

  @override
  void initState() {
    super.initState();
    _productsByBarcode.clear();
    _productsByName.clear();
    _productsById.clear();
    Storage().products.forEach((product) {
      _productsByBarcode[product.barcode] = product;
      _productsByName[product.name] = product;
      _productsById[product.id] = product;
    });

    _countsDisplayed.clear();
    Storage().counts.forEach((count) {
      _countsDisplayed.insert(0, count);
    });

    _barcodeController.addListener(() {
      _validateButton();
      var product = _productsByBarcode[_barcodeController.text];
      if (product != null) {
        if (product.name != _productNameController.text) {
          _productNameController.text = product.name;
          FocusScope.of(context).requestFocus(_qtyFocus);
          Future.delayed(const Duration(milliseconds: 500), () {
            setState(() {
              SystemChannels.textInput.invokeMethod('TextInput.show');
              print('_barcodeController');
            });
          });
        }
      } else {
        _productNameController.clear();
        _qtyController.clear();
      }
    });
    _productNameController.addListener(() {
      _validateButton();
      var product = _productsByName[_productNameController.text];
      if (product != null) {
        if (product.barcode != _barcodeController.text) {
          _barcodeController.text = product.barcode;
          FocusScope.of(context).requestFocus(_qtyFocus);
          Future.delayed(const Duration(milliseconds: 500), () {
            setState(() {
              SystemChannels.textInput.invokeMethod('TextInput.show');
              print('_productNameController');
            });
          });
        }
      } else {
        _barcodeController.clear();
        _qtyController.clear();
      }
    });
    _qtyController.addListener(() {
      _validateButton();
    });
  }

  void _validateButton() {
    _activeButton = (_barcodeController.text.isNotEmpty &&
        _productNameController.text.isNotEmpty &&
        _qtyController.text.isNotEmpty);
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> scan() async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", true, ScanMode.BARCODE);
      print(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _barcodeController.text = barcodeScanRes;
    });
  }

  List<Widget> columnChildren() {
    return <Widget>[
      Card(
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    child: TypeAheadFormField(
                      textFieldConfiguration: TextFieldConfiguration(
                          controller: _barcodeController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Code-barre',
                            prefixIcon: IconButton(
                              onPressed: () => _barcodeController.clear(),
                              icon: Icon(Icons.cancel),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                      ),
                      suggestionsCallback: (pattern) {
                        List<String> suggestions = [];
                        if (pattern.length > 1) {
                          _productsByBarcode.keys.forEach((barcode) {
                            if (barcode.contains(pattern)) {
                              suggestions.add(barcode);
                            }
                          });
                        }
                        return suggestions;
                      },
                      itemBuilder: (context, suggestion) {
                        return ListTile(
                          dense: true,
                          title: Text(suggestion),
                        );
                      },
                      noItemsFoundBuilder: (context) {
                        if (_productNameController.text.length > 1) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Aucun code-barre trouvé',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Theme
                                      .of(context)
                                      .disabledColor, fontSize: 18.0),
                            ),
                          );
                        } else {
                          return null;
                        }
                      },
                      onSuggestionSelected: (suggestion) {
                        _barcodeController.text = suggestion;
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.camera),
                    tooltip: "Scan",
                    onPressed: scan,
                  ),
                ],
              ),
            ),
            TypeAheadFormField(
              textFieldConfiguration: TextFieldConfiguration(
                  controller: _productNameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Nom du produit',
                    prefixIcon: IconButton(
                      onPressed: () => _productNameController.clear(),
                      icon: Icon(Icons.cancel),
                    ),
                  )
              ),
              suggestionsCallback: (pattern) {
                List<String> suggestions = [];
                if (pattern.length > 1) {
                  _productsByName.keys.forEach((name) {
                    var fuzzyName = removeDiacritics(name).toLowerCase();
                    var fuzzyPattern = removeDiacritics(pattern).toLowerCase();
                    var therms = fuzzyPattern.split(' ');
                    var match = true;
                    for(final therm in therms) {
                      if (!fuzzyName.contains(therm)) {
                        match = false;
                        break;
                      }
                    }
                    if (match){
                      suggestions.add(name);
                    }
                  });
                }
                return suggestions;
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  dense: true,
                  title: Text(suggestion),
                );
              },
              noItemsFoundBuilder: (context) {
                if (_productNameController.text.length > 1) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Aucun produit trouvé',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Theme
                              .of(context)
                              .disabledColor, fontSize: 18.0),
                    ),
                  );
                } else {
                  return null;
                }
              },
              onSuggestionSelected: (suggestion) {
                _productNameController.text = suggestion;
              },
            ),
            TextFormField(
              controller: _qtyController,
              focusNode: _qtyFocus,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Quantité',
                prefixIcon: IconButton(
                  onPressed: () => _qtyController.clear(),
                  icon: Icon(Icons.cancel),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            RaisedButton(
              child: Text('Valider'),
              onPressed: _activeButton
                  ? null
                  : () =>
                  setState(() {
                    var product = _productsByBarcode[_barcodeController.text];
                    if (product != null) {
                      ApiClient().postCount(
                          Storage().counter,
                          Storage().zone,
                          _qtyController.text,
                          product.id,
                          Storage().inventory.id);
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
                      FocusScope.of(context).unfocus();
                    }
                  }),
            ),
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
                      Text(product.name),
                      Text(count.qty),
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
        title: Text('Inventaire'),
      ),
      body: Column(
        children: columnChildren(),
      ),
    );
  }
}
