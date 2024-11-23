// lib/models/storage_file.dart

class StorageFile {
  final String name;
  final String path;
  final int size;
  final DateTime updatedAt;
  final String contentType;
  final String downloadUrl;

  StorageFile({
    required this.name,
    required this.path,
    required this.size,
    required this.updatedAt,
    required this.contentType,
    required this.downloadUrl,
  });

  String get url => downloadUrl;

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'path': path,
      'size': size,
      'updatedAt': updatedAt.toIso8601String(),
      'contentType': contentType,
      'downloadUrl': downloadUrl,
    };
  }

  factory StorageFile.empty() {
    return StorageFile(
      name: '',
      path: '',
      size: 0,
      updatedAt: DateTime.now(),
      contentType: 'application/octet-stream',
      downloadUrl: '',
    );
  }

  factory StorageFile.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return StorageFile.empty();
    }

    try {
      return StorageFile(
        name: map['name']?.toString() ?? '',
        path: map['path']?.toString() ?? '',
        size: (map['size'] as num?)?.toInt() ?? 0,
        updatedAt: map['updatedAt'] != null 
            ? DateTime.parse(map['updatedAt'].toString())
            : DateTime.now(),
        contentType: map['contentType']?.toString() ?? 'application/octet-stream',
        downloadUrl: map['downloadUrl']?.toString() ?? '',
      );
    } catch (e) {
      print('Error parsing StorageFile: $e');
      return StorageFile.empty();
    }
  }
}

class StorageStats {
  final int totalSize;
  final int fileCount;
  final Map<String, int> typeDistribution;

  StorageStats({
    required this.totalSize,
    required this.fileCount,
    required this.typeDistribution,
  });

  factory StorageStats.empty() {
    return StorageStats(
      totalSize: 0,
      fileCount: 0,
      typeDistribution: {},
    );
  }

  factory StorageStats.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return StorageStats.empty();
    }

    try {
      return StorageStats(
        totalSize: (map['totalSize'] as num?)?.toInt() ?? 0,
        fileCount: (map['fileCount'] as num?)?.toInt() ?? 0,
        typeDistribution: (map['typeDistribution'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, (value as num).toInt()),
        ) ?? {},
      );
    } catch (e) {
      print('Error parsing StorageStats: $e');
      return StorageStats.empty();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'totalSize': totalSize,
      'fileCount': fileCount,
      'typeDistribution': typeDistribution,
    };
  }

  String get formattedTotalSize {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    }
    if (totalSize < 1024 * 1024 * 1024) {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
