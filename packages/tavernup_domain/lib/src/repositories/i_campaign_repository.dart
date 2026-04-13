import '../models/campaign.dart';

/// Repository interface for managing campaigns.
///
/// A campaign is a long-running narrative arc belonging to a game group.
/// It groups related adventures into a coherent story.
///
/// Implementations:
/// - `SupabaseCampaignRepository`: persists to Supabase
/// - `MockCampaignRepository`: in-memory implementation for testing
abstract interface class ICampaignRepository {
  /// Returns all campaigns for [gameGroupId].
  Future<List<Campaign>> getForGameGroup(String gameGroupId);

  /// Returns the campaign with [id], or null if not found.
  Future<Campaign?> getById(String id);

  /// Creates a new campaign in [gameGroupId].
  Future<Campaign> create({
    required String gameGroupId,
    required String name,
    String? description,
  });

  /// Updates the status of the campaign with [campaignId].
  Future<void> updateStatus(String campaignId, CampaignStatus status);
}
