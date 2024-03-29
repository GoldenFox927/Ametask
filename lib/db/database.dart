import 'package:ametask/models/tasks_model.dart';
import 'package:ametask/models/tasklists_model.dart';
import 'package:ametask/models/folders_model.dart';
import 'package:ametask/models/tags_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AmetaskDatabase {
  static AmetaskDatabase instance = AmetaskDatabase._init();

  Database? _database;

  AmetaskDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('ametaskDatabase.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
    // onCreate execute la fonction lors de la creation de la db
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';

    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const boolType = 'BOOLEAN NOT NULL';

    const nullIntType = 'BOOLEAN';
    const nullTextType = 'TEXT';

    await db.execute('''
CREATE TABLE $tableTags (
  ${TagFields.id} $idType,
  ${TagFields.name} $textType,
  ${TagFields.color} $textType
);
''');

    await db.execute('''
CREATE TABLE $tableFolders (
  ${FolderFields.id} $idType,
  ${FolderFields.name} $textType,
  ${FolderFields.color} $textType,
  ${FolderFields.description} $textType,
  ${FolderFields.tagsList} $textType
);
''');

    await db.execute('''
CREATE TABLE $tableTasklists (
  ${TasklistFields.id} $idType,
  ${TasklistFields.idFolder} $integerType,
  ${TasklistFields.name} $textType,
  ${TasklistFields.color} $textType,
  ${TasklistFields.description} $textType,
  ${TasklistFields.createDate} $textType,
  ${TasklistFields.lastModifDate} $textType,
  ${TasklistFields.tagsList} $textType,
  ${TasklistFields.isShow} $boolType,
  FOREIGN KEY(${TasklistFields.id}) REFERENCES $tableFolders(${FolderFields.id})
);''');

    await db.execute('''
CREATE TABLE $tableTasks (
  ${TasksFields.id} $idType,
  ${TasksFields.idTasklist} $integerType,
  ${TasksFields.position} $integerType,
  ${TasksFields.name} $textType,
  ${TasksFields.description} $textType,
  ${TasksFields.type} $textType,
  ${TasksFields.finished} $boolType,
  ${TasksFields.toDoNum} $nullIntType,
  ${TasksFields.doneNum} $nullIntType,
  ${TasksFields.picture} $nullTextType,
  FOREIGN KEY(${TasksFields.idTasklist}) REFERENCES $tableTasklists(${TasklistFields.id})
)
''');
    createFolder(const Folder(
        name: 'no_folder',
        color: 'white',
        description: 'tasklists without folder',
        tagsList: []));
  }

  Future<Tasklist> createTasklist(Tasklist tasklist) async {
    final db = await instance.database;

    // autre solution (voir la vidéo à 13 min)
    final id = await db.insert(tableTasklists, tasklist.toJson());
    return tasklist.copy(id: id);
  }

  Future<Task> createTask(Task task) async {
    final db = await instance.database;

    // autre solution (voir la vidéo à 13 min)
    final id = await db.insert(tableTasks, task.toJson());
    return task.copy(id: id);
  }

  Future<Tasklist> readTasklist(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      tableTasklists,
      columns: TasklistFields.values,
      where: '${TasklistFields.id} = ?',
      whereArgs: [id], // replace the '?' (prevent sql injection attacks)
    );
    if (maps.isNotEmpty) {
      return Tasklist.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Tasklist>> readAllTasklists() async {
    final db = await instance.database;

    const orderBy = '${TasklistFields.lastModifDate} DESC';

    // autre méthode avec le rawQuery
    try {
      final result = await db.query(tableTasklists, orderBy: orderBy);
      return result.map((json) => Tasklist.fromJson(json)).toList();
    } catch (e) {
      instance = AmetaskDatabase._init();
      final db = await instance.database;
      final result = await db.query(tableTasklists, orderBy: orderBy);
      return result.map((json) => Tasklist.fromJson(json)).toList();
    }
  }

  Future<List<Task>> readAllTasksFor(int idTasklist, bool showFinished) async {
    final db = await instance.database;

    const orderBy = '${TasksFields.position} ASC';

    List<Map<String, Object?>> result;
    // autre méthode avec le rawQuery
    if (showFinished) {
      result = await db.query(tableTasks,
          where: '${TasksFields.idTasklist} = ?',
          whereArgs: [idTasklist],
          orderBy: orderBy);
    } else {
      result = await db.query(
        tableTasks,
        where: '${TasksFields.idTasklist} = ? AND NOT ${TasksFields.finished}',
        whereArgs: [idTasklist],
        orderBy: orderBy,
      );
    }

    return result.map((json) => Task.fromJson(json)).toList();
  }

  Future<int> countAllTasksFor(int idTasklist) async {
    final db = await instance.database;

    int count = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM $tableTasks WHERE ${TasksFields.idTasklist} == $idTasklist'))!;

    return count;
  }

  Future<int> countAllFinishedTasksFor(int idTasklist) async {
    final db = await instance.database;

    int count = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM $tableTasks WHERE ${TasksFields.idTasklist} == $idTasklist AND ${TasksFields.finished}'))!;

    return count;
  }

  Future<Task> readTask(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      tableTasks,
      columns: TasksFields.values,
      where: '${TasksFields.id} = ?',
      whereArgs: [id], // replace the '?' (prevent sql injection attacks)
    );
    if (maps.isNotEmpty) {
      return Task.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future updateTasklist(Tasklist tasklist) async {
    final db = await instance.database;

    return db.update(
      tableTasklists,
      tasklist.toJson(),
      where: '${TasklistFields.id} = ?',
      whereArgs: [tasklist.id],
    );
  }

  Future updateTask(Task task) async {
    final db = await instance.database;

    return db.update(
      tableTasks,
      task.toJson(),
      where: '${TasklistFields.id} = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTasklist(int id) async {
    final db = await instance.database;

    await db.delete(
      tableTasks,
      where: '${TasksFields.idTasklist} = ?',
      whereArgs: [id],
    );

    return await db.delete(
      tableTasklists,
      where: '${TasklistFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await instance.database;

    return await db.delete(
      tableTasks,
      where: '${TasksFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<Folder> createFolder(Folder folder) async {
    final db = await instance.database;

    // autre solution (voir la vidéo à 13 min)
    final id = await db.insert(tableFolders, folder.toJson());
    return folder.copy(id: id);
  }

  Future close() async {
    final db = await instance.database;

    db.close();
  }
}
