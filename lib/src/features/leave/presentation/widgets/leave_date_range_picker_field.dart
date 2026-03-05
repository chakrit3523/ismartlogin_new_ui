import 'package:flutter/material.dart';
import 'package:ismart_login/src/features/leave/domain/entities/leave_date_selection.dart';
import 'package:ismart_login/src/features/leave/domain/usecases/leave_date_calculator.dart';
import 'package:ismart_login/src/features/leave/presentation/helpers/thai_leave_date_formatter.dart';
import 'package:ismart_login/src/features/leave/presentation/widgets/leave_date_range_picker_controller.dart';
import 'package:ismart_login/src/features/leave/presentation/widgets/thai_date_range_picker.dart';

class LeaveDateRangePickerField extends StatefulWidget {
  const LeaveDateRangePickerField({
    super.key,
    this.initialStart,
    this.initialEnd,
    this.enableHalfDay = false,
    this.enableTimeRange = false,
    this.bookedLeaveDates = const {},
    required this.onChanged,
  });

  final DateTime? initialStart;
  final DateTime? initialEnd;
  final bool enableHalfDay;
  final bool enableTimeRange;
  final Set<DateTime> bookedLeaveDates;
  final ValueChanged<LeaveDateSelection> onChanged;

  @override
  State<LeaveDateRangePickerField> createState() =>
      _LeaveDateRangePickerFieldState();
}

class _LeaveDateRangePickerFieldState extends State<LeaveDateRangePickerField> {
  late LeaveDateRangePickerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LeaveDateRangePickerController(
      initialStart: widget.initialStart,
      initialEnd: widget.initialEnd,
    );
  }

  @override
  void didUpdateWidget(covariant LeaveDateRangePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changedInitial = oldWidget.initialStart != widget.initialStart ||
        oldWidget.initialEnd != widget.initialEnd;
    if (changedInitial &&
        widget.initialStart != null &&
        widget.initialEnd != null) {
      _controller.setDateRange(widget.initialStart!, widget.initialEnd!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDateRangeAndOptions() async {
    final pickedRange = await showThaiDateRangePicker(
      context: context,
      initialStart: _controller.startDate,
      initialEnd: _controller.endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      bookedLeaveDates: widget.bookedLeaveDates,
    );

    if (pickedRange == null) {
      return;
    }

    final tempController = LeaveDateRangePickerController(
      initialStart: pickedRange.start,
      initialEnd: pickedRange.end,
    );

    tempController.applySelection(_controller.toSelection());
    tempController.setDateRange(pickedRange.start, pickedRange.end);

    LeaveDateSelection? selection;

    if (widget.enableHalfDay || widget.enableTimeRange) {
      selection = await _showOptionsModal(tempController);
    } else {
      try {
        selection = tempController.toSelection();
      } catch (_) {
        selection = null;
      }
    }

    tempController.dispose();

    if (selection == null) return;

    _controller.applySelection(selection);
    widget.onChanged(selection);
  }

  Future<LeaveDateSelection?> _showOptionsModal(
    LeaveDateRangePickerController controller,
  ) {
    return showModalBottomSheet<LeaveDateSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final validationError = controller.validate();

              String amountLabel = '-';
              if (validationError == null) {
                final amount = controller.toSelection().totalDays;
                amountLabel = controller.isTimeRange
                    ? '${_formatAmount(amount)} ชม.'
                    : '${_formatAmount(amount)} วัน';
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'รายละเอียดการลา',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ThaiLeaveDateFormatter.toThaiDateRange(
                      controller.startDate,
                      controller.endDate,
                      includeBuddhistYear: true,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<_LeaveMode>(
                    showSelectedIcon: false,
                    segments: _buildModeSegments(context),
                    selected: {_currentMode(controller)},
                    onSelectionChanged: (selected) {
                      final mode = selected.first;
                      controller.setHalfDay(mode == _LeaveMode.halfDay);
                      controller.setTimeRange(mode == _LeaveMode.timeRange);
                    },
                  ),
                  if (controller.isTimeRange) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _TimePickerButton(
                            label: 'เวลาเริ่ม',
                            value: controller.startTime,
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: controller.startTime ??
                                    const TimeOfDay(hour: 8, minute: 30),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      useMaterial3: true,
                                    ),
                                    child: child ?? const SizedBox.shrink(),
                                  );
                                },
                              );
                              if (picked != null) {
                                controller.setStartTime(picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimePickerButton(
                            label: 'เวลาสิ้นสุด',
                            value: controller.endTime,
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: controller.endTime ??
                                    const TimeOfDay(hour: 17, minute: 30),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      useMaterial3: true,
                                    ),
                                    child: child ?? const SizedBox.shrink(),
                                  );
                                },
                              );
                              if (picked != null) {
                                controller.setEndTime(picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (controller.isHalfDay) ...[
                    const SizedBox(height: 16),
                    SegmentedButton<HalfDayPeriod>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment<HalfDayPeriod>(
                          value: HalfDayPeriod.morning,
                          label: Text('ครึ่งวันเช้า'),
                          icon: Icon(Icons.wb_sunny_outlined, size: 18),
                        ),
                        ButtonSegment<HalfDayPeriod>(
                          value: HalfDayPeriod.afternoon,
                          label: Text('ครึ่งวันบ่าย'),
                          icon: Icon(Icons.wb_twilight_outlined, size: 18),
                        ),
                      ],
                      selected: {
                        controller.halfDayPeriod ?? HalfDayPeriod.morning
                      },
                      onSelectionChanged: (selected) {
                        controller.setHalfDayPeriod(selected.first);
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('รวม'),
                        Text(
                          amountLabel,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  if (validationError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      mapLeaveDateValidationError(validationError),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: validationError == null
                        ? () =>
                            Navigator.of(context).pop(controller.toSelection())
                        : null,
                    child: const Text('ยืนยัน'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<ButtonSegment<_LeaveMode>> _buildModeSegments(BuildContext context) {
    final segments = <ButtonSegment<_LeaveMode>>[
      const ButtonSegment<_LeaveMode>(
        value: _LeaveMode.fullDay,
        label: Text('ทั้งวัน'),
      ),
    ];

    if (widget.enableHalfDay) {
      segments.add(
        const ButtonSegment<_LeaveMode>(
          value: _LeaveMode.halfDay,
          label: Text('ครึ่งวัน'),
        ),
      );
    }

    if (widget.enableTimeRange) {
      segments.add(
        const ButtonSegment<_LeaveMode>(
          value: _LeaveMode.timeRange,
          label: Text('รายชั่วโมง'),
        ),
      );
    }

    return segments;
  }

  _LeaveMode _currentMode(LeaveDateRangePickerController controller) {
    if (controller.isTimeRange) return _LeaveMode.timeRange;
    if (controller.isHalfDay) return _LeaveMode.halfDay;
    return _LeaveMode.fullDay;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final rangeLabel = ThaiLeaveDateFormatter.toThaiDateRange(
          _controller.startDate,
          _controller.endDate,
        );

        final amountLabel = _controller.isTimeRange
            ? '${_formatAmount(_controller.toSelection().totalDays)} ชม.'
            : '${_formatAmount(_controller.toSelection().totalDays)} วัน';

        final modeLabel = _controller.isTimeRange
            ? 'รายชั่วโมง'
            : _controller.isHalfDay
                ? (_controller.halfDayPeriod == HalfDayPeriod.afternoon
                    ? 'ครึ่งวันบ่าย'
                    : 'ครึ่งวันเช้า')
                : 'ทั้งวัน';

        return InkWell(
          onTap: _pickDateRangeAndOptions,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rangeLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$modeLabel • $amountLabel',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatAmount(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

enum _LeaveMode { fullDay, halfDay, timeRange }

class _TimePickerButton extends StatelessWidget {
  const _TimePickerButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final TimeOfDay? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value == null
                  ? label
                  : ThaiLeaveDateFormatter.toTimeLabel(value!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
