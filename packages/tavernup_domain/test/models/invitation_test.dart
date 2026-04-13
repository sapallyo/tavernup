import 'package:test/test.dart';
import 'package:tavernup_domain/tavernup_domain.dart';

void main() {
  group('Invitation', () {
    final baseInvitation = Invitation(
      id: 'inv-1',
      gameGroupId: 'group-1',
      role: GameGroupRole.player,
      createdBy: 'user-1',
      invitedUserId: 'user-2',
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      createdAt: DateTime.now(),
    );

    group('status checks', () {
      test('pending invitation isValid', () {
        expect(baseInvitation.isValid, isTrue);
        expect(baseInvitation.isExpired, isFalse);
        expect(baseInvitation.isAccepted, isFalse);
      });

      test('expired invitation is not valid', () {
        final expired = Invitation(
          id: 'inv-2',
          gameGroupId: 'group-1',
          role: GameGroupRole.player,
          createdBy: 'user-1',
          invitedUserId: 'user-2',
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
        );
        expect(expired.isExpired, isTrue);
        expect(expired.isValid, isFalse);
      });

      test('accepted invitation is not valid', () {
        final accepted = baseInvitation.copyWith(
          status: InvitationStatus.accepted,
        );
        expect(accepted.isAccepted, isTrue);
        expect(accepted.isValid, isFalse);
      });

      test('rejected invitation is not valid', () {
        final rejected = baseInvitation.copyWith(
          status: InvitationStatus.rejected,
        );
        expect(rejected.isValid, isFalse);
      });
    });

    group('serialisation', () {
      test('fromJson roundtrip preserves status', () {
        final json = baseInvitation.toJson()
          ..['id'] = 'inv-1'
          ..['expires_at'] = baseInvitation.expiresAt.toIso8601String()
          ..['created_at'] = baseInvitation.createdAt.toIso8601String();
        final inv = Invitation.fromJson(json);
        expect(inv.status, InvitationStatus.pending);
        expect(inv.role, GameGroupRole.player);
      });

      test('fromJson defaults to pending for unknown status', () {
        final json = {
          'id': 'inv-1',
          'game_group_id': 'group-1',
          'role': 'player',
          'created_by': 'user-1',
          'invited_user_id': 'user-2',
          'expires_at':
              DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'status': 'unknown_status',
        };
        final inv = Invitation.fromJson(json);
        expect(inv.status, InvitationStatus.pending);
      });
    });

    group('InvitationStatus', () {
      test('fromString parses all values', () {
        expect(
            InvitationStatus.fromString('pending'), InvitationStatus.pending);
        expect(
            InvitationStatus.fromString('accepted'), InvitationStatus.accepted);
        expect(
            InvitationStatus.fromString('rejected'), InvitationStatus.rejected);
      });
    });
  });
}
