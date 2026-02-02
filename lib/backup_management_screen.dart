import 'package:flutter/material.dart';

class BackupManagementScreen extends StatefulWidget {
  @override
  _BackupManagementScreenState createState() => _BackupManagementScreenState();
}

class _BackupManagementScreenState extends State<BackupManagementScreen> {
  Map<String, dynamic> _backupInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBackupInfo();
  }

  Future<void> _loadBackupInfo() async {
    setState(() => _isLoading = true);
    
    // Server-only mode: No local backup info needed
    setState(() {
      _backupInfo = {'message': 'Server-only mode: No local backups'};
      _isLoading = false;
    });
  }

  Future<void> _cleanupOldBackups(int keepCount) async {
    // Server-only mode: No local backups to cleanup
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Server-only mode: No local backups')),
    );
  }

  Future<void> _deleteAllBackups() async {
    // Server-only mode: No local backups to delete
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Server-only mode: No local backups')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة ملفات النسخ الاحتياطية'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // معلومات عامة
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📊 معلومات الملفات الاحتياطية',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('عدد الملفات:'),
                              Text(
                                '${_backupInfo['total_files'] ?? 0}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('الحجم الإجمالي:'),
                              Text(
                                '${_backupInfo['total_size_mb'] ?? 0} ميجابايت',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // أزرار الإدارة
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🔧 إدارة الملفات',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          
                          // تنظيف ذكي
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _cleanupOldBackups(3),
                                  icon: Icon(Icons.cleaning_services),
                                  label: Text('احتفظ بـ 3 ملفات فقط'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 8),
                          
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _cleanupOldBackups(1),
                                  icon: Icon(Icons.auto_delete),
                                  label: Text('احتفظ بملف واحد فقط'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 8),
                          
                          // حذف الكل
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _deleteAllBackups,
                                  icon: Icon(Icons.delete_forever),
                                  label: Text('حذف جميع الملفات'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // قائمة الملفات
                  if (_backupInfo['files'] != null && 
                      (_backupInfo['files'] as List).isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📁 قائمة الملفات',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            ...(_backupInfo['files'] as List).map<Widget>((file) {
                              return Container(
                                margin: EdgeInsets.only(bottom: 8),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      file['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.storage, size: 16, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text(
                                          '${file['size_mb']} ميجابايت',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  SizedBox(height: 16),
                  
                  // نصائح
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb, color: Colors.blue.shade700),
                              SizedBox(width: 8),
                              Text(
                                'نصائح مهمة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            '• النسخ الاحتياطية تُنشأ تلقائياً كل ساعة عند الحفظ\n'
                            '• يتم الاحتفاظ بـ 3 ملفات تلقائياً وحذف الباقي\n'
                            '• البيانات محفوظة أيضاً في مواقع أخرى آمنة\n'
                            '• يمكنك حذف الملفات بأمان دون فقدان البيانات',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadBackupInfo,
        child: Icon(Icons.refresh),
        tooltip: 'تحديث المعلومات',
      ),
    );
  }
}