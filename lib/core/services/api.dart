import 'package:cloud_firestore/cloud_firestore.dart';

class Api {
  late final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final String path;
  late CollectionReference ref;

  Api(this.path) {
    ref = _db.collection(path);
  }

  Future<QuerySnapshot> getDataCollection() {
    return ref.get();
  }

  Stream<QuerySnapshot> streamDataCollection() {
    return ref.snapshots();
  }

  Stream<DocumentSnapshot> streamDataDocument(String id) {
    return ref.doc(id).snapshots();
  }

  Stream<QuerySnapshot> streamDataCollectionWhereArrayContains(
      {required String arrayName, required String value}) {
    return _db
        .collection(path)
        .where(arrayName, arrayContains: value)
        .snapshots();
  }

  Future<DocumentSnapshot> getDocumentById(String id) {
    return ref.doc(id).get();
  }

  Future<void> removeDocument(String id) {
    return ref.doc(id).delete();
  }

  Future<DocumentReference> addDocument(Map data) {
    return ref.add(data);
  }

  Future addUserDocument(Map data, String id) {
    return ref.doc(id).set(data);
  }

  Future<void> updateDocument(Map data, String id) {
    return ref.doc(id).set(data, SetOptions(merge: true));
  }

  // Add the getDataCollectionWhere method
  Future<QuerySnapshot> getDataCollectionWhere(String field, String value) {
    return ref.where(field, isEqualTo: value).get();
  }
}
