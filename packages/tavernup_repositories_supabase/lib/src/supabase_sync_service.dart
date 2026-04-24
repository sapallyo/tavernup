import 'package:supabase/supabase.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

/// Supabase implementation of [ISyncService].
///
/// Uses Supabase Realtime row-level streams to watch tables. Supabase
/// publishes row INSERT / UPDATE / DELETE events to matching subscribers,
/// so the returned streams reflect the database state live.
///
/// [watchById] completes when the target row disappears (delete or missing
/// on subscribe). [watchWhere] always emits the current filtered list on
/// each change — subscribers should replace their local list.
class SupabaseSyncService implements ISyncService {
  final SupabaseClient _client;

  SupabaseSyncService(this._client);

  @override
  Stream<T> watchById<T>(
    String collection,
    String id, {
    required T Function(Map<String, dynamic>) fromJson,
  }) async* {
    var seenRow = false;
    final rows = _client
        .from(collection)
        .stream(primaryKey: ['id'])
        .eq('id', id);
    await for (final batch in rows) {
      if (batch.isEmpty) {
        if (seenRow) return;
        continue;
      }
      seenRow = true;
      yield fromJson(batch.first);
    }
  }

  @override
  Stream<List<T>> watchWhere<T>(
    String collection, {
    required String field,
    required String value,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    return _client
        .from(collection)
        .stream(primaryKey: ['id'])
        .eq(field, value)
        .map((rows) => rows.map(fromJson).toList());
  }
}
