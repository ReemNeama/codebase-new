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

  factory StorageFile.fromMap(Map<String, dynamic> map) {
    return StorageFile(
      name: map['name'] as String,
      path: map['path'] as String,
      size: map['size'] as int,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      contentType: map['contentType'] as String,
      downloadUrl: map['downloadUrl'] as String,
    );
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
