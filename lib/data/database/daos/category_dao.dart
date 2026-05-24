import 'package:drift/drift.dart';
import '../app_database.dart';

class CategoryDao {
  final AppDatabase _db;
  CategoryDao(this._db);

  Future<List<CategoriesTableData>> getAll() => _db.select(_db.categoriesTable).get();

  Future<CategoriesTableData?> getById(int id) {
    return (_db.select(_db.categoriesTable)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<List<CategoriesTableData>> watchAll() => _db.select(_db.categoriesTable).watch();

  Stream<List<CategoriesTableData>> watchByType(String type) {
    return (_db.select(_db.categoriesTable)
      ..where((c) => c.type.equals(type))
      ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)])
    ).watch();
  }

  Future<int> insert(CategoriesTableCompanion entry) {
    return _db.into(_db.categoriesTable).insert(entry);
  }

  Future<bool> update(CategoriesTableCompanion entry) {
    return _db.update(_db.categoriesTable).replace(entry);
  }

  Future<int> delete(int id) {
    return (_db.delete(_db.categoriesTable)..where((c) => c.id.equals(id))).go();
  }

  /// 更新指定分类的排序字段
  Future<void> updateSortOrder(int id, int sortOrder) {
    return (_db.update(_db.categoriesTable)
      ..where((c) => c.id.equals(id))
    ).write(CategoriesTableCompanion(sortOrder: Value(sortOrder)));
  }
}