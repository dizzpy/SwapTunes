// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_post.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedPostCollection on Isar {
  IsarCollection<CachedPost> get cachedPosts => this.collection();
}

const CachedPostSchema = CollectionSchema(
  name: r'CachedPost',
  id: -5355704694074994102,
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
    r'page': PropertySchema(id: 2, name: r'page', type: IsarType.long),
    r'postId': PropertySchema(id: 3, name: r'postId', type: IsarType.string),
  },
  estimateSize: _cachedPostEstimateSize,
  serialize: _cachedPostSerialize,
  deserialize: _cachedPostDeserialize,
  deserializeProp: _cachedPostDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'postId': IndexSchema(
      id: -544810920068516617,
      name: r'postId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'postId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'page': IndexSchema(
      id: -1004952015509011454,
      name: r'page',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'page',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedPostGetId,
  getLinks: _cachedPostGetLinks,
  attach: _cachedPostAttach,
  version: '3.1.0+1',
);

int _cachedPostEstimateSize(
  CachedPost object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.contentJson.length * 3;
  bytesCount += 3 + object.postId.length * 3;
  return bytesCount;
}

void _cachedPostSerialize(
  CachedPost object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.cachedAt);
  writer.writeString(offsets[1], object.contentJson);
  writer.writeLong(offsets[2], object.page);
  writer.writeString(offsets[3], object.postId);
}

CachedPost _cachedPostDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedPost();
  object.cachedAt = reader.readDateTime(offsets[0]);
  object.contentJson = reader.readString(offsets[1]);
  object.isarId = id;
  object.page = reader.readLong(offsets[2]);
  object.postId = reader.readString(offsets[3]);
  return object;
}

P _cachedPostDeserializeProp<P>(
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
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedPostGetId(CachedPost object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _cachedPostGetLinks(CachedPost object) {
  return [];
}

void _cachedPostAttach(IsarCollection<dynamic> col, Id id, CachedPost object) {
  object.isarId = id;
}

extension CachedPostQueryWhereSort
    on QueryBuilder<CachedPost, CachedPost, QWhere> {
  QueryBuilder<CachedPost, CachedPost, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterWhere> anyPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'page'),
      );
    });
  }
}

extension CachedPostQueryWhere
    on QueryBuilder<CachedPost, CachedPost, QWhereClause> {
  QueryBuilder<CachedPost, CachedPost, QAfterWhereClause> isarIdEqualTo(
    Id isarId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(lower: isarId, upper: isarId),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterWhereClause> isarIdNotEqualTo(
    Id isarId,
  ) {
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

  QueryBuilder<CachedPost, CachedPost, QAfterWhereClause> isarIdGreaterThan(
    Id isarId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterWhereClause> isarIdLessThan(
    Id isarId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterWhereClause> isarIdBetween(
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

  QueryBuilder<CachedPost, CachedPost, QAfterWhereClause> postIdEqualTo(
    String postId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'postId', value: [postId]),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterWhereClause> postIdNotEqualTo(
    String postId,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'postId',
                lower: [],
                upper: [postId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'postId',
                lower: [postId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'postId',
                lower: [postId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'postId',
                lower: [],
                upper: [postId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterWhereClause> pageEqualTo(
    int page,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'page', value: [page]),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterWhereClause> pageNotEqualTo(
    int page,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'page',
                lower: [],
                upper: [page],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'page',
                lower: [page],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'page',
                lower: [page],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'page',
                lower: [],
                upper: [page],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterWhereClause> pageGreaterThan(
    int page, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'page',
          lower: [page],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterWhereClause> pageLessThan(
    int page, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'page',
          lower: [],
          upper: [page],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterWhereClause> pageBetween(
    int lowerPage,
    int upperPage, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'page',
          lower: [lowerPage],
          includeLower: includeLower,
          upper: [upperPage],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension CachedPostQueryFilter
    on QueryBuilder<CachedPost, CachedPost, QFilterCondition> {
  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition> cachedAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cachedAt', value: value),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition>
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

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition> cachedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
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

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition> cachedAtBetween(
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

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition>
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

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition>
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

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition>
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

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition>
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

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition>
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

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition>
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

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition>
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

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition>
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

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition>
  contentJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'contentJson', value: ''),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition>
  contentJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'contentJson', value: ''),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition> isarIdEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isarId', value: value),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition> isarIdBetween(
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

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition> pageEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'page', value: value),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition> pageGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'page',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition> pageLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'page',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition> pageBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'page',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition> postIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'postId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition> postIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'postId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition> postIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'postId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition> postIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'postId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition> postIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'postId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition> postIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'postId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition> postIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'postId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition> postIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'postId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition> postIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'postId', value: ''),
      );
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterFilterCondition>
  postIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'postId', value: ''),
      );
    });
  }
}

extension CachedPostQueryObject
    on QueryBuilder<CachedPost, CachedPost, QFilterCondition> {}

extension CachedPostQueryLinks
    on QueryBuilder<CachedPost, CachedPost, QFilterCondition> {}

extension CachedPostQuerySortBy
    on QueryBuilder<CachedPost, CachedPost, QSortBy> {
  QueryBuilder<CachedPost, CachedPost, QAfterSortBy> sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterSortBy> sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterSortBy> sortByContentJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentJson', Sort.asc);
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterSortBy> sortByContentJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentJson', Sort.desc);
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterSortBy> sortByPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'page', Sort.asc);
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterSortBy> sortByPageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'page', Sort.desc);
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterSortBy> sortByPostId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postId', Sort.asc);
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterSortBy> sortByPostIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postId', Sort.desc);
    });
  }
}

extension CachedPostQuerySortThenBy
    on QueryBuilder<CachedPost, CachedPost, QSortThenBy> {
  QueryBuilder<CachedPost, CachedPost, QAfterSortBy> thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterSortBy> thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterSortBy> thenByContentJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentJson', Sort.asc);
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterSortBy> thenByContentJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentJson', Sort.desc);
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterSortBy> thenByPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'page', Sort.asc);
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterSortBy> thenByPageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'page', Sort.desc);
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterSortBy> thenByPostId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postId', Sort.asc);
    });
  }

  QueryBuilder<CachedPost, CachedPost, QAfterSortBy> thenByPostIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postId', Sort.desc);
    });
  }
}

extension CachedPostQueryWhereDistinct
    on QueryBuilder<CachedPost, CachedPost, QDistinct> {
  QueryBuilder<CachedPost, CachedPost, QDistinct> distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<CachedPost, CachedPost, QDistinct> distinctByContentJson({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contentJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedPost, CachedPost, QDistinct> distinctByPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'page');
    });
  }

  QueryBuilder<CachedPost, CachedPost, QDistinct> distinctByPostId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'postId', caseSensitive: caseSensitive);
    });
  }
}

extension CachedPostQueryProperty
    on QueryBuilder<CachedPost, CachedPost, QQueryProperty> {
  QueryBuilder<CachedPost, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<CachedPost, DateTime, QQueryOperations> cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<CachedPost, String, QQueryOperations> contentJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contentJson');
    });
  }

  QueryBuilder<CachedPost, int, QQueryOperations> pageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'page');
    });
  }

  QueryBuilder<CachedPost, String, QQueryOperations> postIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'postId');
    });
  }
}
