import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import '../repo.dart';
import '../theme.dart';
import '../money.dart';

void showAddSheet(BuildContext context, Repo repo) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (c) => _AddSheet(repo: repo),
  );
}

class _AddSheet extends StatefulWidget {
  final Repo repo;
  const _AddSheet({required this.repo});

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  int _amount = 0;
  String _cat = Cat.food;
  XFile? _photo;

  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Hue.lift,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 38, height: 4, child: DecoratedBox(decoration: BoxDecoration(color: Hue.text3, borderRadius: BorderRadius.all(Radius.circular(2))))),
          const SizedBox(height: 24),

          Text(money(_amount), style: figure(42)),
          const SizedBox(height: 24),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Cat.all.map((c) => Pill(
              text: c,
              on: _cat == c,
              dot: Hue.forCategory(c),
              onTap: () => setState(() => _cat = c),
            )).toList(),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Ghost(
                text: _photo == null ? 'Photo' : 'Receipt attached',
                icon: Icons.camera_alt_outlined,
                onTap: () async {
                  final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
                  setState(() => _photo = photo);
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Solid(text: 'Save', onTap: () {
                  if (_amount <= 0) {
                    say(context, 'Enter an amount');
                    return;
                  }
                  widget.repo.addExpense(Expense(
                    amount: _amount,
                    category: _cat,
                    note: 'Added from app',
                    at: DateTime.now(),
                    photo: _photo?.path,
                  ));
                  Navigator.pop(context);
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Simplified Keypad
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            childAspectRatio: 2,
            children: [1,2,3,4,5,6,7,8,9,0,'C'].map((k) => GestureDetector(
              onTap: () => setState(() {
                if (k == 'C') _amount = 0;
                else _amount = (_amount * 10) + (k as int);
              }),
              child: Center(child: Text('$k', style: figure(20))),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
