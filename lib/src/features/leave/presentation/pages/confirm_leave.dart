// ignore_for_file: unused_field, must_call_super

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
import 'package:ismart_login/src/app/pages/main_page.dart';
import 'package:http_parser/http_parser.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/system/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ConfirmDialog extends StatefulWidget {
  final String cause;
  final String cidSub;
  final String fullName;
  final String FirstDate;
  final String LastDate;
  final String numDate;
  final String phoneNum;
  final String firstTime;
  final String lastTime;
  final String selectFulltime;
  final bool select1;
  final bool select2;
  final bool select3;
  final List<File> filesAll;
  final String halfDayPeriod;
  final Function(String) onConfirmTap;

  const ConfirmDialog({
    required Key key,
    required this.onConfirmTap,
    required this.cause,
    required this.fullName,
    required this.select1,
    required this.select2,
    required this.select3,
    required this.FirstDate,
    required this.LastDate,
    required this.numDate,
    required this.phoneNum,
    required this.selectFulltime,
    required this.firstTime,
    required this.lastTime,
    required this.cidSub,
    required this.filesAll,
    this.halfDayPeriod = '',
  }) : super(key: key);

  @override
  State<ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<ConfirmDialog> {
  late String typeLeave;
  late String cidLeave;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.select1) {
      typeLeave = 'ลาป่วย';
      cidLeave = '2';
    } else if (widget.select2) {
      typeLeave = 'ลากิจ';
      cidLeave = '3';
    } else {
      typeLeave = 'ลาอื่น ๆ';
      cidLeave = '4';
    }
  }

  String get _displayNumDate {
    // If half-day, always use the passed numDate (0.5)
    if (widget.halfDayPeriod.isNotEmpty) return widget.numDate;
    // For time-range mode just return numDate
    if (widget.selectFulltime != '1') return widget.numDate;
    // For full-day, recalculate from dates to be accurate
    final from = _parseFlexibleDate(widget.FirstDate);
    final to = _parseFlexibleDate(widget.LastDate);
    if (from == null || to == null) {
      return widget.numDate.isEmpty ? '1' : widget.numDate;
    }
    final days =
        DateTime(to.year, to.month, to.day)
            .difference(DateTime(from.year, from.month, from.day))
            .inDays
            .abs() +
        1;
    return days.toString();
  }

  DateTime? _parseFlexibleDate(String raw) {
    final value = raw.trim();
    final ymd = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(value);
    if (ymd != null) {
      return DateTime(
        int.parse(ymd.group(1)!),
        int.parse(ymd.group(2)!),
        int.parse(ymd.group(3)!),
      );
    }
    final dmy = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2,4})$').firstMatch(value);
    if (dmy != null) {
      int year = int.parse(dmy.group(3)!);
      if (year > 2400) year -= 543;
      return DateTime(year, int.parse(dmy.group(2)!), int.parse(dmy.group(1)!));
    }
    return null;
  }

  String get _halfDayLabel {
    if (widget.halfDayPeriod == 'morning') return 'ครึ่งวันเช้า';
    if (widget.halfDayPeriod == 'afternoon') return 'ครึ่งวันบ่าย';
    return '';
  }

  String get _periodIcon {
    if (widget.halfDayPeriod == 'morning') return '🌅';
    if (widget.halfDayPeriod == 'afternoon') return '🌇';
    return '';
  }

  Future<void> _insertLeave() async {
    if (_isLoading) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final uid = await SharedCashe.getItemsWay(name: 'id');
      final orgId = await SharedCashe.getItemsWay(name: 'org_id');
      final cid = widget.cidSub.isNotEmpty ? widget.cidSub : cidLeave;

      var uri = Uri.parse(Server().insertInfoLeave);
      var request = http.MultipartRequest('POST', uri);
      request.fields['uid'] = uid;
      request.fields['org_id'] = orgId;
      request.fields['cause'] = widget.cause;
      request.fields['firstdate'] = widget.FirstDate;
      request.fields['lastdate'] = widget.LastDate;
      request.fields['phoneNum'] = widget.phoneNum;
      request.fields['numDate'] = _displayNumDate;
      request.fields['selectFultime'] = widget.selectFulltime;
      request.fields['firstTime'] = widget.firstTime;
      request.fields['lastTime'] = widget.lastTime;
      request.fields['selectFulltime'] = widget.selectFulltime;
      request.fields['cid'] = cid;
      if (widget.halfDayPeriod.isNotEmpty) {
        request.fields['half_day_period'] = widget.halfDayPeriod;
      }

      for (int i = 0; i < widget.filesAll.length; i++) {
        final ext = widget.filesAll[i].path.split('.').last;
        final file = await http.MultipartFile.fromPath(
          'file[$i]',
          widget.filesAll[i].path,
          contentType: MediaType('image', ext),
        );
        request.files.add(file);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['msg'] == 'success') {
          Navigator.pop(context);
          _showResultDialog(
            success: true,
            message: 'ส่งใบลาเรียบร้อยแล้ว',
          );
        } else {
          Navigator.pop(context);
          _showResultDialog(
            success: false,
            message: 'ไม่สามารถบันทึกข้อมูลใบลา\nกรุณาติดต่อเจ้าหน้าที่',
          );
        }
      } else {
        Navigator.pop(context);
        _showResultDialog(
          success: false,
          message: 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pop(context);
      _showResultDialog(
        success: false,
        message: 'เกิดข้อผิดพลาด: $e',
      );
    }
  }

  void _showResultDialog({required bool success, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: success ? const Color(0xFF21CCD4) : Colors.red[100],
              ),
              child: Icon(
                success ? Icons.check_rounded : Icons.close_rounded,
                color: success ? Colors.white : Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF21CCD4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                if (success) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => MainPage()),
                    (_) => false,
                  );
                }
              },
              child: Text(
                'รับทราบ',
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTimeRange = widget.selectFulltime == '2';
    final numDisplay = _displayNumDate;
    final unit = isTimeRange ? 'ชม.' : 'วัน';

    String dateString;
    if (isTimeRange) {
      dateString =
          'วันที่ ${widget.FirstDate}\nเวลา ${widget.firstTime} - ${widget.lastTime}';
    } else {
      dateString = widget.FirstDate == widget.LastDate
          ? 'วันที่ ${widget.FirstDate}'
          : 'ตั้งแต่ ${widget.FirstDate}\nถึง ${widget.LastDate}';
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF21CCD4), Color(0xFF0663F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'ยืนยันการส่งใบลา',
                    style: GoogleFonts.kanit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      typeLeave,
                      style: GoogleFonts.kanit(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Body ────────────────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'ผู้ขอลา',
                    value: widget.fullName,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.notes_rounded,
                    label: 'เหตุผล',
                    value: widget.cause,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'วันที่ลา',
                    value: dateString,
                  ),
                  const SizedBox(height: 12),
                  // Day / hour count row
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF21CCD4).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.today_rounded,
                          size: 18,
                          color: Color(0xFF21CCD4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'จำนวน',
                          style: GoogleFonts.kanit(
                              fontSize: 14, color: Colors.grey[600]),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF21CCD4), Color(0xFF0663F7)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$numDisplay $unit',
                          style: GoogleFonts.kanit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Half-day period badge
                  if (widget.halfDayPeriod.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFFFFCC02), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _periodIcon,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _halfDayLabel,
                                style: GoogleFonts.kanit(
                                  fontSize: 12,
                                  color: const Color(0xFFE65100),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'เบอร์ติดต่อ',
                    value: widget.phoneNum,
                  ),
                  const SizedBox(height: 20),
                  // ── Action Buttons ───────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _isLoading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFCCCCCC)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            'ยกเลิก',
                            style: GoogleFonts.kanit(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isLoading ? null : _insertLeave,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF21CCD4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  'ยืนยัน',
                                  style: GoogleFonts.kanit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
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

// ─── Helper widget ────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF21CCD4).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF21CCD4)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.kanit(
                    fontSize: 12, color: Colors.grey[500]),
              ),
              Text(
                value,
                style: GoogleFonts.kanit(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
