import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/models/candidate_model.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/candidate_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/utils/helpers.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/custom_button.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/custom_textfield.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pemilihan_ketua_kelas_informatika/services/persistent_storage_service.dart';

class ManageCandidatesScreen extends StatefulWidget {
  const ManageCandidatesScreen({Key? key}) : super(key: key);

  @override
  State<ManageCandidatesScreen> createState() => _ManageCandidatesScreenState();
}

class _ManageCandidatesScreenState extends State<ManageCandidatesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ketuaController =
      TextEditingController(); // Ganti dari name1Controller
  final _wakilController =
      TextEditingController(); // Ganti dari name2Controller
  final _visiController = TextEditingController();
  final _misiController = TextEditingController();

  // Byte data untuk menyimpan gambar yang dipilih
  Uint8List? _fotoKetuaBytes;
  Uint8List? _fotoWakilBytes;
  String? _fotoKetuaExtension;
  String? _fotoWakilExtension;

  // Untuk preview gambar yang sudah ada (saat edit)
  String? _existingFotoKetua;
  String? _existingFotoWakil;

  CandidateModel? _editingCandidate;

  final ImagePicker _picker = ImagePicker();
  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final candidateProvider = context.read<CandidateProvider>();
      if (candidateProvider.candidates.isEmpty) {
        candidateProvider.fetchCandidates();
      }
    });
  }

  @override
  void dispose() {
    _ketuaController.dispose();
    _wakilController.dispose();
    _visiController.dispose();
    _misiController.dispose();
    super.dispose();
  }

  // Fungsi untuk memilih gambar - langsung tanpa permission handler terpisah
  Future<void> _pickImage(int candidateNumber,
      {bool fromCamera = false}) async {
    if (!mounted) return;

    setState(() {
      _isLoadingImage = true;
    });

    try {
      debugPrint('Memulai pemilihan gambar untuk kandidat $candidateNumber');

      final source = fromCamera ? ImageSource.camera : ImageSource.gallery;

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1280,
        maxHeight: 1280,
      );

      if (pickedFile == null) {
        if (mounted) {
          setState(() => _isLoadingImage = false);
        }
        return;
      }

      final extension = pickedFile.name.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(extension)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Format gambar harus JPG atau PNG'),
              duration: Duration(seconds: 3),
            ),
          );
          setState(() => _isLoadingImage = false);
        }
        return;
      }

      final imageBytes = await pickedFile.readAsBytes();
      if (imageBytes.lengthInBytes > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ukuran gambar maksimal 5MB'),
              duration: Duration(seconds: 3),
            ),
          );
          setState(() => _isLoadingImage = false);
        }
        return;
      }

      debugPrint('Gambar dipilih: ${pickedFile.path}');

      if (!mounted) return;

      setState(() {
        if (candidateNumber == 1) {
          _fotoKetuaBytes = imageBytes;
          _fotoKetuaExtension = extension;
          _existingFotoKetua = null;
        } else {
          _fotoWakilBytes = imageBytes;
          _fotoWakilExtension = extension;
          _existingFotoWakil = null;
        }
        _isLoadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto berhasil dipilih'),
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
    } on PlatformException catch (e) {
      debugPrint(
          'PlatformException saat memilih gambar: ${e.code} - ${e.message}');
      if (mounted) {
        String pesan = 'Gagal membuka galeri/kamera';
        if (e.code == 'photo_access_denied') {
          pesan =
              'Izin akses galeri ditolak. Ubah di Pengaturan > Izin Aplikasi.';
        } else if (e.code == 'camera_access_denied') {
          pesan =
              'Izin akses kamera ditolak. Ubah di Pengaturan > Izin Aplikasi.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pesan),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() => _isLoadingImage = false);
      }
    } catch (e) {
      debugPrint('Error memilih gambar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() => _isLoadingImage = false);
      }
    }
  }

  // Menampilkan dialog pilihan sumber gambar
  void _showImageSourceDialog(int candidateNumber) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Pilih Foto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(candidateNumber, fromCamera: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(candidateNumber, fromCamera: true);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Widget untuk menampilkan preview gambar
  Widget _buildImagePicker(String title, Uint8List? imageBytes,
      String? existingUrl, int candidateNumber) {
    final bool hasImage =
        imageBytes != null || (existingUrl != null && existingUrl.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: hasImage
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageBytes != null
                          ? Image.memory(
                              imageBytes,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildErrorImage(),
                            )
                          : _buildNetworkImage(existingUrl!),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.white, size: 20),
                          onPressed: () {
                            setState(() {
                              if (candidateNumber == 1) {
                                _fotoKetuaBytes = null;
                                _existingFotoKetua = null;
                              } else {
                                _fotoWakilBytes = null;
                                _existingFotoWakil = null;
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.white, size: 20),
                          onPressed: () =>
                              _showImageSourceDialog(candidateNumber),
                        ),
                      ),
                    ),
                  ],
                )
              : InkWell(
                  onTap: () => _showImageSourceDialog(candidateNumber),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _isLoadingImage
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  size: 40, color: Colors.grey.shade600),
                              const SizedBox(height: 8),
                              Text(
                                'Tap untuk pilih foto',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Galeri / Kamera',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          'Format: JPG, PNG (Maks 5MB)',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  // Helper untuk menampilkan network image atau base64
  Widget _buildNetworkImage(String url) {
    final imageProvider = AppHelpers.imageProviderFromUrl(url);
    if (imageProvider != null) {
      return Image(
        image: imageProvider,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
      );
    }

    return _buildErrorImage();
  }

  Widget _buildErrorImage() {
    return Container(
      height: 150,
      color: Colors.grey.shade200,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 40),
            SizedBox(height: 8),
            Text('Gagal memuat gambar'),
          ],
        ),
      ),
    );
  }

  void _clearForm() {
    setState(() {
      _ketuaController.clear();
      _wakilController.clear();
      _visiController.clear();
      _misiController.clear();
      _fotoKetuaBytes = null;
      _fotoWakilBytes = null;
      _fotoKetuaExtension = null;
      _fotoWakilExtension = null;
      _existingFotoKetua = null;
      _existingFotoWakil = null;
      _editingCandidate = null;
    });
  }

  void _editCandidate(CandidateModel candidate) {
    setState(() {
      _editingCandidate = candidate;
      _ketuaController.text = candidate.name1;
      _wakilController.text = candidate.name2;
      _visiController.text = candidate.visi;
      _misiController.text = candidate.misi;
      _fotoKetuaBytes = null;
      _fotoWakilBytes = null;
      _fotoKetuaExtension = null;
      _fotoWakilExtension = null;
      _existingFotoKetua = candidate.photoUrl1;
      _existingFotoWakil = candidate.photoUrl2;
    });
  }

  void _deleteCandidate(BuildContext context, CandidateModel candidate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kandidat'),
        content: Text(
            'Apakah Anda yakin ingin menghapus pasangan ${candidate.getNames}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context
                  .read<CandidateProvider>()
                  .deleteCandidate(candidate.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Pasangan kandidat berhasil dihapus')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  String? _bytesToDataUri(Uint8List bytes, String? extension) {
    if (extension == null) return null;
    final lower = extension.toLowerCase();
    final mimeType = lower == 'png'
        ? 'image/png'
        : 'image/jpeg';
    final base64String = base64Encode(bytes);
    return 'data:$mimeType;base64,$base64String';
  }

  Future<void> _saveCandidate(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoadingImage = true;
    });

    try {
      final candidateProvider = context.read<CandidateProvider>();
      final ketua = _ketuaController.text.trim();
      final wakil = _wakilController.text.trim();
      final visi = _visiController.text.trim();
      final misi = _misiController.text.trim();

      String? fotoKetua = _existingFotoKetua;
      String? fotoWakil = _existingFotoWakil;

      if (_fotoKetuaBytes != null) {
        fotoKetua = _bytesToDataUri(_fotoKetuaBytes!, _fotoKetuaExtension);
        debugPrint(
            '[ManageCandidate] Photo 1 data URI size: ${fotoKetua?.length ?? 0}');
      }

      if (_fotoWakilBytes != null) {
        fotoWakil = _bytesToDataUri(_fotoWakilBytes!, _fotoWakilExtension);
        debugPrint(
            '[ManageCandidate] Photo 2 data URI size: ${fotoWakil?.length ?? 0}');
      }

      if (_editingCandidate != null) {
        final updatedCandidate = _editingCandidate!.copyWith(
          name1: ketua,
          name2: wakil,
          visi: visi,
          misi: misi,
          photoUrl1: fotoKetua,
          photoUrl2: fotoWakil,
        );
        debugPrint(
            '[ManageCandidate] Updating candidate ID: ${updatedCandidate.id}');
        await candidateProvider.updateCandidate(updatedCandidate);

        // Verify data was saved by reloading from storage
        await candidateProvider.fetchCandidates();
        final savedCandidate = candidateProvider.candidates.firstWhere(
          (c) => c.id == updatedCandidate.id,
          orElse: () => CandidateModel(
              id: -1,
              name1: '',
              name2: '',
              visi: '',
              misi: '',
              photoUrl1: '',
              photoUrl2: '',
              voteCount: 0),
        );

        if (savedCandidate.id != -1 &&
            savedCandidate.name1 == updatedCandidate.name1) {
          // Verify photo was also saved
          final photo1Valid = savedCandidate.photoUrl1 != null &&
              savedCandidate.photoUrl1!.isNotEmpty &&
              (fotoKetua == null || savedCandidate.photoUrl1 == fotoKetua || 
               fotoKetua.isEmpty);
          final photo2Valid = savedCandidate.photoUrl2 != null &&
              savedCandidate.photoUrl2!.isNotEmpty &&
              (fotoWakil == null || savedCandidate.photoUrl2 == fotoWakil ||
               fotoWakil.isEmpty);
          
          debugPrint(
              '[ManageCandidate] ✓ Candidate data verified as saved | Photo1: ${photo1Valid ? 'OK' : 'MISSING'} | Photo2: ${photo2Valid ? 'OK' : 'MISSING'}');
          debugPrint(
              '[ManageCandidate] Photo1 URL length: ${savedCandidate.photoUrl1?.length ?? 0}');
          debugPrint(
              '[ManageCandidate] Photo2 URL length: ${savedCandidate.photoUrl2?.length ?? 0}');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    '✓ Pasangan kandidat berhasil diperbarui dan disimpan permanen'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          debugPrint(
              '[ManageCandidate] ⚠ Candidate data may not have been saved properly');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    '⚠ Data tersimpan tapi verifikasi gagal. Silakan coba lagi.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        final newCandidate = CandidateModel(
          id: DateTime.now().millisecondsSinceEpoch,
          name1: ketua,
          name2: wakil,
          visi: visi,
          misi: misi,
          photoUrl1: fotoKetua,
          photoUrl2: fotoWakil,
          voteCount: 0,
        );
        debugPrint(
            '[ManageCandidate] Adding new candidate ID: ${newCandidate.id}');
        await candidateProvider.addCandidate(newCandidate);

        // Verify data was saved
        final storageInfo = await PersistentStorageService.getStorageInfo();
        debugPrint('[ManageCandidate] Storage info after save: $storageInfo');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  '✓ Pasangan kandidat berhasil ditambahkan dan disimpan'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      if (mounted) {
        _clearForm();
      }
    } catch (e) {
      debugPrint('[ManageCandidate] ✗ Error saving candidate: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Gagal menyimpan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pasangan Kandidat'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1A5F7A),
        foregroundColor: Colors.white,
      ),
      body: Consumer<CandidateProvider>(
        builder: (context, candidateProvider, _) {
          final candidates = candidateProvider.candidates;

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Form Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editingCandidate != null
                                ? 'Edit Pasangan Kandidat'
                                : 'Tambah Pasangan Kandidat Baru',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Nama Ketua Kelas',
                            hintText: 'Masukkan nama calon Ketua Kelas',
                            controller: _ketuaController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nama Ketua Kelas tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: 'Nama Wakil Ketua Kelas',
                            hintText: 'Masukkan nama calon Wakil Ketua Kelas',
                            controller: _wakilController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nama Wakil Ketua Kelas tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: 'Visi',
                            hintText: 'Masukkan visi pasangan calon',
                            controller: _visiController,
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Visi tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: 'Misi',
                            hintText: 'Masukkan misi pasangan calon',
                            controller: _misiController,
                            maxLines: 5,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Misi tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildImagePicker('Foto Ketua Kelas', _fotoKetuaBytes,
                              _existingFotoKetua, 1),
                          const SizedBox(height: 16),
                          _buildImagePicker('Foto Wakil Ketua Kelas',
                              _fotoWakilBytes, _existingFotoWakil, 2),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  label: _editingCandidate != null
                                      ? 'Simpan perubahan'
                                      : 'Tambah kandidat',
                                  icon: _editingCandidate != null
                                      ? Icons.save
                                      : Icons.person_add,
                                  onPressed: _isLoadingImage
                                      ? null
                                      : () => _saveCandidate(context),
                                  backgroundColor: _editingCandidate != null
                                      ? const Color(0xFFF2994A)
                                      : const Color(0xFF2D9CDB),
                                  textColor: Colors.white,
                                ),
                              ),
                              if (_editingCandidate != null) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _clearForm,
                                    icon: const Icon(Icons.cancel,
                                        color: Colors.grey),
                                    label: const Text('Batal'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.grey,
                                      side:
                                          const BorderSide(color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Candidates List
                  candidateProvider.isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : candidates.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text('Belum ada pasangan kandidat'),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: candidates.length,
                              itemBuilder: (context, index) {
                                final candidate = candidates[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 52,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              _buildAvatar(candidate.photoUrl1,
                                                  candidate.name1, 'K'),
                                              const SizedBox(width: 4),
                                              _buildAvatar(candidate.photoUrl2,
                                                  candidate.name2, 'W'),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                candidate.getNames,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Suara: ${candidate.voteCount}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Tooltip(
                                              message: 'Edit pasangan kandidat',
                                              child: IconButton(
                                                icon: const Icon(Icons.edit,
                                                    color: Colors.blue),
                                                onPressed: () =>
                                                    _editCandidate(candidate),
                                              ),
                                            ),
                                            Tooltip(
                                              message:
                                                  'Hapus pasangan kandidat',
                                              child: IconButton(
                                                icon: const Icon(
                                                    Icons.delete_forever,
                                                    color: Colors.red),
                                                onPressed: () =>
                                                    _deleteCandidate(
                                                        context, candidate),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper widget untuk avatar
  Widget _buildAvatar(String? photoUrl, String name, String defaultText) {
    final imageProvider = AppHelpers.imageProviderFromUrl(photoUrl);
    if (imageProvider != null) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: imageProvider,
        onBackgroundImageError: (_, __) {},
      );
    }

    return CircleAvatar(
      radius: 16,
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : defaultText),
    );
  }
}
