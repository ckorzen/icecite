library models;

import 'dart:js';
import 'dart:html';
import 'dart:collection';
import 'dart:async';
import 'dart:convert';
import 'dart:mirrors';

import '../auth/auth.dart';
import '../database/pouch_db.dart';
import '../database/library_entry_pouch_db.dart';
import '../database/supplements_pouch_db.dart';
import '../properties.dart';
import '../utils/html/logging_util.dart' as logging;
import 'package:polymer/polymer.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';

part 'pouchable.dart';
part 'user.dart';
part 'entry.dart';
part 'library_entry.dart';
part 'search_entry.dart';
part 'reference_entry.dart';
part 'pdf_annotation.dart';
part 'notification.dart';