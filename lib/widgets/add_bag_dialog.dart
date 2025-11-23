// lib/widgets/add_bag_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/packing_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/device_provider.dart';

import '../models/bag.dart' as model;
import '../service/bag_api.dart';

class AddBagDialog extends StatefulWidget {
  const AddBagDialog({super.key});

  @override
  State<AddBagDialog> createState() => _AddBagDialogState();
}

class _AddBagDialogState extends State<AddBagDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedType = '';

  /// ✅ 서버 enum 값 그대로 사용
  final List<String> _types = [
    'carry_on',
    'checked',
    'custom',
  ];

  /// 화면에 보여줄 한글 라벨
  final Map<String, String> _typeLabels = {
    'carry_on': '기내용',
    'checked': '위탁용',
    'custom': '개인 소지품',
  };

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '새 가방 추가',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '가방 이름',
                  hintText: '예: 보조 가방, 크로스백',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '가방 이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedType.isEmpty ? null : _selectedType,
                decoration: const InputDecoration(
                  labelText: '가방 종류',
                ),
                items: _types.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_typeLabels[type] ?? type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '가방 종류를 선택해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _addBag,
                      child: _isSaving
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text('추가하기'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addBag() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final packingProvider = context.read<PackingProvider>();
    final tripProvider = context.read<TripProvider>();
    final deviceProvider = context.read<DeviceProvider>();

    final name = _nameController.text;
    final bagType = _selectedType;

    try {
      final currentTrip = tripProvider.currentTrip;
      final deviceUuid = deviceProvider.deviceUuid;
      final deviceToken = deviceProvider.deviceToken;

      // 🔹 서버에 요청할 수 있는 조건이 안 되면 → 로컬에만 추가
      if (currentTrip == null ||
          deviceUuid == null ||
          deviceToken == null ||
          currentTrip.id.isEmpty) {
        final colors = ['blue', 'green', 'purple', 'orange', 'pink', 'teal'];
        final randomColor =
        colors[DateTime.now().millisecondsSinceEpoch % colors.length];

        final newBag = model.Bag(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          type: bagType,
          color: randomColor,
          items: const [],
        );

        packingProvider.addBag(newBag);
        Navigator.of(context).pop();
        return;
      }

      // ✅ 여기서부터는 실제 API 호출 (/v1/trips/{trip_id}/bags)
      final api = BagApiService();
      final created = await api.createBag(
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
        tripId: int.parse(currentTrip.id), // 🔥 Trip에는 id(String)만 있음
        name: name,
        bagType: bagType,
      );

      // 프로바이더 상태에도 추가
      packingProvider.addBag(created);

      Navigator.of(context).pop();
    } catch (e) {
      // 에러 메시지는 간단하게 Snackbar로
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('가방 추가에 실패했어요: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
