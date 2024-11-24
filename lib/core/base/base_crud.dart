import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/api.dart';

abstract class BaseCRUD<T> extends ChangeNotifier {
  final Api api;
  List<T> items = [];
  bool isLoading = false;
  String? error;

  BaseCRUD(String collection) : api = Api(collection);

  // Abstract methods to be implemented by subclasses
  Map<String, dynamic> toJson(T item);
  T fromJson(Map<String, dynamic>? data, String id);

  // Helper method for structured logging
  void _logError(String method, dynamic error, [StackTrace? stackTrace]) {
    developer.log(
      'Error in $method: $error',
      name: runtimeType.toString(),
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Helper method for error handling
  Future<R?> _handleError<R>(
      String method, Future<R> Function() operation) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      _logError(method, e, stackTrace);
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<List<T>> fetchItems() async {
    isLoading = true;
    notifyListeners();

    try {
      var result = await api.getDataCollection();
      items = result.docs
          .map((doc) => fromJson(doc.data() as Map<String, dynamic>?, doc.id))
          .toList();
      return items;
    } catch (e, stackTrace) {
      _logError('fetchItems', e, stackTrace);
      return [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Stream<QuerySnapshot> fetchItemsAsStream() => api.streamDataCollection();

  Future<T?> getItem(String id) async {
    return _handleError('getItem', () async {
      var doc = await api.getDocumentById(id);
      return fromJson(doc.data() as Map<String, dynamic>?, doc.id);
    });
  }

  Future<void> removeItem(String id) async {
    await _handleError('removeItem', () async {
      await api.removeDocument(id);
      items.removeWhere(
          (item) => item is Map<String, dynamic> && item['id'] == id);
      notifyListeners();
    });
  }

  Future<T?> updateItem(T item, String id) async {
    return _handleError('updateItem', () async {
      await api.updateDocument(toJson(item), id);
      var doc = await api.getDocumentById(id);
      var updatedItem = fromJson(doc.data() as Map<String, dynamic>?, doc.id);

      // Update local items list
      final index =
          items.indexWhere((i) => i is Map<String, dynamic> && i['id'] == id);
      if (index != -1) {
        items[index] = updatedItem;
        notifyListeners();
      }

      return updatedItem;
    });
  }

  Future<T?> addItem(T item) async {
    return _handleError('addItem', () async {
      var docRef = await api.addDocument(toJson(item));
      var doc = await docRef.get();
      var newItem = fromJson(doc.data() as Map<String, dynamic>?, doc.id);
      items.add(newItem);
      notifyListeners();
      return newItem;
    });
  }

  // Common query methods
  Future<List<T>> getItemsWhere(String field, dynamic value) async {
    try {
      var result = await api.getDataCollectionWhere(field, value);
      return result.docs
          .map((doc) => fromJson(doc.data() as Map<String, dynamic>?, doc.id))
          .toList();
    } catch (e, stackTrace) {
      _logError('getItemsWhere', e, stackTrace);
      return [];
    }
  }

  Future<List<T>> fetchPaginatedItems({
    required int pageSize,
    DocumentSnapshot? lastDocument,
    String? orderBy,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      var query = api.ref.limit(pageSize);
      if (orderBy != null) {
        query = query.orderBy(orderBy);
      }
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      var result = await query.get();
      var newItems = result.docs
          .map((doc) => fromJson(doc.data() as Map<String, dynamic>?, doc.id))
          .toList();

      return newItems;
    } catch (e, stackTrace) {
      _logError('fetchPaginatedItems', e, stackTrace);
      return [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Helper method for search functionality
  Future<List<T>> searchItems(String field, String searchTerm) async {
    try {
      var result = await api.ref
          .where(field, isGreaterThanOrEqualTo: searchTerm)
          .where(field, isLessThan: '${searchTerm}z')
          .get();

      return result.docs
          .map((doc) => fromJson(doc.data() as Map<String, dynamic>?, doc.id))
          .toList();
    } catch (e, stackTrace) {
      _logError('searchItems', e, stackTrace);
      return [];
    }
  }
}
