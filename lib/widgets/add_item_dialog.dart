// lib/widgets/add_item_dialog.dart
import 'package:flutter/material.dart';

class AddItemDialog extends StatefulWidget {
  final String bagId;

  const AddItemDialog({super.key, required this.bagId});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // 카테고리는 당분간 사용 안 함 (추후 재활성화용으로 남겨둠)
  // String _selectedCategory = '';

  String _selectedLocation = '메인칸';

  // final List<String> _categories = [
  //   '의류',
  //   '신발',
  //   '세면용품',
  //   '화장품',
  //   '전자기기',
  //   '서류',
  //   '의료용품',
  //   '액세서리',
  //   '음식',
  //   '기타',
  //   '도서',
  //   '운동용품',
  //   '선물',
  // ];

  final List<String> _locations = [
    '메인칸',
    '앞주머니',
    '노트북칸',
    '지퍼백',
    '세컨파우치',
    '슈즈칸',
    '세면파우치',
    '기타',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '새 아이템 추가',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // 아이템 이름
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '아이템 이름',
                  hintText: '예: 여권, 충전기, 옷가지',
                ),
                validator: (v) =>
                (v == null || v.isEmpty) ? '아이템 이름을 입력해주세요' : null,
              ),
              const SizedBox(height: 16),

              // 🔒 카테고리 선택은 당분간 사용 안 함
              // DropdownButtonFormField<String>(
              //   value: _selectedCategory.isEmpty ? null : _selectedCategory,
              //   decoration: const InputDecoration(labelText: '카테고리'),
              //   items: _categories
              //       .map((c) =>
              //           DropdownMenuItem(value: c, child: Text(c)))
              //       .toList(),
              //   onChanged: (v) => setState(() => _selectedCategory = v ?? ''),
              //   validator: (v) =>
              //       (v == null || v.isEmpty) ? '카테고리를 선택해주세요' : null,
              // ),
              // const SizedBox(height: 16),

              // 가방 위치
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: const InputDecoration(labelText: '가방 위치'),
                items: _locations
                    .map((l) =>
                    DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedLocation = v ?? '메인칸'),
                validator: (v) =>
                (v == null || v.isEmpty) ? '가방 위치를 선택해주세요' : null,
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onSubmit,
                      child: const Text('추가하기'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
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

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(
        NewItemInput(
          name: _nameController.text.trim(),
          // category: _selectedCategory, // 🔒 현재는 사용 안 함
          location: _selectedLocation,
        ),
      );
    }
  }
}

/// 다이얼로그에서 입력한 값 묶어서 반환하는 DTO
class NewItemInput {
  final String name;
  // final String category; // 🔒 카테고리 필드도 잠시 비활성화
  final String location;

  NewItemInput({
    required this.name,
    // required this.category,
    required this.location,
  });
}
