import 'package:inventory_coop/model/count.dart';
import 'package:inventory_coop/model/inventory.dart';
import 'package:inventory_coop/model/product.dart';
import 'package:inventory_coop/model/user.dart';

class Storage {
  late String counter;
  late String zone;
  late User user;
  late Inventory inventory;
  List<Product> products = [];
  List<Count> counts = [];

  Storage._privateConstructor();

  static final Storage _instance = Storage._privateConstructor();

  factory Storage() {
    return _instance;
  }
}
