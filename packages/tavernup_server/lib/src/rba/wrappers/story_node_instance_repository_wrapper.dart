import 'package:tavernup_domain/tavernup_domain.dart';

import '../principal.dart';

/// Authorizing wrapper around a raw [IStoryNodeInstanceRepository].
///
/// Currently pass-through: every call delegates to the raw repository
/// regardless of the principal. Filter and projection logic per
/// principal will be added when the role catalog is filled in.
class StoryNodeInstanceRepositoryWrapper
    implements IStoryNodeInstanceRepository {
  final IStoryNodeInstanceRepository _raw;
  // ignore: unused_field
  final Principal _principal;

  StoryNodeInstanceRepositoryWrapper(this._raw, this._principal);

  @override
  Future<StoryNodeInstance?> getById(String id) => _raw.getById(id);

  @override
  Future<List<StoryNodeInstance>> getForTemplate(String templateId) =>
      _raw.getForTemplate(templateId);

  @override
  Future<StoryNodeInstance> getOrCreate(String templateId) =>
      _raw.getOrCreate(templateId);

  @override
  Future<void> updateStatus(String id, StoryNodeStatus status) =>
      _raw.updateStatus(id, status);

  @override
  Future<void> delete(String id) => _raw.delete(id);
}
