import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class CustomCategoryScreen extends StatefulWidget {
  final String categoryName;
  
  const CustomCategoryScreen({super.key, required this.categoryName});

  @override
  State<CustomCategoryScreen> createState() => _CustomCategoryScreenState();
}

class _CustomCategoryScreenState extends State<CustomCategoryScreen> {
  final List<Map<String, TextEditingController>> _itemControllers = [];

  @override
  void initState() {
    super.initState();
    _loadExistingItems();
  }

  void _loadExistingItems() {
    final appState = Provider.of<AppState>(context, listen: false);
    final items = appState.getCategoryItems(widget.categoryName);
    
    for (String item in items) {
      final price = appState.getOrderPrice(item) / 1000; // تحويل من فلس إلى دينار
      _itemControllers.add({
        'name': TextEditingController(text: item),
        'price': TextEditingController(text: price.toString()),
      });
    }
  }

  @override
  void dispose() {
    for (var controllers in _itemControllers) {
      controllers['name']?.dispose();
      controllers['price']?.dispose();
    }
    super.dispose();
  }

  void _addNewItem() {
    setState(() {
      _itemControllers.add({
        'name': TextEditingController(),
        'price': TextEditingController(text: '1.0'),
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      _itemControllers[index]['name']?.dispose();
      _itemControllers[index]['price']?.dispose();
      _itemControllers.removeAt(index);
    });
  }

  void _saveItems() {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // مسح العناصر الحالية
    final currentItems = appState.getCategoryItems(widget.categoryName).toList();
    for (String item in currentItems) {
      appState.removeItemFromCategory(widget.categoryName, item);
    }
    
    // إضافة العناصر الجديدة
    for (var controllers in _itemControllers) {
      final name = controllers['name']?.text.trim() ?? '';
      final price = double.tryParse(controllers['price']?.text ?? '0') ?? 0.0;
      
      if (name.isNotEmpty) {
        appState.addItemToCategory(widget.categoryName, name, price * 1000); // تحويل إلى فلس
      }
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حفظ عناصر "${widget.categoryName}" بنجاح!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.category,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.categoryName,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _saveItems,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('حفظ التغييرات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // قائمة العناصر
            if (_itemControllers.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.list_rounded, color: Colors.green, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'عناصر القسم',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // عرض العناصر
                    ...List.generate(_itemControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildItemField(index),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // زر إضافة عنصر جديد
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addNewItem,
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة عنصر جديد'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemField(int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اسم العنصر',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : const Color(0xFF666666),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _itemControllers[index]['name'],
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1A1A1A),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'مثال: قهوة تركية',
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white54
                              : const Color(0xFF666666),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'السعر (دينار)',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : const Color(0xFF666666),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _itemControllers[index]['price'],
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.0',
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white54
                              : const Color(0xFF666666),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _removeItem(index),
                icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
