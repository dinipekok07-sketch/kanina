import 'package:flutter/material.dart';
import 'package:pemilihan_ketua_kelas_informatika/models/candidate_model.dart';
import 'package:pemilihan_ketua_kelas_informatika/utils/helpers.dart';

class CandidateCard extends StatelessWidget {
  final CandidateModel candidate;
  final VoidCallback onVote;
  final bool isSelected;
  final VoidCallback? onDetail;

  const CandidateCard({
    Key? key,
    required this.candidate,
    required this.onVote,
    this.isSelected = false,
    this.onDetail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onVote,
      child: Card(
        elevation: isSelected ? 10 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: isSelected
              ? const BorderSide(color: Color(0xFF3182CE), width: 2.5)
              : BorderSide.none,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A365D).withOpacity(0.08),
                      const Color(0xFF3182CE).withOpacity(0.08),
                    ],
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _CandidateAvatar(
                    imageUrl: candidate.photoUrl1,
                    label: candidate.name1,
                  ),
                  const SizedBox(width: 8),
                  _CandidateAvatar(
                    imageUrl: candidate.photoUrl2,
                    label: candidate.name2,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pasangan Nomor ${candidate.id}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          candidate.getNames,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF3182CE),
                      size: 28,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF3182CE).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      candidate.visi,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Misi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      candidate.misi,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onVote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? const Color(0xFF3182CE)
                            : const Color(0xFF1A365D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isSelected ? 'Terpilih' : 'Pilih Kandidat',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (onDetail != null) ...[
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: onDetail,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF3182CE)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Lihat Detail'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CandidateAvatar extends StatelessWidget {
  final String? imageUrl;
  final String label;

  const _CandidateAvatar({
    Key? key,
    required this.imageUrl,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageProvider = AppHelpers.imageProviderFromUrl(imageUrl);

    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFF3182CE),
      child: ClipOval(
        child: imageProvider != null
            ? Image(
                image: imageProvider,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    label.isNotEmpty ? label[0].toUpperCase() : 'K',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  label.isNotEmpty ? label[0].toUpperCase() : 'K',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
      ),
    );
  }
}

