import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

part 'main.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(InventoryItemAdapter());
  Hive.registerAdapter(SaleEntryAdapter());
  Hive.registerAdapter(DailyReportAdapter());

  await Hive.openBox<InventoryItem>('inventory');
  await Hive.openBox<DailyReport>('dailyReports');

  runApp(MyApp());
  // runApp(
  //   MultiProvider(
  //     providers: [
  //       ChangeNotifierProvider(create: (_) => InventoryProvider()),
  //       ChangeNotifierProvider(create: (_) => SalesProvider()),
  //     ],
  //     child: MyApp(),
  //   ),
  // );
}

// Models

@HiveType(typeId: 0)
class InventoryItem extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double price;

  InventoryItem(this.name, this.price);
}

@HiveType(typeId: 1)
class SaleEntry {
  @HiveField(0)
  String itemName;

  @HiveField(1)
  int quantity;

  SaleEntry(this.itemName, this.quantity);
}

@HiveType(typeId: 2)
class DailyReport extends HiveObject {
  @HiveField(0)
  String date;

  @HiveField(1)
  List<SaleEntry> sales;

  DailyReport(this.date, this.sales);
}

// Providers

class InventoryProvider extends ChangeNotifier {
  final Box<InventoryItem> _box = Hive.box('inventory');

  List<InventoryItem> get items => _box.values.toList();

  void addItem(InventoryItem item) {
    _box.add(item);
    notifyListeners();
  }

  void updateItem(int index, InventoryItem item) {
    _box.putAt(index, item);
    notifyListeners();
  }

  void deleteItem(int index) {
    _box.deleteAt(index);
    notifyListeners();
  }
}

class SalesProvider extends ChangeNotifier {
  List<SaleEntry> _currentSales = [];

  List<SaleEntry> get currentSales => _currentSales;

  void addSale(SaleEntry sale) {
    // If item exists in currentSales, increment qty
    final index = _currentSales.indexWhere((e) => e.itemName == sale.itemName);
    if (index >= 0) {
      _currentSales[index] = SaleEntry(
        sale.itemName,
        _currentSales[index].quantity + sale.quantity,
      );
    } else {
      _currentSales.add(sale);
    }
    notifyListeners();
  }

  void clearSales() {
    _currentSales.clear();
    notifyListeners();
  }

  void saveDailyReport() {
    if (_currentSales.isEmpty) return;
    final box = Hive.box<DailyReport>('dailyReports');
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Check if report for today exists; if yes, append sales; else create new
    final existingReportIndex = box.values.toList().indexWhere(
          (r) => r.date == today,
        );
    if (existingReportIndex >= 0) {
      final report = box.getAt(existingReportIndex)!;
      report.sales.addAll(_currentSales);
      report.save();
    } else {
      box.add(DailyReport(today, List.from(_currentSales)));
    }

    clearSales();
  }
}

// Main App

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Sales & Inventory',
        theme: ThemeData(
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode:
            ThemeMode.system, // Automatically switch based on system theme
        home: HomeScreen(),
      ),
    );
  }
}

// UI Screens

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sales & Inventory')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            HomeButton(
              label: 'Enter Sales',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SalesEntryScreen()),
              ),
            ),
            SizedBox(height: 16),
            HomeButton(
              label: 'View Reports',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SalesHistoryScreen()),
              ),
            ),
            SizedBox(height: 16),
            HomeButton(
              label: 'Manage Inventory',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => InventoryScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const HomeButton({required this.label, required this.onTap, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label, style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

class InventoryScreen extends StatefulWidget {
  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _searchTerm = '';

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();

    final filteredItems = inventoryProvider.items.where((item) {
      return item.name.toLowerCase().contains(_searchTerm.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Inventory')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Inventory',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchTerm = val;
                });
              },
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Item Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    final price =
                        double.tryParse(_priceController.text.trim()) ?? 0.0;
                    if (name.isEmpty || price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Enter valid name and price')),
                      );
                      return;
                    }
                    inventoryProvider.addItem(InventoryItem(name, price));
                    _nameController.clear();
                    _priceController.clear();
                  },
                  child: Text('Add'),
                ),
              ],
            ),
            SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, idx) {
                  final item = filteredItems[idx];
                  final originalIndex = inventoryProvider.items.indexOf(item);
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text('\$${item.price.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          inventoryProvider.deleteItem(originalIndex);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SalesEntryScreen extends StatefulWidget {
  @override
  _SalesEntryScreenState createState() => _SalesEntryScreenState();
}

class _SalesEntryScreenState extends State<SalesEntryScreen> {
  InventoryItem? _selectedItem;
  final TextEditingController _quantityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();
    final salesProvider = context.watch<SalesProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('Enter Sales')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<InventoryItem>(
              decoration: InputDecoration(
                labelText: 'Select Item',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: inventoryProvider.items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    '${item.name} (\$${item.price.toStringAsFixed(2)})',
                  ),
                );
              }).toList(),
              onChanged: (item) {
                setState(() {
                  _selectedItem = item;
                });
              },
              value: _selectedItem,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (_selectedItem == null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Select an item')));
                  return;
                }
                final qty = int.tryParse(_quantityController.text.trim()) ?? 0;
                if (qty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Enter valid quantity')),
                  );
                  return;
                }
                salesProvider.addSale(SaleEntry(_selectedItem!.name, qty));
                _quantityController.clear();
              },
              child: Text('Add Sale'),
            ),
            SizedBox(height: 24),
            Expanded(
              child: salesProvider.currentSales.isEmpty
                  ? Center(child: Text('No sales added yet'))
                  : ListView.builder(
                      itemCount: salesProvider.currentSales.length,
                      itemBuilder: (context, index) {
                        final sale = salesProvider.currentSales[index];
                        return ListTile(
                          title: Text(sale.itemName),
                          trailing: Text('Qty: ${sale.quantity}'),
                        );
                      },
                    ),
            ),
            ElevatedButton(
              onPressed: () {
                if (salesProvider.currentSales.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Add some sales first')),
                  );
                  return;
                }
                salesProvider.saveDailyReport();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Daily report saved')));
              },
              child: Text('Save Daily Report'),
            ),
          ],
        ),
      ),
    );
  }
}

class SalesHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dailyReportsBox = Hive.box<DailyReport>('dailyReports');

    return Scaffold(
      appBar: AppBar(title: Text('Sales Reports')),
      body: ValueListenableBuilder(
        valueListenable: dailyReportsBox.listenable(),
        builder: (context, Box<DailyReport> box, _) {
          final reports = box.values.toList();
          if (reports.isEmpty) {
            return Center(child: Text('No reports found'));
          }
          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final totalSales = report.sales.fold<double>(0, (sum, e) {
                final price = Hive.box<InventoryItem>('inventory')
                    .values
                    .firstWhere(
                      (item) => item.name == e.itemName,
                      orElse: () => InventoryItem('Unknown', 0),
                    )
                    .price;
                return sum + price * e.quantity;
              });

              return ExpansionTile(
                title: Text('Date: ${report.date}'),
                subtitle: Text(
                  'Total Sales: \$${totalSales.toStringAsFixed(2)}',
                ),
                children: report.sales.map((sale) {
                  return ListTile(
                    title: Text(sale.itemName),
                    trailing: Text('Qty: ${sale.quantity}'),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
