import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/home_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/item_model.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مخزوني'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'طباعة التقرير (PDF)',
            onPressed: () => _showPrintOptionsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed(AppRoutes.SETTINGS),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Header
          _buildStatsHeader(),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (value) => controller.searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'ابحث عن صنف...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
                hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // Items List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredItems = controller.filteredItems;

              if (filteredItems.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return _buildItemCard(context, item);
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddEditDialog(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة صنف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      height: 140,
      child: Obx(() => ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildStatCard('إجمالي الأصناف', controller.totalItemsCount.toString(), Icons.inventory_2, AppColors.displayBlue, filterKey: 'all'),
          _buildStatCard('قريب الانتهاء', controller.nearExpiryCount.toString(), Icons.warning_amber_rounded, AppColors.stockRed, filterKey: 'near_expiry'),
          _buildStatCard('أصناف بها عجز', controller.deficitItemsCount.toString(), Icons.trending_down_rounded, Colors.orange.shade800, filterKey: 'deficit'),
        ],
      )),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {String? filterKey, bool isStatic = false}) {
    final isSelected = !isStatic && controller.filterMode.value == filterKey;
    return InkWell(
      onTap: isStatic ? null : () {
        if (filterKey != null) {
          controller.filterMode.value = filterKey;
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withOpacity(isSelected ? 0.3 : 0.1), blurRadius: isSelected ? 15 : 10, offset: const Offset(0, 4)),
          ],
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.1), 
            width: isSelected ? 2 : 1
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('لم يتم العثور على نتائج', style: TextStyle(fontSize: 18, color: AppColors.textGrey, fontWeight: FontWeight.bold)),
          const Text('حاول البحث بكلمات أخرى', style: TextStyle(fontSize: 14, color: AppColors.textGrey)),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, ItemModel item) {
    final now = DateTime.now();
    final difference = item.expiryDate.difference(now).inDays;
    Color statusColor = AppColors.systemGreen;
    String statusText = 'سليم';

    if (difference < 0) {
      statusColor = AppColors.stockRed;
      statusText = 'منتهي';
    } else if (difference < controller.expiryAlertDays.value) {
      statusColor = AppColors.storeYellow;
      statusText = 'قريب الإنتهاء';
    }

    final storesTotal = item.storeQuantity + item.displayQuantity;
    final settlement = storesTotal - item.systemQuantity;
    
    Color settlementColor = AppColors.textGrey;
    if (settlement > 0) {
      settlementColor = const Color(0xFF1B5E20); // Dark Green
    } else if (settlement < 0) {
      settlementColor = const Color(0xFFB71C1C); // Dark Red
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ),
                if (statusText != 'سليم')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(width: 8),
                _buildItemActions(context, item),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQtyBadge('المخازن', item.storeQuantity, AppColors.storeYellow, Icons.store),
                _buildQtyBadge('العرض', item.displayQuantity, AppColors.displayBlue, Icons.visibility),
                _buildQtyBadge('النظام', item.systemQuantity, AppColors.systemGreen, Icons.computer),
                _buildQtyBadge('التسوية', settlement, settlementColor, Icons.balance_outlined, isSettlement: true),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.event_note_rounded, size: 14, color: AppColors.textGrey),
                const SizedBox(width: 4),
                Text(
                  'ينتهي في: ${DateFormat('yyyy/MM/dd').format(item.expiryDate)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyBadge(String label, int value, Color color, IconData icon, {bool isSettlement = false}) {
    String displayValue = value.toString();
    if (isSettlement && value > 0) displayValue = '+$value';

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          displayValue,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildItemActions(BuildContext context, ItemModel item) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.textGrey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      onSelected: (value) {
        if (value == 'edit') {
          _showAddEditDialog(context, item: item);
        } else if (value == 'delete') {
          _confirmDelete(item);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.blue), SizedBox(width: 8), Text('تعديل')]),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('حذف')]),
        ),
      ],
    );
  }

  void _confirmDelete(ItemModel item) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        title: const Center(
          child: Text(
            'تأكيد الحذف',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stockRed),
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف ${item.name}؟',
          style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء',
                style: TextStyle(
                    color: AppColors.textGrey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteItem(item.id!);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.stockRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {ItemModel? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final storeController = TextEditingController(text: item?.storeQuantity.toString() ?? '');
    final displayController = TextEditingController(text: item?.displayQuantity.toString() ?? '');
    final systemController = TextEditingController(text: item?.systemQuantity.toString() ?? '');
    DateTime selectedDate = item?.expiryDate ?? DateTime.now();

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(item == null ? 'إضافة صنف جديد' : 'تعديل الصنف', 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'اسم الصنف', 
                      prefixIcon: const Icon(Icons.label_important_outline),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: storeController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'المخازن', 
                            prefixIcon: const Icon(Icons.store_mall_directory_outlined),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: displayController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'العرض', 
                            prefixIcon: const Icon(Icons.grid_view_rounded),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: systemController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'النظام', 
                      prefixIcon: const Icon(Icons.computer),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: ValueKey(selectedDate),
                    initialValue: DateFormat('yyyy/MM/dd').format(selectedDate),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(primary: AppColors.primary),
                            ),
                            child: child!,
                          );
                        }
                      );
                      if (date != null) {
                        setModalState(() => selectedDate = date);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'تاريخ الانتهاء',
                      prefixIcon: const Icon(Icons.calendar_month_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () {
                      if (nameController.text.trim().isEmpty) {
                        Get.snackbar('تحذير', 'الرجاء إدخال اسم الصنف', 
                          backgroundColor: AppColors.stockRed, colorText: Colors.white, snackPosition: SnackPosition.TOP);
                        return;
                      }

                      final newItem = ItemModel(
                        id: item?.id,
                        name: nameController.text.trim(),
                        storeQuantity: int.tryParse(storeController.text) ?? 0,
                        displayQuantity: int.tryParse(displayController.text) ?? 0,
                        systemQuantity: int.tryParse(systemController.text) ?? 0,
                        expiryDate: selectedDate,
                      );

                      if (item == null) {
                        controller.addItem(newItem);
                      } else {
                        controller.updateItem(newItem);
                      }

                      Get.back();
                    },
                    child: Text(item == null ? 'إضافة الصنف' : 'تحديث البيانات'),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        }
      ),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
    );
  }

  void _showPrintOptionsDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        title: const Center(
          child: Text(
            'خيارات الطباعة',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اختر نوع التقرير الذي ترغب في استخراجه',
                style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildPrintOption(
                context,
                title: 'طباعة جميع الأصناف',
                subtitle: 'تقرير شامل لكافة البيانات',
                icon: Icons.inventory_2_outlined,
                color: AppColors.displayBlue,
                onTap: () {
                  Get.back();
                  controller.printPdf();
                },
              ),
              const SizedBox(height: 12),
              _buildPrintOption(
                context,
                title: 'أصناف قريبة الانتهاء',
                subtitle: 'تقرير خاص بالتحذيرات والتنبيهات',
                icon: Icons.warning_amber_rounded,
                color: AppColors.stockRed,
                onTap: () {
                  Get.back();
                  controller.printPdf(
                    itemsToPrint: controller.nearExpiryItems,
                    title: 'تقرير الأصناف قريبة الانتهاء',
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildPrintOption(
                context,
                title: 'تقرير التسوية الشامل',
                subtitle: 'جميع الأصناف وفروقات الجرد',
                icon: Icons.balance_outlined,
                color: AppColors.storeYellow,
                onTap: () {
                  Get.back();
                  controller.printPdf(reportType: 'settlement', title: 'تقرير التسوية الشامل');
                },
              ),
              const SizedBox(height: 12),
              _buildPrintOption(
                context,
                title: 'تقرير عجز التسوية',
                subtitle: 'الأصناف التي بها نقص عن النظام',
                icon: Icons.trending_down_rounded,
                color: Colors.orange.shade800,
                onTap: () {
                  Get.back();
                  controller.printPdf(itemsToPrint: controller.deficitItems, reportType: 'settlement', title: 'تقرير عجز التسوية');
                },
              ),
              const SizedBox(height: 12),
              _buildPrintOption(
                context,
                title: 'تقرير زيادة التسوية',
                subtitle: 'الأصناف التي بها زيادة عن النظام',
                icon: Icons.trending_up_rounded,
                color: AppColors.systemGreen,
                onTap: () {
                  Get.back();
                  controller.printPdf(itemsToPrint: controller.surplusItems, reportType: 'settlement', title: 'تقرير زيادة الفائض (التسوية)');
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء',
                style: TextStyle(
                    color: AppColors.textGrey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Material(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14, decoration: TextDecoration.none)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textGrey, decoration: TextDecoration.none)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: color.withOpacity(0.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
