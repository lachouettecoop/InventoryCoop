import 'package:InventoryCoop/model/count.dart';
import 'package:InventoryCoop/model/inventory.dart';
import 'package:InventoryCoop/model/product.dart';
import 'package:InventoryCoop/model/user.dart';

class Storage {
  String counter;
  String zone;
  User user;
  Inventory inventory;
  List<Product> products = [];
  List<Count> counts = [];

  Storage._privateConstructor();

  static final Storage _instance = Storage._privateConstructor();

  factory Storage() {
    return _instance;
  }
}