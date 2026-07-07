import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'student.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'student_records.db'),
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE students(
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            indexNo   TEXT NOT NULL UNIQUE,
            fullName  TEXT NOT NULL,
            programme TEXT NOT NULL,
            level     INTEGER NOT NULL,
            email     TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE students ADD COLUMN email TEXT');
        }
      },
    );
  }

  // CREATE
  Future<int> insertStudent(Student s) async {
    final db = await database;
    return db.insert('students', s.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // READ (all)
  Future<List<Student>> allStudents() async {
    final db = await database;
    final rows = await db.query('students', orderBy: 'fullName ASC');
    return rows.map(Student.fromMap).toList();
  }

  // READ (search) - Challenge 1
  Future<List<Student>> searchStudents(String term) async {
    final db = await database;
    final rows = await db.query(
      'students',
      where: 'fullName LIKE ?',
      whereArgs: ['%$term%'],
      orderBy: 'fullName ASC',
    );
    return rows.map(Student.fromMap).toList();
  }

  // UPDATE
  Future<int> updateStudent(Student s) async {
    final db = await database;
    return db.update('students', s.toMap(),
        where: 'id = ?', whereArgs: [s.id]);
  }

  // DELETE
  Future<int> deleteStudent(int id) async {
    final db = await database;
    return db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  // STATISTICS - Challenge 2
  Future<List<Map<String, Object?>>> levelStatistics() async {
    final db = await database;
    return db.rawQuery(
        'SELECT level, COUNT(*) AS n FROM students GROUP BY level ORDER BY level');
  }
}
