import 'dart:async';
import 'dart:collection';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:inventory_coop/api/client.dart';
import 'package:inventory_coop/model/count.dart';
import 'package:inventory_coop/model/product.dart';
import 'package:inventory_coop/model/storage.dart';

const NO_BARCODE = '-';

class InventoryWidget extends StatefulWidget {
  @override
  InventoryState createState() => InventoryState();
}

class InventoryState extends State<InventoryWidget> {
  final _barcodeController = TextEditingController();
  final _productNameController = TextEditingController();
  final _qtyController = TextEditingController();

  final _qtyFocus = FocusNode();
  bool _recordInProgress = false;

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
      if (product.barcode.isNotEmpty) {
        _productsByBarcode[product.barcode] = product;
      }
      _productsByName[product.name] = product;
      _productsById[product.id] = product;
    });

    _countsDisplayed.clear();
    Storage().counts.forEach((count) {
      _countsDisplayed.insert(0, count);
    });

    _barcodeController.addListener(() {
      if (_barcodeController.text == NO_BARCODE) {
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
      var product = _productsByName[_productNameController.text];
      if (product != null) {
        var barcode = NO_BARCODE;
        if (product.barcode.isNotEmpty) {
          barcode = product.barcode;
        }
        if (barcode != _barcodeController.text) {
          _barcodeController.text = barcode;
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
  }

  bool _isQtyValid() {
    try {
      var qty = double.parse(_qtyController.text);
      _qtyController.text = NumberFormat('####.##').format(qty);
      return true;
    } on FormatException {}
    return false;
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> scan() async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _barcodeController.text = barcodeScanRes != '-1' ? barcodeScanRes : '';
    });
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
          children: [
            TypeAheadFormField(
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
                  title: Text(suggestion as String),
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
                          color: Theme.of(context).disabledColor,
                          fontSize: 18.0),
                    ),
                  );
                } else {
                  return Text('');
                }
              },
              onSuggestionSelected: (suggestion) {
                _barcodeController.text = suggestion as String;
              },
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
                  )),
              suggestionsCallback: (pattern) {
                List<String> suggestions = [];
                if (pattern.length > 1) {
                  _productsByName.keys.forEach((name) {
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
                  });
                }
                return suggestions;
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  dense: true,
                  title: Text(suggestion as String),
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
                          color: Theme.of(context).disabledColor,
                          fontSize: 18.0),
                    ),
                  );
                } else {
                  return Text('');
                }
              },
              onSuggestionSelected: (suggestion) {
                _productNameController.text = suggestion as String;
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
                        if (!_recordInProgress) this.recordCount();
                      },
                      focusNode: _qtyFocus,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        child: Text('Enregistrer'),
                        onPressed: _productNameController.text.isEmpty ||
                                _recordInProgress
                            ? null
                            : () => setState(() {
                                  this.recordCount();
                                }),
                      ),
                    ),
                  ),
                ],
              ),
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
                      Text(product?.name ?? ''),
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
      floatingActionButton: Container(
        height: 100.0,
        width: 100.0,
        child: FittedBox(
          child: FloatingActionButton(
            tooltip: 'Scan',
            onPressed: scan,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: const Icon(Icons.camera),
          ),
        ),
      ),
    );
  }
}
