// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_schema_metadata.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalSchemaMetadataCollection on Isar {
  IsarCollection<LocalSchemaMetadata> get localSchemaMetadatas =>
      this.collection();
}

const LocalSchemaMetadataSchema = CollectionSchema(
  name: r'LocalSchemaMetadata1',
  id: -4161016041202823430,
  properties: {
    r'appliedAt': PropertySchema(
      id: 0,
      name: r'appliedAt',
      type: IsarType.dateTime,
    ),
    r'description': PropertySchema(
      id: 1,
      name: r'description',
      type: IsarType.string,
    ),
    r'isSuccessful': PropertySchema(
      id: 2,
      name: r'isSuccessful',
      type: IsarType.bool,
    ),
    r'version': PropertySchema(
      id: 3,
      name: r'version',
      type: IsarType.long,
    )
  },
  estimateSize: _localSchemaMetadataEstimateSize,
  serialize: _localSchemaMetadataSerialize,
  deserialize: _localSchemaMetadataDeserialize,
  deserializeProp: _localSchemaMetadataDeserializeProp,
  idName: r'id',
  indexes: {
    r'version': IndexSchema(
      id: -3425991338577364869,
      name: r'version',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'version',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _localSchemaMetadataGetId,
  getLinks: _localSchemaMetadataGetLinks,
  attach: _localSchemaMetadataAttach,
  version: '3.1.0+1',
);

int _localSchemaMetadataEstimateSize(
  LocalSchemaMetadata object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _localSchemaMetadataSerialize(
  LocalSchemaMetadata object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.appliedAt);
  writer.writeString(offsets[1], object.description);
  writer.writeBool(offsets[2], object.isSuccessful);
  writer.writeLong(offsets[3], object.version);
}

LocalSchemaMetadata _localSchemaMetadataDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalSchemaMetadata();
  object.appliedAt = reader.readDateTime(offsets[0]);
  object.description = reader.readStringOrNull(offsets[1]);
  object.id = id;
  object.isSuccessful = reader.readBool(offsets[2]);
  object.version = reader.readLong(offsets[3]);
  return object;
}

P _localSchemaMetadataDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localSchemaMetadataGetId(LocalSchemaMetadata object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _localSchemaMetadataGetLinks(
    LocalSchemaMetadata object) {
  return [];
}

void _localSchemaMetadataAttach(
    IsarCollection<dynamic> col, Id id, LocalSchemaMetadata object) {
  object.id = id;
}

extension LocalSchemaMetadataByIndex on IsarCollection<LocalSchemaMetadata> {
  Future<LocalSchemaMetadata?> getByVersion(int version) {
    return getByIndex(r'version', [version]);
  }

  LocalSchemaMetadata? getByVersionSync(int version) {
    return getByIndexSync(r'version', [version]);
  }

  Future<bool> deleteByVersion(int version) {
    return deleteByIndex(r'version', [version]);
  }

  bool deleteByVersionSync(int version) {
    return deleteByIndexSync(r'version', [version]);
  }

  Future<List<LocalSchemaMetadata?>> getAllByVersion(List<int> versionValues) {
    final values = versionValues.map((e) => [e]).toList();
    return getAllByIndex(r'version', values);
  }

  List<LocalSchemaMetadata?> getAllByVersionSync(List<int> versionValues) {
    final values = versionValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'version', values);
  }

  Future<int> deleteAllByVersion(List<int> versionValues) {
    final values = versionValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'version', values);
  }

  int deleteAllByVersionSync(List<int> versionValues) {
    final values = versionValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'version', values);
  }

  Future<Id> putByVersion(LocalSchemaMetadata object) {
    return putByIndex(r'version', object);
  }

  Id putByVersionSync(LocalSchemaMetadata object, {bool saveLinks = true}) {
    return putByIndexSync(r'version', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByVersion(List<LocalSchemaMetadata> objects) {
    return putAllByIndex(r'version', objects);
  }

  List<Id> putAllByVersionSync(List<LocalSchemaMetadata> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'version', objects, saveLinks: saveLinks);
  }
}

extension LocalSchemaMetadataQueryWhereSort
    on QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QWhere> {
  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterWhere>
      anyVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'version'),
      );
    });
  }
}

extension LocalSchemaMetadataQueryWhere
    on QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QWhereClause> {
  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterWhereClause>
      versionEqualTo(int version) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'version',
        value: [version],
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterWhereClause>
      versionNotEqualTo(int version) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'version',
              lower: [],
              upper: [version],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'version',
              lower: [version],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'version',
              lower: [version],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'version',
              lower: [],
              upper: [version],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterWhereClause>
      versionGreaterThan(
    int version, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'version',
        lower: [version],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterWhereClause>
      versionLessThan(
    int version, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'version',
        lower: [],
        upper: [version],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterWhereClause>
      versionBetween(
    int lowerVersion,
    int upperVersion, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'version',
        lower: [lowerVersion],
        includeLower: includeLower,
        upper: [upperVersion],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension LocalSchemaMetadataQueryFilter on QueryBuilder<LocalSchemaMetadata,
    LocalSchemaMetadata, QFilterCondition> {
  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      appliedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'appliedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      appliedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'appliedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      appliedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'appliedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      appliedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'appliedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      isSuccessfulEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSuccessful',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      versionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      versionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      versionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterFilterCondition>
      versionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'version',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension LocalSchemaMetadataQueryObject on QueryBuilder<LocalSchemaMetadata,
    LocalSchemaMetadata, QFilterCondition> {}

extension LocalSchemaMetadataQueryLinks on QueryBuilder<LocalSchemaMetadata,
    LocalSchemaMetadata, QFilterCondition> {}

extension LocalSchemaMetadataQuerySortBy
    on QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QSortBy> {
  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterSortBy>
      sortByAppliedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appliedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterSortBy>
      sortByAppliedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appliedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterSortBy>
      sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterSortBy>
      sortByIsSuccessful() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSuccessful', Sort.asc);
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterSortBy>
      sortByIsSuccessfulDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSuccessful', Sort.desc);
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterSortBy>
      sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterSortBy>
      sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension LocalSchemaMetadataQuerySortThenBy
    on QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QSortThenBy> {
  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterSortBy>
      thenByAppliedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appliedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterSortBy>
      thenByAppliedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appliedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterSortBy>
      thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterSortBy>
      thenByIsSuccessful() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSuccessful', Sort.asc);
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterSortBy>
      thenByIsSuccessfulDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSuccessful', Sort.desc);
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterSortBy>
      thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QAfterSortBy>
      thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension LocalSchemaMetadataQueryWhereDistinct
    on QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QDistinct> {
  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QDistinct>
      distinctByAppliedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'appliedAt');
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QDistinct>
      distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QDistinct>
      distinctByIsSuccessful() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSuccessful');
    });
  }

  QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QDistinct>
      distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }
}

extension LocalSchemaMetadataQueryProperty
    on QueryBuilder<LocalSchemaMetadata, LocalSchemaMetadata, QQueryProperty> {
  QueryBuilder<LocalSchemaMetadata, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LocalSchemaMetadata, DateTime, QQueryOperations>
      appliedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'appliedAt');
    });
  }

  QueryBuilder<LocalSchemaMetadata, String?, QQueryOperations>
      descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<LocalSchemaMetadata, bool, QQueryOperations>
      isSuccessfulProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSuccessful');
    });
  }

  QueryBuilder<LocalSchemaMetadata, int, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}
