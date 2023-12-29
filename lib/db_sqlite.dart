import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mysql1/mysql1.dart';
import 'dart:convert';
import 'dart:developer' as developer;

class DatabaseHelper {
  static Database? _database;
  static const String cartItemTableName = 'cart_item';

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    // If the database is null, initialize it
    _database = await initDatabase();
    return _database!;
  }

  static Future<Database> initDatabase() async {
    final path = await getDatabasesPath();
    final databasePath = join(path, 'salesNavigator.db');

    return await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        // Create the cart_items table
        await db.execute(
          '''CREATE TABLE IF NOT EXISTS $cartItemTableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            buyer_id INTEGER,
            product_id INTEGER,
            product_name TEXT,
            uom TEXT,
            qty INTEGER,
            discount INTEGER,
            ori_unit_price REAL,
            unit_price REAL,
            total REAL,
            cancel TEXT,
            remark TEXT,
            status TEXT,
            created TEXT,
            modified TEXT
          )''',
        );
      },
    );
  }

  static Future<int> insertData(Map<String, dynamic> data, String tableName) async {
    final db = await database;

    // Check if the data already exists in the database
    final List<Map<String, dynamic>> existingData = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [data['id']],
    );

    // If the data already exists, skip insertion
    if (existingData.isNotEmpty) {
      return 0;
    }

    // Flatten nested maps into JSON strings
    Map<String, dynamic> flattenedData = flattenNestedMaps(data);

    // Insert flattened data into the database
    return await db.insert(tableName, flattenedData);
  }

  // Function to flatten nested maps into JSON strings
  static Map<String, dynamic> flattenNestedMaps(Map<String, dynamic> data) {
    Map<String, dynamic> flattenedData = {};
    data.forEach((key, value) {
      if (value is Map) {
        // Convert nested map to JSON string
        flattenedData[key] = json.encode(value);
      } else {
        flattenedData[key] = value;
      }
    });
    return flattenedData;
  }

  static Future<List<Map<String, dynamic>>> readData(
      Database database,
      String tableName,
      String condition,
      String order,
      String field, {
        List<Object?>? whereArgs,
      }) async {
    String sqlQuery = '';
    String sqlOrder = '';

    if (condition.isNotEmpty) {
      sqlQuery = 'WHERE $condition';
    }

    if (order.isNotEmpty) {
      sqlOrder = 'ORDER BY $order';
    }

    // Construct the SQL query
    String sql = 'SELECT $field FROM $tableName $sqlQuery $sqlOrder';

    // Execute the query with whereArgs
    List<Map<String, dynamic>> queryResult = await database.rawQuery(sql, whereArgs);

    // Process the query result
    List<Map<String, dynamic>> results = [];
    for (var row in queryResult) {
      // Convert Blob to string if necessary
      row.forEach((key, value) {
        if (value is Blob) {
          final blob = value;
          // Convert Blob data to List<int>
          final bytes = blob.toString().codeUnits;
          // Decode bytes to String
          final stringValue = utf8.decode(bytes);
          row[key] = stringValue;
        }
      });
      results.add(row);
    }

    return results;
  }

  static Future<int> countData(Database db, String tableName, String condition) async {
    String sqlQuery = '';

    if (condition.isNotEmpty) {
      sqlQuery = 'WHERE $condition';
    }

    try {
      final db = await database;
      final List<Map<String, dynamic>> queryResult = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM $tableName $sqlQuery',
      );
      final rowCount = queryResult.first['count'] as int;
      return rowCount;
    } catch (e) {
      developer.log('Error counting data: $e', error: e);
      return 0;
    }
  }

  // Get all data from a specific table
  static Future<List<Map<String, dynamic>>> getAllData(String tableName) async {
    final db = await database;
    return await db.query(tableName);
  }

  // Update data in a specific table
  static Future<int> updateData(Map<String, dynamic> data, String tableName) async {
    final db = await DatabaseHelper.database;
    final id = data['id'];

    return await db.update(
      tableName,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deleteData(int? id, String tableName) async {
    final db = await database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> getCartItemCount() async {
    final db = await _database; // Your database initialization
    final List<Map<String, Object?>>? result = await db?.query(
        'SELECT COUNT(*) as count FROM cart_item WHERE status = "in progress"'
    );

    // Ensure the count is returned as an int
    return result != null && result.isNotEmpty
        ? result.first['count'] as int // Cast to int
        : 0;
  }
}
