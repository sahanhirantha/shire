import 'package:flutter/foundation.dart';
import 'package:shire/models/user.dart';

class Shout {
  String message;
  User user;
  DateTime timestamp;

  Shout({@required this.message,@required this.user,@required this.timestamp});
}
