import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';

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
          brightness: Brightness.light,
          colorSchemeSeed: Colors.indigo,
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: Colors.indigo,
          textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        ),
        themeMode: ThemeMode.system,
        home: HomeScreen(),
      ),
    );
  }
}

class InventoryItem extends HiveObject {
  String name;
  int quantity;

  InventoryItem(this.name, this.quantity);
}

class SaleEntry extends HiveObject {
  String itemName;
  int quantity;
  DateTime date;

  SaleEntry(this.itemName, this.quantity, this.date);
}

class DailyReport extends HiveObject {
  String date;
  int totalSales;

  DailyReport(this.date, this.totalSales);
}

class InventoryProvider extends ChangeNotifier {
  final Box<InventoryItem> _inventoryBox = Hive.box<InventoryItem>('inventory');

  List<InventoryItem> get items => _inventoryBox.values.toList();

  void addItem(String name, int quantity) {
    final item = InventoryItem(name, quantity);
    _inventoryBox.add(item);
    notifyListeners();
  }
}

class SalesProvider extends ChangeNotifier {
  final Box<DailyReport> _reportBox = Hive.box<DailyReport>('dailyReports');

  void addSale(String itemName, int quantity) {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month}-${now.day}';

    final report = _reportBox.values.firstWhere(
      (r) => r.date == dateStr,
      orElse: () => DailyReport(dateStr, 0),
    );

    report.totalSales += quantity;

    if (!_reportBox.values.contains(report)) {
      _reportBox.add(report);
    } else {
      report.save();
    }

    notifyListeners();
  }

  List<DailyReport> get reports => _reportBox.values.toList();
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sales & Inventory'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHomeCard(
              context,
              title: 'Enter Sales',
              icon: Icons.point_of_sale,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SalesEntryScreen()),
              ),
            ),
            SizedBox(height: 20),
            _buildHomeCard(
              context,
              title: 'View Reports',
              icon: Icons.analytics_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SalesHistoryScreen()),
              ),
            ),
            SizedBox(height: 20),
            _buildHomeCard(
              context,
              title: 'Manage Inventory',
              icon: Icons.inventory_2,
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

  Widget _buildHomeCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(icon, size: 32),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class SalesEntryScreen extends StatelessWidget {
  final itemController = TextEditingController();
  final quantityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter Sale')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: itemController,
              decoration: InputDecoration(labelText: 'Item Name'),
            ),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final item = itemController.text;
                final qty = int.tryParse(quantityController.text) ?? 0;
                Provider.of<SalesProvider>(
                  context,
                  listen: false,
                ).addSale(item, qty);
                Navigator.pop(context);
              },
              child: Text('Add Sale'),
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
    final reports = Provider.of<SalesProvider>(context).reports;

    return Scaffold(
      appBar: AppBar(title: Text('Sales Reports')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return ListTile(
            title: Text('Date: ${report.date}'),
            subtitle: Text('Total Sales: ${report.totalSales}'),
          );
        },
      ),
    );
  }
}

class InventoryScreen extends StatelessWidget {
  final nameController = TextEditingController();
  final quantityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context).items;

    return Scaffold(
      appBar: AppBar(title: Text('Inventory')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: inventory.length,
              itemBuilder: (context, index) {
                final item = inventory[index];
                return ListTile(
                  title: Text(item.name),
                  trailing: Text('Qty: ${item.quantity}'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Item Name'),
                ),
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text;
                    final qty = int.tryParse(quantityController.text) ?? 0;
                    Provider.of<InventoryProvider>(
                      context,
                      listen: false,
                    ).addItem(name, qty);
                  },
                  child: Text('Add Item'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
