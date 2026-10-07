import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AttendanceLocalDatabase {
AttendanceLocalDatabase._();

static final AttendanceLocalDatabase instance =
AttendanceLocalDatabase._();

Database? _database;

// ============================================================
// DATABASE
// ============================================================

Future<Database> get database async {
if (_database != null) {
return _database!;
}

_database = await _openDatabase();

return _database!;
}

Future<Database> _openDatabase() async {
final databasesPath = await getDatabasesPath();

final path = join(
databasesPath,
'staff_attendance.db',
);

return openDatabase(
path,

// Increased from 1 to 2 because we are adding
// employee-specific indexes.
version: 2,

onCreate: (db, version) async {
await _createAttendanceTable(db);
await _createIndexes(db);
},

onUpgrade: (db, oldVersion, newVersion) async {
if (oldVersion < 2) {
await _createEmployeeIndex(db);
}
},
);
}

// ============================================================
// CREATE TABLE
// ============================================================

Future<void> _createAttendanceTable(
Database db,
) async {
await db.execute('''
      CREATE TABLE attendance_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        uuid TEXT NOT NULL UNIQUE,

        employee_id INTEGER NOT NULL,

        type TEXT NOT NULL,

        occurred_at TEXT NOT NULL,

        latitude REAL NOT NULL,

        longitude REAL NOT NULL,

        accuracy REAL NOT NULL,

        photo_path TEXT,

        device_id TEXT NOT NULL,

        sync_status TEXT NOT NULL DEFAULT 'pending',

        remarks TEXT,

        server_received_at TEXT,

        server_id INTEGER,

        created_at TEXT,

        updated_at TEXT
      )
    ''');
}

// ============================================================
// CREATE INDEXES
// ============================================================

Future<void> _createIndexes(
Database db,
) async {
await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_attendance_employee
      ON attendance_queue(employee_id)
    ''');

await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_attendance_employee_type
      ON attendance_queue(employee_id, type)
    ''');

await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_attendance_employee_date
      ON attendance_queue(employee_id, occurred_at)
    ''');

await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_attendance_sync_status
      ON attendance_queue(sync_status)
    ''');

await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_attendance_employee_sync
      ON attendance_queue(employee_id, sync_status)
    ''');

await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_attendance_occurred_at
      ON attendance_queue(occurred_at)
    ''');
}

Future<void> _createEmployeeIndex(
Database db,
) async {
await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_attendance_employee
      ON attendance_queue(employee_id)
    ''');

await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_attendance_employee_type
      ON attendance_queue(employee_id, type)
    ''');

await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_attendance_employee_date
      ON attendance_queue(employee_id, occurred_at)
    ''');

await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_attendance_employee_sync
      ON attendance_queue(employee_id, sync_status)
    ''');
}

// ============================================================
// INSERT ATTENDANCE
// ============================================================

Future<int> insertAttendance(
Map<String, dynamic> data,
) async {
final db = await database;

final type = data['type']?.toString();

if (type != 'check_in' && type != 'check_out') {
throw Exception(
'Invalid attendance type: $type',
);
}

final employeeId = _parseEmployeeId(
data['employee_id'],
);

if (employeeId == null || employeeId <= 0) {
throw Exception(
'Employee ID is required when saving attendance locally.',
);
}

final uuid = data['uuid']?.toString();

if (uuid == null || uuid.trim().isEmpty) {
throw Exception(
'Attendance UUID is required.',
);
}

/*
    |--------------------------------------------------------------------------
    | Check if this UUID already exists
    |--------------------------------------------------------------------------
    */

final existing = await getByUuid(uuid);

if (existing != null) {
return existing['id'] as int;
}

/*
    |--------------------------------------------------------------------------
    | Make sure employee_id is always stored
    |--------------------------------------------------------------------------
    */

final attendanceData = <String, dynamic>{
...data,
'employee_id': employeeId,
'uuid': uuid,
'type': type,
'sync_status':
data['sync_status']?.toString() ?? 'pending',
};

/*
    |--------------------------------------------------------------------------
    | Insert
    |--------------------------------------------------------------------------
    */

return db.insert(
'attendance_queue',
attendanceData,
conflictAlgorithm: ConflictAlgorithm.abort,
);
}

// ============================================================
// GET PENDING ATTENDANCE
// FOR CURRENT EMPLOYEE ONLY
// ============================================================

Future<List<Map<String, dynamic>>> getPendingAttendances({
required int employeeId,
}) async {
final db = await database;

return db.query(
'attendance_queue',
where: '''
        employee_id = ?
        AND sync_status = ?
      ''',
whereArgs: [
employeeId,
'pending',
],
orderBy: 'occurred_at ASC',
);
}

// ============================================================
// GET ALL ATTENDANCE
// FOR CURRENT EMPLOYEE ONLY
// ============================================================

Future<List<Map<String, dynamic>>> getAllAttendances({
required int employeeId,
String? from,
String? to,
}) async {
final db = await database;

final conditions = <String>[
'employee_id = ?',
];

final arguments = <dynamic>[
employeeId,
];

/*
    |--------------------------------------------------------------------------
    | Optional FROM
    |--------------------------------------------------------------------------
    */

if (from != null && from.trim().isNotEmpty) {
conditions.add(
'date(occurred_at) >= date(?)',
);

arguments.add(from);
}

/*
    |--------------------------------------------------------------------------
    | Optional TO
    |--------------------------------------------------------------------------
    */

if (to != null && to.trim().isNotEmpty) {
conditions.add(
'date(occurred_at) <= date(?)',
);

arguments.add(to);
}

return db.query(
'attendance_queue',
where: conditions.join(' AND '),
whereArgs: arguments,
orderBy: 'occurred_at DESC',
);
}

// ============================================================
// GET ATTENDANCE BY UUID
// ============================================================

Future<Map<String, dynamic>?> getByUuid(
String uuid,
) async {
final db = await database;

final result = await db.query(
'attendance_queue',
where: 'uuid = ?',
whereArgs: [uuid],
limit: 1,
);

if (result.isEmpty) {
return null;
}

return result.first;
}

// ============================================================
// GET ATTENDANCE BY EMPLOYEE + DATE + TYPE
// ============================================================

Future<Map<String, dynamic>?> getAttendanceForEmployeeDateType({
required int employeeId,
required String date,
required String type,
}) async {
final db = await database;

final result = await db.query(
'attendance_queue',
where: '''
        employee_id = ?
        AND date(occurred_at) = date(?)
        AND type = ?
      ''',
whereArgs: [
employeeId,
date,
type,
],
orderBy: 'occurred_at DESC',
limit: 1,
);

if (result.isEmpty) {
return null;
}

return result.first;
}

// ============================================================
// CHECK WHETHER EMPLOYEE HAS CHECKED IN TODAY
// ============================================================

Future<bool> hasCheckedInToday({
required int employeeId,
required String date,
}) async {
final record =
await getAttendanceForEmployeeDateType(
employeeId: employeeId,
date: date,
type: 'check_in',
);

return record != null;
}

// ============================================================
// CHECK WHETHER EMPLOYEE HAS CHECKED OUT TODAY
// ============================================================

Future<bool> hasCheckedOutToday({
required int employeeId,
required String date,
}) async {
final record =
await getAttendanceForEmployeeDateType(
employeeId: employeeId,
date: date,
type: 'check_out',
);

return record != null;
}

// ============================================================
// MARK AS SYNCED
// ============================================================

Future<void> markAsSynced({
required String uuid,
int? serverId,
String? serverReceivedAt,
String? createdAt,
String? updatedAt,
}) async {
final db = await database;

await db.update(
'attendance_queue',
{
'sync_status': 'synced',
'server_id': serverId,
'server_received_at': serverReceivedAt,
'created_at': createdAt,
'updated_at': updatedAt,
},
where: 'uuid = ?',
whereArgs: [uuid],
);
}

// ============================================================
// MARK AS FAILED
// ============================================================

Future<void> markAsFailed(
String uuid,
) async {
final db = await database;

await db.update(
'attendance_queue',
{
'sync_status': 'pending',
},
where: 'uuid = ?',
whereArgs: [uuid],
);
}

// ============================================================
// PENDING COUNT
// FOR CURRENT EMPLOYEE ONLY
// ============================================================

Future<int> pendingCount({
required int employeeId,
}) async {
final db = await database;

final result = await db.rawQuery(
'''
      SELECT COUNT(*) AS count
      FROM attendance_queue
      WHERE employee_id = ?
        AND sync_status = ?
      ''',
[
employeeId,
'pending',
],
);

return Sqflite.firstIntValue(result) ?? 0;
}

// ============================================================
// DELETE OLD SYNCED ATTENDANCE
// FOR CURRENT EMPLOYEE ONLY
// ============================================================

Future<void> deleteSyncedOlderThan({
required int employeeId,
required DateTime date,
}) async {
final db = await database;

await db.delete(
'attendance_queue',
where: '''
        employee_id = ?
        AND sync_status = ?
        AND occurred_at < ?
      ''',
whereArgs: [
employeeId,
'synced',
date.toUtc().toIso8601String(),
],
);
}

// ============================================================
// DELETE ONE RECORD
// ============================================================

Future<void> deleteByUuid(
String uuid,
) async {
final db = await database;

await db.delete(
'attendance_queue',
where: 'uuid = ?',
whereArgs: [uuid],
);
}

// ============================================================
// GET EMPLOYEE ATTENDANCE COUNT
// ============================================================

Future<int> attendanceCount({
required int employeeId,
}) async {
final db = await database;

final result = await db.rawQuery(
'''
      SELECT COUNT(*) AS count
      FROM attendance_queue
      WHERE employee_id = ?
      ''',
[employeeId],
);

return Sqflite.firstIntValue(result) ?? 0;
}

// ============================================================
// CLEAR EMPLOYEE LOCAL DATA
// ============================================================

/*
  |--------------------------------------------------------------------------
  | Use this only if you intentionally want to remove
  | one employee's local attendance records.
  |--------------------------------------------------------------------------
  */

Future<void> clearEmployeeAttendance(
int employeeId,
) async {
final db = await database;

await db.delete(
'attendance_queue',
where: 'employee_id = ?',
whereArgs: [employeeId],
);
}

// ============================================================
// DATABASE DEBUG
// ============================================================

Future<List<Map<String, dynamic>>> debugAllRecords() async {
final db = await database;

return db.query(
'attendance_queue',
orderBy: 'id ASC',
);
}

// ============================================================
// PARSE EMPLOYEE ID
// ============================================================

int? _parseEmployeeId(
dynamic value,
) {
if (value == null) {
return null;
}

if (value is int) {
return value;
}

return int.tryParse(
value.toString(),
);
}

// ============================================================
// CLOSE DATABASE
// ============================================================

Future<void> close() async {
if (_database == null) {
return;
}

await _database!.close();

_database = null;
}
}

