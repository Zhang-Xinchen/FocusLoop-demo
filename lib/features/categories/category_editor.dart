import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../domain/domain.dart';

const presetCategoryColors = [
  0xFFE57373,
  0xFF64B5F6,
  0xFF81C784,
  0xFFFFD54F,
  0xFFBA68C8,
  0xFF4DB6AC,
  0xFFFF8A65,
  0xFF90A4AE,
];

/// Shows the new/edit-category dialog. Returns the saved category,
/// or null if the user cancelled.
Future<Category?> showCategoryEditor(
  BuildContext context,
  WidgetRef ref, {
  Category? category,
}) async {
  final nameController = TextEditingController(text: category?.name ?? '');
  final target = category?.targetSeconds ?? 0;
  final hoursController =
      TextEditingController(text: target ~/ 3600 > 0 ? '${target ~/ 3600}' : '');
  final minutesController = TextEditingController(
    text: (target % 3600) ~/ 60 > 0 ? '${(target % 3600) ~/ 60}' : '',
  );
  var color = category?.color ?? presetCategoryColors.first;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(category == null ? '新分类' : '修改分类'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '分类名称'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text('目标时长（可选）'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: hoursController,
                        decoration: const InputDecoration(labelText: '小时'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: minutesController,
                        decoration: const InputDecoration(labelText: '分钟'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final preset in presetCategoryColors)
                      GestureDetector(
                        onTap: () => setState(() => color = preset),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(preset),
                            shape: BoxShape.circle,
                            border: preset == color
                                ? Border.all(color: Colors.black54, width: 3)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('保存'),
              ),
            ],
          );
        },
      );
    },
  );
  final name = nameController.text.trim();
  final hours = int.tryParse(hoursController.text.trim()) ?? 0;
  final minutes = int.tryParse(minutesController.text.trim()) ?? 0;
  nameController.dispose();
  hoursController.dispose();
  minutesController.dispose();
  if (confirmed != true || name.isEmpty) {
    return null;
  }
  final now = DateTime.now();
  final saved = Category(
    id: category?.id ?? const Uuid().v4(),
    name: name,
    color: color,
    sortOrder: category?.sortOrder ?? 0,
    targetSeconds: hours * 3600 + minutes * 60,
    createdAt: category?.createdAt ?? now,
    updatedAt: now,
    deleted: category?.deleted ?? false,
  );
  await ref.read(categoryRepositoryProvider).save(saved);
  return saved;
}
