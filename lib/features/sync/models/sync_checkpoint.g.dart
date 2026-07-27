// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_checkpoint.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSyncCheckpointCollection on Isar {
  IsarCollection<SyncCheckpoint> get syncCheckpoints => this.collection();
}

const SyncCheckpointSchema = CollectionSchema(
  name: r'SyncCheckpoint1',
  id: -6969987133484667112,
  properties: {
    r'checkpointKey': PropertySchema(
      id: 0,
      name: r'checkpointKey',
      type: IsarType.string,
    ),
    r'entityType': PropertySchema(
      id: 1,
      name: r'entityType',
      type: IsarType.string,
    ),
    r'lastServerUpdatedAt': PropertySchema(
      id: 2,
      name: r'lastServerUpdatedAt',
      type: IsarType.dateTime,
    ),
    r'ownerUid': PropertySchema(
      id: 3,
      name: r'ownerUid',
      type: IsarType.string,
    ),
    r'tieBreakerDocId': PropertySchema(
      id: 4,
      name: r'tieBreakerDocId',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 5,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _syncCheckpointEstimateSize,
  serialize: _syncCheckpointSerialize,
  deserialize: _syncCheckpointDeserialize,
  deserializeProp: _syncCheckpointDeserializeProp,
  idName: r'id',
  indexes: {
    r'checkpointKey': IndexSchema(
      id: 887671787489577385,
      name: r'checkpointKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'checkpointKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'ownerUid': IndexSchema(
      id: -8016718989707307851,
      name: r'ownerUid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'ownerUid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _syncCheckpointGetId,
  getLinks: _syncCheckpointGetLinks,
  attach: _syncCheckpointAttach,
  version: '3.1.0+1',
);

int _syncCheckpointEstimateSize(
  SyncCheckpoint object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.checkpointKey.length * 3;
  bytesCount += 3 + object.entityType.length * 3;
  bytesCount += 3 + object.ownerUid.length * 3;
  {
    final value = object.tieBreakerDocId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _syncCheckpointSerialize(
  SyncCheckpoint object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.checkpointKey);
  writer.writeString(offsets[1], object.entityType);
  writer.writeDateTime(offsets[2], object.lastServerUpdatedAt);
  writer.writeString(offsets[3], object.ownerUid);
  writer.writeString(offsets[4], object.tieBreakerDocId);
  writer.writeDateTime(offsets[5], object.updatedAt);
}

SyncCheckpoint _syncCheckpointDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SyncCheckpoint();
  object.checkpointKey = reader.readString(offsets[0]);
  object.entityType = reader.readString(offsets[1]);
  object.id = id;
  object.lastServerUpdatedAt = reader.readDateTimeOrNull(offsets[2]);
  object.ownerUid = reader.readString(offsets[3]);
  object.tieBreakerDocId = reader.readStringOrNull(offsets[4]);
  object.updatedAt = reader.readDateTime(offsets[5]);
  return object;
}

P _syncCheckpointDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _syncCheckpointGetId(SyncCheckpoint object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _syncCheckpointGetLinks(SyncCheckpoint object) {
  return [];
}

void _syncCheckpointAttach(
    IsarCollection<dynamic> col, Id id, SyncCheckpoint object) {
  object.id = id;
}

extension SyncCheckpointByIndex on IsarCollection<SyncCheckpoint> {
  Future<SyncCheckpoint?> getByCheckpointKey(String checkpointKey) {
    return getByIndex(r'checkpointKey', [checkpointKey]);
  }

  SyncCheckpoint? getByCheckpointKeySync(String checkpointKey) {
    return getByIndexSync(r'checkpointKey', [checkpointKey]);
  }

  Future<bool> deleteByCheckpointKey(String checkpointKey) {
    return deleteByIndex(r'checkpointKey', [checkpointKey]);
  }

  bool deleteByCheckpointKeySync(String checkpointKey) {
    return deleteByIndexSync(r'checkpointKey', [checkpointKey]);
  }

  Future<List<SyncCheckpoint?>> getAllByCheckpointKey(
      List<String> checkpointKeyValues) {
    final values = checkpointKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'checkpointKey', values);
  }

  List<SyncCheckpoint?> getAllByCheckpointKeySync(
      List<String> checkpointKeyValues) {
    final values = checkpointKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'checkpointKey', values);
  }

  Future<int> deleteAllByCheckpointKey(List<String> checkpointKeyValues) {
    final values = checkpointKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'checkpointKey', values);
  }

  int deleteAllByCheckpointKeySync(List<String> checkpointKeyValues) {
    final values = checkpointKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'checkpointKey', values);
  }

  Future<Id> putByCheckpointKey(SyncCheckpoint object) {
    return putByIndex(r'checkpointKey', object);
  }

  Id putByCheckpointKeySync(SyncCheckpoint object, {bool saveLinks = true}) {
    return putByIndexSync(r'checkpointKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCheckpointKey(List<SyncCheckpoint> objects) {
    return putAllByIndex(r'checkpointKey', objects);
  }

  List<Id> putAllByCheckpointKeySync(List<SyncCheckpoint> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'checkpointKey', objects, saveLinks: saveLinks);
  }
}

extension SyncCheckpointQueryWhereSort
    on QueryBuilder<SyncCheckpoint, SyncCheckpoint, QWhere> {
  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SyncCheckpointQueryWhere
    on QueryBuilder<SyncCheckpoint, SyncCheckpoint, QWhereClause> {
  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterWhereClause> idBetween(
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

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterWhereClause>
      checkpointKeyEqualTo(String checkpointKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'checkpointKey',
        value: [checkpointKey],
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterWhereClause>
      checkpointKeyNotEqualTo(String checkpointKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'checkpointKey',
              lower: [],
              upper: [checkpointKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'checkpointKey',
              lower: [checkpointKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'checkpointKey',
              lower: [checkpointKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'checkpointKey',
              lower: [],
              upper: [checkpointKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterWhereClause>
      ownerUidEqualTo(String ownerUid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ownerUid',
        value: [ownerUid],
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterWhereClause>
      ownerUidNotEqualTo(String ownerUid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid',
              lower: [],
              upper: [ownerUid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid',
              lower: [ownerUid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid',
              lower: [ownerUid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerUid',
              lower: [],
              upper: [ownerUid],
              includeUpper: false,
            ));
      }
    });
  }
}

extension SyncCheckpointQueryFilter
    on QueryBuilder<SyncCheckpoint, SyncCheckpoint, QFilterCondition> {
  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      checkpointKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'checkpointKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      checkpointKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'checkpointKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      checkpointKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'checkpointKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      checkpointKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'checkpointKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      checkpointKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'checkpointKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      checkpointKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'checkpointKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      checkpointKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'checkpointKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      checkpointKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'checkpointKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      checkpointKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'checkpointKey',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      checkpointKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'checkpointKey',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      entityTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      entityTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      entityTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      entityTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'entityType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      entityTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      entityTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      entityTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      entityTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'entityType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      entityTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entityType',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      entityTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'entityType',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
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

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
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

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition> idBetween(
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

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      lastServerUpdatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastServerUpdatedAt',
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      lastServerUpdatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastServerUpdatedAt',
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      lastServerUpdatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastServerUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      lastServerUpdatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastServerUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      lastServerUpdatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastServerUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      lastServerUpdatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastServerUpdatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      ownerUidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      ownerUidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      ownerUidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      ownerUidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownerUid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      ownerUidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ownerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      ownerUidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ownerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      ownerUidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      ownerUidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownerUid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      ownerUidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerUid',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      ownerUidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownerUid',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      tieBreakerDocIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tieBreakerDocId',
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      tieBreakerDocIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tieBreakerDocId',
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      tieBreakerDocIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tieBreakerDocId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      tieBreakerDocIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tieBreakerDocId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      tieBreakerDocIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tieBreakerDocId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      tieBreakerDocIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tieBreakerDocId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      tieBreakerDocIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tieBreakerDocId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      tieBreakerDocIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tieBreakerDocId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      tieBreakerDocIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tieBreakerDocId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      tieBreakerDocIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tieBreakerDocId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      tieBreakerDocIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tieBreakerDocId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      tieBreakerDocIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tieBreakerDocId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SyncCheckpointQueryObject
    on QueryBuilder<SyncCheckpoint, SyncCheckpoint, QFilterCondition> {}

extension SyncCheckpointQueryLinks
    on QueryBuilder<SyncCheckpoint, SyncCheckpoint, QFilterCondition> {}

extension SyncCheckpointQuerySortBy
    on QueryBuilder<SyncCheckpoint, SyncCheckpoint, QSortBy> {
  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy>
      sortByCheckpointKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkpointKey', Sort.asc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy>
      sortByCheckpointKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkpointKey', Sort.desc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy>
      sortByEntityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.asc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy>
      sortByEntityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.desc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy>
      sortByLastServerUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastServerUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy>
      sortByLastServerUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastServerUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy> sortByOwnerUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.asc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy>
      sortByOwnerUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.desc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy>
      sortByTieBreakerDocId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tieBreakerDocId', Sort.asc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy>
      sortByTieBreakerDocIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tieBreakerDocId', Sort.desc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension SyncCheckpointQuerySortThenBy
    on QueryBuilder<SyncCheckpoint, SyncCheckpoint, QSortThenBy> {
  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy>
      thenByCheckpointKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkpointKey', Sort.asc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy>
      thenByCheckpointKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkpointKey', Sort.desc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy>
      thenByEntityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.asc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy>
      thenByEntityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.desc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy>
      thenByLastServerUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastServerUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy>
      thenByLastServerUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastServerUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy> thenByOwnerUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.asc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy>
      thenByOwnerUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.desc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy>
      thenByTieBreakerDocId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tieBreakerDocId', Sort.asc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy>
      thenByTieBreakerDocIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tieBreakerDocId', Sort.desc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension SyncCheckpointQueryWhereDistinct
    on QueryBuilder<SyncCheckpoint, SyncCheckpoint, QDistinct> {
  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QDistinct>
      distinctByCheckpointKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'checkpointKey',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QDistinct> distinctByEntityType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QDistinct>
      distinctByLastServerUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastServerUpdatedAt');
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QDistinct> distinctByOwnerUid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerUid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QDistinct>
      distinctByTieBreakerDocId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tieBreakerDocId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncCheckpoint, SyncCheckpoint, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension SyncCheckpointQueryProperty
    on QueryBuilder<SyncCheckpoint, SyncCheckpoint, QQueryProperty> {
  QueryBuilder<SyncCheckpoint, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SyncCheckpoint, String, QQueryOperations>
      checkpointKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'checkpointKey');
    });
  }

  QueryBuilder<SyncCheckpoint, String, QQueryOperations> entityTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityType');
    });
  }

  QueryBuilder<SyncCheckpoint, DateTime?, QQueryOperations>
      lastServerUpdatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastServerUpdatedAt');
    });
  }

  QueryBuilder<SyncCheckpoint, String, QQueryOperations> ownerUidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerUid');
    });
  }

  QueryBuilder<SyncCheckpoint, String?, QQueryOperations>
      tieBreakerDocIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tieBreakerDocId');
    });
  }

  QueryBuilder<SyncCheckpoint, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
