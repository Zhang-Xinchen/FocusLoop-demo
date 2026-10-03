import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../domain/domain.dart';
import '../categories/category_editor.dart';
import 'task_service.dart';

Future<void> showTaskEditor(BuildContext context, {Task? task}) {
  return showDialog<void>(
    context: context,
    builder: (context) => TaskEditorDialog(task: task),
  );
}

class TaskEditorDialog extends ConsumerStatefulWidget {
  const TaskEditorDialog({super.key, this.task});

  final Task? task;

  @override
  ConsumerState<TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends ConsumerState<TaskEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;
  String? _categoryId;
  DateTime? _dueDate;
  bool _timed = true;
  bool _reviewEnabled = false;
  String _templateId = ReviewTemplate.standard.id;

  Task? get _task => widget.task;

  @override
  void initState() {
    super.initState();
    final task = _task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _noteController = TextEditingController(text: task?.note ?? '');
    final target = task?.targetSeconds ?? 0;
    _hoursController =
        TextEditingController(text: target ~/ 3600 > 0 ? '${target ~/ 3600}' : '');
    _minutesController = TextEditingController(
      text: (target % 3600) ~/ 60 > 0 ? '${(target % 3600) ~/ 60}' : '',
    );
    _categoryId = task?.categoryId;
    _dueDate = task?.dueDate;
    _timed = task?.timed ?? true;
    _reviewEnabled = task?.reviewEnabled ?? false;
    _templateId = task?.reviewTemplateId ?? ReviewTemplate.standard.id;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final hours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
    final now = DateTime.now();
    final existing = _task;
    final task = Task(
      id: existing?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      categoryId: _categoryId,
      dueDate: _dueDate,
      targetSeconds: _timed ? hours * 3600 + minutes * 60 : 0,
      accumulatedSeconds: existing?.accumulatedSeconds ?? 0,
      status: existing?.status ?? TaskStatus.active,
      timed: _timed,
      reviewEnabled: _reviewEnabled,
      reviewTemplateId: _reviewEnabled ? _templateId : null,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await ref.read(taskServiceProvider).saveTask(task);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: '选择完成日期',
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}年${date.month}月${date.day}日';

  @override
  Widget build(BuildContext context) {
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final validCategoryId = _categoryId != null &&
            categories.any((category) => category.id == _categoryId)
        ? _categoryId
        : null;
    return AlertDialog(
      title: Text(_task == null ? '新任务' : '编辑任务'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: '任务名称'),
                  autofocus: _task == null,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? '请输入任务名称'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: '备注（可选）'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: validCategoryId,
                        decoration: const InputDecoration(labelText: '分类'),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('无分类')),
                          for (final category in categories)
                            DropdownMenuItem(
                              value: category.id,
                              child: Text(category.name),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _categoryId = value),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final created =
                            await showCategoryEditor(context, ref);
                        if (created != null) {
                          setState(() => _categoryId = created.id);
                        }
                      },
                      child: const Text('新建'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: const Text('完成日期'),
                  subtitle:
                      Text(_dueDate == null ? '未设置' : _formatDate(_dueDate!)),
                  trailing: _dueDate == null
                      ? const Icon(Icons.chevron_right)
                      : IconButton(
                          tooltip: '清除日期',
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _dueDate = null),
                        ),
                  onTap: _pickDueDate,
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('计时任务'),
                  subtitle: const Text('关闭后为普通待办，点击圆圈即可完成'),
                  value: _timed,
                  onChanged: (value) => setState(() => _timed = value),
                ),
                if (_timed) ...[
                  Text('目标时长',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _hoursController,
                          decoration: const InputDecoration(labelText: '小时'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            return int.tryParse(value.trim()) == null
                                ? '请输入数字'
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _minutesController,
                          decoration: const InputDecoration(labelText: '分钟'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            return int.tryParse(value.trim()) == null
                                ? '请输入数字'
                                : null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('艾宾浩斯复习任务'),
                  value: _reviewEnabled,
                  onChanged: (value) =>
                      setState(() => _reviewEnabled = value),
                ),
                if (_reviewEnabled)
                  DropdownButtonFormField<String>(
                    initialValue: _templateId,
                    decoration: const InputDecoration(labelText: '复习曲线'),
                    items: [
                      for (final template in ReviewTemplate.builtIn)
                        DropdownMenuItem(
                          value: template.id,
                          child: Text(template.name),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _templateId = value);
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}
