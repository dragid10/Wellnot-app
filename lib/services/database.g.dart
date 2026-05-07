// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SymptomEntriesTable extends SymptomEntries
    with TableInfo<$SymptomEntriesTable, SymptomEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SymptomEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entryDateTimeMeta =
      const VerificationMeta('entryDateTime');
  @override
  late final GeneratedColumn<DateTime> entryDateTime =
      GeneratedColumn<DateTime>('entry_date_time', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
      'mood', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, entryDateTime, mood, notes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'symptom_entries';
  @override
  VerificationContext validateIntegrity(Insertable<SymptomEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entry_date_time')) {
      context.handle(
          _entryDateTimeMeta,
          entryDateTime.isAcceptableOrUnknown(
              data['entry_date_time']!, _entryDateTimeMeta));
    } else if (isInserting) {
      context.missing(_entryDateTimeMeta);
    }
    if (data.containsKey('mood')) {
      context.handle(
          _moodMeta, mood.isAcceptableOrUnknown(data['mood']!, _moodMeta));
    } else if (isInserting) {
      context.missing(_moodMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SymptomEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SymptomEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entryDateTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}entry_date_time'])!,
      mood: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mood'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $SymptomEntriesTable createAlias(String alias) {
    return $SymptomEntriesTable(attachedDatabase, alias);
  }
}

class SymptomEntry extends DataClass implements Insertable<SymptomEntry> {
  final int id;
  final DateTime entryDateTime;
  final String mood;
  final String? notes;
  const SymptomEntry(
      {required this.id,
      required this.entryDateTime,
      required this.mood,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entry_date_time'] = Variable<DateTime>(entryDateTime);
    map['mood'] = Variable<String>(mood);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  SymptomEntriesCompanion toCompanion(bool nullToAbsent) {
    return SymptomEntriesCompanion(
      id: Value(id),
      entryDateTime: Value(entryDateTime),
      mood: Value(mood),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory SymptomEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SymptomEntry(
      id: serializer.fromJson<int>(json['id']),
      entryDateTime: serializer.fromJson<DateTime>(json['entryDateTime']),
      mood: serializer.fromJson<String>(json['mood']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entryDateTime': serializer.toJson<DateTime>(entryDateTime),
      'mood': serializer.toJson<String>(mood),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  SymptomEntry copyWith(
          {int? id,
          DateTime? entryDateTime,
          String? mood,
          Value<String?> notes = const Value.absent()}) =>
      SymptomEntry(
        id: id ?? this.id,
        entryDateTime: entryDateTime ?? this.entryDateTime,
        mood: mood ?? this.mood,
        notes: notes.present ? notes.value : this.notes,
      );
  SymptomEntry copyWithCompanion(SymptomEntriesCompanion data) {
    return SymptomEntry(
      id: data.id.present ? data.id.value : this.id,
      entryDateTime: data.entryDateTime.present
          ? data.entryDateTime.value
          : this.entryDateTime,
      mood: data.mood.present ? data.mood.value : this.mood,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SymptomEntry(')
          ..write('id: $id, ')
          ..write('entryDateTime: $entryDateTime, ')
          ..write('mood: $mood, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entryDateTime, mood, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SymptomEntry &&
          other.id == this.id &&
          other.entryDateTime == this.entryDateTime &&
          other.mood == this.mood &&
          other.notes == this.notes);
}

class SymptomEntriesCompanion extends UpdateCompanion<SymptomEntry> {
  final Value<int> id;
  final Value<DateTime> entryDateTime;
  final Value<String> mood;
  final Value<String?> notes;
  const SymptomEntriesCompanion({
    this.id = const Value.absent(),
    this.entryDateTime = const Value.absent(),
    this.mood = const Value.absent(),
    this.notes = const Value.absent(),
  });
  SymptomEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime entryDateTime,
    required String mood,
    this.notes = const Value.absent(),
  })  : entryDateTime = Value(entryDateTime),
        mood = Value(mood);
  static Insertable<SymptomEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? entryDateTime,
    Expression<String>? mood,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryDateTime != null) 'entry_date_time': entryDateTime,
      if (mood != null) 'mood': mood,
      if (notes != null) 'notes': notes,
    });
  }

  SymptomEntriesCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? entryDateTime,
      Value<String>? mood,
      Value<String?>? notes}) {
    return SymptomEntriesCompanion(
      id: id ?? this.id,
      entryDateTime: entryDateTime ?? this.entryDateTime,
      mood: mood ?? this.mood,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entryDateTime.present) {
      map['entry_date_time'] = Variable<DateTime>(entryDateTime.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SymptomEntriesCompanion(')
          ..write('id: $id, ')
          ..write('entryDateTime: $entryDateTime, ')
          ..write('mood: $mood, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $UserSymptomsTable extends UserSymptoms
    with TableInfo<$UserSymptomsTable, UserSymptom> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSymptomsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_symptoms';
  @override
  VerificationContext validateIntegrity(Insertable<UserSymptom> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserSymptom map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSymptom(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $UserSymptomsTable createAlias(String alias) {
    return $UserSymptomsTable(attachedDatabase, alias);
  }
}

class UserSymptom extends DataClass implements Insertable<UserSymptom> {
  final int id;
  final String name;
  const UserSymptom({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  UserSymptomsCompanion toCompanion(bool nullToAbsent) {
    return UserSymptomsCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory UserSymptom.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSymptom(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  UserSymptom copyWith({int? id, String? name}) => UserSymptom(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  UserSymptom copyWithCompanion(UserSymptomsCompanion data) {
    return UserSymptom(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSymptom(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSymptom && other.id == this.id && other.name == this.name);
}

class UserSymptomsCompanion extends UpdateCompanion<UserSymptom> {
  final Value<int> id;
  final Value<String> name;
  const UserSymptomsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  UserSymptomsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<UserSymptom> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  UserSymptomsCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return UserSymptomsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSymptomsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $UserTagsTable extends UserTags with TableInfo<$UserTagsTable, UserTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_tags';
  @override
  VerificationContext validateIntegrity(Insertable<UserTag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserTag(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $UserTagsTable createAlias(String alias) {
    return $UserTagsTable(attachedDatabase, alias);
  }
}

class UserTag extends DataClass implements Insertable<UserTag> {
  final int id;
  final String name;
  const UserTag({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  UserTagsCompanion toCompanion(bool nullToAbsent) {
    return UserTagsCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory UserTag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserTag(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  UserTag copyWith({int? id, String? name}) => UserTag(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  UserTag copyWithCompanion(UserTagsCompanion data) {
    return UserTag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserTag(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserTag && other.id == this.id && other.name == this.name);
}

class UserTagsCompanion extends UpdateCompanion<UserTag> {
  final Value<int> id;
  final Value<String> name;
  const UserTagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  UserTagsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<UserTag> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  UserTagsCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return UserTagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserTagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $SymptomEntryWithSymptomTable extends SymptomEntryWithSymptom
    with TableInfo<$SymptomEntryWithSymptomTable, SymptomEntryWithSymptomData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SymptomEntryWithSymptomTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _symptomEntryIdMeta =
      const VerificationMeta('symptomEntryId');
  @override
  late final GeneratedColumn<int> symptomEntryId = GeneratedColumn<int>(
      'symptom_entry_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES symptom_entries (id)'));
  static const VerificationMeta _userSymptomIdMeta =
      const VerificationMeta('userSymptomId');
  @override
  late final GeneratedColumn<int> userSymptomId = GeneratedColumn<int>(
      'user_symptom_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES user_symptoms (id)'));
  static const VerificationMeta _severityMeta =
      const VerificationMeta('severity');
  @override
  late final GeneratedColumn<int> severity = GeneratedColumn<int>(
      'severity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  @override
  List<GeneratedColumn> get $columns =>
      [symptomEntryId, userSymptomId, severity];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'symptom_entry_with_symptom';
  @override
  VerificationContext validateIntegrity(
      Insertable<SymptomEntryWithSymptomData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('symptom_entry_id')) {
      context.handle(
          _symptomEntryIdMeta,
          symptomEntryId.isAcceptableOrUnknown(
              data['symptom_entry_id']!, _symptomEntryIdMeta));
    } else if (isInserting) {
      context.missing(_symptomEntryIdMeta);
    }
    if (data.containsKey('user_symptom_id')) {
      context.handle(
          _userSymptomIdMeta,
          userSymptomId.isAcceptableOrUnknown(
              data['user_symptom_id']!, _userSymptomIdMeta));
    } else if (isInserting) {
      context.missing(_userSymptomIdMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(_severityMeta,
          severity.isAcceptableOrUnknown(data['severity']!, _severityMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  SymptomEntryWithSymptomData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SymptomEntryWithSymptomData(
      symptomEntryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}symptom_entry_id'])!,
      userSymptomId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_symptom_id'])!,
      severity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}severity'])!,
    );
  }

  @override
  $SymptomEntryWithSymptomTable createAlias(String alias) {
    return $SymptomEntryWithSymptomTable(attachedDatabase, alias);
  }
}

class SymptomEntryWithSymptomData extends DataClass
    implements Insertable<SymptomEntryWithSymptomData> {
  final int symptomEntryId;
  final int userSymptomId;
  final int severity;
  const SymptomEntryWithSymptomData(
      {required this.symptomEntryId,
      required this.userSymptomId,
      required this.severity});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['symptom_entry_id'] = Variable<int>(symptomEntryId);
    map['user_symptom_id'] = Variable<int>(userSymptomId);
    map['severity'] = Variable<int>(severity);
    return map;
  }

  SymptomEntryWithSymptomCompanion toCompanion(bool nullToAbsent) {
    return SymptomEntryWithSymptomCompanion(
      symptomEntryId: Value(symptomEntryId),
      userSymptomId: Value(userSymptomId),
      severity: Value(severity),
    );
  }

  factory SymptomEntryWithSymptomData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SymptomEntryWithSymptomData(
      symptomEntryId: serializer.fromJson<int>(json['symptomEntryId']),
      userSymptomId: serializer.fromJson<int>(json['userSymptomId']),
      severity: serializer.fromJson<int>(json['severity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'symptomEntryId': serializer.toJson<int>(symptomEntryId),
      'userSymptomId': serializer.toJson<int>(userSymptomId),
      'severity': serializer.toJson<int>(severity),
    };
  }

  SymptomEntryWithSymptomData copyWith(
          {int? symptomEntryId, int? userSymptomId, int? severity}) =>
      SymptomEntryWithSymptomData(
        symptomEntryId: symptomEntryId ?? this.symptomEntryId,
        userSymptomId: userSymptomId ?? this.userSymptomId,
        severity: severity ?? this.severity,
      );
  SymptomEntryWithSymptomData copyWithCompanion(
      SymptomEntryWithSymptomCompanion data) {
    return SymptomEntryWithSymptomData(
      symptomEntryId: data.symptomEntryId.present
          ? data.symptomEntryId.value
          : this.symptomEntryId,
      userSymptomId: data.userSymptomId.present
          ? data.userSymptomId.value
          : this.userSymptomId,
      severity: data.severity.present ? data.severity.value : this.severity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SymptomEntryWithSymptomData(')
          ..write('symptomEntryId: $symptomEntryId, ')
          ..write('userSymptomId: $userSymptomId, ')
          ..write('severity: $severity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(symptomEntryId, userSymptomId, severity);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SymptomEntryWithSymptomData &&
          other.symptomEntryId == this.symptomEntryId &&
          other.userSymptomId == this.userSymptomId &&
          other.severity == this.severity);
}

class SymptomEntryWithSymptomCompanion
    extends UpdateCompanion<SymptomEntryWithSymptomData> {
  final Value<int> symptomEntryId;
  final Value<int> userSymptomId;
  final Value<int> severity;
  final Value<int> rowid;
  const SymptomEntryWithSymptomCompanion({
    this.symptomEntryId = const Value.absent(),
    this.userSymptomId = const Value.absent(),
    this.severity = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SymptomEntryWithSymptomCompanion.insert({
    required int symptomEntryId,
    required int userSymptomId,
    this.severity = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : symptomEntryId = Value(symptomEntryId),
        userSymptomId = Value(userSymptomId);
  static Insertable<SymptomEntryWithSymptomData> custom({
    Expression<int>? symptomEntryId,
    Expression<int>? userSymptomId,
    Expression<int>? severity,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (symptomEntryId != null) 'symptom_entry_id': symptomEntryId,
      if (userSymptomId != null) 'user_symptom_id': userSymptomId,
      if (severity != null) 'severity': severity,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SymptomEntryWithSymptomCompanion copyWith(
      {Value<int>? symptomEntryId,
      Value<int>? userSymptomId,
      Value<int>? severity,
      Value<int>? rowid}) {
    return SymptomEntryWithSymptomCompanion(
      symptomEntryId: symptomEntryId ?? this.symptomEntryId,
      userSymptomId: userSymptomId ?? this.userSymptomId,
      severity: severity ?? this.severity,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (symptomEntryId.present) {
      map['symptom_entry_id'] = Variable<int>(symptomEntryId.value);
    }
    if (userSymptomId.present) {
      map['user_symptom_id'] = Variable<int>(userSymptomId.value);
    }
    if (severity.present) {
      map['severity'] = Variable<int>(severity.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SymptomEntryWithSymptomCompanion(')
          ..write('symptomEntryId: $symptomEntryId, ')
          ..write('userSymptomId: $userSymptomId, ')
          ..write('severity: $severity, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SymptomEntryWithTagTable extends SymptomEntryWithTag
    with TableInfo<$SymptomEntryWithTagTable, SymptomEntryWithTagData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SymptomEntryWithTagTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _symptomEntryIdMeta =
      const VerificationMeta('symptomEntryId');
  @override
  late final GeneratedColumn<int> symptomEntryId = GeneratedColumn<int>(
      'symptom_entry_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES symptom_entries (id)'));
  static const VerificationMeta _userTagIdMeta =
      const VerificationMeta('userTagId');
  @override
  late final GeneratedColumn<int> userTagId = GeneratedColumn<int>(
      'user_tag_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES user_tags (id)'));
  @override
  List<GeneratedColumn> get $columns => [symptomEntryId, userTagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'symptom_entry_with_tag';
  @override
  VerificationContext validateIntegrity(
      Insertable<SymptomEntryWithTagData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('symptom_entry_id')) {
      context.handle(
          _symptomEntryIdMeta,
          symptomEntryId.isAcceptableOrUnknown(
              data['symptom_entry_id']!, _symptomEntryIdMeta));
    } else if (isInserting) {
      context.missing(_symptomEntryIdMeta);
    }
    if (data.containsKey('user_tag_id')) {
      context.handle(
          _userTagIdMeta,
          userTagId.isAcceptableOrUnknown(
              data['user_tag_id']!, _userTagIdMeta));
    } else if (isInserting) {
      context.missing(_userTagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  SymptomEntryWithTagData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SymptomEntryWithTagData(
      symptomEntryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}symptom_entry_id'])!,
      userTagId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_tag_id'])!,
    );
  }

  @override
  $SymptomEntryWithTagTable createAlias(String alias) {
    return $SymptomEntryWithTagTable(attachedDatabase, alias);
  }
}

class SymptomEntryWithTagData extends DataClass
    implements Insertable<SymptomEntryWithTagData> {
  final int symptomEntryId;
  final int userTagId;
  const SymptomEntryWithTagData(
      {required this.symptomEntryId, required this.userTagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['symptom_entry_id'] = Variable<int>(symptomEntryId);
    map['user_tag_id'] = Variable<int>(userTagId);
    return map;
  }

  SymptomEntryWithTagCompanion toCompanion(bool nullToAbsent) {
    return SymptomEntryWithTagCompanion(
      symptomEntryId: Value(symptomEntryId),
      userTagId: Value(userTagId),
    );
  }

  factory SymptomEntryWithTagData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SymptomEntryWithTagData(
      symptomEntryId: serializer.fromJson<int>(json['symptomEntryId']),
      userTagId: serializer.fromJson<int>(json['userTagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'symptomEntryId': serializer.toJson<int>(symptomEntryId),
      'userTagId': serializer.toJson<int>(userTagId),
    };
  }

  SymptomEntryWithTagData copyWith({int? symptomEntryId, int? userTagId}) =>
      SymptomEntryWithTagData(
        symptomEntryId: symptomEntryId ?? this.symptomEntryId,
        userTagId: userTagId ?? this.userTagId,
      );
  SymptomEntryWithTagData copyWithCompanion(SymptomEntryWithTagCompanion data) {
    return SymptomEntryWithTagData(
      symptomEntryId: data.symptomEntryId.present
          ? data.symptomEntryId.value
          : this.symptomEntryId,
      userTagId: data.userTagId.present ? data.userTagId.value : this.userTagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SymptomEntryWithTagData(')
          ..write('symptomEntryId: $symptomEntryId, ')
          ..write('userTagId: $userTagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(symptomEntryId, userTagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SymptomEntryWithTagData &&
          other.symptomEntryId == this.symptomEntryId &&
          other.userTagId == this.userTagId);
}

class SymptomEntryWithTagCompanion
    extends UpdateCompanion<SymptomEntryWithTagData> {
  final Value<int> symptomEntryId;
  final Value<int> userTagId;
  final Value<int> rowid;
  const SymptomEntryWithTagCompanion({
    this.symptomEntryId = const Value.absent(),
    this.userTagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SymptomEntryWithTagCompanion.insert({
    required int symptomEntryId,
    required int userTagId,
    this.rowid = const Value.absent(),
  })  : symptomEntryId = Value(symptomEntryId),
        userTagId = Value(userTagId);
  static Insertable<SymptomEntryWithTagData> custom({
    Expression<int>? symptomEntryId,
    Expression<int>? userTagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (symptomEntryId != null) 'symptom_entry_id': symptomEntryId,
      if (userTagId != null) 'user_tag_id': userTagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SymptomEntryWithTagCompanion copyWith(
      {Value<int>? symptomEntryId, Value<int>? userTagId, Value<int>? rowid}) {
    return SymptomEntryWithTagCompanion(
      symptomEntryId: symptomEntryId ?? this.symptomEntryId,
      userTagId: userTagId ?? this.userTagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (symptomEntryId.present) {
      map['symptom_entry_id'] = Variable<int>(symptomEntryId.value);
    }
    if (userTagId.present) {
      map['user_tag_id'] = Variable<int>(userTagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SymptomEntryWithTagCompanion(')
          ..write('symptomEntryId: $symptomEntryId, ')
          ..write('userTagId: $userTagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnlockedAchievementsTable extends UnlockedAchievements
    with TableInfo<$UnlockedAchievementsTable, UnlockedAchievement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnlockedAchievementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _achievementIdMeta =
      const VerificationMeta('achievementId');
  @override
  late final GeneratedColumn<String> achievementId = GeneratedColumn<String>(
      'achievement_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unlockedAtMeta =
      const VerificationMeta('unlockedAt');
  @override
  late final GeneratedColumn<DateTime> unlockedAt = GeneratedColumn<DateTime>(
      'unlocked_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _progressMeta =
      const VerificationMeta('progress');
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
      'progress', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [achievementId, unlockedAt, progress];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unlocked_achievements';
  @override
  VerificationContext validateIntegrity(
      Insertable<UnlockedAchievement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('achievement_id')) {
      context.handle(
          _achievementIdMeta,
          achievementId.isAcceptableOrUnknown(
              data['achievement_id']!, _achievementIdMeta));
    } else if (isInserting) {
      context.missing(_achievementIdMeta);
    }
    if (data.containsKey('unlocked_at')) {
      context.handle(
          _unlockedAtMeta,
          unlockedAt.isAcceptableOrUnknown(
              data['unlocked_at']!, _unlockedAtMeta));
    } else if (isInserting) {
      context.missing(_unlockedAtMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(_progressMeta,
          progress.isAcceptableOrUnknown(data['progress']!, _progressMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {achievementId};
  @override
  UnlockedAchievement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnlockedAchievement(
      achievementId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}achievement_id'])!,
      unlockedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}unlocked_at'])!,
      progress: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}progress'])!,
    );
  }

  @override
  $UnlockedAchievementsTable createAlias(String alias) {
    return $UnlockedAchievementsTable(attachedDatabase, alias);
  }
}

class UnlockedAchievement extends DataClass
    implements Insertable<UnlockedAchievement> {
  final String achievementId;
  final DateTime unlockedAt;
  final int progress;
  const UnlockedAchievement(
      {required this.achievementId,
      required this.unlockedAt,
      required this.progress});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['achievement_id'] = Variable<String>(achievementId);
    map['unlocked_at'] = Variable<DateTime>(unlockedAt);
    map['progress'] = Variable<int>(progress);
    return map;
  }

  UnlockedAchievementsCompanion toCompanion(bool nullToAbsent) {
    return UnlockedAchievementsCompanion(
      achievementId: Value(achievementId),
      unlockedAt: Value(unlockedAt),
      progress: Value(progress),
    );
  }

  factory UnlockedAchievement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnlockedAchievement(
      achievementId: serializer.fromJson<String>(json['achievementId']),
      unlockedAt: serializer.fromJson<DateTime>(json['unlockedAt']),
      progress: serializer.fromJson<int>(json['progress']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'achievementId': serializer.toJson<String>(achievementId),
      'unlockedAt': serializer.toJson<DateTime>(unlockedAt),
      'progress': serializer.toJson<int>(progress),
    };
  }

  UnlockedAchievement copyWith(
          {String? achievementId, DateTime? unlockedAt, int? progress}) =>
      UnlockedAchievement(
        achievementId: achievementId ?? this.achievementId,
        unlockedAt: unlockedAt ?? this.unlockedAt,
        progress: progress ?? this.progress,
      );
  UnlockedAchievement copyWithCompanion(UnlockedAchievementsCompanion data) {
    return UnlockedAchievement(
      achievementId: data.achievementId.present
          ? data.achievementId.value
          : this.achievementId,
      unlockedAt:
          data.unlockedAt.present ? data.unlockedAt.value : this.unlockedAt,
      progress: data.progress.present ? data.progress.value : this.progress,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnlockedAchievement(')
          ..write('achievementId: $achievementId, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('progress: $progress')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(achievementId, unlockedAt, progress);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnlockedAchievement &&
          other.achievementId == this.achievementId &&
          other.unlockedAt == this.unlockedAt &&
          other.progress == this.progress);
}

class UnlockedAchievementsCompanion
    extends UpdateCompanion<UnlockedAchievement> {
  final Value<String> achievementId;
  final Value<DateTime> unlockedAt;
  final Value<int> progress;
  final Value<int> rowid;
  const UnlockedAchievementsCompanion({
    this.achievementId = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.progress = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnlockedAchievementsCompanion.insert({
    required String achievementId,
    required DateTime unlockedAt,
    this.progress = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : achievementId = Value(achievementId),
        unlockedAt = Value(unlockedAt);
  static Insertable<UnlockedAchievement> custom({
    Expression<String>? achievementId,
    Expression<DateTime>? unlockedAt,
    Expression<int>? progress,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (achievementId != null) 'achievement_id': achievementId,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      if (progress != null) 'progress': progress,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnlockedAchievementsCompanion copyWith(
      {Value<String>? achievementId,
      Value<DateTime>? unlockedAt,
      Value<int>? progress,
      Value<int>? rowid}) {
    return UnlockedAchievementsCompanion(
      achievementId: achievementId ?? this.achievementId,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (achievementId.present) {
      map['achievement_id'] = Variable<String>(achievementId.value);
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnlockedAchievementsCompanion(')
          ..write('achievementId: $achievementId, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('progress: $progress, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SymptomEntriesTable symptomEntries = $SymptomEntriesTable(this);
  late final $UserSymptomsTable userSymptoms = $UserSymptomsTable(this);
  late final $UserTagsTable userTags = $UserTagsTable(this);
  late final $SymptomEntryWithSymptomTable symptomEntryWithSymptom =
      $SymptomEntryWithSymptomTable(this);
  late final $SymptomEntryWithTagTable symptomEntryWithTag =
      $SymptomEntryWithTagTable(this);
  late final $UnlockedAchievementsTable unlockedAchievements =
      $UnlockedAchievementsTable(this);
  late final Index idxEntryDateTime = Index('idx_entry_date_time',
      'CREATE INDEX idx_entry_date_time ON symptom_entries (entry_date_time)');
  late final Index idxSewsEntryId = Index('idx_sews_entry_id',
      'CREATE INDEX idx_sews_entry_id ON symptom_entry_with_symptom (symptom_entry_id)');
  late final Index idxSewtEntryId = Index('idx_sewt_entry_id',
      'CREATE INDEX idx_sewt_entry_id ON symptom_entry_with_tag (symptom_entry_id)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        symptomEntries,
        userSymptoms,
        userTags,
        symptomEntryWithSymptom,
        symptomEntryWithTag,
        unlockedAchievements,
        idxEntryDateTime,
        idxSewsEntryId,
        idxSewtEntryId
      ];
}

typedef $$SymptomEntriesTableCreateCompanionBuilder = SymptomEntriesCompanion
    Function({
  Value<int> id,
  required DateTime entryDateTime,
  required String mood,
  Value<String?> notes,
});
typedef $$SymptomEntriesTableUpdateCompanionBuilder = SymptomEntriesCompanion
    Function({
  Value<int> id,
  Value<DateTime> entryDateTime,
  Value<String> mood,
  Value<String?> notes,
});

final class $$SymptomEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $SymptomEntriesTable, SymptomEntry> {
  $$SymptomEntriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SymptomEntryWithSymptomTable,
      List<SymptomEntryWithSymptomData>> _symptomEntryWithSymptomRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.symptomEntryWithSymptom,
          aliasName: $_aliasNameGenerator(
              db.symptomEntries.id, db.symptomEntryWithSymptom.symptomEntryId));

  $$SymptomEntryWithSymptomTableProcessedTableManager
      get symptomEntryWithSymptomRefs {
    final manager = $$SymptomEntryWithSymptomTableTableManager(
            $_db, $_db.symptomEntryWithSymptom)
        .filter((f) => f.symptomEntryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_symptomEntryWithSymptomRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SymptomEntryWithTagTable,
      List<SymptomEntryWithTagData>> _symptomEntryWithTagRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.symptomEntryWithTag,
          aliasName: $_aliasNameGenerator(
              db.symptomEntries.id, db.symptomEntryWithTag.symptomEntryId));

  $$SymptomEntryWithTagTableProcessedTableManager get symptomEntryWithTagRefs {
    final manager = $$SymptomEntryWithTagTableTableManager(
            $_db, $_db.symptomEntryWithTag)
        .filter((f) => f.symptomEntryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_symptomEntryWithTagRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SymptomEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SymptomEntriesTable> {
  $$SymptomEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get entryDateTime => $composableBuilder(
      column: $table.entryDateTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mood => $composableBuilder(
      column: $table.mood, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  Expression<bool> symptomEntryWithSymptomRefs(
      Expression<bool> Function($$SymptomEntryWithSymptomTableFilterComposer f)
          f) {
    final $$SymptomEntryWithSymptomTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.symptomEntryWithSymptom,
            getReferencedColumn: (t) => t.symptomEntryId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SymptomEntryWithSymptomTableFilterComposer(
                  $db: $db,
                  $table: $db.symptomEntryWithSymptom,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<bool> symptomEntryWithTagRefs(
      Expression<bool> Function($$SymptomEntryWithTagTableFilterComposer f) f) {
    final $$SymptomEntryWithTagTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.symptomEntryWithTag,
        getReferencedColumn: (t) => t.symptomEntryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SymptomEntryWithTagTableFilterComposer(
              $db: $db,
              $table: $db.symptomEntryWithTag,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SymptomEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SymptomEntriesTable> {
  $$SymptomEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get entryDateTime => $composableBuilder(
      column: $table.entryDateTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mood => $composableBuilder(
      column: $table.mood, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));
}

class $$SymptomEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SymptomEntriesTable> {
  $$SymptomEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get entryDateTime => $composableBuilder(
      column: $table.entryDateTime, builder: (column) => column);

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  Expression<T> symptomEntryWithSymptomRefs<T extends Object>(
      Expression<T> Function($$SymptomEntryWithSymptomTableAnnotationComposer a)
          f) {
    final $$SymptomEntryWithSymptomTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.symptomEntryWithSymptom,
            getReferencedColumn: (t) => t.symptomEntryId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SymptomEntryWithSymptomTableAnnotationComposer(
                  $db: $db,
                  $table: $db.symptomEntryWithSymptom,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> symptomEntryWithTagRefs<T extends Object>(
      Expression<T> Function($$SymptomEntryWithTagTableAnnotationComposer a)
          f) {
    final $$SymptomEntryWithTagTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.symptomEntryWithTag,
            getReferencedColumn: (t) => t.symptomEntryId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SymptomEntryWithTagTableAnnotationComposer(
                  $db: $db,
                  $table: $db.symptomEntryWithTag,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$SymptomEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SymptomEntriesTable,
    SymptomEntry,
    $$SymptomEntriesTableFilterComposer,
    $$SymptomEntriesTableOrderingComposer,
    $$SymptomEntriesTableAnnotationComposer,
    $$SymptomEntriesTableCreateCompanionBuilder,
    $$SymptomEntriesTableUpdateCompanionBuilder,
    (SymptomEntry, $$SymptomEntriesTableReferences),
    SymptomEntry,
    PrefetchHooks Function(
        {bool symptomEntryWithSymptomRefs, bool symptomEntryWithTagRefs})> {
  $$SymptomEntriesTableTableManager(
      _$AppDatabase db, $SymptomEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SymptomEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SymptomEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SymptomEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> entryDateTime = const Value.absent(),
            Value<String> mood = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              SymptomEntriesCompanion(
            id: id,
            entryDateTime: entryDateTime,
            mood: mood,
            notes: notes,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime entryDateTime,
            required String mood,
            Value<String?> notes = const Value.absent(),
          }) =>
              SymptomEntriesCompanion.insert(
            id: id,
            entryDateTime: entryDateTime,
            mood: mood,
            notes: notes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SymptomEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {symptomEntryWithSymptomRefs = false,
              symptomEntryWithTagRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (symptomEntryWithSymptomRefs) db.symptomEntryWithSymptom,
                if (symptomEntryWithTagRefs) db.symptomEntryWithTag
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (symptomEntryWithSymptomRefs)
                    await $_getPrefetchedData<SymptomEntry,
                            $SymptomEntriesTable, SymptomEntryWithSymptomData>(
                        currentTable: table,
                        referencedTable: $$SymptomEntriesTableReferences
                            ._symptomEntryWithSymptomRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SymptomEntriesTableReferences(db, table, p0)
                                .symptomEntryWithSymptomRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.symptomEntryId == item.id),
                        typedResults: items),
                  if (symptomEntryWithTagRefs)
                    await $_getPrefetchedData<SymptomEntry,
                            $SymptomEntriesTable, SymptomEntryWithTagData>(
                        currentTable: table,
                        referencedTable: $$SymptomEntriesTableReferences
                            ._symptomEntryWithTagRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SymptomEntriesTableReferences(db, table, p0)
                                .symptomEntryWithTagRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.symptomEntryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SymptomEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SymptomEntriesTable,
    SymptomEntry,
    $$SymptomEntriesTableFilterComposer,
    $$SymptomEntriesTableOrderingComposer,
    $$SymptomEntriesTableAnnotationComposer,
    $$SymptomEntriesTableCreateCompanionBuilder,
    $$SymptomEntriesTableUpdateCompanionBuilder,
    (SymptomEntry, $$SymptomEntriesTableReferences),
    SymptomEntry,
    PrefetchHooks Function(
        {bool symptomEntryWithSymptomRefs, bool symptomEntryWithTagRefs})>;
typedef $$UserSymptomsTableCreateCompanionBuilder = UserSymptomsCompanion
    Function({
  Value<int> id,
  required String name,
});
typedef $$UserSymptomsTableUpdateCompanionBuilder = UserSymptomsCompanion
    Function({
  Value<int> id,
  Value<String> name,
});

final class $$UserSymptomsTableReferences
    extends BaseReferences<_$AppDatabase, $UserSymptomsTable, UserSymptom> {
  $$UserSymptomsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SymptomEntryWithSymptomTable,
      List<SymptomEntryWithSymptomData>> _symptomEntryWithSymptomRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.symptomEntryWithSymptom,
          aliasName: $_aliasNameGenerator(
              db.userSymptoms.id, db.symptomEntryWithSymptom.userSymptomId));

  $$SymptomEntryWithSymptomTableProcessedTableManager
      get symptomEntryWithSymptomRefs {
    final manager = $$SymptomEntryWithSymptomTableTableManager(
            $_db, $_db.symptomEntryWithSymptom)
        .filter((f) => f.userSymptomId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_symptomEntryWithSymptomRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$UserSymptomsTableFilterComposer
    extends Composer<_$AppDatabase, $UserSymptomsTable> {
  $$UserSymptomsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  Expression<bool> symptomEntryWithSymptomRefs(
      Expression<bool> Function($$SymptomEntryWithSymptomTableFilterComposer f)
          f) {
    final $$SymptomEntryWithSymptomTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.symptomEntryWithSymptom,
            getReferencedColumn: (t) => t.userSymptomId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SymptomEntryWithSymptomTableFilterComposer(
                  $db: $db,
                  $table: $db.symptomEntryWithSymptom,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$UserSymptomsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserSymptomsTable> {
  $$UserSymptomsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));
}

class $$UserSymptomsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserSymptomsTable> {
  $$UserSymptomsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> symptomEntryWithSymptomRefs<T extends Object>(
      Expression<T> Function($$SymptomEntryWithSymptomTableAnnotationComposer a)
          f) {
    final $$SymptomEntryWithSymptomTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.symptomEntryWithSymptom,
            getReferencedColumn: (t) => t.userSymptomId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SymptomEntryWithSymptomTableAnnotationComposer(
                  $db: $db,
                  $table: $db.symptomEntryWithSymptom,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$UserSymptomsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserSymptomsTable,
    UserSymptom,
    $$UserSymptomsTableFilterComposer,
    $$UserSymptomsTableOrderingComposer,
    $$UserSymptomsTableAnnotationComposer,
    $$UserSymptomsTableCreateCompanionBuilder,
    $$UserSymptomsTableUpdateCompanionBuilder,
    (UserSymptom, $$UserSymptomsTableReferences),
    UserSymptom,
    PrefetchHooks Function({bool symptomEntryWithSymptomRefs})> {
  $$UserSymptomsTableTableManager(_$AppDatabase db, $UserSymptomsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSymptomsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSymptomsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserSymptomsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) =>
              UserSymptomsCompanion(
            id: id,
            name: name,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
          }) =>
              UserSymptomsCompanion.insert(
            id: id,
            name: name,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$UserSymptomsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({symptomEntryWithSymptomRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (symptomEntryWithSymptomRefs) db.symptomEntryWithSymptom
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (symptomEntryWithSymptomRefs)
                    await $_getPrefetchedData<UserSymptom, $UserSymptomsTable,
                            SymptomEntryWithSymptomData>(
                        currentTable: table,
                        referencedTable: $$UserSymptomsTableReferences
                            ._symptomEntryWithSymptomRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UserSymptomsTableReferences(db, table, p0)
                                .symptomEntryWithSymptomRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.userSymptomId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$UserSymptomsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserSymptomsTable,
    UserSymptom,
    $$UserSymptomsTableFilterComposer,
    $$UserSymptomsTableOrderingComposer,
    $$UserSymptomsTableAnnotationComposer,
    $$UserSymptomsTableCreateCompanionBuilder,
    $$UserSymptomsTableUpdateCompanionBuilder,
    (UserSymptom, $$UserSymptomsTableReferences),
    UserSymptom,
    PrefetchHooks Function({bool symptomEntryWithSymptomRefs})>;
typedef $$UserTagsTableCreateCompanionBuilder = UserTagsCompanion Function({
  Value<int> id,
  required String name,
});
typedef $$UserTagsTableUpdateCompanionBuilder = UserTagsCompanion Function({
  Value<int> id,
  Value<String> name,
});

final class $$UserTagsTableReferences
    extends BaseReferences<_$AppDatabase, $UserTagsTable, UserTag> {
  $$UserTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SymptomEntryWithTagTable,
      List<SymptomEntryWithTagData>> _symptomEntryWithTagRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.symptomEntryWithTag,
          aliasName: $_aliasNameGenerator(
              db.userTags.id, db.symptomEntryWithTag.userTagId));

  $$SymptomEntryWithTagTableProcessedTableManager get symptomEntryWithTagRefs {
    final manager =
        $$SymptomEntryWithTagTableTableManager($_db, $_db.symptomEntryWithTag)
            .filter((f) => f.userTagId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_symptomEntryWithTagRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$UserTagsTableFilterComposer
    extends Composer<_$AppDatabase, $UserTagsTable> {
  $$UserTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  Expression<bool> symptomEntryWithTagRefs(
      Expression<bool> Function($$SymptomEntryWithTagTableFilterComposer f) f) {
    final $$SymptomEntryWithTagTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.symptomEntryWithTag,
        getReferencedColumn: (t) => t.userTagId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SymptomEntryWithTagTableFilterComposer(
              $db: $db,
              $table: $db.symptomEntryWithTag,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UserTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserTagsTable> {
  $$UserTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));
}

class $$UserTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserTagsTable> {
  $$UserTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> symptomEntryWithTagRefs<T extends Object>(
      Expression<T> Function($$SymptomEntryWithTagTableAnnotationComposer a)
          f) {
    final $$SymptomEntryWithTagTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.symptomEntryWithTag,
            getReferencedColumn: (t) => t.userTagId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SymptomEntryWithTagTableAnnotationComposer(
                  $db: $db,
                  $table: $db.symptomEntryWithTag,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$UserTagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserTagsTable,
    UserTag,
    $$UserTagsTableFilterComposer,
    $$UserTagsTableOrderingComposer,
    $$UserTagsTableAnnotationComposer,
    $$UserTagsTableCreateCompanionBuilder,
    $$UserTagsTableUpdateCompanionBuilder,
    (UserTag, $$UserTagsTableReferences),
    UserTag,
    PrefetchHooks Function({bool symptomEntryWithTagRefs})> {
  $$UserTagsTableTableManager(_$AppDatabase db, $UserTagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) =>
              UserTagsCompanion(
            id: id,
            name: name,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
          }) =>
              UserTagsCompanion.insert(
            id: id,
            name: name,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$UserTagsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({symptomEntryWithTagRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (symptomEntryWithTagRefs) db.symptomEntryWithTag
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (symptomEntryWithTagRefs)
                    await $_getPrefetchedData<UserTag, $UserTagsTable,
                            SymptomEntryWithTagData>(
                        currentTable: table,
                        referencedTable: $$UserTagsTableReferences
                            ._symptomEntryWithTagRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UserTagsTableReferences(db, table, p0)
                                .symptomEntryWithTagRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.userTagId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$UserTagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserTagsTable,
    UserTag,
    $$UserTagsTableFilterComposer,
    $$UserTagsTableOrderingComposer,
    $$UserTagsTableAnnotationComposer,
    $$UserTagsTableCreateCompanionBuilder,
    $$UserTagsTableUpdateCompanionBuilder,
    (UserTag, $$UserTagsTableReferences),
    UserTag,
    PrefetchHooks Function({bool symptomEntryWithTagRefs})>;
typedef $$SymptomEntryWithSymptomTableCreateCompanionBuilder
    = SymptomEntryWithSymptomCompanion Function({
  required int symptomEntryId,
  required int userSymptomId,
  Value<int> severity,
  Value<int> rowid,
});
typedef $$SymptomEntryWithSymptomTableUpdateCompanionBuilder
    = SymptomEntryWithSymptomCompanion Function({
  Value<int> symptomEntryId,
  Value<int> userSymptomId,
  Value<int> severity,
  Value<int> rowid,
});

final class $$SymptomEntryWithSymptomTableReferences extends BaseReferences<
    _$AppDatabase, $SymptomEntryWithSymptomTable, SymptomEntryWithSymptomData> {
  $$SymptomEntryWithSymptomTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $SymptomEntriesTable _symptomEntryIdTable(_$AppDatabase db) =>
      db.symptomEntries.createAlias($_aliasNameGenerator(
          db.symptomEntryWithSymptom.symptomEntryId, db.symptomEntries.id));

  $$SymptomEntriesTableProcessedTableManager get symptomEntryId {
    final $_column = $_itemColumn<int>('symptom_entry_id')!;

    final manager = $$SymptomEntriesTableTableManager($_db, $_db.symptomEntries)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_symptomEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UserSymptomsTable _userSymptomIdTable(_$AppDatabase db) =>
      db.userSymptoms.createAlias($_aliasNameGenerator(
          db.symptomEntryWithSymptom.userSymptomId, db.userSymptoms.id));

  $$UserSymptomsTableProcessedTableManager get userSymptomId {
    final $_column = $_itemColumn<int>('user_symptom_id')!;

    final manager = $$UserSymptomsTableTableManager($_db, $_db.userSymptoms)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userSymptomIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SymptomEntryWithSymptomTableFilterComposer
    extends Composer<_$AppDatabase, $SymptomEntryWithSymptomTable> {
  $$SymptomEntryWithSymptomTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get severity => $composableBuilder(
      column: $table.severity, builder: (column) => ColumnFilters(column));

  $$SymptomEntriesTableFilterComposer get symptomEntryId {
    final $$SymptomEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.symptomEntryId,
        referencedTable: $db.symptomEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SymptomEntriesTableFilterComposer(
              $db: $db,
              $table: $db.symptomEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UserSymptomsTableFilterComposer get userSymptomId {
    final $$UserSymptomsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userSymptomId,
        referencedTable: $db.userSymptoms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserSymptomsTableFilterComposer(
              $db: $db,
              $table: $db.userSymptoms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SymptomEntryWithSymptomTableOrderingComposer
    extends Composer<_$AppDatabase, $SymptomEntryWithSymptomTable> {
  $$SymptomEntryWithSymptomTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get severity => $composableBuilder(
      column: $table.severity, builder: (column) => ColumnOrderings(column));

  $$SymptomEntriesTableOrderingComposer get symptomEntryId {
    final $$SymptomEntriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.symptomEntryId,
        referencedTable: $db.symptomEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SymptomEntriesTableOrderingComposer(
              $db: $db,
              $table: $db.symptomEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UserSymptomsTableOrderingComposer get userSymptomId {
    final $$UserSymptomsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userSymptomId,
        referencedTable: $db.userSymptoms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserSymptomsTableOrderingComposer(
              $db: $db,
              $table: $db.userSymptoms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SymptomEntryWithSymptomTableAnnotationComposer
    extends Composer<_$AppDatabase, $SymptomEntryWithSymptomTable> {
  $$SymptomEntryWithSymptomTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  $$SymptomEntriesTableAnnotationComposer get symptomEntryId {
    final $$SymptomEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.symptomEntryId,
        referencedTable: $db.symptomEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SymptomEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.symptomEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UserSymptomsTableAnnotationComposer get userSymptomId {
    final $$UserSymptomsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userSymptomId,
        referencedTable: $db.userSymptoms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserSymptomsTableAnnotationComposer(
              $db: $db,
              $table: $db.userSymptoms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SymptomEntryWithSymptomTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SymptomEntryWithSymptomTable,
    SymptomEntryWithSymptomData,
    $$SymptomEntryWithSymptomTableFilterComposer,
    $$SymptomEntryWithSymptomTableOrderingComposer,
    $$SymptomEntryWithSymptomTableAnnotationComposer,
    $$SymptomEntryWithSymptomTableCreateCompanionBuilder,
    $$SymptomEntryWithSymptomTableUpdateCompanionBuilder,
    (SymptomEntryWithSymptomData, $$SymptomEntryWithSymptomTableReferences),
    SymptomEntryWithSymptomData,
    PrefetchHooks Function({bool symptomEntryId, bool userSymptomId})> {
  $$SymptomEntryWithSymptomTableTableManager(
      _$AppDatabase db, $SymptomEntryWithSymptomTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SymptomEntryWithSymptomTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$SymptomEntryWithSymptomTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SymptomEntryWithSymptomTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> symptomEntryId = const Value.absent(),
            Value<int> userSymptomId = const Value.absent(),
            Value<int> severity = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SymptomEntryWithSymptomCompanion(
            symptomEntryId: symptomEntryId,
            userSymptomId: userSymptomId,
            severity: severity,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int symptomEntryId,
            required int userSymptomId,
            Value<int> severity = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SymptomEntryWithSymptomCompanion.insert(
            symptomEntryId: symptomEntryId,
            userSymptomId: userSymptomId,
            severity: severity,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SymptomEntryWithSymptomTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {symptomEntryId = false, userSymptomId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (symptomEntryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.symptomEntryId,
                    referencedTable: $$SymptomEntryWithSymptomTableReferences
                        ._symptomEntryIdTable(db),
                    referencedColumn: $$SymptomEntryWithSymptomTableReferences
                        ._symptomEntryIdTable(db)
                        .id,
                  ) as T;
                }
                if (userSymptomId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userSymptomId,
                    referencedTable: $$SymptomEntryWithSymptomTableReferences
                        ._userSymptomIdTable(db),
                    referencedColumn: $$SymptomEntryWithSymptomTableReferences
                        ._userSymptomIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SymptomEntryWithSymptomTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $SymptomEntryWithSymptomTable,
        SymptomEntryWithSymptomData,
        $$SymptomEntryWithSymptomTableFilterComposer,
        $$SymptomEntryWithSymptomTableOrderingComposer,
        $$SymptomEntryWithSymptomTableAnnotationComposer,
        $$SymptomEntryWithSymptomTableCreateCompanionBuilder,
        $$SymptomEntryWithSymptomTableUpdateCompanionBuilder,
        (SymptomEntryWithSymptomData, $$SymptomEntryWithSymptomTableReferences),
        SymptomEntryWithSymptomData,
        PrefetchHooks Function({bool symptomEntryId, bool userSymptomId})>;
typedef $$SymptomEntryWithTagTableCreateCompanionBuilder
    = SymptomEntryWithTagCompanion Function({
  required int symptomEntryId,
  required int userTagId,
  Value<int> rowid,
});
typedef $$SymptomEntryWithTagTableUpdateCompanionBuilder
    = SymptomEntryWithTagCompanion Function({
  Value<int> symptomEntryId,
  Value<int> userTagId,
  Value<int> rowid,
});

final class $$SymptomEntryWithTagTableReferences extends BaseReferences<
    _$AppDatabase, $SymptomEntryWithTagTable, SymptomEntryWithTagData> {
  $$SymptomEntryWithTagTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $SymptomEntriesTable _symptomEntryIdTable(_$AppDatabase db) =>
      db.symptomEntries.createAlias($_aliasNameGenerator(
          db.symptomEntryWithTag.symptomEntryId, db.symptomEntries.id));

  $$SymptomEntriesTableProcessedTableManager get symptomEntryId {
    final $_column = $_itemColumn<int>('symptom_entry_id')!;

    final manager = $$SymptomEntriesTableTableManager($_db, $_db.symptomEntries)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_symptomEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UserTagsTable _userTagIdTable(_$AppDatabase db) =>
      db.userTags.createAlias($_aliasNameGenerator(
          db.symptomEntryWithTag.userTagId, db.userTags.id));

  $$UserTagsTableProcessedTableManager get userTagId {
    final $_column = $_itemColumn<int>('user_tag_id')!;

    final manager = $$UserTagsTableTableManager($_db, $_db.userTags)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userTagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SymptomEntryWithTagTableFilterComposer
    extends Composer<_$AppDatabase, $SymptomEntryWithTagTable> {
  $$SymptomEntryWithTagTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$SymptomEntriesTableFilterComposer get symptomEntryId {
    final $$SymptomEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.symptomEntryId,
        referencedTable: $db.symptomEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SymptomEntriesTableFilterComposer(
              $db: $db,
              $table: $db.symptomEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UserTagsTableFilterComposer get userTagId {
    final $$UserTagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userTagId,
        referencedTable: $db.userTags,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserTagsTableFilterComposer(
              $db: $db,
              $table: $db.userTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SymptomEntryWithTagTableOrderingComposer
    extends Composer<_$AppDatabase, $SymptomEntryWithTagTable> {
  $$SymptomEntryWithTagTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$SymptomEntriesTableOrderingComposer get symptomEntryId {
    final $$SymptomEntriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.symptomEntryId,
        referencedTable: $db.symptomEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SymptomEntriesTableOrderingComposer(
              $db: $db,
              $table: $db.symptomEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UserTagsTableOrderingComposer get userTagId {
    final $$UserTagsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userTagId,
        referencedTable: $db.userTags,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserTagsTableOrderingComposer(
              $db: $db,
              $table: $db.userTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SymptomEntryWithTagTableAnnotationComposer
    extends Composer<_$AppDatabase, $SymptomEntryWithTagTable> {
  $$SymptomEntryWithTagTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$SymptomEntriesTableAnnotationComposer get symptomEntryId {
    final $$SymptomEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.symptomEntryId,
        referencedTable: $db.symptomEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SymptomEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.symptomEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UserTagsTableAnnotationComposer get userTagId {
    final $$UserTagsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userTagId,
        referencedTable: $db.userTags,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserTagsTableAnnotationComposer(
              $db: $db,
              $table: $db.userTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SymptomEntryWithTagTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SymptomEntryWithTagTable,
    SymptomEntryWithTagData,
    $$SymptomEntryWithTagTableFilterComposer,
    $$SymptomEntryWithTagTableOrderingComposer,
    $$SymptomEntryWithTagTableAnnotationComposer,
    $$SymptomEntryWithTagTableCreateCompanionBuilder,
    $$SymptomEntryWithTagTableUpdateCompanionBuilder,
    (SymptomEntryWithTagData, $$SymptomEntryWithTagTableReferences),
    SymptomEntryWithTagData,
    PrefetchHooks Function({bool symptomEntryId, bool userTagId})> {
  $$SymptomEntryWithTagTableTableManager(
      _$AppDatabase db, $SymptomEntryWithTagTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SymptomEntryWithTagTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SymptomEntryWithTagTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SymptomEntryWithTagTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> symptomEntryId = const Value.absent(),
            Value<int> userTagId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SymptomEntryWithTagCompanion(
            symptomEntryId: symptomEntryId,
            userTagId: userTagId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int symptomEntryId,
            required int userTagId,
            Value<int> rowid = const Value.absent(),
          }) =>
              SymptomEntryWithTagCompanion.insert(
            symptomEntryId: symptomEntryId,
            userTagId: userTagId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SymptomEntryWithTagTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({symptomEntryId = false, userTagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (symptomEntryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.symptomEntryId,
                    referencedTable: $$SymptomEntryWithTagTableReferences
                        ._symptomEntryIdTable(db),
                    referencedColumn: $$SymptomEntryWithTagTableReferences
                        ._symptomEntryIdTable(db)
                        .id,
                  ) as T;
                }
                if (userTagId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userTagId,
                    referencedTable: $$SymptomEntryWithTagTableReferences
                        ._userTagIdTable(db),
                    referencedColumn: $$SymptomEntryWithTagTableReferences
                        ._userTagIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SymptomEntryWithTagTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SymptomEntryWithTagTable,
    SymptomEntryWithTagData,
    $$SymptomEntryWithTagTableFilterComposer,
    $$SymptomEntryWithTagTableOrderingComposer,
    $$SymptomEntryWithTagTableAnnotationComposer,
    $$SymptomEntryWithTagTableCreateCompanionBuilder,
    $$SymptomEntryWithTagTableUpdateCompanionBuilder,
    (SymptomEntryWithTagData, $$SymptomEntryWithTagTableReferences),
    SymptomEntryWithTagData,
    PrefetchHooks Function({bool symptomEntryId, bool userTagId})>;
typedef $$UnlockedAchievementsTableCreateCompanionBuilder
    = UnlockedAchievementsCompanion Function({
  required String achievementId,
  required DateTime unlockedAt,
  Value<int> progress,
  Value<int> rowid,
});
typedef $$UnlockedAchievementsTableUpdateCompanionBuilder
    = UnlockedAchievementsCompanion Function({
  Value<String> achievementId,
  Value<DateTime> unlockedAt,
  Value<int> progress,
  Value<int> rowid,
});

class $$UnlockedAchievementsTableFilterComposer
    extends Composer<_$AppDatabase, $UnlockedAchievementsTable> {
  $$UnlockedAchievementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get achievementId => $composableBuilder(
      column: $table.achievementId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get unlockedAt => $composableBuilder(
      column: $table.unlockedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnFilters(column));
}

class $$UnlockedAchievementsTableOrderingComposer
    extends Composer<_$AppDatabase, $UnlockedAchievementsTable> {
  $$UnlockedAchievementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get achievementId => $composableBuilder(
      column: $table.achievementId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get unlockedAt => $composableBuilder(
      column: $table.unlockedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnOrderings(column));
}

class $$UnlockedAchievementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnlockedAchievementsTable> {
  $$UnlockedAchievementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get achievementId => $composableBuilder(
      column: $table.achievementId, builder: (column) => column);

  GeneratedColumn<DateTime> get unlockedAt => $composableBuilder(
      column: $table.unlockedAt, builder: (column) => column);

  GeneratedColumn<int> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);
}

class $$UnlockedAchievementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UnlockedAchievementsTable,
    UnlockedAchievement,
    $$UnlockedAchievementsTableFilterComposer,
    $$UnlockedAchievementsTableOrderingComposer,
    $$UnlockedAchievementsTableAnnotationComposer,
    $$UnlockedAchievementsTableCreateCompanionBuilder,
    $$UnlockedAchievementsTableUpdateCompanionBuilder,
    (
      UnlockedAchievement,
      BaseReferences<_$AppDatabase, $UnlockedAchievementsTable,
          UnlockedAchievement>
    ),
    UnlockedAchievement,
    PrefetchHooks Function()> {
  $$UnlockedAchievementsTableTableManager(
      _$AppDatabase db, $UnlockedAchievementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnlockedAchievementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnlockedAchievementsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnlockedAchievementsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> achievementId = const Value.absent(),
            Value<DateTime> unlockedAt = const Value.absent(),
            Value<int> progress = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UnlockedAchievementsCompanion(
            achievementId: achievementId,
            unlockedAt: unlockedAt,
            progress: progress,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String achievementId,
            required DateTime unlockedAt,
            Value<int> progress = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UnlockedAchievementsCompanion.insert(
            achievementId: achievementId,
            unlockedAt: unlockedAt,
            progress: progress,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UnlockedAchievementsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $UnlockedAchievementsTable,
        UnlockedAchievement,
        $$UnlockedAchievementsTableFilterComposer,
        $$UnlockedAchievementsTableOrderingComposer,
        $$UnlockedAchievementsTableAnnotationComposer,
        $$UnlockedAchievementsTableCreateCompanionBuilder,
        $$UnlockedAchievementsTableUpdateCompanionBuilder,
        (
          UnlockedAchievement,
          BaseReferences<_$AppDatabase, $UnlockedAchievementsTable,
              UnlockedAchievement>
        ),
        UnlockedAchievement,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SymptomEntriesTableTableManager get symptomEntries =>
      $$SymptomEntriesTableTableManager(_db, _db.symptomEntries);
  $$UserSymptomsTableTableManager get userSymptoms =>
      $$UserSymptomsTableTableManager(_db, _db.userSymptoms);
  $$UserTagsTableTableManager get userTags =>
      $$UserTagsTableTableManager(_db, _db.userTags);
  $$SymptomEntryWithSymptomTableTableManager get symptomEntryWithSymptom =>
      $$SymptomEntryWithSymptomTableTableManager(
          _db, _db.symptomEntryWithSymptom);
  $$SymptomEntryWithTagTableTableManager get symptomEntryWithTag =>
      $$SymptomEntryWithTagTableTableManager(_db, _db.symptomEntryWithTag);
  $$UnlockedAchievementsTableTableManager get unlockedAchievements =>
      $$UnlockedAchievementsTableTableManager(_db, _db.unlockedAchievements);
}
