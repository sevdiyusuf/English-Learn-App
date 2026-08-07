// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_pair_io.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetWordPairCollection on Isar {
  IsarCollection<WordPair> get wordPairs => this.collection();
}

const WordPairSchema = CollectionSchema(
  name: r'WordPair365',
  id: 7450263015964090,
  properties: {
    r'english': PropertySchema(id: 0, name: r'english', type: IsarType.string),
    r'learned': PropertySchema(id: 1, name: r'learned', type: IsarType.bool),
    r'setId': PropertySchema(id: 2, name: r'setId', type: IsarType.long),
    r'turkish': PropertySchema(id: 3, name: r'turkish', type: IsarType.string),
  },
  estimateSize: _wordPairEstimateSize,
  serialize: _wordPairSerialize,
  deserialize: _wordPairDeserialize,
  deserializeProp: _wordPairDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _wordPairGetId,
  getLinks: _wordPairGetLinks,
  attach: _wordPairAttach,
  version: '3.1.0+1',
);

int _wordPairEstimateSize(
  WordPair object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.english.length * 3;
  bytesCount += 3 + object.turkish.length * 3;
  return bytesCount;
}

void _wordPairSerialize(
  WordPair object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.english);
  writer.writeBool(offsets[1], object.learned);
  writer.writeLong(offsets[2], object.setId);
  writer.writeString(offsets[3], object.turkish);
}

WordPair _wordPairDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WordPair();
  object.english = reader.readString(offsets[0]);
  object.id = id;
  object.learned = reader.readBool(offsets[1]);
  object.setId = reader.readLong(offsets[2]);
  object.turkish = reader.readString(offsets[3]);
  return object;
}

P _wordPairDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _wordPairGetId(WordPair object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _wordPairGetLinks(WordPair object) {
  return [];
}

void _wordPairAttach(IsarCollection<dynamic> col, Id id, WordPair object) {
  object.id = id;
}

extension WordPairQueryWhereSort on QueryBuilder<WordPair, WordPair, QWhere> {
  QueryBuilder<WordPair, WordPair, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension WordPairQueryWhere on QueryBuilder<WordPair, WordPair, QWhereClause> {
  QueryBuilder<WordPair, WordPair, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<WordPair, WordPair, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension WordPairQueryFilter
    on QueryBuilder<WordPair, WordPair, QFilterCondition> {
  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> englishEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'english',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> englishGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'english',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> englishLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'english',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> englishBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'english',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> englishStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'english',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> englishEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'english',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> englishContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'english',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> englishMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'english',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> englishIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'english', value: ''),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> englishIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'english', value: ''),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> learnedEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'learned', value: value),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> setIdEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'setId', value: value),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> setIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'setId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> setIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'setId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> setIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'setId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> turkishEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'turkish',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> turkishGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'turkish',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> turkishLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'turkish',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> turkishBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'turkish',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> turkishStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'turkish',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> turkishEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'turkish',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> turkishContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'turkish',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> turkishMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'turkish',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> turkishIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'turkish', value: ''),
      );
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterFilterCondition> turkishIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'turkish', value: ''),
      );
    });
  }
}

extension WordPairQueryObject
    on QueryBuilder<WordPair, WordPair, QFilterCondition> {}

extension WordPairQueryLinks
    on QueryBuilder<WordPair, WordPair, QFilterCondition> {}

extension WordPairQuerySortBy on QueryBuilder<WordPair, WordPair, QSortBy> {
  QueryBuilder<WordPair, WordPair, QAfterSortBy> sortByEnglish() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'english', Sort.asc);
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterSortBy> sortByEnglishDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'english', Sort.desc);
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterSortBy> sortByLearned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'learned', Sort.asc);
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterSortBy> sortByLearnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'learned', Sort.desc);
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterSortBy> sortBySetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'setId', Sort.asc);
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterSortBy> sortBySetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'setId', Sort.desc);
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterSortBy> sortByTurkish() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'turkish', Sort.asc);
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterSortBy> sortByTurkishDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'turkish', Sort.desc);
    });
  }
}

extension WordPairQuerySortThenBy
    on QueryBuilder<WordPair, WordPair, QSortThenBy> {
  QueryBuilder<WordPair, WordPair, QAfterSortBy> thenByEnglish() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'english', Sort.asc);
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterSortBy> thenByEnglishDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'english', Sort.desc);
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterSortBy> thenByLearned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'learned', Sort.asc);
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterSortBy> thenByLearnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'learned', Sort.desc);
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterSortBy> thenBySetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'setId', Sort.asc);
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterSortBy> thenBySetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'setId', Sort.desc);
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterSortBy> thenByTurkish() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'turkish', Sort.asc);
    });
  }

  QueryBuilder<WordPair, WordPair, QAfterSortBy> thenByTurkishDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'turkish', Sort.desc);
    });
  }
}

extension WordPairQueryWhereDistinct
    on QueryBuilder<WordPair, WordPair, QDistinct> {
  QueryBuilder<WordPair, WordPair, QDistinct> distinctByEnglish({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'english', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WordPair, WordPair, QDistinct> distinctByLearned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'learned');
    });
  }

  QueryBuilder<WordPair, WordPair, QDistinct> distinctBySetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'setId');
    });
  }

  QueryBuilder<WordPair, WordPair, QDistinct> distinctByTurkish({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'turkish', caseSensitive: caseSensitive);
    });
  }
}

extension WordPairQueryProperty
    on QueryBuilder<WordPair, WordPair, QQueryProperty> {
  QueryBuilder<WordPair, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<WordPair, String, QQueryOperations> englishProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'english');
    });
  }

  QueryBuilder<WordPair, bool, QQueryOperations> learnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'learned');
    });
  }

  QueryBuilder<WordPair, int, QQueryOperations> setIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'setId');
    });
  }

  QueryBuilder<WordPair, String, QQueryOperations> turkishProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'turkish');
    });
  }
}
