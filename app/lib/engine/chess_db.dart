import 'dart:convert';
import 'dart:io';

import '../common/prt.dart';

class ChessDB {
  //
  static const kHost = 'www.chessdb.cn';
  static const kPath = '/chessdb.php';

  static Future<String?> query(String board, {String? banMoves}) async {
    //
    final queryParameters = (banMoves != null)
        ? {
            'action': 'queryall',
            'learn': '1',
            'showall': '1',
            'board': board,
            'ban': banMoves,
          }
        : {
            'action': 'queryall',
            'learn': '1',
            'showall': '1',
            'board': board,
          };

    Uri url = Uri(
      scheme: 'http',
      host: kHost,
      path: kPath,
      queryParameters: queryParameters,
    );

    final httpClient = HttpClient();
    httpClient.badCertificateCallback = (cert, String host, int port) => true;

    try {
      final request = await httpClient.getUrl(url);
      final response = await request.close();
      return await response.transform(utf8.decoder).join();
      //
    } catch (e) {
      prt('ChessDB.query: $e');
    } finally {
      httpClient.close();
    }

    return null;
  }

  static Future<String?> requestComputeBackground(String board) async {
    //
    Uri url = Uri(
      scheme: 'http',
      host: kHost,
      path: kPath,
      queryParameters: {'action': 'queue', 'board': board},
    );

    final httpClient = HttpClient();
    httpClient.badCertificateCallback = (cert, String host, int port) => true;

    try {
      final request = await httpClient.getUrl(url);
      final response = await request.close();
      return await response.transform(utf8.decoder).join();
      //
    } catch (e) {
      prt('requestComputeBackground: $e');
    } finally {
      httpClient.close();
    }

    return null;
  }
}
