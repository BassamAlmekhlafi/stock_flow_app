import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../data/models/item_model.dart';

class ExcelService extends GetxService {
  // ألوان رؤوس الأعمدة لكل نوع تقرير
  static const _colorDark    = '#1E3A5F'; // أزرق داكن - الرأس الرئيسي
  static const _colorGreen   = '#1B5E20'; // أخضر - اسم الصنف
  static const _colorRed     = '#B71C1C'; // أحمر - النظام
  static const _colorOrange  = '#E65100'; // برتقالي - المخازن
  static const _colorBlue    = '#1565C0'; // أزرق - تسوية/التاريخ
  static const _colorGrey    = '#424242'; // رمادي - حقول أخرى

  CellStyle _header(String hexColor) => CellStyle(
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    backgroundColorHex: ExcelColor.fromHexString(hexColor),
    fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
  );

  CellStyle _cell({bool center = true}) => CellStyle(
    horizontalAlign: center ? HorizontalAlign.Center : HorizontalAlign.Right,
  );

  CellStyle _settlementCell(int value) => CellStyle(
    horizontalAlign: HorizontalAlign.Center,
    bold: true,
    fontColorHex: value > 0
        ? ExcelColor.fromHexString('#1B5E20')
        : value < 0
            ? ExcelColor.fromHexString('#B71C1C')
            : ExcelColor.fromHexString('#000000'),
  );

  /// تصدير بيانات الأصناف إلى ملف Excel بأنواع مختلفة
  /// [reportType]: 'standard' | 'settlement' | 'near_expiry'
  Future<bool> exportToExcel(
    List<ItemModel> items, {
    String reportType = 'standard',
    String? sheetName,
    String? fileName,
  }) async {
    try {
      final excel = Excel.createExcel();
      final resolvedSheet = sheetName ?? _sheetNameFor(reportType);
      final sheet = excel[resolvedSheet];

      switch (reportType) {
        case 'settlement':
        case 'settlement_deficit':
        case 'settlement_surplus':
          _buildSettlementSheet(sheet, items);
          break;
        case 'near_expiry':
          _buildNearExpirySheet(sheet, items);
          break;
        default:
          _buildStandardSheet(sheet, items);
      }

      excel.delete('Sheet1');

      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final resolvedFileName = fileName ?? '${resolvedSheet}_$dateStr.xlsx';
      final fileBytes = excel.encode();
      if (fileBytes == null) return false;

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ ملف Excel',
        fileName: resolvedFileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: Uint8List.fromList(fileBytes),
      );

      if (result != null) {
        try {
          final file = File(result);
          if (!await file.exists() || await file.length() == 0) {
            await file.writeAsBytes(fileBytes, flush: true);
          }
        } catch (e) {
          debugPrint('Excel save fallback skipped: $e');
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Excel export failed: $e');
      return false;
    }
  }

  String _sheetNameFor(String type) {
    switch (type) {
      case 'settlement': return 'تقرير_التسوية_الشامل';
      case 'settlement_deficit': return 'عجز_التسوية';
      case 'settlement_surplus': return 'فائض_التسوية';
      case 'near_expiry': return 'قريبة_الانتهاء';
      default: return 'المخزون_الشامل';
    }
  }

  // --- تقرير المخزون الشامل ---
  void _buildStandardSheet(Sheet sheet, List<ItemModel> items) {
    final headers = ['الصنف', 'المخازن', 'العرض', 'المخزن الكلي', 'تاريخ الانتهاء'];
    final colors = [_colorGreen, _colorOrange, _colorGrey, _colorRed, _colorBlue];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = _header(colors[i]);
    }

    for (int r = 0; r < items.length; r++) {
      final item = items[r];
      final ri = r + 1;
      _setText(sheet, 0, ri, item.name);
      _setInt(sheet, 1, ri, item.storeQuantity);
      _setInt(sheet, 2, ri, item.displayQuantity);
      _setInt(sheet, 3, ri, item.storeQuantity + item.displayQuantity);
      _setText(sheet, 4, ri, DateFormat('yyyy/MM/dd').format(item.expiryDate), center: true);
    }

    sheet.setColumnWidth(0, 32);
    sheet.setColumnWidth(1, 13);
    sheet.setColumnWidth(2, 13);
    sheet.setColumnWidth(3, 13);
    sheet.setColumnWidth(4, 18);
  }

  // --- تقرير التسوية ---
  void _buildSettlementSheet(Sheet sheet, List<ItemModel> items) {
    final headers = ['الصنف', 'النظام', 'المخازن (فعلي)', 'التاريخ', 'التسوية'];
    final colors = [_colorGreen, _colorRed, _colorOrange, _colorBlue, _colorDark];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = _header(colors[i]);
    }

    for (int r = 0; r < items.length; r++) {
      final item = items[r];
      final ri = r + 1;
      final storesTotal = item.storeQuantity + item.displayQuantity;
      final settlement = storesTotal - item.systemQuantity;

      _setText(sheet, 0, ri, item.name);
      _setInt(sheet, 1, ri, item.systemQuantity);
      _setInt(sheet, 2, ri, storesTotal);
      _setText(sheet, 3, ri, DateFormat('yyyy/MM/dd').format(item.expiryDate), center: true);

      // التسوية بلون مخصص
      final settCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: ri));
      settCell.value = IntCellValue(settlement);
      settCell.cellStyle = _settlementCell(settlement);
    }

    sheet.setColumnWidth(0, 32);
    sheet.setColumnWidth(1, 14);
    sheet.setColumnWidth(2, 16);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 14);
  }

  // --- تقرير قريبة الانتهاء ---
  void _buildNearExpirySheet(Sheet sheet, List<ItemModel> items) {
    final headers = ['الصنف', 'المخازن', 'العرض', 'المخزن الكلي', 'تاريخ الانتهاء', 'الأيام المتبقية'];
    final colors = [_colorGreen, _colorOrange, _colorGrey, _colorRed, _colorBlue, _colorDark];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = _header(colors[i]);
    }

    final now = DateTime.now();
    for (int r = 0; r < items.length; r++) {
      final item = items[r];
      final ri = r + 1;
      final remaining = item.expiryDate.difference(now).inDays;

      _setText(sheet, 0, ri, item.name);
      _setInt(sheet, 1, ri, item.storeQuantity);
      _setInt(sheet, 2, ri, item.displayQuantity);
      _setInt(sheet, 3, ri, item.storeQuantity + item.displayQuantity);
      _setText(sheet, 4, ri, DateFormat('yyyy/MM/dd').format(item.expiryDate), center: true);

      final daysCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: ri));
      daysCell.value = IntCellValue(remaining);
      daysCell.cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        bold: remaining < 0,
        fontColorHex: remaining < 0
            ? ExcelColor.fromHexString('#B71C1C')
            : remaining < 30
                ? ExcelColor.fromHexString('#E65100')
                : ExcelColor.fromHexString('#1B5E20'),
      );
    }

    sheet.setColumnWidth(0, 32);
    sheet.setColumnWidth(1, 13);
    sheet.setColumnWidth(2, 13);
    sheet.setColumnWidth(3, 13);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 16);
  }

  // --- مساعدات ---
  void _setText(Sheet s, int col, int row, String val, {bool center = false}) {
    final c = s.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    c.value = TextCellValue(val);
    c.cellStyle = _cell(center: center);
  }

  void _setInt(Sheet s, int col, int row, int val) {
    final c = s.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    c.value = IntCellValue(val);
    c.cellStyle = _cell();
  }

  /// استيراد أصناف من ملف Excel مع دمجها (لا تمسح الموجودة)
  Future<List<ItemModel>?> importFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) return null;

      final bytes = result.files.single.bytes!;
      final excel = Excel.decodeBytes(bytes);

      final sheet = excel.tables.values.first;
      final List<ItemModel> imported = [];

      // ابدأ من الصف الثاني (تخطي الرأس)
      for (int r = 1; r < sheet.maxRows; r++) {
        final row = sheet.row(r);

        // تخطي الصفوف الفارغة
        if (row.isEmpty || row[0]?.value == null) continue;

        final name = row[0]?.value?.toString().trim() ?? '';
        if (name.isEmpty) continue;

        final storeQty = _parseInt(row.length > 1 ? row[1]?.value : null);
        final displayQty = _parseInt(row.length > 2 ? row[2]?.value : null);
        final systemQty = _parseInt(row.length > 3 ? row[3]?.value : null);
        final expiryDate = _parseDate(row.length > 4 ? row[4]?.value : null);

        imported.add(ItemModel(
          name: name,
          storeQuantity: storeQty,
          displayQuantity: displayQty,
          systemQuantity: systemQty,
          expiryDate: expiryDate,
        ));
      }

      return imported;
    } catch (e) {
      debugPrint('Excel import failed: $e');
      return null;
    }
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is IntCellValue) return value.value;
    if (value is DoubleCellValue) return value.value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now().add(const Duration(days: 365));
    final str = value.toString().trim();
    // تحاول تحليل الصيغة yyyy/MM/dd أو yyyy-MM-dd
    try {
      return DateFormat('yyyy/MM/dd').parse(str);
    } catch (_) {
      try {
        return DateTime.parse(str);
      } catch (_) {
        return DateTime.now().add(const Duration(days: 365));
      }
    }
  }
}
