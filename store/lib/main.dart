import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

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
}

// Models remain unchanged
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

// Providers remain unchanged
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
    final index = _currentSales.indexWhere((e) => e.itemName == sale.itemName);
    if (index >= 0) {
      _currentSales[index] = SaleEntry(
          sale.itemName, _currentSales[index].quantity + sale.quantity);
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

<<<<<<< HEAD:store/lib/main.dart
    // Check if report for today exists; if yes, append sales; else create new
    final existingReportIndex =
        box.values.toList().indexWhere((r) => r.date == today);
=======
    final existingReportIndex = box.values.toList().indexWhere(
          (r) => r.date == today,
        );
>>>>>>> a16e6243cf9976c091faf0363f8ceb0fb6b32a58:lib/main.dart
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
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
<<<<<<< HEAD:store/lib/main.dart
              seedColor: Colors.indigo, brightness: Brightness.dark),
          useMaterial3: true,
=======
            seedColor: Color(0xFF6366F1),
            secondary: Color(0xFFEC4899),
          ),
          cardTheme: CardTheme(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
>>>>>>> a16e6243cf9976c091faf0363f8ceb0fb6b32a58:lib/main.dart
        ),
        home: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD:store/lib/main.dart
      appBar: AppBar(title: Text('Sales & Inventory')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            HomeButton(
                label: 'Enter Sales',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => SalesEntryScreen()))),
            SizedBox(height: 16),
            HomeButton(
                label: 'View Reports',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => SalesHistoryScreen()))),
            SizedBox(height: 16),
            HomeButton(
                label: 'Manage Inventory',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => InventoryScreen()))),
          ],
=======
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales & Inventory',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 32),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildAnimatedCard(
                        context,
                        'Enter Sales',
                        Icons.point_of_sale,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SalesEntryScreen()),
                        ),
                      ),
                      _buildAnimatedCard(
                        context,
                        'View Reports',
                        Icons.bar_chart,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SalesHistoryScreen()),
                        ),
                      ),
                      _buildAnimatedCard(
                        context,
                        'Manage Inventory',
                        Icons.inventory_2,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => InventoryScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
>>>>>>> a16e6243cf9976c091faf0363f8ceb0fb6b32a58:lib/main.dart
        ),
      ),
    );
  }

<<<<<<< HEAD:store/lib/main.dart
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
=======
  Widget _buildAnimatedCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Hero(
      tag: title,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder(
          duration: Duration(milliseconds: 300),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Card(
            color: Colors.white.withOpacity(0.9),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
>>>>>>> a16e6243cf9976c091faf0363f8ceb0fb6b32a58:lib/main.dart
        ),
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
    final filteredItems = inventoryProvider.items
        .where((item) =>
            item.name.toLowerCase().contains(_searchTerm.toLowerCase()))
        .toList();

    return Scaffold(
<<<<<<< HEAD:store/lib/main.dart
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
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) {
                setState(() {
                  _searchTerm = val;
                });
              },
=======
      appBar: AppBar(
        title: Text('Inventory'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
>>>>>>> a16e6243cf9976c091faf0363f8ceb0fb6b32a58:lib/main.dart
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
<<<<<<< HEAD:store/lib/main.dart
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Item Name',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
=======
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Inventory',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
>>>>>>> a16e6243cf9976c091faf0363f8ceb0fb6b32a58:lib/main.dart
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchTerm = val),
                ),
<<<<<<< HEAD:store/lib/main.dart
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Enter valid name and price')));
                      return;
                    }
                    inventoryProvider.addItem(InventoryItem(name, price));
                    _nameController.clear();
                    _priceController.clear();
                  },
                  child: Text('Add'),
                )
=======
                SizedBox(height: 16),
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
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final name = _nameController.text.trim();
                        final price =
                            double.tryParse(_priceController.text.trim()) ?? 0.0;
                        if (name.isEmpty || price <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Enter valid name and price')),
                          );
                          return;
                        }
                        inventoryProvider.addItem(InventoryItem(name, price));
                        _nameController.clear();
                        _priceController.clear();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Icon(Icons.add),
                    ),
                  ],
                ),
>>>>>>> a16e6243cf9976c091faf0363f8ceb0fb6b32a58:lib/main.dart
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: ListView.builder(
                key: ValueKey(filteredItems.length),
                padding: EdgeInsets.all(16),
                itemCount: filteredItems.length,
                itemBuilder: (context, idx) {
                  final item = filteredItems[idx];
                  final originalIndex = inventoryProvider.items.indexOf(item);
<<<<<<< HEAD:store/lib/main.dart
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text('\$${item.price.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          inventoryProvider.deleteItem(originalIndex);
                        },
=======
                  return TweenAnimationBuilder(
                    duration: Duration(milliseconds: 300),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          item.name,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => inventoryProvider.deleteItem(originalIndex),
                        ),
>>>>>>> a16e6243cf9976c091faf0363f8ceb0fb6b32a58:lib/main.dart
                      ),
                    ),
                  );
                },
              ),
<<<<<<< HEAD:store/lib/main.dart
            )
          ],
        ),
=======
            ),
          ),
        ],
>>>>>>> a16e6243cf9976c091faf0363f8ceb0fb6b32a58:lib/main.dart
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
      appBar: AppBar(
        title: Text('Enter Sales'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
<<<<<<< HEAD:store/lib/main.dart
            DropdownButtonFormField<InventoryItem>(
              decoration: InputDecoration(
                labelText: 'Select Item',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: inventoryProvider.items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child:
                      Text('${item.name} (\$${item.price.toStringAsFixed(2)})'),
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
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (_selectedItem == null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Select an item')));
                  return;
                }
                final qty = int.tryParse(_quantityController.text.trim()) ?? 0;
                if (qty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Enter valid quantity')));
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
=======
            Card(
              child: Padding(
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
>>>>>>> a16e6243cf9976c091faf0363f8ceb0fb6b32a58:lib/main.dart
                        );
                      }).toList(),
                      onChanged: (item) {
                        setState(() {
                          _selectedItem = item;
                        });
                      },
                      value: _selectedItem,
                    ),
                    SizedBox(height: 16),
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
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_selectedItem == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Select an item')),
                          );
                          return;
                        }
                        final qty =
                            int.tryParse(_quantityController.text.trim()) ?? 0;
                        if (qty <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Enter valid quantity')),
                          );
                          return;
                        }
                        salesProvider
                            .addSale(SaleEntry(_selectedItem!.name, qty));
                        _quantityController.clear();
                      },
                      icon: Icon(Icons.add_shopping_cart),
                      label: Text('Add Sale'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
<<<<<<< HEAD:store/lib/main.dart
            ElevatedButton(
              onPressed: () {
                if (salesProvider.currentSales.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Add some sales first')));
                  return;
                }
                salesProvider.saveDailyReport();
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Daily report saved')));
              },
              child: Text('Save Daily Report'),
            )
=======
            SizedBox(height: 16),
            Expanded(
              child: Card(
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: salesProvider.currentSales.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No sales added yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: salesProvider.currentSales.length,
                          itemBuilder: (context, index) {
                            final sale = salesProvider.currentSales[index];
                            final item = inventoryProvider.items.firstWhere(
                              (i) => i.name == sale.itemName,
                              orElse: () => InventoryItem('Unknown', 0),
                            );
                            return ListTile(
                              title: Text(
                                sale.itemName,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Total: \$${(item.price * sale.quantity).toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                              trailing: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Qty: ${sale.quantity}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: salesProvider.currentSales.isEmpty
                  ? null
                  : () {
                      salesProvider.saveDailyReport();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Daily report saved successfully'),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
              icon: Icon(Icons.save),
              label: Text('Save Daily Report'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
>>>>>>> a16e6243cf9976c091faf0363f8ceb0fb6b32a58:lib/main.dart
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
      appBar: AppBar(
        title: Text('Sales Reports'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: dailyReportsBox.listenable(),
        builder: (context, Box<DailyReport> box, _) {
          final reports = box.values.toList();
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No reports found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final totalSales = report.sales.fold<double>(
                0,
                (sum, e) {
                  final price = Hive.box<InventoryItem>('inventory')
                      .values
                      .firstWhere(
                        (item) => item.name == e.itemName,
                        orElse: () => InventoryItem('Unknown', 0),
                      )
                      .price;
                  return sum + price * e.quantity;
                },
              );

<<<<<<< HEAD:store/lib/main.dart
              return ExpansionTile(
                title: Text('Date: ${report.date}'),
                subtitle:
                    Text('Total Sales: \$${totalSales.toStringAsFixed(2)}'),
                children: report.sales.map((sale) {
                  return ListTile(
                    title: Text(sale.itemName),
                    trailing: Text('Qty: ${sale.quantity}'),
                  );
                }).toList(),
=======
              return Card(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    title: Text(
                      'Date: ${report.date}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Total Sales: \$${totalSales.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    children: report.sales.map((sale) {
                      final item = Hive.box<InventoryItem>('inventory')
                          .values
                          .firstWhere(
                            (item) => item.name == sale.itemName,
                            orElse: () => InventoryItem('Unknown', 0),
                          );
                      return ListTile(
                        title: Text(sale.itemName),
                        subtitle: Text(
                          'Total: \$${(item.price * sale.quantity).toStringAsFixed(2)}',
                        ),
                        trailing: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Qty: ${sale.quantity}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
>>>>>>> a16e6243cf9976c091faf0363f8ceb0fb6b32a58:lib/main.dart
              );
            },
          );
        },
      ),
    );
  }
}