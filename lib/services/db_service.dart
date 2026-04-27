import 'package:appwrite/appwrite.dart';
import '../config/app_config.dart';
import '../models/models.dart';

/// Database service for RescueNet — full CRUD for disasters, resources, volunteers
class DbService {
  static final DbService _i = DbService._();
  factory DbService() => _i;
  DbService._();

  late Client _client;
  late Databases _db;
  late Account _account;

  void init() {
    _client = Client()
        .setEndpoint(AppConfig.endpoint)
        .setProject(AppConfig.projectId);
    _db = Databases(_client);
    _account = Account(_client);
  }

  Client get client => _client;
  Account get account => _account;

  // ── Auth ──
  Future<void> signup(String email, String pass, String name) async {
    await _account.create(userId: ID.unique(), email: email, password: pass, name: name);
    await _account.createEmailPasswordSession(email: email, password: pass);
  }

  Future<void> login(String email, String pass) async {
    await _account.createEmailPasswordSession(email: email, password: pass);
  }

  Future<void> logout() async {
    await _account.deleteSession(sessionId: 'current');
  }

  Future<dynamic> getUser() async {
    try { return await _account.get(); } catch (_) { return null; }
  }

  // ── Disasters ──
  Future<List<Disaster>> getDisasters() async {
    final r = await _db.listDocuments(
      databaseId: AppConfig.databaseId, collectionId: AppConfig.disastersCollection,
      queries: [Query.orderDesc('\$createdAt'), Query.limit(100)],
    );
    return r.documents.map((d) => Disaster.fromMap(d.data)).toList();
  }

  Future<void> addDisaster(Disaster d) async {
    await _db.createDocument(
      databaseId: AppConfig.databaseId, collectionId: AppConfig.disastersCollection,
      documentId: ID.unique(), data: d.toMap(),
    );
  }

  Future<void> updateDisaster(String id, Map<String, dynamic> data) async {
    await _db.updateDocument(
      databaseId: AppConfig.databaseId, collectionId: AppConfig.disastersCollection,
      documentId: id, data: data,
    );
  }

  Future<void> deleteDisaster(String id) async {
    await _db.deleteDocument(
      databaseId: AppConfig.databaseId, collectionId: AppConfig.disastersCollection, documentId: id,
    );
  }

  // ── Resources ──
  Future<List<ResourceRequest>> getResources(String disasterId) async {
    final r = await _db.listDocuments(
      databaseId: AppConfig.databaseId, collectionId: AppConfig.resourcesCollection,
      queries: [Query.equal('disasterId', disasterId), Query.orderDesc('\$createdAt'), Query.limit(100)],
    );
    return r.documents.map((d) => ResourceRequest.fromMap(d.data)).toList();
  }

  Future<List<ResourceRequest>> getAllResources() async {
    final r = await _db.listDocuments(
      databaseId: AppConfig.databaseId, collectionId: AppConfig.resourcesCollection,
      queries: [Query.orderDesc('\$createdAt'), Query.limit(100)],
    );
    return r.documents.map((d) => ResourceRequest.fromMap(d.data)).toList();
  }

  Future<void> addResource(ResourceRequest res) async {
    await _db.createDocument(
      databaseId: AppConfig.databaseId, collectionId: AppConfig.resourcesCollection,
      documentId: ID.unique(), data: res.toMap(),
    );
  }

  Future<void> updateResource(String id, Map<String, dynamic> data) async {
    await _db.updateDocument(
      databaseId: AppConfig.databaseId, collectionId: AppConfig.resourcesCollection,
      documentId: id, data: data,
    );
  }

  // ── Volunteers ──
  Future<List<Volunteer>> getVolunteers() async {
    final r = await _db.listDocuments(
      databaseId: AppConfig.databaseId, collectionId: AppConfig.volunteersCollection,
      queries: [Query.orderDesc('\$createdAt'), Query.limit(100)],
    );
    return r.documents.map((d) => Volunteer.fromMap(d.data)).toList();
  }

  Future<void> addVolunteer(Volunteer v) async {
    await _db.createDocument(
      databaseId: AppConfig.databaseId, collectionId: AppConfig.volunteersCollection,
      documentId: ID.unique(), data: v.toMap(),
    );
  }

  Future<void> updateVolunteer(String id, Map<String, dynamic> data) async {
    await _db.updateDocument(
      databaseId: AppConfig.databaseId, collectionId: AppConfig.volunteersCollection,
      documentId: id, data: data,
    );
  }
}
