import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pemilihan_ketua_kelas_informatika/services/local_storage.dart';
import 'package:pemilihan_ketua_kelas_informatika/services/voting_service.dart';
import 'package:pemilihan_ketua_kelas_informatika/utils/exceptions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    await LocalStorage.clear();
    await VotingService.resetData();
  });

  tearDown(() async {
    await LocalStorage.clear();
    await VotingService.resetData();
  });

  test('Unit Test Voting: submitVote records a vote and prevents duplicate voting', () async {
    const userId = '1';
    const candidateId = 2;

    final submittedVote = await VotingService.submitVote(userId, candidateId);

    expect(submittedVote.userId, userId);
    expect(submittedVote.candidateId, candidateId);
    expect(await VotingService.hasUserVoted(userId), isTrue);
    expect(await VotingService.getTotalVotes(), 1);

    final results = await VotingService.getVoteResults();
    expect(results[candidateId], 1);

    expect(
      () async => await VotingService.submitVote(userId, candidateId),
      throwsA(isA<VotingException>()),
    );
  });

  test('Unit Test Hitung Suara: vote calculation returns correct vote counts and percentages', () async {
    await VotingService.submitVote('1', 1);
    await VotingService.submitVote('2', 1);
    await VotingService.submitVote('3', 2);

    final results = await VotingService.getVoteResults();
    expect(results[1], 2);
    expect(results[2], 1);
    expect(results[3], isNull);

    final totalVotes = await VotingService.getTotalVotes();
    expect(totalVotes, 3);

    final percentageCandidate1 = await VotingService.getVotePercentage(1);
    final percentageCandidate2 = await VotingService.getVotePercentage(2);

    expect(percentageCandidate1, closeTo(66.666, 0.1));
    expect(percentageCandidate2, closeTo(33.333, 0.1));
  });

  test('Integration Test E-Voting: input pemilih, voting, dan hasil akhir berjalan lengkap', () async {
    const userId = '4';
    const candidateId = 3;

    expect(await VotingService.hasUserVoted(userId), isFalse);

    final vote = await VotingService.submitVote(userId, candidateId);
    expect(vote.userId, userId);
    expect(vote.candidateId, candidateId);

    final hasVoted = await VotingService.hasUserVoted(userId);
    final userVote = await VotingService.getUserVote(userId);
    final voteResults = await VotingService.getVoteResults();
    final totalVotes = await VotingService.getTotalVotes();

    expect(hasVoted, isTrue);
    expect(userVote, isNotNull);
    expect(userVote?.candidateId, candidateId);
    expect(voteResults[candidateId], 1);
    expect(totalVotes, 1);

    // Ensure voting again is not allowed and no duplicate vote is counted.
    expect(
      () async => await VotingService.submitVote(userId, candidateId),
      throwsA(isA<VotingException>()),
    );

    final afterDuplicateAttemptTotal = await VotingService.getTotalVotes();
    expect(afterDuplicateAttemptTotal, 1);
  });
}
