import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../data/models/item_model.dart';
import '../../../data/interfaces/item_repository_interface.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/interfaces/auth_repository_interface.dart';

class HomeController extends GetxController {
  final IItemRepository itemRepo;
  late final IAuthRepository authRepo;

  HomeController({required this.itemRepo});

  var items = <ItemModel>[].obs;
  var isLoading = true.obs;
  var searchQuery = ''.obs;
  var filterMode = 'all'.obs;
  var expiryAlertDays = 30.obs;

  List<ItemModel> get filteredItems {
    var result = items.toList();
    
    // Apply stats card filter
    if (filterMode.value == 'near_expiry') {
      final now = DateTime.now();
      final expiryThreshold = now.add(Duration(days: expiryAlertDays.value));
      result = result.where((item) => item.expiryDate.isBefore(expiryThreshold)).toList();
    } else if (filterMode.value == 'deficit') {
      result = result.where((item) {
        final storesTotal = item.storeQuantity + item.displayQuantity;
        return storesTotal < item.systemQuantity;
      }).toList();
    }

    // Apply search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result = result.where((item) => item.name.toLowerCase().contains(query)).toList();
    }
    
    return result;
  }

  int get totalItemsCount => items.length;

  int get nearExpiryCount => nearExpiryItems.length;

  List<ItemModel> get nearExpiryItems {
    final now = DateTime.now();
    final expiryThreshold = now.add(Duration(days: expiryAlertDays.value));
    return items.where((item) => item.expiryDate.isBefore(expiryThreshold)).toList();
  }

  List<ItemModel> get deficitItems {
    return items.where((item) {
      final storesTotal = item.storeQuantity + item.displayQuantity;
      return storesTotal < item.systemQuantity;
    }).toList();
  }

  int get deficitItemsCount => deficitItems.length;

  List<ItemModel> get surplusItems {
    return items.where((item) {
      final storesTotal = item.storeQuantity + item.displayQuantity;
      return storesTotal > item.systemQuantity;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    authRepo = Get.find<IAuthRepository>();
    _loadInitialSettings();
    loadItems();
  }

  Future<void> _loadInitialSettings() async {
    expiryAlertDays.value = await authRepo.getExpiryAlertDays();
  }

  Future<void> loadItems() async {
    isLoading.value = true;
    final data = await itemRepo.getItems();
    // Refresh settings each time items are loaded (e.g., coming from settings page)
    expiryAlertDays.value = await authRepo.getExpiryAlertDays();
    items.assignAll(data);
    isLoading.value = false;
  }

  Future<void> addItem(ItemModel item) async {
    await itemRepo.insertItem(item);
    loadItems();
  }

  Future<void> updateItem(ItemModel item) async {
    await itemRepo.updateItem(item);
    await loadItems();
  }

  Future<void> deleteItem(int id) async {
    await itemRepo.deleteItem(id);
    await loadItems();
  }

  Future<void> printPdf({List<ItemModel>? itemsToPrint, String? title, String reportType = 'standard'}) async {
    final pdf = pw.Document();
    final reportItems = itemsToPrint ?? items.toList();
    final reportTitle = title ?? 'تقرير المخزون الشامل';

    final fontData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: ttf),
        header: (pw.Context context) => pw.Container(
          alignment: pw.Alignment.centerLeft,
          padding: const pw.EdgeInsets.only(bottom: 15),
          child: pw.Text(
            DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now()),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ),
        build: (pw.Context context) {
          pw.Widget table;

          if (reportType == 'settlement') {
            table = pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 1),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.2), // تسوية
                1: pw.FlexColumnWidth(1),   // التاريخ
                2: pw.FlexColumnWidth(1.2), // المخازن
                3: pw.FlexColumnWidth(1.2), // النظام
                4: pw.FlexColumnWidth(2.5), // الصنف
              },
              children: [
                // Headers with custom colors
                pw.TableRow(
                  children: [
                    _buildCustomHeader('تسويه', PdfColor.fromInt(0xFF1976D2)), // Blue 700
                    _buildCustomHeader('التاريخ', PdfColor.fromInt(0xFF616161)), // Grey 700
                    _buildCustomHeader('المخازن', PdfColor.fromInt(0xFFF57C00)), // Orange 700
                    _buildCustomHeader('النظام', PdfColor.fromInt(0xFFD32F2F)),  // Red 700
                    _buildCustomHeader('الصنف', PdfColor.fromInt(0xFF455A64)),   // BlueGrey 700
                  ],
                ),
                // Data rows
                ...reportItems.map((item) {
                  final storesTotal = item.storeQuantity + item.displayQuantity;
                  final settlement = storesTotal - item.systemQuantity;
                  final settlementText = settlement > 0 ? '+$settlement' : settlement.toString();
                  
                  PdfColor? settlementColor;
                  if (settlement > 0) {
                    settlementColor = PdfColor.fromInt(0xFF1B5E20); // الاخضر الغامق (Dark Green)
                  } else if (settlement < 0) {
                    settlementColor = PdfColor.fromInt(0xFFB71C1C); // الاحمر الغامق (Dark Red)
                  }

                  return pw.TableRow(
                    children: [
                      _buildCell(settlementText, textColor: settlementColor),
                      _buildCell(DateFormat('MM/dd').format(item.expiryDate)),
                      _buildCell(storesTotal.toString()),
                      _buildCell(item.systemQuantity.toString()),
                      _buildCell(item.name),
                    ],
                  );
                }),
              ],
            );
          } else if (reportType == 'comprehensive') {
            table = pw.Table.fromTextArray(
              context: context,
              headers: ['تاريخ الانتهاء', 'النظام', 'المخازن', 'الصنف'],
              headerStyle: pw.TextStyle(color: PdfColors.white, fontSize: 12, fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
              cellAlignment: pw.Alignment.center,
              columnWidths: const {
                0: pw.FlexColumnWidth(1.2),
                1: pw.FlexColumnWidth(1),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(3),
              },
              data: reportItems.map((item) => [
                DateFormat('yyyy/MM/dd').format(item.expiryDate),
                item.systemQuantity.toString(),
                (item.storeQuantity + item.displayQuantity).toString(),
                item.name,
              ]).toList(),
            );
          } else {
             // Standard format
             table = pw.Table.fromTextArray(
              context: context,
              headers: ['تاريخ الانتهاء', 'المخزن الكلي', 'العرض', 'المخازن', 'الصنف'],
              headerStyle: pw.TextStyle(color: PdfColors.white, fontSize: 12, fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
              cellAlignment: pw.Alignment.center,
              columnWidths: const {
                0: pw.FlexColumnWidth(1.2),
                1: pw.FlexColumnWidth(1.0),
                2: pw.FlexColumnWidth(0.8),
                3: pw.FlexColumnWidth(0.8),
                4: pw.FlexColumnWidth(3),
              },
              data: reportItems.map((item) => [
                DateFormat('yyyy/MM/dd').format(item.expiryDate),
                (item.storeQuantity + item.displayQuantity).toString(),
                item.displayQuantity.toString(),
                item.storeQuantity.toString(),
                item.name,
              ]).toList(),
            );
          }

          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(reportTitle, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                  pw.Text('عدد الأصناف: ${reportItems.length}', style: const pw.TextStyle(fontSize: 14)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            table,
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${reportTitle.replaceAll(' ', '_')}.pdf',
    );
  }

  pw.Widget _buildCustomHeader(String text, PdfColor bgColor, {PdfColor textColor = PdfColors.white}) {
    return pw.Container(
      color: bgColor,
      padding: const pw.EdgeInsets.all(8),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildCell(String text, {PdfColor? textColor}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 11, color: textColor ?? PdfColors.black),
      ),
    );
  }
}
