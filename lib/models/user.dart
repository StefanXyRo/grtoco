class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      email: data['email'],
      displayName: data['displayName'],
      photoURL: data['photoURL'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
    };
  }
}
