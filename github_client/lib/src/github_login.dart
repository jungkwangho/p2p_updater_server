import 'dart:io';

import 'package:flutter/material.dart';
import 'package:github_client/src/github_oauth_credentials.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:url_launcher/url_launcher.dart';

final _authorizationEndpoint = Uri.parse('https://github.com/login/oauth/authorize');
final _tokenEndpoint = Uri.parse('https://github.com/login/oauth/access_token');

class GithubLoginWidget extends StatefulWidget {
  const GithubLoginWidget({
    required this.builder,
    required this.githubClientId,
    required this.githubClientSecret,
    required this.githubScopes,
    super.key,
  });
  final AuthenticatedBuilder builder;
  final String githubClientId;
  final String githubClientSecret;
  final List<String> githubScopes;

  @override
  State<GithubLoginWidget> createState() => _GithubLoginState();
}

typedef AuthenticatedBuilder = Widget Function(
  BuildContext context, oauth2.Client client);

class _GithubLoginState extends State<GithubLoginWidget>{
  HttpServer? _redirectServer; // local server
  oauth2.Client? _client;      // oauth2 client

  @override
  Widget build(BuildContext context){
    final client = _client;
    if (client != null){
      return widget.builder(context, client);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Github Login'),
      ),
      body: Center (
        child: ElevatedButton(
          onPressed: () async {

            // _redirectServer 가 NULL 이 아니면 닫는다.
            await _redirectServer?.close();

            // _redirectServer 를 새로 바인딩한다.
            _redirectServer = await HttpServer.bind('localhost', 0);

            // 1. id, secret, localhost:port 를 인자로 하여 github authorization endpoint url 을 띄운다.
            // 2. localhost:port 로 로컬 웹서버를 띄운다.
            // 3. 인증이 완료된 github authorization 페이지에서 localhost:port/auth?code=9c52edccba0a4c0eab91 를 호출하면
            // 4. code -> oauth2.Client(토큰) 으로 변환하여 반환한다.
            var authenticatedHttpClient = await _getOAuth2Client(
              Uri.parse('http://localhost:${_redirectServer!.port}/auth'));

            setState(() {
              _client = authenticatedHttpClient;
            });
          },
          child: const Text('Login to Github'),
        ),
      ),
    );
  }

  Future<oauth2.Client> _getOAuth2Client(Uri redirectUrl) async {
    if (widget.githubClientId.isEmpty || widget.githubClientSecret.isEmpty){
      throw const GithubLoginException(
        'githubClientId and githubClientSecret must be not empty. '
        'See `lib/github_oauth_credentials.dart` for more detail.');
    }

    var grant = oauth2.AuthorizationCodeGrant(
      widget.githubClientId,            // github 에서 생성한 사용자 oauth id
      _authorizationEndpoint,           // github 인증 url
      _tokenEndpoint,                   // github 토큰변환 url
      secret: widget.githubClientSecret, // github 에서 생성한 사용자 oauth password
      httpClient: _JsonAcceptingHttpClient(),
    );

    // github authorization endpoint url 을 생성한다.
    var authorizationUrl = grant.getAuthorizationUrl(redirectUrl, scopes: githubScopes);

    // 사용자 웹브라우저에서 github authorization endpoint url 로 redirect 한다. (이 주소에 localhost:port 주소가 포함되어있음)
    await _redirect(authorizationUrl);

    // github authorization endpoint 에서 인증이 완료된후 {code: 9c52edccba0a4c0eab91} 형태의 인증 코드를 받아온다.
    // 인증 완료시 까지 block
    var responseQueryParameters = await _listen();

    // 인증 코드를 oauth2 token으로 변환한다.
    var client = await grant.handleAuthorizationResponse(responseQueryParameters);
    print("after grant.handleAuthorizationRespose: $client");

    return client;
  }

  // Github 인증 페이지로 redirect 함
  Future<void> _redirect(Uri authorizationUrl) async {
    if (await canLaunchUrl(authorizationUrl)) {
      await launchUrl(authorizationUrl);
    }else{
      throw GithubLoginException('Could not launch $authorizationUrl');
    }
  }

  Future<Map<String, String>> _listen() async {
    // github 에서 localhost:port/auth?code=9c52edccba0a4c0eab91 를 호출하기 전까지 대기한다.
    var request = await _redirectServer!.first;
    var params = request.uri.queryParameters;
    request.response.statusCode = 200;
    request.response.headers.set('content-type', 'text/plain');
    request.response.writeln('Authenticated! You can close this tab.');
    await request.response.close();
    await _redirectServer!.close();
    _redirectServer = null;
    return params;
  }
}

// Json 형식 응답을 받기 위한 HttpClient
class _JsonAcceptingHttpClient extends http.BaseClient {
  final _httpClient = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request){
    request.headers['Accept'] = 'application/json';
    return _httpClient.send(request);
  }
}

// Exception 인터페이스 구현
class GithubLoginException implements Exception {
  const GithubLoginException(this.message);
  final String message;
  @override
  String toString() => message;
}