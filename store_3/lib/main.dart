import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

part 'main.g.dart';

// -------- Hive Models --------

@HiveType(typeId: 0)
class InventoryItem extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int quantity;

  @HiveField(2)
  double unitPrice;

  @HiveField(3)
  double costPrice;

  InventoryItem(this.name, this.quantity, this.unitPrice, this.costPrice);
}

@HiveType(typeId: 1)
class SaleEntry extends HiveObject {
  @HiveField(0)
  String itemName;

  @HiveField(1)
  int quantity;

  @HiveField(2)
  double unitPrice;

  @HiveField(3)
  double costPrice;

  @HiveField(4)
  DateTime timestamp;

  SaleEntry({
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.costPrice,
    required this.timestamp,
  });

  double get totalPrice => quantity * unitPrice;

  double get profit => quantity * (unitPrice - costPrice);
}

@HiveType(typeId: 2)
class ExpenseEntry extends HiveObject {
  @HiveField(0)
  String category;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime timestamp;

  ExpenseEntry({
    required this.category,
    required this.amount,
    required this.timestamp,
  });
}

// -------- Providers --------

class InventoryProvider extends ChangeNotifier {
  final Box<InventoryItem> _inventoryBox = Hive.box<InventoryItem>('inventory');

  List<InventoryItem> get items => _inventoryBox.values.toList();

  void addItem(InventoryItem item) {
    _inventoryBox.add(item);
    notifyListeners();
  }

  void updateItem(int index, InventoryItem item) {
    _inventoryBox.putAt(index, item);
    notifyListeners();
  }
}

class SalesProvider extends ChangeNotifier {
  final Box<SaleEntry> _salesBox = Hive.box<SaleEntry>('sales');

  List<SaleEntry> get sales => _salesBox.values.toList();

  void addSale(SaleEntry sale) {
    _salesBox.add(sale);
    notifyListeners();
  }

  void deleteSale(int index) {
    _salesBox.getAt(index)?.delete();
    notifyListeners();
  }

  /// Filter sales in date range (inclusive)
  List<SaleEntry> salesInRange(DateTime start, DateTime end) {
    return sales.where((sale) {
      return sale.timestamp.isAfter(
            start.subtract(const Duration(seconds: 1)),
          ) &&
          sale.timestamp.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  List<SaleEntry> get salesToday {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));
    return salesInRange(start, end);
  }

  List<SaleEntry> get salesThisWeek {
    final now = DateTime.now();
    final weekday = now.weekday;
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: weekday - 1));
    final end = start
        .add(const Duration(days: 7))
        .subtract(const Duration(seconds: 1));
    return salesInRange(start, end);
  }

  List<SaleEntry> get salesThisMonth {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(
      now.year,
      now.month + 1,
      1,
    ).subtract(const Duration(seconds: 1));
    return salesInRange(start, end);
  }

  double sumTotalPrice(List<SaleEntry> sales) =>
      sales.fold(0, (sum, sale) => sum + sale.totalPrice);

  double sumProfit(List<SaleEntry> sales) =>
      sales.fold(0, (sum, sale) => sum + sale.profit);

  int sumQuantity(List<SaleEntry> sales) =>
      sales.fold(0, (sum, sale) => sum + sale.quantity);

  String? bestSellingProduct(List<SaleEntry> sales) {
    if (sales.isEmpty) return null;
    Map<String, int> counts = {};
    for (var sale in sales) {
      counts[sale.itemName] = (counts[sale.itemName] ?? 0) + sale.quantity;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

class ExpenseProvider extends ChangeNotifier {
  final Box<ExpenseEntry> _expenseBox = Hive.box<ExpenseEntry>('expenses');

  List<ExpenseEntry> get expenses => _expenseBox.values.toList();

  void addExpense(ExpenseEntry expense) {
    _expenseBox.add(expense);
    notifyListeners();
  }

  List<ExpenseEntry> expensesInRange(DateTime start, DateTime end) {
    return expenses.where((expense) {
      return expense.timestamp.isAfter(
            start.subtract(const Duration(seconds: 1)),
          ) &&
          expense.timestamp.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  double sumExpenses(List<ExpenseEntry> expenses) =>
      expenses.fold(0, (sum, expense) => sum + expense.amount);

  List<ExpenseEntry> get expensesToday {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));
    return expensesInRange(start, end);
  }

  List<ExpenseEntry> get expensesThisWeek {
    final now = DateTime.now();
    final weekday = now.weekday;
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: weekday - 1));
    final end = start
        .add(const Duration(days: 7))
        .subtract(const Duration(seconds: 1));
    return expensesInRange(start, end);
  }

  List<ExpenseEntry> get expensesThisMonth {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(
      now.year,
      now.month + 1,
      1,
    ).subtract(const Duration(seconds: 1));
    return expensesInRange(start, end);
  }
}

// -------- Main App --------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(InventoryItemAdapter());
  Hive.registerAdapter(SaleEntryAdapter());
  Hive.registerAdapter(ExpenseEntryAdapter());

  await Hive.openBox<InventoryItem>('inventory');
  await Hive.openBox<SaleEntry>('sales');
  await Hive.openBox<ExpenseEntry>('expenses');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = true;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CHAPAL ARCHIVE',
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
          colorSchemeSeed: Colors.grey,
          textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          colorSchemeSeed: Colors.grey,
          textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        ),
        home: HomeScreen(
          isDarkMode: isDarkMode,
          toggleTheme: () {
            setState(() {
              isDarkMode = !isDarkMode;
            });
          },
        ),
      ),
    );
  }
}

// -------- UI Screens --------

class HomeScreen extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final salesProvider = Provider.of<SalesProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);

    final todaySales = salesProvider.salesToday;
    final weekSales = salesProvider.salesThisWeek;
    final monthSales = salesProvider.salesThisMonth;

    final todayExpenses = expenseProvider.expensesToday;
    final weekExpenses = expenseProvider.expensesThisWeek;
    final monthExpenses = expenseProvider.expensesThisMonth;

    double profitToday =
        salesProvider.sumProfit(todaySales) -
        expenseProvider.sumExpenses(todayExpenses);
    double profitWeek =
        salesProvider.sumProfit(weekSales) -
        expenseProvider.sumExpenses(weekExpenses);
    double profitMonth =
        salesProvider.sumProfit(monthSales) -
        expenseProvider.sumExpenses(monthExpenses);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'CHAPAL ARCHIVE',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            letterSpacing: 2,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: toggleTheme,
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            SummaryCard(
              title: 'Today\'s Sales',
              totalSales: salesProvider.sumTotalPrice(todaySales),
              totalProfit: profitToday,
              itemsSold: salesProvider.sumQuantity(todaySales),
              bestSeller: salesProvider.bestSellingProduct(todaySales),
              color: Colors.deepPurpleAccent,
            ),
            const SizedBox(height: 15),
            SummaryCard(
              title: 'This Week\'s Sales',
              totalSales: salesProvider.sumTotalPrice(weekSales),
              totalProfit: profitWeek,
              itemsSold: salesProvider.sumQuantity(weekSales),
              bestSeller: salesProvider.bestSellingProduct(weekSales),
              color: Colors.tealAccent.shade400,
            ),
            const SizedBox(height: 15),
            SummaryCard(
              title: 'This Month\'s Sales',
              totalSales: salesProvider.sumTotalPrice(monthSales),
              totalProfit: profitMonth,
              itemsSold: salesProvider.sumQuantity(monthSales),
              bestSeller: salesProvider.bestSellingProduct(monthSales),
              color: Colors.orangeAccent,
            ),
            const SizedBox(height: 30),
            HomeMenuButton(
              icon: Icons.point_of_sale,
              label: 'Enter New Sale',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SaleEntryScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            HomeMenuButton(
              icon: Icons.inventory_2,
              label: 'Manage Inventory',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            HomeMenuButton(
              icon: Icons.analytics,
              label: 'View Sales History',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            HomeMenuButton(
              icon: Icons.money_off,
              label: 'Manage Expenses',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExpenseScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final double totalSales;
  final double totalProfit;
  final int itemsSold;
  final String? bestSeller;
  final Color color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.totalSales,
    required this.totalProfit,
    required this.itemsSold,
    this.bestSeller,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Total Sales: ₨${totalSales.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Total Profit: ₨${totalProfit.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Items Sold: $itemsSold',
              style: const TextStyle(fontSize: 16),
            ),
            if (bestSeller != null) ...[
              const SizedBox(height: 6),
              Text(
                'Best Seller: $bestSeller',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HomeMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const HomeMenuButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(label, style: const TextStyle(fontSize: 18)),
      ),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
      ),
      onPressed: onTap,
    );
  }
}

// -------- Sale Entry Screen --------

class SaleEntryScreen extends StatefulWidget {
  const SaleEntryScreen({super.key});

  @override
  State<SaleEntryScreen> createState() => _SaleEntryScreenState();
}

class _SaleEntryScreenState extends State<SaleEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedProduct;
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final salesProvider = Provider.of<SalesProvider>(context);

    List<InventoryItem> items = inventoryProvider.items;

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Sale')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Product'),
                value: selectedProduct,
                items: items
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.name,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedProduct = val;
                  });
                },
                validator: (val) => val == null || val.isEmpty
                    ? 'Please select a product'
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'Enter quantity sold',
                ),
                keyboardType: TextInputType.number,
                initialValue: '1',
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return 'Please enter quantity';
                  if (int.tryParse(val) == null || int.parse(val) <= 0) {
                    return 'Quantity must be positive integer';
                  }
                  return null;
                },
                onSaved: (val) => quantity = int.parse(val!),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // Find selected inventory item
                    final invItem = items.firstWhere(
                      (item) => item.name == selectedProduct,
                      orElse: () => InventoryItem('', 0, 0, 0),
                    );
                    if (invItem.name == '') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Product not found')),
                      );
                      return;
                    }
                    if (quantity > invItem.quantity) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Not enough inventory. Only ${invItem.quantity} left',
                          ),
                        ),
                      );
                      return;
                    }
                    // Create sale entry with timestamp = now
                    final sale = SaleEntry(
                      itemName: invItem.name,
                      quantity: quantity,
                      unitPrice: invItem.unitPrice,
                      costPrice: invItem.costPrice,
                      timestamp: DateTime.now(),
                    );
                    salesProvider.addSale(sale);

                    // Update inventory quantity
                    invItem.quantity -= quantity;
                    invItem.save();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sale added successfully')),
                    );

                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Sale'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------- Inventory Screen --------

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '0',
  );
  final TextEditingController _unitPriceController = TextEditingController(
    text: '0.0',
  );
  final TextEditingController _costPriceController = TextEditingController(
    text: '0.0',
  );

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Inventory')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<InventoryItem>(
                  'inventory',
                ).listenable(),
                builder: (context, Box<InventoryItem> box, _) {
                  if (box.isEmpty) {
                    return const Center(child: Text('No inventory items'));
                  }
                  return ListView.builder(
                    itemCount: box.length,
                    itemBuilder: (context, index) {
                      final item = box.getAt(index)!;
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                          'Qty: ${item.quantity}  |  Price: ₨${item.unitPrice.toStringAsFixed(2)}  |  Cost: ₨${item.costPrice.toStringAsFixed(2)}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            item.delete();
                          },
                        ),
                        onTap: () {
                          _nameController.text = item.name;
                          _quantityController.text = item.quantity.toString();
                          _unitPriceController.text = item.unitPrice.toString();
                          _costPriceController.text = item.costPrice.toString();

                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Edit Inventory Item'),
                              content: Form(
                                key: _formKey,
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextFormField(
                                        controller: _nameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Name',
                                        ),
                                        validator: (val) =>
                                            val == null || val.isEmpty
                                            ? 'Enter name'
                                            : null,
                                      ),
                                      TextFormField(
                                        controller: _quantityController,
                                        decoration: const InputDecoration(
                                          labelText: 'Quantity',
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (val) {
                                          if (val == null || val.isEmpty) {
                                            return 'Enter quantity';
                                          }
                                          if (int.tryParse(val) == null) {
                                            return 'Enter valid number';
                                          }
                                          return null;
                                        },
                                      ),
                                      TextFormField(
                                        controller: _unitPriceController,
                                        decoration: const InputDecoration(
                                          labelText: 'Unit Price',
                                        ),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        validator: (val) {
                                          if (val == null || val.isEmpty) {
                                            return 'Enter unit price';
                                          }
                                          if (double.tryParse(val) == null) {
                                            return 'Enter valid number';
                                          }
                                          return null;
                                        },
                                      ),
                                      TextFormField(
                                        controller: _costPriceController,
                                        decoration: const InputDecoration(
                                          labelText: 'Cost Price',
                                        ),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        validator: (val) {
                                          if (val == null || val.isEmpty) {
                                            return 'Enter cost price';
                                          }
                                          if (double.tryParse(val) == null) {
                                            return 'Enter valid number';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      item.name = _nameController.text;
                                      item.quantity = int.parse(
                                        _quantityController.text,
                                      );
                                      item.unitPrice = double.parse(
                                        _unitPriceController.text,
                                      );
                                      item.costPrice = double.parse(
                                        _costPriceController.text,
                                      );
                                      item.save();
                                      Navigator.pop(ctx);
                                    }
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                    ),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Enter product name'
                        : null,
                  ),
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter quantity';
                      if (int.tryParse(val) == null)
                        return 'Enter valid number';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _unitPriceController,
                    decoration: const InputDecoration(labelText: 'Unit Price'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter unit price';
                      if (double.tryParse(val) == null)
                        return 'Enter valid number';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _costPriceController,
                    decoration: const InputDecoration(labelText: 'Cost Price'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter cost price';
                      if (double.tryParse(val) == null)
                        return 'Enter valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final newItem = InventoryItem(
                          _nameController.text,
                          int.parse(_quantityController.text),
                          double.parse(_unitPriceController.text),
                          double.parse(_costPriceController.text),
                        );
                        Provider.of<InventoryProvider>(
                          context,
                          listen: false,
                        ).addItem(newItem);
                        _nameController.clear();
                        _quantityController.text = '0';
                        _unitPriceController.text = '0.0';
                        _costPriceController.text = '0.0';
                      }
                    },
                    child: const Text('Add Inventory Item'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------- Sales History Screen --------

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final salesProvider = Provider.of<SalesProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sales History')),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<SaleEntry>('sales').listenable(),
        builder: (context, Box<SaleEntry> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('No sales recorded yet'));
          }
          final sales = box.values.toList();
          sales.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return ListView.builder(
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index];
              return ListTile(
                title: Text('${sale.itemName} x${sale.quantity}'),
                subtitle: Text(
                  'Sold at ₨${sale.unitPrice.toStringAsFixed(2)} each\nDate: ${sale.timestamp.toLocal()}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// -------- Expenses Screen --------

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Expenses')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<ExpenseEntry>(
                  'expenses',
                ).listenable(),
                builder: (context, Box<ExpenseEntry> box, _) {
                  if (box.isEmpty) {
                    return const Center(child: Text('No expenses recorded'));
                  }
                  final expenses = box.values.toList();
                  expenses.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                  return ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return ListTile(
                        title: Text(expense.category),
                        subtitle: Text(
                          'Amount: ₨${expense.amount.toStringAsFixed(2)}\nDate: ${expense.timestamp.toLocal()}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            expense.delete();
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter description' : null,
                  ),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter amount';
                      if (double.tryParse(val) == null)
                        return 'Enter valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final newExpense = ExpenseEntry(
                          category: _descriptionController.text,
                          amount: double.parse(_amountController.text),
                          timestamp: DateTime.now(),
                        );
                        Provider.of<ExpenseProvider>(
                          context,
                          listen: false,
                        ).addExpense(newExpense);
                        _descriptionController.clear();
                        _amountController.clear();
                      }
                    },
                    child: const Text('Add Expense'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------- Providers and Models --------

// InventoryItem Hive Model

// (Removed duplicate InventoryItem class, as it is already defined above)

// SaleEntry Hive Model

// Expense Hive Model

// (Removed duplicate Expense class, as ExpenseEntry is already defined above)

// InventoryProvider

// (Removed duplicate InventoryProvider, already defined above)

// SalesProvider

// (Removed duplicate SalesProvider, already defined above)

// ExpenseProvider

// ExpenseProvider

// (Removed duplicate ExpenseProvider, already defined above with correct ExpenseEntry type)
