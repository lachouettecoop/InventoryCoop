import 'package:inventory_coop/model/count.dart';
import 'package:inventory_coop/model/inventory.dart';
import 'package:inventory_coop/model/product.dart';
import 'package:inventory_coop/model/user.dart';

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