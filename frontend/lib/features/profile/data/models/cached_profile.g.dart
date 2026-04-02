// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_profile.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedProfileCollection on Isar {
  IsarCollection<CachedProfile> get cachedProfiles => this.collection();
}

const CachedProfileSchema = CollectionSchema(
  name: r'CachedProfile',
  id: -3272954809300854847,
  properties: {
    r'cachedAt': PropertySchema(
      id: 0,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'contentJson': PropertySchema(
      id: 1,
      name: r'contentJson',
      type: IsarType.string,
    ),
    r'username': PropertySchema(
      id: 2,
      name: r'username',
      type: IsarType.string,
    ),
  },
  estimateSize: _cachedProfileEstimateSize,
  serialize: _cachedProfileSerialize,
  deserialize: _cachedProfileDeserialize,
  deserializeProp: _cachedProfileDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'username': IndexSchema(
      id: -2899563114555695793,
      name: r'username',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'username',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedProfileGetId,
  getLinks: _cachedProfileGetLinks,
  attach: _cachedProfileAttach,
  version: '3.1.0+1',
);

int _cachedProfileEstimateSize(
  CachedProfile object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.contentJson.length * 3;
  bytesCount += 3 + object.username.length * 3;
  return bytesCount;
}

void _cachedProfileSerialize(
  CachedProfile object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.cachedAt);
  writer.writeString(offsets[1], object.contentJson);
  writer.writeString(offsets[2], object.username);
}

CachedProfile _cachedProfileDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedProfile();
  object.cachedAt = reader.readDateTime(offsets[0]);
  object.contentJson = reader.readString(offsets[1]);
  object.isarId = id;
  object.username = reader.readString(offsets[2]);
  return object;
}

P _cachedProfileDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedProfileGetId(CachedProfile object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _cachedProfileGetLinks(CachedProfile object) {
  return [];
}

void _cachedProfileAttach(
  IsarCollection<dynamic> col,
  Id id,
  CachedProfile object,
) {
  object.isarId = id;
}

extension CachedProfileByIndex on IsarCollection<CachedProfile> {
  Future<CachedProfile?> getByUsername(String username) {
    return getByIndex(r'username', [username]);
  }

  CachedProfile? getByUsernameSync(String username) {
    return getByIndexSync(r'username', [username]);
  }

  Future<bool> deleteByUsername(String username) {
    return deleteByIndex(r'username', [username]);
  }

  bool deleteByUsernameSync(String username) {
    return deleteByIndexSync(r'username', [username]);
  }

  Future<List<CachedProfile?>> getAllByUsername(List<String> usernameValues) {
    final values = usernameValues.map((e) => [e]).toList();
    return getAllByIndex(r'username', values);
  }

  List<CachedProfile?> getAllByUsernameSync(List<String> usernameValues) {
    final values = usernameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'username', values);
  }

  Future<int> deleteAllByUsername(List<String> usernameValues) {
    final values = usernameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'username', values);
  }

  int deleteAllByUsernameSync(List<String> usernameValues) {
    final values = usernameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'username', values);
  }

  Future<Id> putByUsername(CachedProfile object) {
    return putByIndex(r'username', object);
  }

  Id putByUsernameSync(CachedProfile object, {bool saveLinks = true}) {
    return putByIndexSync(r'username', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUsername(List<CachedProfile> objects) {
    return putAllByIndex(r'username', objects);
  }

  List<Id> putAllByUsernameSync(
    List<CachedProfile> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'username', objects, saveLinks: saveLinks);
  }
}

extension CachedProfileQueryWhereSort
    on QueryBuilder<CachedProfile, CachedProfile, QWhere> {
  QueryBuilder<CachedProfile, CachedProfile, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedProfileQueryWhere
    on QueryBuilder<CachedProfile, CachedProfile, QWhereClause> {
  QueryBuilder<CachedProfile, CachedProfile, QAfterWhereClause> isarIdEqualTo(
    Id isarId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(lower: isarId, upper: isarId),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterWhereClause>
  isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterWhereClause>
  isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterWhereClause> isarIdLessThan(
    Id isarId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerIsarId,
          includeLower: includeLower,
          upper: upperIsarId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterWhereClause> usernameEqualTo(
    String username,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'username', value: [username]),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterWhereClause>
  usernameNotEqualTo(String username) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'username',
                lower: [],
                upper: [username],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'username',
                lower: [username],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'username',
                lower: [username],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'username',
                lower: [],
                upper: [username],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension CachedProfileQueryFilter
    on QueryBuilder<CachedProfile, CachedProfile, QFilterCondition> {
  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  cachedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cachedAt', value: value),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  cachedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cachedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  cachedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cachedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  cachedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cachedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  contentJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'contentJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  contentJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'contentJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  contentJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'contentJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  contentJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'contentJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  contentJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'contentJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  contentJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'contentJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  contentJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'contentJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  contentJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'contentJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  contentJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'contentJson', value: ''),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  contentJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'contentJson', value: ''),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isarId', value: value),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  isarIdGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  isarIdLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'isarId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  usernameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'username',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  usernameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'username',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  usernameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'username',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  usernameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'username',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  usernameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'username',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  usernameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'username',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  usernameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'username',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  usernameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'username',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  usernameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'username', value: ''),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
  usernameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'username', value: ''),
      );
    });
  }
}

extension CachedProfileQueryObject
    on QueryBuilder<CachedProfile, CachedProfile, QFilterCondition> {}

extension CachedProfileQueryLinks
    on QueryBuilder<CachedProfile, CachedProfile, QFilterCondition> {}

extension CachedProfileQuerySortBy
    on QueryBuilder<CachedProfile, CachedProfile, QSortBy> {
  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy>
  sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByContentJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentJson', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy>
  sortByContentJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentJson', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy>
  sortByUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.desc);
    });
  }
}

extension CachedProfileQuerySortThenBy
    on QueryBuilder<CachedProfile, CachedProfile, QSortThenBy> {
  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy>
  thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByContentJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentJson', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy>
  thenByContentJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentJson', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy>
  thenByUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.desc);
    });
  }
}

extension CachedProfileQueryWhereDistinct
    on QueryBuilder<CachedProfile, CachedProfile, QDistinct> {
  QueryBuilder<CachedProfile, CachedProfile, QDistinct> distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QDistinct> distinctByContentJson({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contentJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QDistinct> distinctByUsername({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'username', caseSensitive: caseSensitive);
    });
  }
}

extension CachedProfileQueryProperty
    on QueryBuilder<CachedProfile, CachedProfile, QQueryProperty> {
  QueryBuilder<CachedProfile, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<CachedProfile, DateTime, QQueryOperations> cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<CachedProfile, String, QQueryOperations> contentJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contentJson');
    });
  }

  QueryBuilder<CachedProfile, String, QQueryOperations> usernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'username');
    });
  }
}
