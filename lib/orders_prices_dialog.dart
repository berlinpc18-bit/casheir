import 'packa  final List<String> _orderItems = [];tter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class OrdersPricesDialog extends StatefulWidget {
  const OrdersPricesDialog({super.key});

  @override
  State<OrdersPricesDialog> createState() => _OrdersPricesDialogState();
}

class _OrdersPricesDialogState extends State<OrdersPricesDialog> {
  final Map<String, TextEditingController> _controllers = {};
  final List<String> _orderNames = [];

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    for (final name in _orderNames) {
      _controllers[name] = TextEditingController(text: appState.getOrderPrice(name).toString());
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final appState = Provider.of<AppState>(context, listen: false);
    for (final name in _orderNames) {
      final price = double.tryParse(_controllers[name]?.text ?? '');
      if (price != null && price > 0) {
        appState.updateOrderPrice(name, price);
      }
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ أسعار الطلبات بنجاح!')));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('تعديل أسعار الطلبات', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 400,
        height: 500,
        child: ListView(
          children: _orderNames.map((name) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _controllers[name],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(),
                      suffixText: 'د.ع',
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
