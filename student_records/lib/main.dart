import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'student.dart';

void main() => runApp(const RecordsApp());

class RecordsApp extends StatelessWidget {
  const RecordsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Student Records',
        theme: ThemeData(
            colorSchemeSeed: const Color(0xFF002060),
            useMaterial3: true),
        home: const StudentListPage(),
      );
}

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});
  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final _dbh = DatabaseHelper.instance;
  final _searchCtrl = TextEditingController();
  List<Student> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final term = _searchCtrl.text.trim();
    final data = term.isEmpty
        ? await _dbh.allStudents()
        : await _dbh.searchStudents(term);
    if (!mounted) return;
    setState(() {
      _students = data;
      _loading = false;
    });
  }

  Future<void> _showStatistics() async {
    final stats = await _dbh.levelStatistics();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Students per level'),
        content: stats.isEmpty
            ? const Text('No data yet.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: stats
                    .map((row) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Level ${row['level']}'),
                              Text('${row['n']} student(s)'),
                            ],
                          ),
                        ))
                    .toList(),
              ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _openForm({Student? existing}) async {
    final indexCtrl = TextEditingController(text: existing?.indexNo ?? '');
    final nameCtrl = TextEditingController(text: existing?.fullName ?? '');
    final progCtrl = TextEditingController(text: existing?.programme ?? '');
    final levelCtrl =
        TextEditingController(text: existing?.level.toString() ?? '100');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(existing == null ? 'Add Student' : 'Edit Student',
                style: Theme.of(ctx).textTheme.titleLarge),
            TextField(
                controller: indexCtrl,
                decoration:
                    const InputDecoration(labelText: 'Index number')),
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full name')),
            TextField(
                controller: progCtrl,
                decoration: const InputDecoration(labelText: 'Programme')),
            TextField(
                controller: levelCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Level (100-400)')),
            TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(labelText: 'Email (optional)')),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final student = Student(
                  id: existing?.id,
                  indexNo: indexCtrl.text.trim(),
                  fullName: nameCtrl.text.trim(),
                  programme: progCtrl.text.trim(),
                  level: int.tryParse(levelCtrl.text) ?? 100,
                  email: emailCtrl.text.trim().isEmpty
                      ? null
                      : emailCtrl.text.trim(),
                );
                if (existing == null) {
                  await _dbh.insertStudent(student);
                } else {
                  await _dbh.updateStudent(student);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(existing == null ? 'Save' : 'Update'),
            ),
          ],
        ),
      ),
    );
    _refresh();
  }

  Future<void> _confirmDelete(Student s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${s.fullName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _dbh.deleteStudent(s.id!);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Records'),
        actions: [
          IconButton(
              onPressed: _showStatistics,
              icon: const Icon(Icons.bar_chart),
              tooltip: 'Statistics'),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _refresh(),
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(child: Text('No students yet - tap +'))
              : ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (context, i) {
                    final s = _students[i];
                    return ListTile(
                      leading:
                          CircleAvatar(child: Text('${s.level ~/ 100}')),
                      title: Text(s.fullName),
                      subtitle: Text('${s.indexNo} - ${s.programme}'),
                      onTap: () => _openForm(existing: s),
                      onLongPress: () => _confirmDelete(s),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
