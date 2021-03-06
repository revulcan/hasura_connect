import 'dart:convert';

import 'package:hasura_connect/src/domain/errors/errors.dart';
import 'package:hasura_connect/src/domain/models/request.dart';
import 'package:hasura_connect/src/domain/entities/response.dart';
import 'package:hasura_connect/src/infra/datasources/request_datasource.dart';
import 'package:http/http.dart' as http;

class PostHttpRequest implements RequestDatasource {
  final http.Client Function() clientFactory;

  PostHttpRequest(this.clientFactory);

  @override
  Future<Response> post({Request request}) async {
    final client = clientFactory();
    try {
      var response = await client.post(Uri.parse(request.url),
          body: request.query.toString(), headers: request.headers);
      if (response.statusCode == 200) {
        Map json = jsonDecode(response.body);
        if (json.containsKey('errors')) {
          throw HasuraRequestError.fromJson(
            (json['errors'][0]),
            request: request,
          );
        }
        return Response(
          data: json,
          statusCode: response.statusCode,
          request: request,
        );
      } else {
        throw ConnectionError('Connection Rejected', request: request);
      }
    } catch (e) {
      // When the phone is offline, the httpClient throws SocketException,
      // which will be converted to ConnectionError, so that the CacheInterceptor can,
      // handle the exception and serve the cached data
      print('Caught : ${e.toString()}');
      throw ConnectionError('Connection Rejected', request: request);
    } finally {
      client.close();
    }
  }
}
