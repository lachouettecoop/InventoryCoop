import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';

import 'package:InventoryCoop/model/count.dart';
import 'package:InventoryCoop/model/inventory.dart';
import 'package:InventoryCoop/model/product.dart';
import 'package:InventoryCoop/model/user.dart';

class ApiClient {
  Future<List<Count>> fetchCounts(where) async {
    final response = await get('counts', {'where': json.encode(where)});

    if (response.statusCode == 200) {
      List<Count> counts = List<Count>();
      var body = jsonDecode(response.body);
      body['items'].forEach((count) {
        counts.add(Count.fromJson(count));
      });
      return counts;
    } else {
      throw Exception('Failed to load counts');
    }
  }

  Future<List<Product>> fetchProducts(where) async {
    final response = await get('products', {'where': json.encode(where)});

    if (response.statusCode == 200) {
      List<Product> products = List<Product>();
      var body = jsonDecode(response.body);
      body['items'].forEach((product) {
        products.add(Product.fromJson(product));
      });
      return products;
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<List<Inventory>> fetchInventories() async {
    final response = await get('inventories', null);

    if (response.statusCode == 200) {
      List<Inventory> inventories = List<Inventory>();
      var body = jsonDecode(response.body);
      body['items'].forEach((inventory) {
        inventories.add(Inventory.fromJson(inventory));
      });
      return inventories;
    } else {
      throw Exception('Failed to load inventories');
    }
  }

  Future<Count> postCount(String counter, String zone, String qty, String productId, String inventoryId) async {
    var body = json.encode({
      'counter': counter,
      'zone': zone,
      'qty': qty,
      'product': productId,
      'inventory': inventoryId,
    });
    final response = await post('counts', null, body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Count.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load inventories');
    }
  }

  String _decodeBase64(String str) {
    //'-', '+' 62nd char of encoding,  '_', '/' 63rd char of encoding
    String output = str.replaceAll('-', '+').replaceAll('_', '/');  switch (output.length % 4) { // Pad with trailing '='
      case 0: // No pad chars in this case
        break;
      case 2: // Two pad chars
        output += '==';
        break;
      case 3: // One pad char
        output += '=';
        break;
      default:
        throw Exception('Illegal base64 string');
    }
    return utf8.decode(base64Url.decode(output));
  }

  Future<User> login(String email, String password) async {
    var body = json.encode({
      'email': email,
      'password': password,
    });
    final response = await post('login', null, body);

    if (response.statusCode == 200) {
      var body = jsonDecode(response.body);
      _token = body['token'];
      return User.fromJson(json.decode(_decodeBase64(_token.split('.')[1])));
    } else {
      throw Exception('Failed to login');
    }
  }

  clear() {
    _hostUri = Uri();
    _token = '';
  }

  Map<String, String> _getHeaders() {
    var headers = {
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json;charset=utf-8',
    };
    if (_token.isNotEmpty) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $_token';
    }
    return headers;
  }

  Future<http.Response> get(String path, Map<String, String> params) async {
    var uri = _hostUri.replace(path: 'api/v1/$path', queryParameters: params);
    return await _r.retry(
      () => _client.get(uri, headers: _getHeaders()).timeout(Duration(seconds: 5)),
      retryIf: (e) => e is SocketException || e is TimeoutException,
    );
  }

  Future<http.Response> post(
      String path, Map<String, String> params, String body) async {
    var uri = _hostUri.replace(path: 'api/v1/$path', queryParameters: params);
    return await _r.retry(
      () => _client
          .post(uri, headers: _getHeaders(), body: body)
          .timeout(Duration(seconds: 5)),
      retryIf: (e) => e is SocketException || e is TimeoutException,
    );
  }

  ApiClient._privateConstructor();

  static final ApiClient _instance = ApiClient._privateConstructor();
  static final _client = http.Client();
  static final _r = RetryOptions(maxAttempts: 4);
  Uri _hostUri;
  String _token = '';

  setHostUri(uri) {
    _hostUri = Uri.parse(uri);
  }

  factory ApiClient() {
    return _instance;
  }
}
