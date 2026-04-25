import 'package:tavernup_domain/tavernup_domain.dart';

import '../principal.dart';

/// Authorizing wrapper around a raw [IStoryNodeRepository].
///
/// Currently pass-through: every call delegates to the raw repository
/// regardless of the principal. Filter and projection logic per
/// principal will be added when the role catalog is filled in.
class StoryNodeRepositoryWrapper implements IStoryNodeRepository {
  final IStoryNodeRepository _raw;
  // ignore: unused_field
  final Principal _principal;

  StoryNodeRepositoryWrapper(this._raw, this._principal);

  @override
  Future<List<StoryNode>> getRoots(String userId) => _raw.getRoots(userId);

  @override
  Future<List<StoryNode>> getChildren(String parentId) =>
      _raw.getChildren(parentId);

  @override
  Future<StoryNode?> getById(String id) => _raw.getById(id);

  @override
  Future<StoryNode> create({
    required String title,
    String? description,
    String? imageUrl,
    String? systemKey,
    String? parentId,
  }) =>
      _raw.create(
        title: title,
        description: description,
        imageUrl: imageUrl,
        systemKey: systemKey,
        parentId: parentId,
      );

  @override
  Future<void> save(StoryNode node) => _raw.save(node);

  @override
  Future<void> delete(String id) => _raw.delete(id);

  @override
  Stream<List<StoryNode>> watchChildren(String parentId) =>
      _raw.watchChildren(parentId);
}
